import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_aws_iot_medium/mqtt_aws_iot.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttServices {
  late MqttServerClient client;
  late String username;

  init() async {
    safePrint('MQTT client initializing....');
    CognitoAuthSession awsCredentials = await fetchCognitoAuthSession();
    String? accessKey = awsCredentials.credentialsResult.value.accessKeyId;
    String? secretKey = awsCredentials.credentialsResult.value.secretAccessKey;
    String? sessionToken = awsCredentials.credentialsResult.value.sessionToken;
    String? identityId = awsCredentials.identityIdResult.value;
    username = awsCredentials.userSubResult.value;

    mqttConnect(accessKey, secretKey, sessionToken!, identityId, username);
  }

  disconnect() {
    client.disconnect();
  }

  Future mqttConnect(String accessKey, String secretKey, String sessionToken,
      String identityId, String username) async {
    // Your AWS region
    const region = 'us-east-2';
    // Your AWS IoT Core endpoint url
    const baseUrl = 'a2k4uqgawrkgp2-ats.iot.$region.amazonaws.com';
    const scheme = 'wss://';
    const urlPath = '/mqtt';
    // AWS IoT MQTT default port for websockets
    const port = 443;

    // Transform the url into a Websocket url using SigV4 signing
    String signedUrl = getWebSocketURL(
        accessKey: accessKey,
        secretKey: secretKey,
        sessionToken: sessionToken,
        region: region,
        scheme: scheme,
        endpoint: baseUrl,
        urlPath: urlPath);

    // Create the client with the signed url
    client = MqttServerClient.withPort(signedUrl, username, port,
        maxConnectionAttempts: 1);

    // Set the protocol to V3.1.1 for AWS IoT Core, if you fail to do this you will not receive a connect ack with the response code
    client.setProtocolV311();
    // logging if you wish
    client.logging(on: false);
    client.useWebSocket = true;
    client.secure = false;
    client.autoReconnect = false;
    client.disconnectOnNoResponsePeriod = 90;
    client.keepAlivePeriod = 30;
    // client.connectTimeoutPeriod = 2000;

    client.onConnected = onConnected;

    client.onDisconnected = onDisconnected;

    final MqttConnectMessage connMess =
        MqttConnectMessage().withClientIdentifier(username);

    client.connectionMessage = connMess;

    // Connect the client

    try {
      print('MQTT client connecting to AWS IoT using cognito....');
      await client.connect();
    } on Exception catch (e) {
      print('MQTT client exception - $e');
      if (e.toString().contains('NoConnectionException')) {
        print('MQTT client connecting....');
      }
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT client connected to AWS IoT');

      // Publish to a topic of your choice
      final topic = '$username/+/+';

      // // Important: AWS IoT Core can only handle QOS of 0 or 1. QOS 2 (exactlyOnce) will fail!
      // client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

      // Subscribe to the same topic
      client.subscribe(topic, MqttQos.atMostOnce);
      // Print incoming messages from another client on this topic
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final recMess = c[0].payload as MqttPublishMessage;
        final pt =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        print(
            'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
      });
    } else {
      print(
          'ERROR MQTT client connection failed - disconnecting, state is ${client.connectionStatus!.state}');
      client.disconnect();
    }

    print('Sleeping....');
    await MqttUtilities.asyncSleep(10);
  }

  Future publishMessage(String topic, MqttQos qos, String message) async {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, qos, builder.payload!);
  }

  Stream receivedMessage() {
    return client.updates!.map((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      return pt;
    });
  }

  /// The pre auto re connect callback
  void onAutoReconnect() {
    print(
        'EXAMPLE::onAutoReconnect client callback - Client auto reconnection sequence will start');
  }

  /// The post auto re connect callback
  void onAutoReconnected() {
    print(
        'EXAMPLE::onAutoReconnected client callback - Client auto reconnection sequence has completed');
  }

  /// The successful connect callback
  void onConnected() {
    print(
        'EXAMPLE::OnConnected client callback - Client connection was successful');
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    print(
        'EXAMPLE::OnDisconnected client callback - Client disconnection was unsolicited');
  }

  Future fetchCognitoAuthSession() async {
    try {
      final cognitoPlugin =
          Amplify.Auth.getPlugin(AmplifyAuthCognito.pluginKey);
      final result = await cognitoPlugin.fetchAuthSession();
      final identityId = result.identityIdResult.value;
      safePrint("Current user's identity ID: $identityId");
      return result;
    } on AuthException catch (e) {
      safePrint('Error retrieving auth session: ${e.message}');
    }
  }
}
