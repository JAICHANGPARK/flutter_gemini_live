import 'package:flutter/material.dart';

import '../model/models.dart';
import '../voices_service.dart';

/// Signature for building a custom voice resource card in [GeminiLiveVoiceStudioSheet].
typedef GeminiLiveVoiceResourceItemBuilder = Widget Function(
  BuildContext context,
  VoiceResource voice,
  VoidCallback onSelect,
  VoidCallback? onDelete,
);

/// An interactive Voice Design, Voice Remix ([PromptedVoice.baseVoice]), and
/// Custom Voice management studio sheet powered by [GeminiVoicesService].
///
/// Can be used either with a live [voicesService] (automatically calling
/// `createVoice`, `listVoices`, and `deleteVoice`) or in standalone mode via
/// [onCreateVoiceRequest] and [onSpeechConfigSelected].
class GeminiLiveVoiceStudioSheet extends StatefulWidget {
  /// Optional [GeminiVoicesService] (`genAI.voices`) to execute REST calls directly.
  final GeminiVoicesService? voicesService;

  /// Initial list of custom [VoiceResource] items to display.
  final List<VoiceResource> initialCustomVoices;

  /// Initial natural-language voice design prompt.
  final String? initialPrompt;

  /// Initial base voice name for Voice Remix (e.g. `'Puck'`, `'Leda'`), or `null` for from-scratch design.
  final String? initialBaseVoice;

  /// Callback invoked with the constructed [CreateVoiceRequest] when the user taps Create/Remix.
  final ValueChanged<CreateVoiceRequest>? onCreateVoiceRequest;

  /// Callback invoked when a [SpeechConfig] is selected or created.
  final ValueChanged<SpeechConfig>? onSpeechConfigSelected;

  /// Optional custom header builder.
  final WidgetBuilder? headerBuilder;

  /// Optional custom builder for each [VoiceResource] item in the saved list.
  final GeminiLiveVoiceResourceItemBuilder? voiceItemBuilder;

  /// Sheet title text. Defaults to `'Gemini Voice Studio'`.
  final String title;

  /// Subtitle text.
  final String subtitle;

  /// Primary button label. Defaults to `'Generate / Remix Voice'`.
  final String createButtonLabel;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Optional primary accent color override.
  final Color? accentColor;

  /// Creates a customizable [GeminiLiveVoiceStudioSheet].
  const GeminiLiveVoiceStudioSheet({
    super.key,
    this.voicesService,
    this.initialCustomVoices = const [],
    this.initialPrompt,
    this.initialBaseVoice,
    this.onCreateVoiceRequest,
    this.onSpeechConfigSelected,
    this.headerBuilder,
    this.voiceItemBuilder,
    this.title = 'Gemini Voice Studio',
    this.subtitle =
        'Design a new voice from a text prompt or remix one of the 30 prebuilt voices.',
    this.createButtonLabel = 'Generate / Remix Voice',
    this.backgroundColor,
    this.accentColor,
  });

  /// Presents [GeminiLiveVoiceStudioSheet] as a modal bottom sheet and returns
  /// the selected or newly created [SpeechConfig].
  static Future<SpeechConfig?> show(
    BuildContext context, {
    GeminiVoicesService? voicesService,
    List<VoiceResource> initialCustomVoices = const [],
    String? initialPrompt,
    String? initialBaseVoice,
    ValueChanged<CreateVoiceRequest>? onCreateVoiceRequest,
  }) {
    return showModalBottomSheet<SpeechConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GeminiLiveVoiceStudioSheet(
        voicesService: voicesService,
        initialCustomVoices: initialCustomVoices,
        initialPrompt: initialPrompt,
        initialBaseVoice: initialBaseVoice,
        onCreateVoiceRequest: onCreateVoiceRequest,
        onSpeechConfigSelected: (config) {
          Navigator.of(sheetContext).pop(config);
        },
      ),
    );
  }

  @override
  State<GeminiLiveVoiceStudioSheet> createState() =>
      _GeminiLiveVoiceStudioSheetState();
}

