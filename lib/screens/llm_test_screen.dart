import 'package:flutter/material.dart';
import '../services/llm_service.dart';

/// Developer test screen for verifying connection to open-weight AI models via OpenRouter API.
class LlmTestScreen extends StatefulWidget {
  final LlmService? llmService;

  const LlmTestScreen({super.key, this.llmService});

  @override
  State<LlmTestScreen> createState() => _LlmTestScreenState();
}

class _LlmTestScreenState extends State<LlmTestScreen> {
  late final LlmService _llmService;
  bool _isLoading = false;
  LlmResult? _result;

  @override
  void initState() {
    super.initState();
    _llmService = widget.llmService ?? LlmService();
  }

  Future<void> _sendTestPrompt() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    final res = await _llmService.sendTestPrompt();

    if (mounted) {
      setState(() {
        _result = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Connection Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Model Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.smart_toy_outlined,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Model Information',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      'Router Endpoint:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      LlmService.modelName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Provider:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      LlmService.providerName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'API Key Status:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Row(
                      children: [
                        Icon(
                          _llmService.hasApiKey
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
                          size: 16,
                          color: _llmService.hasApiKey
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _llmService.hasApiKey
                              ? 'Configured via --dart-define'
                              : 'Unconfigured (API key missing)',
                          style: TextStyle(
                            fontSize: 13,
                            color: _llmService.hasApiKey
                                ? Colors.green.shade700
                                : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Fixed Test Prompt Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fixed Test Prompt',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F9FF),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: const Color(0xFFCFE3F7)),
                      ),
                      child: Text(
                        LlmService.defaultTestPrompt,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Contains zero personal user data.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendTestPrompt,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Send Test Prompt to AI Model'),
              ),
            ),
            const SizedBox(height: 20),

            // AI Response Display Box
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Model Response',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Divider(height: 20),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('Connecting to AI Model...'),
                            ],
                          ),
                        ),
                      )
                    else if (_result != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F0FB),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.smart_toy_outlined,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Generated by: ${_result!.activeModel}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: _result!.isSuccess
                              ? const Color(0xFFF4F9FF)
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: _result!.isSuccess
                                ? const Color(0xFFCFE3F7)
                                : Colors.orange.shade200,
                          ),
                        ),
                        child: Text(
                          _result!.text,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _result!.isSuccess
                                    ? null
                                    : Colors.orange.shade900,
                              ),
                        ),
                      ),
                    ] else
                      const Text(
                        'Tap "Send Test Prompt" above to test the OpenRouter AI connection.',
                        style: TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
