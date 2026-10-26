import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/live_logger.dart';

/// Signature for customizing individual log rows in [GeminiLiveLogConsole].
typedef GeminiLiveLogEntryBuilder = Widget Function(
  BuildContext context,
  GeminiLiveLogEntry entry,
  int index,
);

/// Signature for customizing the collapsed floating trigger button in
/// [GeminiLiveLogOverlay].
typedef GeminiLiveCollapsedLogButtonBuilder = Widget Function(
  BuildContext context,
  GeminiLiveLogController controller,
  VoidCallback onExpand,
);

/// Signature for replacing the entire expanded console inside [GeminiLiveLogOverlay].
typedef GeminiLiveLogConsoleBuilder = Widget Function(
  BuildContext context,
  GeminiLiveLogController controller,
  VoidCallback onMinimize,
  VoidCallback? onClose,
);

/// Signature for customizing the filter bar inside [GeminiLiveLogConsole].
typedef GeminiLiveLogFilterBarBuilder = Widget Function(
  BuildContext context,
  GeminiLiveLogController controller,
);

/// Visual theme configuration for [GeminiLiveLogOverlay] and [GeminiLiveLogConsole].
class GeminiLiveLogTheme {
  /// Background color of the expanded console panel.
  final Color consoleBackgroundColor;

  /// Border color of the expanded console panel.
  final Color consoleBorderColor;

  /// Corner radius of the expanded console panel.
  final BorderRadiusGeometry consoleBorderRadius;

  /// Background color of the collapsed floating pill.
  final Color pillBackgroundColor;

  /// Text and icon color of the collapsed floating pill.
  final Color pillForegroundColor;

  /// Corner radius of the collapsed floating pill.
  final BorderRadiusGeometry pillBorderRadius;

  /// Primary accent color for active filter chips and icons.
  final Color accentColor;

  /// Color for outgoing (`📤`) WebSocket traffic logs.
  final Color trafficOutgoingColor;

  /// Color for incoming (`📥`) WebSocket traffic logs.
  final Color trafficIncomingColor;

  /// Color for [GeminiLiveLogLevel.info] logs.
  final Color infoColor;

  /// Color for [GeminiLiveLogLevel.warning] logs.
  final Color warningColor;

  /// Color for [GeminiLiveLogLevel.error] logs.
  final Color errorColor;

  /// Optional custom text style for log timestamps.
  final TextStyle? timestampTextStyle;

  /// Optional custom base text style for log messages.
  final TextStyle? messageTextStyle;

  /// Optional custom text style for the console header title.
  final TextStyle? titleTextStyle;

  /// Creates a visual theme for [GeminiLiveLogOverlay] and [GeminiLiveLogConsole].
  const GeminiLiveLogTheme({
    this.consoleBackgroundColor = const Color(0xF2090D16),
    this.consoleBorderColor = Colors.white12,
    this.consoleBorderRadius = const BorderRadius.all(Radius.circular(16.0)),
    this.pillBackgroundColor = const Color(0xEB0F172A),
    this.pillForegroundColor = Colors.white,
    this.pillBorderRadius = const BorderRadius.all(Radius.circular(24.0)),
    this.accentColor = const Color(0xFF38BDF8),
    this.trafficOutgoingColor = const Color(0xFFA78BFA),
    this.trafficIncomingColor = const Color(0xFF34D399),
    this.infoColor = const Color(0xFF60A5FA),
    this.warningColor = const Color(0xFFFBBF24),
    this.errorColor = const Color(0xFFF87171),
    this.timestampTextStyle,
    this.messageTextStyle,
    this.titleTextStyle,
  });

  /// High-contrast light theme preset for bright outdoor debugging.
  static const GeminiLiveLogTheme light = GeminiLiveLogTheme(
    consoleBackgroundColor: Color(0xF8FFFFFF),
    consoleBorderColor: Color(0xFFE2E8F0),
    pillBackgroundColor: Color(0xF20F172A),
    pillForegroundColor: Colors.white,
    accentColor: Color(0xFF0284C7),
    trafficOutgoingColor: Color(0xFF7C3AED),
    trafficIncomingColor: Color(0xFF059669),
    infoColor: Color(0xFF2563EB),
    warningColor: Color(0xFFD97706),
    errorColor: Color(0xFFDC2626),
  );
}

