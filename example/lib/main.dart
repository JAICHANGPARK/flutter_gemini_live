import 'package:flutter/material.dart';

import 'api_key_store.dart';
import 'app_settings_dialog.dart';
import 'chat_page.dart';
import 'function_calling_demo.dart';
import 'live_api_demo.dart';
import 'live_media_subtitle_page.dart';
import 'live_music_studio_page.dart';
import 'live_smart_notetaker_page.dart';
import 'live_translation_page.dart';
import 'live_vision_call_page.dart';
import 'dj_midi_box_page.dart';
import 'pro_dj_console_page.dart';
import 'realtime_media_demo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiKeyStore.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Gemini Live API',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _openApiKeySettings() async {
    final changed = await AppSettingsDialog.show(context);
    if (changed == true && mounted) {
      setState(() {});
    }
  }

  void _openDemoPage(BuildContext context, Widget page) {
    if (!ApiKeyStore.hasApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gemini API 키가 설정되지 않았습니다. Settings에서 먼저 입력하세요.'),
          action: SnackBarAction(
            label: 'Settings',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Live API Examples'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'API Key Settings',
            onPressed: _openApiKeySettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader('Featured Services'),
          _buildDemoCard(
            context: context,
            title: '🌐 Live Translation (양방향 대면 번역)',
            subtitle:
                '실시간 음성 대 음성 통역 · 테이블 대면 플립 뷰 (180도 회전 자막) · gemini-3.5-live-translate-preview',
            icon: Icons.translate_rounded,
            color: Colors.teal.shade700,
            page: const LiveTranslationPage(),
          ),
          const SizedBox(height: 12),
          _buildDemoCard(
            context: context,
            title: '🎬 Live Media Subtitles (유튜브/미디어 실시간 번역 자막)',
            subtitle:
                'YouTube 영상 링크 재생 · 시스템/마이크 오디오 실시간 번역 자막 HUD · gemini-3.8-live',
            icon: Icons.subtitles_rounded,
            color: Colors.indigo.shade700,
            page: const LiveMediaSubtitlePage(),
          ),
          const SizedBox(height: 12),
          _buildDemoCard(
            context: context,
            title: '📝 Live AI Smart NoteTaker (실시간 강의/회의 통번역 노트)',
            subtitle:
                '실시간 음성 전사(STT) · 동시 번역 · 마크다운 실시간 구조화 노트 및 액션 아이템 추출',
            icon: Icons.edit_note_rounded,
            color: Colors.amber.shade900,
            page: const LiveSmartNotePage(),
          ),
          const SizedBox(height: 12),
          _buildDemoCard(
            context: context,
            title: '✨ Live Vision Agent',
            subtitle:
                'Universal real-time camera viewfinder & mic streaming with low-latency flutter_soloud audio response',
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFF14532D),
            page: const LiveVisionCallPage(),
          ),
          const SizedBox(height: 12),
          _buildDemoCard(
            context: context,
            title: '🎵 Live Music Studio (Lyria 실시간 음원 생성)',
            subtitle:
                'BidiGenerateMusic 양방향 스트리밍 · 가중치 프롬프트 실시간 제어 · BPM/스케일/스템 믹싱 & 실시간 PCM 오디오 재생',
            icon: Icons.music_note_rounded,
            color: Colors.purple.shade800,
            page: const LiveMusicStudioPage(),
          ),
          const SizedBox(height: 12),
          _buildDemoCard(
            context: context,
            title: '🎧 Pro DJ Console (프로 DJ 콘솔)',
            subtitle:
                '플래그십 DJ 하드웨어 콘솔 UI · 듀얼 조그 휠 회전 · 3밴드 EQ 노브 & 듀얼 스테레오 VU 미터 · 8구 RGB 핫 큐 패드 & 크로스페이더',
            icon: Icons.album_rounded,
            color: const Color(0xFFC2185B),
            page: const ProDjConsolePage(),
          ),
          const SizedBox(height: 12),
          _buildDemoCard(
            context: context,
            title: '🎛️ DJ MIDI Box (AI Studio Prompt DJ 스타일)',
            subtitle:
                '16구 로터리 다이얼 그리드 · 네온 헤일로 링 & 아크 게이지 · 원터치 토글 및 실시간 드래그 회전 · Lyria 실시간 음원 믹싱',
            icon: Icons.grid_view_rounded,
            color: const Color(0xFF7C3AED),
            page: const DjMidiBoxPage(),
          ),
          const SizedBox(height: 16),
          _buildHeader('Basic Examples'),
          _buildDemoCard(
            context: context,
            title: 'Chat Interface',
            subtitle: 'Basic chat with text, image, and audio input',
            icon: Icons.chat,
            color: Colors.blue,
            page: const ChatPage(),
          ),
          const SizedBox(height: 16),
          _buildHeader('New Features'),
          _buildDemoCard(
            context: context,
            title: 'Live API Features',
            subtitle:
                'Demo of all new features: VAD, transcription, session resumption, etc.',
            icon: Icons.auto_awesome,
            color: Colors.purple,
            page: const LiveAPIDemoPage(),
          ),
          const SizedBox(height: 12),
          _buildDemoCard(
            context: context,
            title: 'Function Calling',
            subtitle: 'Tool calling with weather/time/fx/search/reminder',
            icon: Icons.functions,
            color: Colors.green,
            page: const FunctionCallingDemoPage(),
          ),
          const SizedBox(height: 12),
          _buildDemoCard(
            context: context,
            title: 'Realtime Media',
            subtitle:
                'Realtime camera preview, microphone streaming, and activity detection',
            icon: Icons.videocam,
            color: Colors.orange,
            page: const RealtimeMediaDemoPage(),
          ),
          const SizedBox(height: 24),
          _buildHeader('Setup'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'API Key Configuration',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Status:'),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          ApiKeyStore.hasApiKey
                              ? 'Configured (${ApiKeyStore.maskedApiKey})'
                              : 'Not configured',
                        ),
                        backgroundColor: ApiKeyStore.hasApiKey
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'API 키를 앱 화면의 Settings 메뉴에서 입력/수정할 수 있습니다.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get your API key from: https://aistudio.google.com/app/apikey',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _openApiKeySettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Open Settings'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildHeader('New Features Included'),
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
      ),
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
      elevation: 2,
      child: InkWell(
        onTap: () => _openDemoPage(context, page),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Chip(
        label: Text(feature, style: const TextStyle(fontSize: 11)),
        backgroundColor: Colors.blue.shade50,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
