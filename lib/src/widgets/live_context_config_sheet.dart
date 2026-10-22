import 'package:flutter/material.dart';

import '../model/models.dart';
import '../utils/live_session_controller.dart';

/// A preset persona and toolset configuration for mid-session
/// [LiveSession.sendContextUpdate] (`LiveClientContextUpdate`) switching.
class GeminiLiveContextPreset {
  /// Unique identifier for this preset.
  final String id;

  /// Human-readable title displayed on the preset chip/card.
  final String title;

  /// Optional short description of the persona or mode.
  final String? subtitle;

  /// Optional leading icon for the preset chip.
  final IconData? icon;

  /// System instruction string or [Content] applied when selected.
  final Object systemInstruction;

  /// Optional list of [Tool]s applied when this preset is selected.
  /// Pass `const <Tool>[]` to clear all tools when switching to this preset.
  final List<Tool>? tools;

  /// Creates an in-session context preset.
  const GeminiLiveContextPreset({
    required this.id,
    required this.title,
    required this.systemInstruction,
    this.subtitle,
    this.icon,
    this.tools,
  });

  /// Extracts the plain text representation of [systemInstruction].
  String get systemInstructionText {
    final value = systemInstruction;
    if (value is String) return value;
    if (value is Content) {
      return value.parts
              ?.map((p) => p.text)
              .whereType<String>()
              .join('\n')
              .trim() ??
          '';
    }
    return value.toString();
  }
}

/// A compact pill badge that summarizes the active session context
/// (`systemInstruction` and `tools` count) and opens
/// [GeminiLiveContextConfigSheet] when tapped.
class GeminiLiveContextBadge extends StatelessWidget {
  /// Optional controller to read active context from.
  final GeminiLiveSessionController? controller;

  /// Optional explicit label override.
  final String? label;

  /// Optional number of active tools. When null, derived from [controller].
  final int? activeToolCount;

  /// Optional tap callback.
  final VoidCallback? onTap;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Optional foreground text/icon color override.
  final Color? foregroundColor;

  /// Creates a compact badge for inspecting or updating live session context.
  const GeminiLiveContextBadge({
    super.key,
    this.controller,
    this.label,
    this.activeToolCount,
    this.onTap,
    this.backgroundColor,
    this.foregroundColor,
  });

  String _resolveLabel() {
    if (label != null && label!.isNotEmpty) return label!;
    final instruction = controller?.activeSystemInstruction;
    final text = instruction?.parts
        ?.map((p) => p.text)
        .whereType<String>()
        .join(' ')
        .trim();
    if (text != null && text.isNotEmpty) {
      return text.length > 28 ? '${text.substring(0, 28)}…' : text;
    }
    return 'Session Context';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final toolCount = activeToolCount ?? controller?.activeTools.length ?? 0;

    final effectiveBg =
        backgroundColor ??
        (isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5));
    final effectiveFg =
        foregroundColor ??
        (isDark ? const Color(0xFFE4E4E7) : const Color(0xFF27272A));