/// Fluent extension allowing any [Widget] to have a floating
/// [GeminiLiveLogOverlay] attached with a single method call.
///
/// ```dart
/// MyLiveScreen().withGeminiLiveLogOverlay(
///   controller: logController,
/// )
/// ```
extension GeminiLiveLogWidgetExtension on Widget {
  /// Wraps this widget in a `Stack` with a floating, draggable [GeminiLiveLogOverlay].
  Widget withGeminiLiveLogOverlay({
    Key? key,
    GeminiLiveLogController? controller,
    bool enabled = true,
    bool initialExpanded = false,
    bool draggable = true,
    Offset initialOffset = const Offset(16.0, 80.0),
    double expandedWidth = 350.0,
    double expandedHeight = 340.0,
    String title = 'Gemini Live Logs',
    GeminiLiveLogTheme theme = const GeminiLiveLogTheme(),
    GeminiLiveCollapsedLogButtonBuilder? collapsedBuilder,
    GeminiLiveLogConsoleBuilder? consoleBuilder,
    WidgetBuilder? headerBuilder,
    GeminiLiveLogFilterBarBuilder? filterBarBuilder,
    GeminiLiveLogEntryBuilder? entryBuilder,
    WidgetBuilder? emptyBuilder,
    WidgetBuilder? footerBuilder,
    List<Widget> customActions = const [],
  }) {
    if (!enabled) return this;
    return GeminiLiveLogOverlay(
      key: key,
      controller: controller,
      initialExpanded: initialExpanded,
      draggable: draggable,
      initialOffset: initialOffset,
      expandedWidth: expandedWidth,
      expandedHeight: expandedHeight,
      title: title,
      theme: theme,
      collapsedBuilder: collapsedBuilder,
      consoleBuilder: consoleBuilder,
      headerBuilder: headerBuilder,
      filterBarBuilder: filterBarBuilder,
      entryBuilder: entryBuilder,
      emptyBuilder: emptyBuilder,
      footerBuilder: footerBuilder,
      customActions: customActions,
      child: this,
    );
  }
}

/// A floating, draggable in-app log overlay widget that can wrap **any widget**
/// ([child]), be placed inside a `Stack`, or be attached to Flutter's `Overlay`
/// ([showOverlay]) for debugging Gemini Live WebSocket traffic and events on
/// physical devices or staging/production builds.
///
/// ### 1. Wrap any widget directly (`child:` or `.withGeminiLiveLogOverlay()`)
/// ```dart
/// GeminiLiveLogOverlay(
///   controller: logController,
///   child: MyAnyScreenOrWidget(),
/// )
/// // Or via fluent extension on any widget:
/// MyAnyScreenOrWidget().withGeminiLiveLogOverlay(controller: logController)
/// ```
///
/// ### 2. Usage inside an existing `Stack`
/// ```dart
/// Stack(
///   children: [
///     MyLiveScreen(controller: sessionController),
///     GeminiLiveLogOverlay(controller: logController),
///   ],
/// )
/// ```
///
/// ### 3. Usage with Flutter's `Overlay`
/// ```dart
/// final entry = GeminiLiveLogOverlay.showOverlay(
///   context,
///   controller: logController,
/// );
/// // Later: entry.remove();
/// ```
class GeminiLiveLogOverlay extends StatefulWidget {
  /// Optional widget to wrap. When provided, [GeminiLiveLogOverlay] automatically
  /// creates a `Stack` around [child] and floats the log overlay on top of it.
  final Widget? child;

  /// The log controller providing buffered [GeminiLiveLogEntry] items.
  /// Defaults to [GeminiLiveLogController.instance] if omitted.
  final GeminiLiveLogController? controller;

  /// Whether the console starts expanded. Defaults to `false` (collapsed pill).
  final bool initialExpanded;

  /// Whether the collapsed pill (and expanded panel) can be dragged across the screen.
  /// Defaults to `true`.
  final bool draggable;

  /// Initial offset from the top-left of the stack/screen.
  final Offset initialOffset;

  /// Width of the expanded console panel. Defaults to `350.0`.
  final double expandedWidth;

  /// Height of the expanded console panel. Defaults to `340.0`.
  final double expandedHeight;

  /// Title shown in the console header. Defaults to `'Gemini Live Logs'`.
  final String title;

  /// Visual theme configuration for colors, borders, and typography.
  final GeminiLiveLogTheme theme;

  /// Optional custom builder for the collapsed floating button/pill.
  final GeminiLiveCollapsedLogButtonBuilder? collapsedBuilder;

