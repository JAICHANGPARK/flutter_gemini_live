import 'package:flutter/material.dart';

import '../view_models/media_subtitle_view_model.dart';
import 'floating_subtitle_hud.dart';

/// 16:9 video thumbnail with status overlays, play button and floating HUD.
class VideoPlayerWithHud extends StatelessWidget {
  const VideoPlayerWithHud({
    super.key,
    required this.viewModel,
    required this.pulse,
  });

  final MediaSubtitleViewModel viewModel;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final thumbnailUrl =
        'https://img.youtube.com/vi/${vm.currentVideoId}/maxresdefault.jpg';

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.1),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video Thumbnail (Clickable)
            GestureDetector(
              onTap: vm.playVideo,
              child: Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF1E293B),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.smart_display,
                          color: Colors.redAccent,
                          size: 54,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Video ID: ${vm.currentVideoId}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Subtle dark gradient for subtitle legibility
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black26, Colors.transparent, Colors.black87],
                ),
              ),
            ),

            // Top Status Overlay
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: vm.isConnected
                          ? Colors.red.shade600
                          : Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (vm.isConnected)
                          FadeTransition(
                            opacity: pulse,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        else
                          const Icon(Icons.circle, size: 8, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          vm.isConnected ? 'LIVE SUBTITLES ON' : 'STANDBY',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Target language pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      'Live Translate (gemini-3.5) ➔ ${vm.targetLanguageName}',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Center Interactive YouTube Play Button
            Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: vm.playVideo,
                  borderRadius: BorderRadius.circular(50),
                  hoverColor: Colors.white10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: vm.isConnected
                            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                            : [
                                const Color(0xFFFF0000),
                                const Color(0xFFCC0000),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: vm.isConnected
                            ? Colors.cyanAccent.withValues(alpha: 0.5)
                            : Colors.white30,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (vm.isConnected ? Colors.cyanAccent : Colors.red)
                                  .withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          vm.isConnected
                              ? Icons.open_in_browser_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          vm.isConnected ? '브라우저에서 영상 열기' : '영상 재생 & 실시간 자막 시작',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Cinematic Floating Subtitle HUD
            if (vm.showFloatingHud)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: FloatingSubtitleHud(viewModel: vm),
              ),
          ],
        ),
      ),
    );
  }
}
