import 'package:flutter/material.dart';

import 'api_key_store.dart';
import 'app_settings_dialog.dart';
import 'app_translations.dart';
import 'chat_page.dart';
import 'function_calling_demo.dart';
import 'live_api_demo.dart';
import 'live_media_subtitle_page.dart';
import 'live_music_studio_page.dart';
import 'live_smart_notetaker_page.dart';
import 'live_translation_page.dart';
import 'live_vision_call_page.dart';
import 'dj_midi_box_page.dart';
import 'foldable_utils.dart';
import 'live_math_tutor_page.dart';
import 'pro_dj_console_page.dart';
import 'realtime_media_demo.dart';
import 'scrollable_app_bar_actions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiKeyStore.load();
  await AppLanguageController.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLanguageController.instance,
      builder: (context, _) {
        return AppLanguageScope(
          controller: AppLanguageController.instance,
          child: MaterialApp(
            key: ValueKey(AppLanguageController.instance.currentLanguage),
            title: AppLanguageController.instance.t.appTitle,
            locale: AppLanguageController.instance.currentLocale,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
              useMaterial3: true,
            ),
            home: const HomePage(),
          ),
        );
      },
    );
  }
}

enum HomeViewMode {
  auto,
  list,
  grid,
  foldable;

  IconData get icon {
    switch (this) {
      case HomeViewMode.auto:
        return Icons.auto_awesome_mosaic_rounded;
      case HomeViewMode.list:
        return Icons.view_agenda_rounded;
      case HomeViewMode.grid:
        return Icons.grid_view_rounded;
      case HomeViewMode.foldable:
        return Icons.devices_fold_rounded;
    }
  }