  /// Optional builder to replace the entire expanded console widget.
  final GeminiLiveLogConsoleBuilder? consoleBuilder;

  /// Optional custom header builder for the expanded console.
  final WidgetBuilder? headerBuilder;

  /// Optional custom filter bar builder for the expanded console.
  final GeminiLiveLogFilterBarBuilder? filterBarBuilder;

  /// Optional custom builder for each log row.
  final GeminiLiveLogEntryBuilder? entryBuilder;

  /// Optional custom builder when no log entries match.
  final WidgetBuilder? emptyBuilder;

  /// Optional custom footer widget at the bottom of the expanded console.
  final WidgetBuilder? footerBuilder;

  /// Optional extra action widgets appended to the default console header.
  final List<Widget> customActions;

  /// Optional callback when the user closes/dismisses the overlay completely.
  final VoidCallback? onClose;

  /// Creates a [GeminiLiveLogOverlay] that can wrap any [child] or sit inside a `Stack`.
  const GeminiLiveLogOverlay({
    super.key,
    this.child,
    this.controller,
    this.initialExpanded = false,
    this.draggable = true,
    this.initialOffset = const Offset(16.0, 80.0),
    this.expandedWidth = 350.0,
    this.expandedHeight = 340.0,
    this.title = 'Gemini Live Logs',
    this.theme = const GeminiLiveLogTheme(),
    this.collapsedBuilder,
    this.consoleBuilder,
    this.headerBuilder,
    this.filterBarBuilder,
    this.entryBuilder,
    this.emptyBuilder,
    this.footerBuilder,
    this.customActions = const [],
    this.onClose,
  });

  /// Attaches a floating [GeminiLiveLogOverlay] to the nearest [Overlay] and
  /// returns the created [OverlayEntry] (call `entry.remove()` to dismiss).
  static OverlayEntry showOverlay(
    BuildContext context, {
    GeminiLiveLogController? controller,
    bool initialExpanded = false,
    Offset initialOffset = const Offset(16.0, 80.0),
    double expandedWidth = 350.0,
    double expandedHeight = 340.0,
    String title = 'Gemini Live Logs',
    GeminiLiveLogTheme theme = const GeminiLiveLogTheme(),
    GeminiLiveCollapsedLogButtonBuilder? collapsedBuilder,
    GeminiLiveLogConsoleBuilder? consoleBuilder,
    WidgetBuilder? headerBuilder,
    GeminiLiveLogFilterBarBuilder? filterBarBuilder,
    GeminiLiveLogEntryBuilder? entryBuilder,
    WidgetBuilder? emptyBuilder,
    WidgetBuilder? footerBuilder,
    List<Widget> customActions = const [],
  }) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => GeminiLiveLogOverlay(
        controller: controller,
        initialExpanded: initialExpanded,
        initialOffset: initialOffset,
        expandedWidth: expandedWidth,
        expandedHeight: expandedHeight,
        title: title,
        theme: theme,
        collapsedBuilder: collapsedBuilder,
        consoleBuilder: consoleBuilder,
        headerBuilder: headerBuilder,
        filterBarBuilder: filterBarBuilder,
        entryBuilder: entryBuilder,
        emptyBuilder: emptyBuilder,
        footerBuilder: footerBuilder,
        customActions: customActions,
        onClose: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }

  @override
  State<GeminiLiveLogOverlay> createState() => _GeminiLiveLogOverlayState();
}

class _GeminiLiveLogOverlayState extends State<GeminiLiveLogOverlay> {
  late bool _isExpanded;
  late Offset _offset;