class _GeminiLiveVoiceStudioSheetState
    extends State<GeminiLiveVoiceStudioSheet> {
  late final TextEditingController _promptController;
  late final TextEditingController _nameController;
  String? _selectedBaseVoice;
  VoicePitch _selectedPitch = VoicePitch.medium;
  bool _storeOnServer = true;
  bool _isLoading = false;
  late List<VoiceResource> _customVoices;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.initialPrompt ?? '');
    _nameController = TextEditingController();
    _selectedBaseVoice = widget.initialBaseVoice;
    _customVoices = List<VoiceResource>.from(widget.initialCustomVoices);
  }

  @override
  void dispose() {
    _promptController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateVoice() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final request = CreateVoiceRequest.prompted(
      prompt: prompt,
      baseVoice: _selectedBaseVoice,
      displayName: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : null,
      pitch: _selectedPitch,
      store: _storeOnServer,
    );

    widget.onCreateVoiceRequest?.call(request);

    if (widget.voicesService != null) {
      setState(() => _isLoading = true);
      try {
        final created = await widget.voicesService!.createVoice(request);
        if (!mounted) return;
        setState(() {
          _customVoices.insert(0, created);
          _isLoading = false;
        });
        final voiceKeyOrId = created.id ?? created.key;
        if (voiceKeyOrId != null) {
          widget.onSpeechConfigSelected?.call(
            SpeechConfig.fromVoice(voiceKeyOrId),
          );
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
      return;
    }

    // Direct session SpeechConfig fallback when no REST service is injected
    widget.onSpeechConfigSelected?.call(
      SpeechConfig.withPromptedVoice(
        input: prompt,
        baseVoice: _selectedBaseVoice,
      ),
    );
  }

  Future<void> _handleDeleteVoice(VoiceResource voice) async {
    final id = voice.id;
    if (id != null && widget.voicesService != null) {
      try {
        await widget.voicesService!.deleteVoice(id);
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _customVoices.remove(voice);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = widget.accentColor ?? theme.colorScheme.primary;
    final bg =
        widget.backgroundColor ??
        (isDark ? const Color(0xFF18181B) : Colors.white);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20.0,
        14.0,
        20.0,
        24.0 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: 14.0),

            widget.headerBuilder?.call(context) ??
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.spatial_audio_off_rounded,
                          color: primary,
                          size: 22.0,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 17.0,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
            const SizedBox(height: 14.0),

            // Base voice selector for Voice Remix
            DropdownButtonFormField<String?>(
              initialValue: _selectedBaseVoice,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Base Voice to Remix (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'None (Design Voice From Scratch)',
                    style: TextStyle(fontSize: 13.0),
                  ),
                ),
                ...GeminiLiveVoice.values.map(
                  (v) => DropdownMenuItem<String?>(
                    value: v.voiceName,
                    child: Text(
                      '${v.voiceName} — ${v.tone}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.0),
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedBaseVoice = value;
                });
              },
            ),
            const SizedBox(height: 12.0),

            // Voice design / remix prompt
            TextField(
              controller: _promptController,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Voice Style & Persona Prompt',
                hintText:
                    'e.g., Speak slightly faster with a warm, cheerful anime heroine tone',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            const SizedBox(height: 12.0),

            // Display name + Pitch row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Display Name (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                SegmentedButton<VoicePitch>(
                  segments: const [
                    ButtonSegment(value: VoicePitch.low, label: Text('Low')),
                    ButtonSegment(value: VoicePitch.medium, label: Text('Mid')),
                    ButtonSegment(value: VoicePitch.high, label: Text('High')),
                  ],
                  selected: {_selectedPitch},
                  onSelectionChanged: (set) {
                    setState(() {
                      _selectedPitch = set.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8.0),

            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'Store in Google Voice Repository',
                style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'When off, returns an ephemeral client-managed voice key (voicekey_...).',
                style: TextStyle(fontSize: 11.5),
              ),
              value: _storeOnServer,
              onChanged: (v) => setState(() => _storeOnServer = v),
            ),
            const SizedBox(height: 10.0),

            FilledButton.icon(
              onPressed: _isLoading ? null : _handleCreateVoice,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16.0,
                      height: 16.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 18.0),
              label: Text(widget.createButtonLabel),
            ),

            // Saved custom voices list
            if (_customVoices.isNotEmpty) ...[
              const SizedBox(height: 16.0),
              Text(
                'Custom Voices (${_customVoices.length})',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8.0),
              for (final voice in _customVoices)
                widget.voiceItemBuilder != null
                    ? widget.voiceItemBuilder!(
                        context,
                        voice,
                        () {
                          final idOrKey = voice.id ?? voice.key;
                          if (idOrKey != null) {
                            widget.onSpeechConfigSelected?.call(
                              SpeechConfig.fromVoice(idOrKey),
                            );
                          }
                        },
                        () => _handleDeleteVoice(voice),
                      )
                    : ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                        ),
                        leading: Icon(Icons.graphic_eq_rounded, color: primary),
                        title: Text(
                          voice.displayName ??
                              voice.id ??
                              voice.key ??
                              'Custom Voice',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          voice.prompted?.baseVoice != null
                              ? 'Remix of ${voice.prompted!.baseVoice}: ${voice.prompted!.input}'
                              : (voice.description ??
                                    voice.prompted?.input ??
                                    voice.id ??
                                    ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: 'Delete Voice',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18.0,
                          ),
                          onPressed: () => _handleDeleteVoice(voice),
                        ),
                        onTap: () {
                          final idOrKey = voice.id ?? voice.key;
                          if (idOrKey != null) {
                            widget.onSpeechConfigSelected?.call(
                              SpeechConfig.fromVoice(idOrKey),
                            );
                          }
                        },
                      ),
            ],
          ],
          ),
        ),
      ),
    );
  }
}
