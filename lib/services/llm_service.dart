import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// DTO representing the response result from an LLM prompt request.
class LlmResult {
  final String text;
  final String activeModel;
  final bool isSuccess;

  const LlmResult({
    required this.text,
    required this.activeModel,
    required this.isSuccess,
  });
}

/// Service responsible for communicating with open-weight AI models via the OpenRouter Cloud API.
class LlmService {
  static const String modelName = 'openrouter/free';
  static const String fallbackModelName = 'google/gemma-4-31b-it:free';
  static const String providerName = 'OpenRouter Cloud API Gateway (Auto-Free Router)';
  static const String defaultTestPrompt =
      'Provide a 2-sentence plain-language environmental safety message for a resident in Los Angeles.';

  /// API key injected securely at build/run time via `--dart-define=OPENROUTER_API_KEY=your_key`.
  static const String openRouterApiKey =
      String.fromEnvironment('OPENROUTER_API_KEY');

  final http.Client _client;

  LlmService({http.Client? client}) : _client = client ?? http.Client();

  /// Returns true if an OpenRouter API key was passed at build time via --dart-define.
  bool get hasApiKey => openRouterApiKey.isNotEmpty;

  /// Sends a test prompt to OpenRouter's Auto-Free Router (with fallback) and returns the LlmResult.
  Future<LlmResult> sendTestPrompt({
    String prompt = defaultTestPrompt,
    String? targetModel,
  }) async {
    if (!hasApiKey) {
      return const LlmResult(
        text: 'OpenRouter API key is missing. Pass --dart-define=OPENROUTER_API_KEY=your_key at build time.',
        activeModel: modelName,
        isSuccess: false,
      );
    }

    final modelToUse = targetModel ?? modelName;

    try {
      final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
      final headers = {
        'Authorization': 'Bearer $openRouterApiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer':
            'https://github.com/oladimeji11/cmsi694_fall26_oladimejiadams_mawa',
        'X-Title': 'MAWA Environmental App',
      };

      final body = json.encode({
        'model': modelToUse,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
      });

      final response = await _client
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonMap = json.decode(response.body) as Map<String, dynamic>;
        final returnedModel = (jsonMap['model'] as String?) ?? modelToUse;
        final choices = jsonMap['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            return LlmResult(
              text: content.trim(),
              activeModel: returnedModel,
              isSuccess: true,
            );
          }
        }
        return LlmResult(
          text: 'Received empty response from model.',
          activeModel: returnedModel,
          isSuccess: false,
        );
      } else if (response.statusCode == 429 && modelToUse != fallbackModelName) {
        debugPrint(
          'MAWA OpenRouter 429 Rate Limit on $modelToUse. Automatically retrying with fallback model $fallbackModelName...',
        );
        return await sendTestPrompt(
          prompt: prompt,
          targetModel: fallbackModelName,
        );
      } else {
        String errorText = 'Unable to connect to AI model (HTTP ${response.statusCode}).';
        try {
          final errorMap = json.decode(response.body) as Map<String, dynamic>;
          final errorObj = errorMap['error'];
          if (errorObj is Map && errorObj['message'] != null) {
            errorText = 'OpenRouter Error (${response.statusCode}): ${errorObj['message']}';
          }
        } catch (_) {}
        if (response.statusCode == 401) {
          errorText = 'Unauthorized: Invalid OpenRouter API Key.';
        }
        return LlmResult(
          text: errorText,
          activeModel: modelToUse,
          isSuccess: false,
        );
      }
    } on SocketException catch (_) {
      return LlmResult(
        text: 'Network connection offline or unreachable.',
        activeModel: modelToUse,
        isSuccess: false,
      );
    } on http.ClientException catch (_) {
      return LlmResult(
        text: 'Network client error connecting to OpenRouter API.',
        activeModel: modelToUse,
        isSuccess: false,
      );
    } catch (e) {
      debugPrint('MAWA OpenRouter LLM API Error: $e');
      return LlmResult(
        text: 'Unable to connect to AI model.',
        activeModel: modelToUse,
        isSuccess: false,
      );
    }
  }
}