  GeminiLiveLogController get _effectiveController =>
      widget.controller ?? GeminiLiveLogController.instance;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
    _offset = widget.initialOffset;
  }

  void _handlePanUpdate(DragUpdateDetails details, Size screenSize) {
    if (!widget.draggable) return;
    setState(() {
      final nextDx = (_offset.dx + details.delta.dx).clamp(
        8.0,
        (screenSize.width - 100.0).clamp(8.0, double.infinity),
      );
      final nextDy = (_offset.dy + details.delta.dy).clamp(
        8.0,
        (screenSize.height - 60.0).clamp(8.0, double.infinity),
      );
      _offset = Offset(nextDx, nextDy);
    });
  }

  Widget _buildPositionedOverlay(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final controller = _effectiveController;

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: Material(
        color: Colors.transparent,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (!_isExpanded) {
              final collapsed = widget.collapsedBuilder != null
                  ? widget.collapsedBuilder!(
                      context,
                      controller,
                      () => setState(() => _isExpanded = true),
                    )
                  : _buildDefaultCollapsedPill(context, controller);

              return GestureDetector(
                onPanUpdate: (d) => _handlePanUpdate(d, screenSize),
                child: collapsed,
              );
            }

            final maxW = (screenSize.width - 24.0).clamp(
              240.0,
              widget.expandedWidth,
            );
            final maxH = (screenSize.height - 48.0).clamp(
              200.0,
              widget.expandedHeight,
            );

            final consoleWidget = widget.consoleBuilder != null
                ? widget.consoleBuilder!(
                    context,
                    controller,
                    () => setState(() => _isExpanded = false),
                    widget.onClose,
                  )
                : GeminiLiveLogConsole(
                    controller: controller,
                    title: widget.title,
                    theme: widget.theme,
                    headerBuilder: widget.headerBuilder,
                    filterBarBuilder: widget.filterBarBuilder,
                    entryBuilder: widget.entryBuilder,
                    emptyBuilder: widget.emptyBuilder,
                    footerBuilder: widget.footerBuilder,
                    customActions: widget.customActions,
                    onMinimize: () => setState(() => _isExpanded = false),
                    onClose: widget.onClose,
                  );

            return GestureDetector(
              onPanUpdate: (d) => _handlePanUpdate(d, screenSize),
              child: SizedBox(
                width: maxW,
                height: maxH,
                child: consoleWidget,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overlayLayer = _buildPositionedOverlay(context);
    if (widget.child != null) {
      return Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child!,
          overlayLayer,
        ],
      );
    }
    return overlayLayer;
  }

  Widget _buildDefaultCollapsedPill(
    BuildContext context,
    GeminiLiveLogController controller,
  ) {
    final hasErrors = controller.errorCount > 0;
    final hasWarnings = controller.warningCount > 0;
    final total = controller.entries.length;
    final theme = widget.theme;

    final Color badgeColor = hasErrors
        ? theme.errorColor
        : (hasWarnings ? theme.warningColor : const Color(0xFF10B981));

    return InkWell(
      borderRadius: BorderRadius.circular(24.0),
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: theme.pillBackgroundColor,
          borderRadius: theme.pillBorderRadius,
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.7),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 10.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8.0,
              height: 8.0,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7.0),
            Icon(
              Icons.terminal_rounded,
              size: 15.0,
              color: theme.pillForegroundColor,
            ),
            const SizedBox(width: 5.0),
            Text(
              'Logs ($total)',
              style: TextStyle(
                color: theme.pillForegroundColor,
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (hasErrors) ...[
              const SizedBox(width: 6.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5.0,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: theme.errorColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '${controller.errorCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// An embeddable and customizable real-time log inspector console for
/// [GeminiLiveLogController].
///
/// Can be used inside [GeminiLiveLogOverlay], embedded directly in any widget tree,
/// or presented as a modal bottom sheet via [GeminiLiveLogConsole.showSheet].
class GeminiLiveLogConsole extends StatefulWidget {
  /// The log controller to inspect. Defaults to [GeminiLiveLogController.instance].
  final GeminiLiveLogController? controller;

  /// Header title string. Defaults to `'Gemini Live Logs'`.
  final String title;

  /// Whether to show the search filter text field. Defaults to `true`.
  final bool showSearchBar;

  /// Whether to show severity filter chips (`ALL`, `TRAFFIC`, `INFO`, `WARN`, `ERROR`)
  /// and custom tag chips. Defaults to `true`.
  final bool showLevelFilters;

  /// Whether to automatically scroll to the newest log entry as logs arrive.
  /// Defaults to `true`.
  final bool autoScroll;

  /// Visual theme configuration for the console.
  final GeminiLiveLogTheme theme;

  /// Optional custom header builder.
  final WidgetBuilder? headerBuilder;

  /// Optional custom filter bar builder.
  final GeminiLiveLogFilterBarBuilder? filterBarBuilder;

  /// Optional custom builder for each log entry row.
  final GeminiLiveLogEntryBuilder? entryBuilder;

  /// Optional custom builder when no log entries match.
  final WidgetBuilder? emptyBuilder;

  /// Optional custom footer widget at the bottom of the console.
  final WidgetBuilder? footerBuilder;

  /// Optional extra action widgets appended to the default console header.
  final List<Widget> customActions;

  /// Optional callback to minimize the console (used by [GeminiLiveLogOverlay]).
  final VoidCallback? onMinimize;

  /// Optional callback to close the console completely.
  final VoidCallback? onClose;

  /// Optional background color override (takes precedence over [theme]).
  final Color? backgroundColor;

  /// Optional border radius override (takes precedence over [theme]).
  final BorderRadiusGeometry? borderRadius;

  /// Creates a customizable [GeminiLiveLogConsole].
  const GeminiLiveLogConsole({
    super.key,
    this.controller,
    this.title = 'Gemini Live Logs',
    this.showSearchBar = true,
    this.showLevelFilters = true,
    this.autoScroll = true,
    this.theme = const GeminiLiveLogTheme(),
    this.headerBuilder,
    this.filterBarBuilder,
    this.entryBuilder,
    this.emptyBuilder,
    this.footerBuilder,
    this.customActions = const [],
    this.onMinimize,
    this.onClose,
    this.backgroundColor,
    this.borderRadius,
  });

  /// Displays [GeminiLiveLogConsole] inside a modal bottom sheet.
  static Future<void> showSheet(
    BuildContext context, {
    GeminiLiveLogController? controller,
    String title = 'Gemini Live Logs',
    double heightFactor = 0.65,
    GeminiLiveLogTheme theme = const GeminiLiveLogTheme(),
    GeminiLiveLogEntryBuilder? entryBuilder,
    List<Widget> customActions = const [],
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: heightFactor,
        child: GeminiLiveLogConsole(
          controller: controller,
          title: title,
          theme: theme,
          entryBuilder: entryBuilder,
          customActions: customActions,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  State<GeminiLiveLogConsole> createState() => _GeminiLiveLogConsoleState();
}

class _GeminiLiveLogConsoleState extends State<GeminiLiveLogConsole> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _expandedIndices = <int>{};
  int _lastCount = 0;

  GeminiLiveLogController get _effectiveController =>
      widget.controller ?? GeminiLiveLogController.instance;

  @override
  void initState() {
    super.initState();
    _searchController.text = _effectiveController.searchQuery;
    _lastCount = _effectiveController.entries.length;
    _effectiveController.addListener(_onLogsUpdated);
  }

  @override
  void didUpdateWidget(GeminiLiveLogConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? GeminiLiveLogController.instance)
          .removeListener(_onLogsUpdated);
      _effectiveController.addListener(_onLogsUpdated);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onLogsUpdated);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onLogsUpdated() {
    if (!mounted) return;
    final currentCount = _effectiveController.entries.length;
    final shouldScroll =
        widget.autoScroll &&
        !_effectiveController.isPaused &&
        currentCount > _lastCount;
    _lastCount = currentCount;
    setState(() {});
    if (shouldScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _copyLogsToClipboard(GeminiLiveLogController controller) async {
    final text = controller.exportText(onlyFiltered: true);
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Copied ${controller.filteredEntries.length} log entries to clipboard',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _effectiveController;
    final entries = controller.filteredEntries;
    final theme = widget.theme;
    final bg = widget.backgroundColor ?? theme.consoleBackgroundColor;
    final radius = widget.borderRadius ?? theme.consoleBorderRadius;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: theme.consoleBorderColor, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16.0,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header bar
            widget.headerBuilder?.call(context) ??
                _buildHeader(context, controller),

            // Level & Tag filter chips
            if (widget.showLevelFilters)
              widget.filterBarBuilder != null
                  ? widget.filterBarBuilder!(context, controller)
                  : _buildLevelFilters(controller),

            // Search input
            if (widget.showSearchBar) _buildSearchField(controller),

            Divider(height: 1.0, color: theme.consoleBorderColor),

            // Log list
            Expanded(
              child: entries.isEmpty
                  ? (widget.emptyBuilder?.call(context) ??
                        const Center(
                          child: Text(
                            'No log entries captured yet.',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12.0,
                            ),
                          ),
                        ))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 6.0,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        if (widget.entryBuilder != null) {
                          return widget.entryBuilder!(context, entry, index);
                        }
                        return _buildDefaultLogRow(entry, index);
                      },
                    ),
            ),

            if (widget.footerBuilder != null) widget.footerBuilder!(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    GeminiLiveLogController controller,
  ) {
    final theme = widget.theme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 6.0, 4.0),
      child: Row(
        children: [
          Icon(
            Icons.terminal_rounded,
            size: 16.0,
            color: theme.accentColor,
          ),
          const SizedBox(width: 6.0),
          Expanded(
            child: Text(
              '${widget.title} (${controller.filteredEntries.length})',
              overflow: TextOverflow.ellipsis,
              style:
                  theme.titleTextStyle ??
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          ...widget.customActions,
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: controller.isPaused ? 'Resume Logs' : 'Pause Logs',
            onPressed: controller.togglePaused,
            icon: Icon(
              controller.isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              size: 17.0,
              color: controller.isPaused ? theme.warningColor : Colors.white70,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Copy Logs',
            onPressed: () => _copyLogsToClipboard(controller),
            icon: const Icon(
              Icons.copy_rounded,
              size: 15.0,
              color: Colors.white70,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Clear Logs',
            onPressed: () {
              _expandedIndices.clear();
              controller.clear();
            },
            icon: const Icon(
              Icons.delete_sweep_rounded,
              size: 17.0,
              color: Colors.white70,
            ),
          ),
          if (widget.onMinimize != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Minimize Overlay',
              onPressed: widget.onMinimize,
              icon: const Icon(
                Icons.minimize_rounded,
                size: 17.0,
                color: Colors.white70,
              ),
            ),
          if (widget.onClose != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Close Overlay',
              onPressed: widget.onClose,
              icon: const Icon(
                Icons.close_rounded,
                size: 17.0,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLevelFilters(GeminiLiveLogController controller) {
    final current = controller.filterLevel;
    final currentTag = controller.filterTag;
    final tags = controller.availableTags;
    final accent = widget.theme.accentColor;

    final options = <(String, GeminiLiveLogLevel?)>[
      ('ALL', null),
      ('TRAFFIC', GeminiLiveLogLevel.traffic),
      ('INFO', GeminiLiveLogLevel.info),
      ('WARN', GeminiLiveLogLevel.warning),
      ('ERROR', GeminiLiveLogLevel.error),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      child: Row(
        children: [
          for (final (label, level) in options)
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(10.0),
                onTap: () => controller.setFilterLevel(level),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: current == level
                        ? accent.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: current == level ? accent : Colors.white12,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: current == level ? accent : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          for (final tag in tags)
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(10.0),
                onTap: () =>
                    controller.setFilterTag(currentTag == tag ? null : tag),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: currentTag == tag
                        ? const Color(0xFFA78BFA).withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: currentTag == tag
                          ? const Color(0xFFA78BFA)
                          : Colors.white12,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: currentTag == tag
                          ? const Color(0xFFA78BFA)
                          : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField(GeminiLiveLogController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10.0, 2.0, 10.0, 6.0),
      child: SizedBox(
        height: 30.0,
        child: TextField(
          controller: _searchController,
          onChanged: controller.setSearchQuery,
          style: const TextStyle(color: Colors.white, fontSize: 11.5),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 6.0,
            ),
            hintText: 'Filter by keyword or #tag...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 11.0),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 14.0,
              color: Colors.white54,
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 28.0),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultLogRow(GeminiLiveLogEntry entry, int index) {
    final isExpanded = _expandedIndices.contains(index);
    final theme = widget.theme;
    final color = switch (entry.level) {
      GeminiLiveLogLevel.error => theme.errorColor,
      GeminiLiveLogLevel.warning => theme.warningColor,
      GeminiLiveLogLevel.info => theme.infoColor,
      GeminiLiveLogLevel.traffic =>
        entry.isOutgoing
            ? theme.trafficOutgoingColor
            : theme.trafficIncomingColor,
      GeminiLiveLogLevel.none => Colors.white54,
    };

    final displayLine = (entry.tag != null && entry.tag!.isNotEmpty)
        ? '[${entry.tag}] ${entry.message}'
        : entry.message;

    return InkWell(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedIndices.remove(index);
          } else {
            _expandedIndices.add(index);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.timeString,
              style:
                  theme.timestampTextStyle ??
                  const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.0,
                    color: Colors.white38,
                  ),
            ),
            const SizedBox(width: 6.0),
            Expanded(
              child: Text(
                displayLine,
                maxLines: isExpanded ? null : 2,
                overflow: isExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style:
                    (theme.messageTextStyle ??
                            const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11.0,
                              height: 1.3,
                            ))
                        .copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