    return Semantics(
      button: onTap != null,
      label: _resolveLabel(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.08),
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 14.0,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6.0),
              Flexible(
                child: Text(
                  _resolveLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: effectiveFg,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  '$toolCount ${toolCount == 1 ? 'tool' : 'tools'}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interactive Material 3 sheet for updating `systemInstruction` and `tools`
/// in-place during an active Gemini Live session via `sendContextUpdate`
/// ([LiveClientContextUpdate]).
class GeminiLiveContextConfigSheet extends StatefulWidget {
  /// Optional [GeminiLiveSessionController] to read initial context from and
  /// automatically dispatch [GeminiLiveSessionController.sendContextUpdate] to.
  final GeminiLiveSessionController? controller;

  /// Initial system instruction text when [controller] is not provided.
  final String? initialSystemInstruction;

  /// Optional list of quick persona/context presets.
  final List<GeminiLiveContextPreset> presets;

  /// Optional catalog of named tools that the user can toggle on or off.
  /// Keys are human-readable tool labels (e.g. `'Google Search'`, `'Weather API'`)
  /// and values are the corresponding [Tool] definitions.
  final Map<String, Tool> availableTools;

  /// Initial set of enabled tool keys from [availableTools].
  final Set<String>? initialEnabledToolKeys;

  /// Callback invoked when the user taps the Apply button with the constructed
  /// [LiveClientContextUpdate].
  final ValueChanged<LiveClientContextUpdate>? onApply;

  /// Sheet title text. Defaults to `'Live Context Update'`.
  final String title;

  /// Subtitle explaining that updates take effect in-order without reconnecting.
  final String subtitle;

  /// Label for the primary apply button. Defaults to `'Apply Context Update'`.
  final String applyButtonLabel;

  /// Whether to close the modal sheet (`Navigator.pop`) when Apply is pressed.
  /// Defaults to `false` when embedded directly, or `true` when opened via
  /// [GeminiLiveContextConfigSheet.show].
  final bool closeOnApply;

  /// Creates an interactive configuration sheet for `sendContextUpdate`.
  const GeminiLiveContextConfigSheet({
    super.key,
    this.controller,
    this.initialSystemInstruction,
    this.presets = const [],
    this.availableTools = const {},
    this.initialEnabledToolKeys,
    this.onApply,
    this.title = 'Live Context Update',
    this.subtitle =
        'Update system instructions or tools mid-session without reconnecting.',
    this.applyButtonLabel = 'Apply Context Update',
    this.closeOnApply = false,
  });

  /// Presents [GeminiLiveContextConfigSheet] as a modal bottom sheet and
  /// returns the applied [LiveClientContextUpdate] (or `null` if dismissed).
  static Future<LiveClientContextUpdate?> show({
    required BuildContext context,
    GeminiLiveSessionController? controller,
    String? initialSystemInstruction,
    List<GeminiLiveContextPreset> presets = const [],
    Map<String, Tool> availableTools = const {},
    Set<String>? initialEnabledToolKeys,
    ValueChanged<LiveClientContextUpdate>? onApply,
    String title = 'Live Context Update',
  }) {
    return showModalBottomSheet<LiveClientContextUpdate>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: GeminiLiveContextConfigSheet(
          controller: controller,
          initialSystemInstruction: initialSystemInstruction,
          presets: presets,
          availableTools: availableTools,
          initialEnabledToolKeys: initialEnabledToolKeys,
          onApply: onApply,
          title: title,
          closeOnApply: true,
        ),
      ),
    );
  }

  @override
  State<GeminiLiveContextConfigSheet> createState() =>
      _GeminiLiveContextConfigSheetState();
}

class _GeminiLiveContextConfigSheetState
    extends State<GeminiLiveContextConfigSheet> {
  late final TextEditingController _instructionController;
  late final Set<String> _enabledToolKeys;
  String? _selectedPresetId;
  bool _clearAllTools = false;

  @override
  void initState() {
    super.initState();
    final initialText =
        widget.initialSystemInstruction ??
        widget.controller?.activeSystemInstruction?.parts
            ?.map((p) => p.text)
            .whereType<String>()
            .join('\n')
            .trim() ??
        '';
    _instructionController = TextEditingController(text: initialText);
    _enabledToolKeys = Set<String>.from(
      widget.initialEnabledToolKeys ?? widget.availableTools.keys,
    );
  }

  @override
  void dispose() {
    _instructionController.dispose();
    super.dispose();
  }

  void _selectPreset(GeminiLiveContextPreset preset) {
    setState(() {
      _selectedPresetId = preset.id;
      _instructionController.text = preset.systemInstructionText;
      if (preset.tools != null && preset.tools!.isEmpty) {
        _clearAllTools = true;
        _enabledToolKeys.clear();
      } else if (preset.tools != null) {
        _clearAllTools = false;
      }
    });
  }

  void _handleApply() {
    final text = _instructionController.text.trim();
    final List<Tool>? resolvedTools;
    if (_clearAllTools) {
      resolvedTools = const <Tool>[];
    } else if (widget.availableTools.isNotEmpty) {
      resolvedTools = _enabledToolKeys
          .map((k) => widget.availableTools[k])
          .whereType<Tool>()
          .toList();
    } else {
      final preset = widget.presets
          .where((p) => p.id == _selectedPresetId)
          .firstOrNull;
      resolvedTools = preset?.tools;
    }

    final update = LiveClientContextUpdate(
      systemInstruction: text.isNotEmpty ? text : null,
      tools: resolvedTools,
    );

    if (update.systemInstruction == null && update.tools == null) {
      return;
    }

    widget.controller?.sendContextUpdate(update: update);
    widget.onApply?.call(update);

    if (widget.closeOnApply && Navigator.canPop(context)) {
      Navigator.pop(context, update);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: theme.colorScheme.primary,
                size: 22.0,
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            widget.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
            ),
          ),
          if (widget.presets.isNotEmpty) ...[
            const SizedBox(height: 16.0),
            Text(
              'Persona Presets',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: widget.presets.map((preset) {
                final selected = _selectedPresetId == preset.id;
                return ChoiceChip(
                  avatar: preset.icon != null
                      ? Icon(preset.icon, size: 16.0)
                      : null,
                  label: Text(preset.title),
                  selected: selected,
                  onSelected: (_) => _selectPreset(preset),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16.0),
          Text(
            'System Instruction',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8.0),
          TextField(
            controller: _instructionController,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter live system instructions or persona rules…',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              contentPadding: const EdgeInsets.all(12.0),
            ),
          ),
          if (widget.availableTools.isNotEmpty) ...[
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Session Tools',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _clearAllTools = !_clearAllTools;
                      if (_clearAllTools) {
                        _enabledToolKeys.clear();
                      } else {
                        _enabledToolKeys.addAll(widget.availableTools.keys);
                      }
                    });
                  },
                  icon: Icon(
                    _clearAllTools
                        ? Icons.restart_alt_rounded
                        : Icons.clear_all_rounded,
                    size: 16.0,
                  ),
                  label: Text(
                    _clearAllTools ? 'Restore Tools' : 'Clear All Tools',
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: widget.availableTools.keys.map((key) {
                final enabled = !_clearAllTools && _enabledToolKeys.contains(key);
                return FilterChip(
                  label: Text(key),
                  selected: enabled,
                  onSelected: (selected) {
                    setState(() {
                      _clearAllTools = false;
                      if (selected) {
                        _enabledToolKeys.add(key);
                      } else {
                        _enabledToolKeys.remove(key);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ] else ...[
            const SizedBox(height: 12.0),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Clear All Session Tools',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                'Sends tools: [] via sendContextUpdate to disable active tools.',
              ),
              value: _clearAllTools,
              onChanged: (value) {
                setState(() {
                  _clearAllTools = value;
                });
              },
            ),
          ],
          const SizedBox(height: 16.0),
          FilledButton.icon(
            onPressed: _handleApply,
            icon: const Icon(Icons.bolt_rounded, size: 18.0),
            label: Text(widget.applyButtonLabel),
          ),
        ],
      ),
    );
  }
}
