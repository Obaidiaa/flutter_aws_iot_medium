import 'package:amplify_flutter/amplify_flutter.dart';

import 'package:aws_signature_v4/aws_signature_v4.dart';

String getWebSocketURL(
    {required String accessKey,
    required String secretKey,
    required String sessionToken,
    required String region,
    required String scheme,
    required String endpoint,
    required String urlPath}) {
  final creds = AWSCredentials(accessKey, secretKey, sessionToken);

  final signer = AWSSigV4Signer(
    credentialsProvider: AWSCredentialsProvider(creds),
  );

  final scope = AWSCredentialScope(
      region: region, service: const AWSService('iotdevicegateway'));

  final request = AWSHttpRequest(
    method: AWSHttpMethod.get,
    uri: Uri.https(endpoint, urlPath),
  );

  ServiceConfiguration serviceConfiguration =
      const BaseServiceConfiguration(omitSessionToken: true);

  var signed = signer.presignSync(request,
      credentialScope: scope,
      expiresIn: const Duration(hours: 1),
      serviceConfiguration: serviceConfiguration);
  var finalParams = signed.query;
  return '$scheme$endpoint$urlPath?$finalParams';
}
