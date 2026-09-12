import 'package:flutter/material.dart';

import 'api_key_store.dart';

/// Modal dialog allowing users to view and update Gemini API Key and Live Model.
class AppSettingsDialog extends StatefulWidget {
  const AppSettingsDialog({super.key});

  /// Displays the settings dialog and returns `true` if settings were updated.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const AppSettingsDialog(),
    );
  }

  @override
  State<AppSettingsDialog> createState() => _AppSettingsDialogState();
}

class _AppSettingsDialogState extends State<AppSettingsDialog> {
  late final TextEditingController _keyController;
  late final TextEditingController _customModelController;

  late String _selectedModel;
  bool _obscureKey = true;
  bool _isCustomModel = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: ApiKeyStore.apiKey);

    final currentModel = ApiKeyStore.liveModel;
    if (ApiKeyStore.availableModels.contains(currentModel)) {
      _selectedModel = currentModel;
      _customModelController = TextEditingController();
      _isCustomModel = false;
    } else {
      _selectedModel = 'custom';
      _customModelController = TextEditingController(text: currentModel);
      _isCustomModel = true;
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newKey = _keyController.text.trim();
    final newModel = _isCustomModel
        ? _customModelController.text.trim()
        : _selectedModel;

    await ApiKeyStore.save(newKey);
    await ApiKeyStore.saveModel(newModel);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.tune_rounded, color: Colors.blueAccent),
          SizedBox(width: 8),
          Text('Live API Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. API Key Field
              const Text(
                'Gemini API Key',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _keyController,
                obscureText: _obscureKey,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'AIzaSy...',
                  isDense: true,
                  prefixIcon: const Icon(Icons.key_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureKey ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Google AI Studio에서 발급받은 API 키를 입력하세요.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 18),

              // 2. Model Selection
              const Text(
                'Gemini Live Model',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedModel,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.psychology_rounded, size: 20),
                ),
                items: [
                  ...ApiKeyStore.availableModels.map((model) {
                    final isRecommended = model == ApiKeyStore.defaultModel;
                    return DropdownMenuItem<String>(
                      value: model,
                      child: Text(
                        isRecommended ? '$model (Recommended)' : model,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isRecommended ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                  const DropdownMenuItem<String>(
                    value: 'custom',
                    child: Text('Custom model (직접 입력)', style: TextStyle(fontSize: 13)),
                  ),
                ],
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    _selectedModel = val;
                    _isCustomModel = val == 'custom';
                  });
                },
              ),

              if (_isCustomModel) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _customModelController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Model Name',
                    hintText: 'e.g. gemini-2.0-flash-exp',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Save Settings'),
        ),
      ],
    );
  }
}
