/// Preset YouTube videos for quick testing.
class YouTubePreset {
  final String title;
  final String subtitle;
  final String videoId;
  final String category;

  const YouTubePreset({
    required this.title,
    required this.subtitle,
    required this.videoId,
    required this.category,
  });
}

const List<YouTubePreset> kYouTubePresets = [
  YouTubePreset(
    title: 'Google Gemini AI 발표',
    subtitle: 'Google 공식: 가장 진보된 멀티모달 Gemini 모델 발표',
    videoId: 'jV1vkHv4zq8',
    category: 'Gemini / AI',
  ),
  YouTubePreset(
    title: 'TED: Demis Hassabis',
    subtitle: 'DeepMind CEO: AI가 과학의 비밀을 푸는 방법 (AlphaFold)',
    videoId: '0_M_syPuFos',
    category: 'Keynote',
  ),
  YouTubePreset(
    title: 'Steve Jobs 스탠포드 연설',
    subtitle: '스탠포드 대학교 2005 전설적인 졸업식 명연설',
    videoId: 'UF8uR6Z6KLc',
    category: 'Speech',
  ),
  YouTubePreset(
    title: 'Flutter in 100 Seconds',
    subtitle: 'Fireship: 100초 만에 완벽 정리하는 Flutter 핵심',
    videoId: 'lHhRhPV--G0',
    category: 'Developer',
  ),
  YouTubePreset(
    title: 'MKBHD Apple Vision Pro',
    subtitle: 'Marques Brownlee의 생생한 공간 컴퓨팅 실사용 리뷰',
    videoId: 'dtp6b76pMak',
    category: 'Tech Review',
  ),
];
