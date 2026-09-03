import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/chat_message.dart';

/// Thrown when the AI call fails for a reason the person can act on
/// (missing/invalid key, network error, rate limit, etc). The [message] is
/// safe to show directly in the UI.
class AiChatException implements Exception {
  final String message;
  AiChatException(this.message);
  @override
  String toString() => message;
}

/// Calls the OpenAI Chat Completions API (also used by many
/// OpenAI-compatible providers). Requires the person to supply their own
/// API key in Settings ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â there is no built-in key, since API access is
/// tied to a paid/free account that only the person can create.
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  static const String _endpoint = 'https://api.openai.com/v1/chat/completions';

  /// Sends the full conversation so far (already trimmed to a reasonable
  /// length by the caller) and returns the assistant's reply text.
  /// Throws [AiChatException] with a user-facing message on any failure.
  Future<String> sendMessage({
    required String apiKey,
    required String model,
    required List<ChatMessage> history,
    String? systemPrompt,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw AiChatException(
          'Add your OpenAI API key in Settings to use the AI assistant.');
    }

    final List<Map<String, String>> messages = [];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    for (final m in history) {
      messages.add({
        'role': m.role == ChatRole.user ? 'user' : 'assistant',
        'content': m.content,
      });
    }

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${apiKey.trim()}',
            },
            body: jsonEncode({
              'model': model,
              'messages': messages,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw AiChatException(
          'Could not reach the AI service - check your internet connection and try again.');
    }

    if (response.statusCode == 401) {
      throw AiChatException(
          'That API key was rejected. Double-check it in Settings.');
    }
    if (response.statusCode == 429) {
      throw AiChatException(
          'Rate limit reached on your API key - wait a moment and try again.');
    }
    if (response.statusCode != 200) {
      String detail = 'Request failed (HTTP ${response.statusCode}).';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final errorField = decoded['error'];
          if (errorField is Map) {
            final errMsg = errorField['message'];
            if (errMsg is String && errMsg.isNotEmpty) {
              detail = errMsg;
            }
          }
        }
      } catch (_) {}
      throw AiChatException(detail);
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw AiChatException('The AI returned an empty response - try again.');
      }
      final firstChoice = choices[0];
      String? content;
      if (firstChoice is Map) {
        final messageField = firstChoice['message'];
        if (messageField is Map) {
          final contentField = messageField['content'];
          if (contentField is String) content = contentField;
        }
      }
      if (content == null || content.trim().isEmpty) {
        throw AiChatException('The AI returned an empty response - try again.');
      }
      return content.trim();
    } catch (e) {
      if (e is AiChatException) rethrow;
      throw AiChatException('Could not read the AI\'s response - try again.');
    }
  }
}
