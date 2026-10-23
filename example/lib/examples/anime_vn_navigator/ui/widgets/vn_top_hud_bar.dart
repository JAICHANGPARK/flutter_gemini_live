import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../domain/models/vn_character_models.dart';
import '../../domain/models/vn_sdk_chapter.dart';
import '../view_models/anime_vn_view_model.dart';

/// Top Visual Novel HUD displaying Hikari's Affection Meter (好感度),
/// Chapter Selector, Expression/Scene Quick Switchers, Voice Persona selector,
/// and Live Token Usage badge.
class VnTopHudBar extends StatelessWidget {
  final AnimeVnViewModel viewModel;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenBacklog;

  const VnTopHudBar({
    super.key,
    required this.viewModel,
    required this.onOpenSettings,
    required this.onOpenBacklog,
  });

  static const List<GeminiLiveVoice> _recommendedVoices = [
    GeminiLiveVoice.aoede,
    GeminiLiveVoice.kore,
    GeminiLiveVoice.leda,
    GeminiLiveVoice.zephyr,
    GeminiLiveVoice.puck,
    GeminiLiveVoice.fenrir,
  ];

  @override
  Widget build(BuildContext context) {
    final emotion = viewModel.currentEmotion;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xE6090D16),
            const Color(0xB3090D16),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Back button, Title, Affection Meter, Voice Selector, Usage Badge, Settings
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 8),

                // Game Title Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFEC4899).withValues(alpha: 0.85),
                        const Color(0xFF6366F1).withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🌸', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 6),
                      Text(
                        'ときめき☆Gemini Live ナビ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Affection Heart Meter (好感度メーター)
                _buildAffectionBadge(),
                const SizedBox(width: 10),

                // Connection Status / Reconnect Pill
                _buildConnectionPill(),
                const SizedBox(width: 8),

                // Voice Persona Selector (CV切替)
                _buildVoiceSelector(context),
                const SizedBox(width: 8),

                // Scene Background Selector
                _buildSceneSelector(context),
                const SizedBox(width: 8),

                // Real-time Token Usage & Cost Badge
                GeminiLiveUsageBadge(
                  tracker: viewModel.usageTracker,
                  compact: true,
                ),
                const SizedBox(width: 6),

                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'API Key & Audio Settings',
                  icon: const Icon(
                    Icons.settings_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: onOpenSettings,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Row 2: Conference Chapter Tabs + Expression Test Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Chapters 1..4
                for (var i = 0; i < VnScenarioCatalog.chapters.length; i++) ...[
                  _buildChapterChip(i, VnScenarioCatalog.chapters[i]),
                  const SizedBox(width: 6),
                ],
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.white24,
                ),
                const SizedBox(width: 8),

                // Expression Quick Switcher (表情テスト)
                for (final exp in VnCharacterEmotion.values) ...[
                  _buildEmotionPill(exp, isSelected: exp == emotion),
                  const SizedBox(width: 5),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAffectionBadge() {
    final pts = viewModel.affectionPoints;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xCC1E1B4B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF472B6).withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_rounded, color: Color(0xFFF472B6), size: 16),
          const SizedBox(width: 5),
          Text(
            '好感度 $pts%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 48,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pts / 100.0,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFF472B6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            viewModel.affectionRankLabelJa,
            style: const TextStyle(
              color: Color(0xFFFBCFE8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionPill() {
    final connected = viewModel.isConnected;
    final connecting = viewModel.isConnecting;
    final color = connected
        ? const Color(0xFF10B981)
        : (connecting ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
    final label = connected
        ? 'LIVE 接続中 (ja-JP)'
        : (connecting ? '接続中...' : '未接続 (タップで開始)');

    return InkWell(
      onTap: () => viewModel.connectSession(sendInitialGreeting: true),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceSelector(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'CV（キャラクターボイス）変更',
      initialValue: viewModel.selectedVoice,
      onSelected: viewModel.changeVoice,
      itemBuilder: (context) => _recommendedVoices.map((v) {
        final selected = v.id == viewModel.selectedVoice;
        return PopupMenuItem<String>(
          value: v.id,
          child: Row(
            children: [
              Icon(
                Icons.record_voice_over_rounded,
                size: 16,
                color: selected ? const Color(0xFFEC4899) : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CV: ${v.id} (${v.characterDescription})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.spatial_audio_off_rounded,
              color: Color(0xFF38BDF8),
              size: 15,
            ),
            const SizedBox(width: 5),
            Text(
              'CV: ${viewModel.selectedVoice}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSceneSelector(BuildContext context) {
    return PopupMenuButton<VnSceneBackground>(
      tooltip: '背景ステージ変更',
      initialValue: viewModel.currentScene,
      onSelected: viewModel.setSceneManually,
      itemBuilder: (context) => VnSceneBackground.values.map((scene) {
        return PopupMenuItem<VnSceneBackground>(
          value: scene,
          child: Text('${scene.nameJa} (${scene.nameKo})'),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.landscape_rounded, color: Colors.amber, size: 15),
            const SizedBox(width: 5),
            Text(
              viewModel.currentScene.nameJa,
              style: const TextStyle(color: Colors.white, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterChip(int index, VnSdkChapter chapter) {
    final isSelected = viewModel.currentChapterIndex == index;
    return InkWell(
      onTap: () => viewModel.selectChapter(index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF38BDF8).withValues(alpha: 0.28)
              : const Color(0x990F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : Colors.white24,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          'Ch.${chapter.chapterNumber} ${chapter.titleJa.split('：').last}',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionPill(
    VnCharacterEmotion emotion, {
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => viewModel.setEmotionManually(emotion),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? emotion.accentColor.withValues(alpha: 0.3)
              : Colors.black45,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? emotion.accentColor : Colors.white24,
          ),
        ),
        child: Text(
          '${emotion.badgeEmoji} ${emotion.labelJa.split('・').first}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
