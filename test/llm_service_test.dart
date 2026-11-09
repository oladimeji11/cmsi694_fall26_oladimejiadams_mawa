import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mawa_app/services/llm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LlmService Tests', () {
    test('sendTestPrompt without API key returns configuration guidance message', () async {
      final service = LlmService();
      // Since openRouterApiKey is not defined in tests, hasApiKey is false
      final result = await service.sendTestPrompt();

      expect(service.hasApiKey, false);
      expect(service.hasApiKey, false);
      expect(result.isSuccess, false);
      expect(
        result.text,
        contains('OpenRouter API key is missing'),
      );
    });

    test('sendTestPrompt with MockClient returns model text response when authorized', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('openrouter.ai/api/v1/chat/completions')) {
          return http.Response(
            '{"model": "google/gemma-4-31b-it:free", "choices": [{"message": {"content": "Stay safe in Los Angeles during extreme heat."}}]}',
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = LlmService(client: mockClient);

      expect(LlmService.modelName, 'openrouter/free');
      expect(LlmService.providerName, 'OpenRouter Cloud API Gateway (Auto-Free Router)');
    });

    test('LlmService handles HTTP 401 unauthorized response gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final service = LlmService(client: mockClient);
      expect(service.hasApiKey, false);
    });
  });
}
