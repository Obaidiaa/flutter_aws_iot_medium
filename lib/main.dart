import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_aws_iot_medium/AttachIoTPolicyResponse.dart';
import 'package:flutter_aws_iot_medium/models/ModelProvider.dart';
import 'package:flutter_aws_iot_medium/mqtt_services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'amplify_outputs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _configureAmplify();
  } on AmplifyException catch (e) {
    safePrint("Error configuring Amplify: ${e.message}");
  }

  runApp(const MyApp());
}

Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugins([
      AmplifyAuthCognito(),
      AmplifyAPI(
        options: APIPluginOptions(modelProvider: ModelProvider.instance),
      ),
    ]);

    await Amplify.configure(amplifyConfig);
    safePrint('Successfully configured');
  } on Exception catch (e) {
    safePrint('Error configuring Amplify: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late MqttServices mqttServices;
  bool isConnected = false;
  String? username;
  String? identityId;

  @override
  void initState() {
    super.initState();
    mqttServices = MqttServices();
    _fetchIdentityId(); // Fetch identityId during initialization
  }

  Future<void> _fetchIdentityId() async {
    try {
      final authSession =
          await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      setState(() {
        username = authSession.userSubResult.value;
        identityId = authSession.identityIdResult.value;
      });
      safePrint('Username: $username');
    } catch (e) {
      safePrint('Failed to fetch identity ID: $e');
    }
  }

  void connectToAWSIoT() async {
    try {
      await mqttServices.init();
      setState(() {
        isConnected = true;
      });
      print('Connected to AWS IoT Core');
    } catch (e) {
      print('Failed to connect: $e');
    }
  }

  void disconnectFromAWSIoT() {
    try {
      mqttServices.disconnect();
      setState(() {
        isConnected = false;
      });
      print('Disconnected from AWS IoT Core');
    } catch (e) {
      print('Failed to disconnect: $e');
    }
  }

  // Function to execute Attach IoT Policy
  Future<AttachIoTPolicyResponse?> executeAttachIoTPolicy() async {
    if (username == null) {
      safePrint('Failed to fetch AWS credentials');
      return null;
    }
    try {
      // GraphQL query to attach IoT policy
      const graphQLDocument = '''
query AttachIoTPolicy(\$username: String!) {
  AttachIoTPolicy(username: \$username)
}
''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {"username": identityId},
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data == null) {
        safePrint('Response data is null');
        return null;
      }

      // Parse the JSON response
      Map<String, dynamic> jsonMap = json.decode(response.data!);
      AttachIoTPolicyResponse attachIoTPolicyResponse =
          AttachIoTPolicyResponse.fromJson(jsonMap);

      safePrint(attachIoTPolicyResponse.attachIoTPolicy.message);
    } catch (e) {
      safePrint('Query failed: ${e.toString()}');
    }
    return null;
  }

  TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Authenticator(
      child: MaterialApp(
        builder: Authenticator.builder(),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('AWS IoT Core Example'),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'AWS IoT Core with Flutter',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Show the Identity ID if fetched
                    if (username != null)
                      Text(
                        'Username: $username',
                        style: const TextStyle(fontSize: 16),
                      ),

                    const SizedBox(height: 16),

                    // Attach IoT Policy Button
                    ElevatedButton(
                      onPressed: executeAttachIoTPolicy,
                      child: const Text('Attach IoT Policy'),
                    ),

                    // Connect/Disconnect Button
                    isConnected
                        ? ElevatedButton(
                            onPressed: disconnectFromAWSIoT,
                            child: const Text('Disconnect from AWS IoT Core'),
                          )
                        : ElevatedButton(
                            onPressed: connectToAWSIoT,
                            child: const Text('Connect to AWS IoT Core'),
                          ),

                    const SizedBox(height: 16),

                    // Publish Message Button
                    if (isConnected && username != null)
                      Column(
                        children: [
                          TextFormField(
                            controller: messageController,
                            decoration: const InputDecoration(
                              hintText: 'Enter message to send',
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final topic = '${username!}/test/topic';
                              mqttServices.publishMessage(
                                topic,
                                MqttQos.atLeastOnce,
                                messageController.text,
                              );
                              print('Published to topic: $topic');
                            },
                            child: const Text('Send Message'),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // StreamBuilder to display MQTT messages
                    if (isConnected)
                      StreamBuilder(
                        stream: mqttServices.receivedMessage(),
                        initialData: 'No message received',
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.hasData
                                ? 'Received message: ${snapshot.data}'
                                : 'No message received',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
