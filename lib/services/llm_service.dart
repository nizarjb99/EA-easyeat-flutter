import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/llm.dart';

class LlmService {
  final String baseUrl = '${AppConstants.baseUrl}/llm';

  Future<Map<String, String>> _headers(String? token) async {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<LlmResponse> askAssistant(String message, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/generate'),
      headers: await _headers(token),
      body: json.encode({'model': "qwen2.5:14b", 'prompt': message}),
    );

    if (response.statusCode == 200) {
      return LlmResponse.fromJson(json.decode(response.body));
    } else if (response.statusCode == 400) {
      String message = json.decode(response.body)['message'];

      LlmResponse answer = LlmResponse(
        message: message,
        response:
            "There has been an error with missing parameters, please try again and, if the error persists, please, contact us.",
        done: true,
        done_reason: "Error",
      );

      return answer;
    } else {
      String message = json.decode(response.body)['message'];

      LlmResponse answer = LlmResponse(
        message: message,
        response:
            "There has been an error with the server, please try again and, if the error persists, please, contact us.",
        done: true,
        done_reason: "Error",
      );

      return answer;
    }
  }
}
