import 'package:flutter/material.dart';

import '../model/models.dart';
import '../music_service.dart';

/// Signature for building a custom weighted prompt row in [GeminiLiveMusicControlDeck].
typedef GeminiLiveMusicPromptItemBuilder = Widget Function(
  BuildContext context,
  WeightedPrompt prompt,
  int index,
  ValueChanged<double> onWeightChanged,
  VoidCallback onRemove,
);

/// Signature for building a custom playback transport bar in [GeminiLiveMusicControlDeck].
typedef GeminiLiveMusicTransportBuilder = Widget Function(
  BuildContext context,
  bool isPlaying,
  ValueChanged<LiveMusicPlaybackControl> onControl,
);

/// A pre-built, customizable Prompt DJ & transport mixer widget for
/// Google's Lyria Realtime Music ([LiveMusicSession]).
///
/// Users can either pass an active [session] (which automatically dispatches
/// `setWeightedPrompts`, `setMusicGenerationConfig`, and playback controls to
/// the WebSocket session) or handle changes manually via [onPromptsChanged],
/// [onConfigChanged], and [onPlaybackControl].
///
/// ### Customization
/// - [headerBuilder]: Replace the default title header.
/// - [promptItemBuilder]: Customize each weighted prompt slider row.
/// - [transportBuilder]: Replace the Play / Pause / Stop / Reset transport bar.
/// - [backgroundColor], [accentColor], [borderRadius], [padding]: Visual styling.
class GeminiLiveMusicControlDeck extends StatefulWidget {
  /// Optional active [LiveMusicSession] to steer directly.
  final LiveMusicSession? session;

  /// Initial list of weighted prompts.
  final List<WeightedPrompt> initialPrompts;

  /// Initial music generation configuration (BPM, scale, temperature, etc.).
  final LiveMusicGenerationConfig? initialConfig;

  /// Callback invoked whenever weighted prompts are added, removed, or adjusted.
  final ValueChanged<List<WeightedPrompt>>? onPromptsChanged;

  /// Callback invoked whenever BPM, scale, or generation parameters change.
  final ValueChanged<LiveMusicGenerationConfig>? onConfigChanged;

  /// Callback invoked when a playback control button (Play, Pause, Stop, Reset) is tapped.
  final ValueChanged<LiveMusicPlaybackControl>? onPlaybackControl;

  /// Optional custom header builder.
  final WidgetBuilder? headerBuilder;

  /// Optional custom builder for each weighted prompt row.
  final GeminiLiveMusicPromptItemBuilder? promptItemBuilder;

  /// Optional custom builder for the playback transport bar.
  final GeminiLiveMusicTransportBuilder? transportBuilder;

  /// Deck title text. Defaults to `'Lyria Live Music DJ'`.
  final String title;

  /// Placeholder hint for adding a new prompt.
  final String promptInputHint;

  /// Whether to show the text field for adding new weighted prompts. Defaults to `true`.
  final bool showAddPromptInput;

  /// Whether to show the BPM slider control. Defaults to `true`.
  final bool showBpmControl;

  /// Whether to show the musical scale selector. Defaults to `true`.
  final bool showScaleSelector;

  /// Optional card background color override.
  final Color? backgroundColor;

  /// Optional primary accent color override.
  final Color? accentColor;

  /// Border radius of the deck container. Defaults to `20.0`.
  final BorderRadiusGeometry borderRadius;

  /// Inner padding of the deck container.
  final EdgeInsetsGeometry padding;

