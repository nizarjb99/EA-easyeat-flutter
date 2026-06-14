class LlmResponse {
  final String message;
  final String response;
  final bool done;
  final String done_reason;

  LlmResponse({
    required this.message,
    required this.response,
    required this.done,
    required this.done_reason,
  });

  factory LlmResponse.fromJson(Map<String, dynamic> json) {
    return LlmResponse(
      message: json['message'].toString(),
      response: json['response'].toString(),
      done: json['done'] as bool,
      done_reason: json['done_reason'].toString(),
    );
  }
}
