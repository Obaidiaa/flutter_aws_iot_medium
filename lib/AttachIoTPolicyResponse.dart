import 'dart:convert';

class AttachIoTPolicyResponse {
  final AttachIoTPolicy attachIoTPolicy;

  AttachIoTPolicyResponse({
    required this.attachIoTPolicy,
  });

  factory AttachIoTPolicyResponse.fromJson(Map<String, dynamic> json) {
    return AttachIoTPolicyResponse(
      attachIoTPolicy: AttachIoTPolicy.fromJson(
          jsonDecode(json['AttachIoTPolicy'] as String)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AttachIoTPolicy': attachIoTPolicy.toJson(),
    };
  }
}

class AttachIoTPolicy {
  final int status;
  final String message;

  AttachIoTPolicy({
    required this.status,
    required this.message,
  });

  factory AttachIoTPolicy.fromJson(Map<String, dynamic> json) {
    return AttachIoTPolicy(
      status: json['status'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
    };
  }
}