  String label(AppTranslations t) {
    switch (this) {
      case HomeViewMode.auto:
        return t.viewModeAuto;
      case HomeViewMode.list:
        return t.viewModeList;
      case HomeViewMode.grid:
        return t.viewModeGrid;
      case HomeViewMode.foldable:
        return t.viewModeFoldable;
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeViewMode _viewMode = HomeViewMode.auto;

  Future<void> _openApiKeySettings() async {
    final changed = await AppSettingsDialog.show(context);
    if (changed == true && mounted) {
      setState(() {});
    }
  }

  void _openDemoPage(BuildContext context, Widget page) {
    final t = AppLanguageController.instance.t;
    if (!ApiKeyStore.hasApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.apiKeyMissingWarning),
          action: SnackBarAction(
            label: t.openSettingsButton,
            onPressed: _openApiKeySettings,
          ),
        ),
      );
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLanguageController.instance,
      builder: (context, _) {
        final t = AppLanguageController.instance.t;

        return Scaffold(
          appBar: AppBar(
            title: Text(t.appTitle),
            centerTitle: true,
            actions: [
              ScrollableAppBarActions(
                children: [
                  PopupMenuButton<HomeViewMode>(
                    tooltip: _viewMode.label(t),
                    initialValue: _viewMode,
                    icon: Icon(_viewMode.icon, size: 20),
                    onSelected: (mode) => setState(() => _viewMode = mode),
                    itemBuilder: (context) => HomeViewMode.values.map((mode) {
                      final isSelected = mode == _viewMode;
                      return PopupMenuItem(
                        value: mode,
                        child: Row(
                          children: [
                            Icon(
                              mode.icon,
                              size: 18,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              mode.label(t),
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 4),
                  const LanguageSelectorButton(),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: t.settingsTooltip,
                    onPressed: _openApiKeySettings,
                  ),
                  const SizedBox(width: 4),
                  Builder(
                    builder: (context) {
                      final foldableInfo = FoldableLayoutInfo.of(context);
                      if (!foldableInfo.hasHinge &&
                          !foldableInfo.isFoldableOrWide) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Tooltip(
                          message: foldableInfo.isTabletop
                              ? t.tabletopMode
                              : t.foldableDetected,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  foldableInfo.isTabletop
                                      ? Icons.laptop_chromebook_rounded
                                      : Icons.devices_fold_rounded,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  foldableInfo.isTabletop
                                      ? 'FLEX'
                                      : (foldableInfo.isDualScreen
                                            ? 'DUO'
                                            : 'FOLD'),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final foldableInfo = FoldableLayoutInfo.of(context);
              final isFoldable =
                  _viewMode == HomeViewMode.foldable ||
                  (_viewMode == HomeViewMode.auto &&
                      (foldableInfo.hasHinge ||
                          (foldableInfo.isFoldableOrWide && width >= 640)));

              // Dual-pane layout for foldable devices (Surface Duo, Galaxy Fold, Wide)
              if (isFoldable) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: FoldableTwoPane(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      startPane: ListView(
                        children: [
                          _buildHeader(t.featuredServices),
                          _buildSectionGrid(
                            isGrid: width >= 1100,
                            maxWidth: width / 2,
                            children: _buildFeaturedCards(context, t),
                          ),
                        ],
                      ),
                      endPane: ListView(
                        children: [
                          _buildHeader(t.basicExamples),
                          _buildSectionGrid(
                            isGrid: false,
                            maxWidth: width / 2,
                            children: _buildBasicCards(context, t),
                          ),
                          const SizedBox(height: 18),
                          _buildHeader(t.newFeatures),
                          _buildSectionGrid(
                            isGrid: width >= 1100,
                            maxWidth: width / 2,
                            children: _buildNewFeatureCards(context, t),
                          ),
                          const SizedBox(height: 20),
                          _buildHeader(t.setupHeader),
                          _buildApiKeyCard(t),
                          const SizedBox(height: 16),
                          _buildHeader(t.capabilitiesHeader),
                          _buildCapabilitiesWrap(),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final isGrid =
                  _viewMode == HomeViewMode.grid ||
                  (_viewMode == HomeViewMode.auto && width >= 660);

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    children: [
                      _buildHeader(t.featuredServices),
                      _buildSectionGrid(
                        isGrid: isGrid,
                        maxWidth: width,
                        children: _buildFeaturedCards(context, t),
                      ),
                      const SizedBox(height: 20),
                      _buildHeader(t.basicExamples),
                      _buildSectionGrid(
                        isGrid: isGrid,
                        maxWidth: width,
                        children: _buildBasicCards(context, t),
                      ),
                      const SizedBox(height: 20),
                      _buildHeader(t.newFeatures),
                      _buildSectionGrid(
                        isGrid: isGrid,
                        maxWidth: width,
                        children: _buildNewFeatureCards(context, t),
                      ),
                      const SizedBox(height: 24),
                      _buildHeader(t.setupHeader),
                      _buildApiKeyCard(t),
                      const SizedBox(height: 16),
                      _buildHeader(t.capabilitiesHeader),
                      _buildCapabilitiesWrap(),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _buildFeaturedCards(BuildContext context, AppTranslations t) {
    return [
      _buildDemoCard(
        context: context,
        title: t.liveTranslationTitle,
        subtitle: t.liveTranslationSubtitle,
        icon: Icons.translate_rounded,
        color: Colors.teal.shade700,
        page: const LiveTranslationPage(),
      ),
      _buildDemoCard(
        context: context,
        title: t.liveMediaSubtitleTitle,
        subtitle: t.liveMediaSubtitleSubtitle,
        icon: Icons.subtitles_rounded,
        color: Colors.indigo.shade700,
        page: const LiveMediaSubtitlePage(),
      ),
      _buildDemoCard(
        context: context,
        title: t.liveSmartNoteTitle,
        subtitle: t.liveSmartNoteSubtitle,
        icon: Icons.edit_note_rounded,
        color: Colors.amber.shade900,
        page: const LiveSmartNotePage(),
      ),
      _buildDemoCard(
        context: context,
        title: t.liveMathTutorTitle,
        subtitle: t.liveMathTutorSubtitle,
        icon: Icons.school_rounded,
        color: Colors.amber.shade900,
        page: const LiveMathTutorPage(),
      ),
      _buildDemoCard(
        context: context,
        title: t.liveVisionAgentTitle,
        subtitle: t.liveVisionAgentSubtitle,
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF14532D),
        page: const LiveVisionCallPage(),
      ),
      _buildDemoCard(
        context: context,
        title: t.liveMusicStudioTitle,
        subtitle: t.liveMusicStudioSubtitle,
        icon: Icons.music_note_rounded,
        color: Colors.purple.shade800,
        page: const LiveMusicStudioPage(),
      ),
      _buildDemoCard(
        context: context,
        title: t.proDjConsoleTitle,
        subtitle: t.proDjConsoleSubtitle,
        icon: Icons.album_rounded,
        color: const Color(0xFFC2185B),
        page: const ProDjConsolePage(),
      ),
      _buildDemoCard(
        context: context,
        title: t.djMidiBoxTitle,
        subtitle: t.djMidiBoxSubtitle,
        icon: Icons.grid_view_rounded,
        color: const Color(0xFF7C3AED),
        page: const DjMidiBoxPage(),
      ),
    ];
  }

  List<Widget> _buildBasicCards(BuildContext context, AppTranslations t) {
    return [
      _buildDemoCard(
        context: context,
        title: t.chatInterfaceTitle,
        subtitle: t.chatInterfaceSubtitle,
        icon: Icons.chat,
        color: Colors.blue,
        page: const ChatPage(),
      ),
    ];
  }

  List<Widget> _buildNewFeatureCards(BuildContext context, AppTranslations t) {
    return [
      _buildDemoCard(
        context: context,
        title: t.liveApiFeaturesTitle,
        subtitle: t.liveApiFeaturesSubtitle,
        icon: Icons.auto_awesome,
        color: Colors.purple,
        page: const LiveAPIDemoPage(),
      ),
      _buildDemoCard(
        context: context,
        title: t.functionCallingTitle,
        subtitle: t.functionCallingSubtitle,
        icon: Icons.functions,
        color: Colors.green,
        page: const FunctionCallingDemoPage(),
      ),
      _buildDemoCard(
        context: context,
        title: t.realtimeMediaTitle,
        subtitle: t.realtimeMediaSubtitle,
        icon: Icons.videocam,
        color: Colors.orange,
        page: const RealtimeMediaDemoPage(),
      ),
    ];
  }

  Widget _buildApiKeyCard(AppTranslations t) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.apiKeyConfigTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(t.statusLabel),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    ApiKeyStore.hasApiKey
                        ? t.configuredStatus(ApiKeyStore.maskedApiKey)
                        : t.notConfiguredStatus,
                  ),
                  backgroundColor: ApiKeyStore.hasApiKey
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              t.apiKeySettingsHelp,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              '${t.getApiKeyLink}: https://aistudio.google.com/app/apikey',
              style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openApiKeySettings,
              icon: const Icon(Icons.settings),
              label: Text(t.openSettingsButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilitiesWrap() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _buildFeatureChip('interactionStatus (IN_PROGRESS / IDLE)'),
        _buildFeatureChip('AudioTranscriptionConfigMode (SMART / VERBATIM)'),
        _buildFeatureChip('GeminiLiveStatusBadge (Widget)'),
        _buildFeatureChip('GeminiLiveMicButton (Widget)'),
        _buildFeatureChip('GeminiLiveVoiceIndicator (Widget)'),
        _buildFeatureChip('toolCall / LiveServerToolCall'),
        _buildFeatureChip('toolCallCancellation'),
        _buildFeatureChip('goAway / LiveServerGoAway'),
        _buildFeatureChip('sessionResumptionUpdate'),
        _buildFeatureChip('voiceActivityDetection'),
        _buildFeatureChip('realtimeInputConfig'),
        _buildFeatureChip('audioTranscription'),
        _buildFeatureChip('contextWindowCompression'),
        _buildFeatureChip('proactivityConfig'),
        _buildFeatureChip('mediaChunks'),
        _buildFeatureChip('activityStart/End'),
        _buildFeatureChip('sendClientContent()'),
        _buildFeatureChip('sendToolResponse()'),
        _buildFeatureChip('sendRealtimeInput()'),
      ],
    );
  }

  Widget _buildSectionGrid({
    required bool isGrid,
    required double maxWidth,
    required List<Widget> children,
  }) {
    if (!isGrid) {
      return Column(
        children: children
            .map(
              (c) =>
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: c),
            )
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxWidth >= 1100 ? 400 : 540,
        mainAxisExtent: 114,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDemoCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: InkWell(
        onTap: () => _openDemoPage(context, page),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String feature) {
    return Chip(
      label: Text(feature, style: const TextStyle(fontSize: 11)),
      backgroundColor: Colors.blue.shade50,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