  /// Creates a customizable Lyria Realtime Music control deck.
  const GeminiLiveMusicControlDeck({
    super.key,
    this.session,
    this.initialPrompts = const [
      WeightedPrompt(text: 'Lo-fi chill hip hop beats', weight: 1.0),
      WeightedPrompt(text: 'Warm Rhodes electric piano', weight: 0.7),
    ],
    this.initialConfig,
    this.onPromptsChanged,
    this.onConfigChanged,
    this.onPlaybackControl,
    this.headerBuilder,
    this.promptItemBuilder,
    this.transportBuilder,
    this.title = 'Lyria Live Music DJ',
    this.promptInputHint = 'Add musical style or instrument...',
    this.showAddPromptInput = true,
    this.showBpmControl = true,
    this.showScaleSelector = true,
    this.backgroundColor,
    this.accentColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(20.0)),
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  State<GeminiLiveMusicControlDeck> createState() =>
      _GeminiLiveMusicControlDeckState();
}

class _GeminiLiveMusicControlDeckState
    extends State<GeminiLiveMusicControlDeck> {
  late List<WeightedPrompt> _prompts;
  late int _bpm;
  late Scale _scale;
  late double _temperature;
  bool _isPlaying = false;
  final TextEditingController _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prompts = List<WeightedPrompt>.from(widget.initialPrompts);
    _bpm = widget.initialConfig?.bpm ?? 110;
    _scale = widget.initialConfig?.scale ?? Scale.SCALE_UNSPECIFIED;
    _temperature = widget.initialConfig?.temperature ?? 1.0;
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _emitPrompts() {
    final nonEmpty = _prompts
        .where((p) => (p.text ?? '').trim().isNotEmpty)
        .toList();
    if (nonEmpty.isNotEmpty) {
      widget.session?.setWeightedPrompts(nonEmpty);
    }
    widget.onPromptsChanged?.call(List<WeightedPrompt>.unmodifiable(_prompts));
  }

  void _emitConfig() {
    final config = LiveMusicGenerationConfig(
      bpm: _bpm,
      scale: _scale == Scale.SCALE_UNSPECIFIED ? null : _scale,
      temperature: _temperature,
      density: widget.initialConfig?.density,
      brightness: widget.initialConfig?.brightness,
    );
    widget.session?.setMusicGenerationConfig(config);
    widget.onConfigChanged?.call(config);
  }

  void _handleControl(LiveMusicPlaybackControl control) {
    setState(() {
      if (control == LiveMusicPlaybackControl.PLAY) {
        _isPlaying = true;
      } else if (control == LiveMusicPlaybackControl.PAUSE ||
          control == LiveMusicPlaybackControl.STOP) {
        _isPlaying = false;
      }
    });
    widget.session?.sendPlaybackControl(control);
    widget.onPlaybackControl?.call(control);
  }

  void _addPrompt() {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;
    _promptController.clear();
    setState(() {
      _prompts.add(WeightedPrompt(text: text, weight: 1.0));
    });
    _emitPrompts();
  }

  void _updateWeight(int index, double weight) {
    setState(() {
      _prompts[index] = WeightedPrompt(
        text: _prompts[index].text,
        weight: double.parse(weight.toStringAsFixed(2)),
      );
    });
    _emitPrompts();
  }

  void _removePrompt(int index) {
    if (_prompts.length <= 1) return;
    setState(() {
      _prompts.removeAt(index);
    });
    _emitPrompts();
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
      padding: widget.padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          widget.headerBuilder?.call(context) ??
              Row(
                children: [
                  Icon(Icons.queue_music_rounded, color: primary, size: 20.0),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 3.0,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      '$_bpm BPM',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),
          const SizedBox(height: 12.0),

          // Weighted prompts list
          for (var i = 0; i < _prompts.length; i++)
            widget.promptItemBuilder != null
                ? widget.promptItemBuilder!(
                    context,
                    _prompts[i],
                    i,
                    (v) => _updateWeight(i, v),
                    () => _removePrompt(i),
                  )
                : _buildDefaultPromptRow(context, i, primary, isDark),

          // Add prompt input
          if (widget.showAddPromptInput) ...[
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    onSubmitted: (_) => _addPrompt(),
                    style: TextStyle(
                      fontSize: 13.0,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: widget.promptInputHint,
                      hintStyle: TextStyle(
                        fontSize: 12.0,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton.filledTonal(
                  tooltip: 'Add Prompt',
                  onPressed: _addPrompt,
                  icon: const Icon(Icons.add_rounded, size: 18.0),
                ),
              ],
            ),
          ],

          // BPM slider
          if (widget.showBpmControl) ...[
            const SizedBox(height: 12.0),
            Row(
              children: [
                Text(
                  'Tempo (BPM)',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _bpm.toDouble(),
                    min: 60,
                    max: 200,
                    divisions: 140,
                    activeColor: primary,
                    label: '$_bpm BPM',
                    onChanged: (value) {
                      setState(() {
                        _bpm = value.round();
                      });
                      _emitConfig();
                    },
                  ),
                ),
              ],
            ),
          ],

          // Scale selector
          if (widget.showScaleSelector) ...[
            const SizedBox(height: 4.0),
            DropdownButtonFormField<Scale>(
              initialValue: _scale,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Musical Scale',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              items: Scale.values
                  .map(
                    (s) => DropdownMenuItem<Scale>(
                      value: s,
                      child: Text(
                        s == Scale.SCALE_UNSPECIFIED
                            ? 'Auto (Unspecified)'
                            : s.name.replaceAll('_', ' '),
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (next) {
                if (next == null) return;
                setState(() {
                  _scale = next;
                });
                _emitConfig();
              },
            ),
          ],

          const SizedBox(height: 14.0),

          // Playback Transport Bar
          widget.transportBuilder != null
              ? widget.transportBuilder!(context, _isPlaying, _handleControl)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _handleControl(
                        _isPlaying
                            ? LiveMusicPlaybackControl.PAUSE
                            : LiveMusicPlaybackControl.PLAY,
                      ),
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 18.0,
                      ),
                      label: Text(_isPlaying ? 'Pause' : 'Play'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _handleControl(LiveMusicPlaybackControl.STOP),
                      icon: const Icon(Icons.stop_rounded, size: 18.0),
                      label: const Text('Stop'),
                    ),
                    IconButton(
                      tooltip: 'Reset Music Context',
                      onPressed: () => _handleControl(
                        LiveMusicPlaybackControl.RESET_CONTEXT,
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 20.0),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildDefaultPromptRow(
    BuildContext context,
    int index,
    Color primary,
    bool isDark,
  ) {
    final prompt = _prompts[index];
    final weight = (prompt.weight ?? 1.0).clamp(0.0, 2.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  prompt.text ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                weight.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
              if (_prompts.length > 1)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove Prompt',
                  onPressed: () => _removePrompt(index),
                  icon: const Icon(Icons.close_rounded, size: 16.0),
                ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
            ),
            child: Slider(
              value: weight,
              min: 0.0,
              max: 2.0,
              activeColor: primary,
              onChanged: (v) => _updateWeight(index, v),
            ),
          ),
        ],
      ),
    );
  }
}
