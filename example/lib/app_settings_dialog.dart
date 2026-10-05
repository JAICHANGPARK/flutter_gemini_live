import 'package:flutter/material.dart';
import 'package:record/record.dart';

import 'api_key_store.dart';
import 'app_translations.dart';

/// Modal dialog allowing users to view and update Gemini API Key, Live Model, and Audio Device.
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

  final AudioRecorder _audioRecorder = AudioRecorder();
  List<InputDevice> _audioDevices = [];
  String _selectedAudioDeviceId = '';
  bool _isLoadingDevices = true;

  late String _selectedModel;
  late String _selectedVoice;
  bool _obscureKey = true;
  bool _isCustomModel = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: ApiKeyStore.apiKey);
    _selectedAudioDeviceId = ApiKeyStore.audioDeviceId;
    _selectedVoice = ApiKeyStore.voice;

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

    _loadAudioDevices();
  }

  Future<void> _loadAudioDevices() async {
    try {
      final devices = await _audioRecorder.listInputDevices();
      if (mounted) {
        setState(() {
          _audioDevices = devices;
          _isLoadingDevices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDevices = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _customModelController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newKey = _keyController.text.trim();
    final newModel = _isCustomModel
        ? _customModelController.text.trim()
        : _selectedModel;

    await ApiKeyStore.save(newKey);
    await ApiKeyStore.saveModel(newModel);
    await ApiKeyStore.saveVoice(_selectedVoice);

    final selectedDev = _audioDevices
        .where((d) => d.id == _selectedAudioDeviceId)
        .firstOrNull;
    await ApiKeyStore.saveAudioDevice(
      _selectedAudioDeviceId,
      selectedDev?.label ?? '',
    );

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLanguageController.instance,
      builder: (context, _) {
        final t = AppLanguageController.instance.t;

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.tune_rounded, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.settingsDialogTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const LanguageSelectorButton(compact: true),
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
                  Text(
                    t.apiKeyLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
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
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.apiKeyFieldHint,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 18),

                  // 2. Model Selection
                  Text(
                    t.liveModelLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
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
                              fontWeight: isRecommended
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }),
                      DropdownMenuItem<String>(
                        value: 'custom',
                        child: Text(
                          t.customModelOption,
                          style: const TextStyle(fontSize: 13),
                        ),
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
                  const SizedBox(height: 18),

                  // 3. Voice (음성) Selection
                  Text(
                    t.voiceLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue:
                        ApiKeyStore.availableVoices.any(
                          (v) => v['name'] == _selectedVoice,
                        )
                        ? _selectedVoice
                        : ApiKeyStore.defaultVoice,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(
                        Icons.record_voice_over_rounded,
                        size: 20,
                      ),
                    ),
                    items: ApiKeyStore.availableVoices.map((voice) {
                      final name = voice['name']!;
                      final desc = voice['desc']!;
                      final isDefault = name == ApiKeyStore.defaultVoice;
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text(
                          isDefault
                              ? '$name -- $desc (Default)'
                              : '$name -- $desc',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isDefault
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _selectedVoice = val;
                      });
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.voiceSelectionDesc,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 18),

                  // 4. Audio Input Device (Microphone) Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.audioDeviceLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (_isLoadingDevices)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue:
                        _selectedAudioDeviceId.isEmpty ||
                            !_audioDevices.any(
                              (d) => d.id == _selectedAudioDeviceId,
                            )
                        ? ''
                        : _selectedAudioDeviceId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.mic_rounded, size: 20),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text(
                          t.defaultDeviceLabel,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      ..._audioDevices.map((dev) {
                        final label = dev.label.isNotEmpty
                            ? dev.label
                            : 'Device ${dev.id}';
                        return DropdownMenuItem<String>(
                          value: dev.id,
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedAudioDeviceId = val ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.audioDeviceDesc,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.cancelButton),
            ),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(t.saveButton),
            ),
          ],
        );
      },
    );
  }
}
