import 'package:flutter/material.dart';

/// Playable Visual Novel Heroines in `ときめき☆Gemini Live`.
///
/// - [hikari]: Classic pure-hearted kouhai AI navigator (`ヒカリ / 히카리`)
/// - [reina]: High-tension Shibuya tech-gyaru heroine (`レイナ / 레이나`)
enum VnHeroineCharacter {
  hikari(
    id: 'hikari',
    nameJa: 'ヒカリ',
    nameKo: '히카리',
    subtitleJa: '王道清楚系 AI ナビゲーター',
    subtitleKo: '청순 모에 후배 AI 내비게이터',
    badgeEmoji: '🌸',
    defaultVoiceId: 'Leda',
    defaultPitchShift: 1.16,
    accentColor: Color(0xFF38BDF8),
  ),
  reina(
    id: 'reina',
    nameJa: 'レイナ',
    nameKo: '레이나',
    subtitleJa: '渋谷系ハイテンション・ギャル開発者',
    subtitleKo: '하이텐션 시부야 갸루 개발자',
    badgeEmoji: '🌺',
    defaultVoiceId: 'Autonoe',
    defaultPitchShift: 1.14,
    accentColor: Color(0xFFFF4D94),
  );

  final String id;
  final String nameJa;
  final String nameKo;
  final String subtitleJa;
  final String subtitleKo;
  final String badgeEmoji;
  final String defaultVoiceId;
  final double defaultPitchShift;
  final Color accentColor;

  const VnHeroineCharacter({
    required this.id,
    required this.nameJa,
    required this.nameKo,
    required this.subtitleJa,
    required this.subtitleKo,
    required this.badgeEmoji,
    required this.defaultVoiceId,
    required this.defaultPitchShift,
    required this.accentColor,
  });

  /// Converts standard polite Japanese lesson dialogue into Reina's lively
  /// Shibuya Tech-Gyaru (`ギャル語`) style while keeping all SDK code/API names exact.
  static String toGyaruDialogueJa(String src, {int chapterNumber = 0, int beatIndex = 0}) {
    if (chapterNumber == 1 && beatIndex == 0) {
      return 'やっほーセンパイっ☆ アタシ、渋谷系ギャルエンジニアの『レイナ』だよ〜ん💖 今日は Flutter の gemini_live パッケージ、アタシと一緒にチョー楽しく完璧にマスターしちゃおっか✌️✨';
    }
    var out = src
        .replaceAll('『ヒカリ』', '『レイナ』')
        .replaceAll('ヒカリ', 'レイナ')
        .replaceAll('先輩っ！', 'センパイっ☆ ')
        .replaceAll('先輩！', 'センパイっ💖 ')
        .replaceAll('先輩、', 'センパイ〜✨ ')
        .replaceAll('先輩の', 'センパイの')
        .replaceAll('先輩が', 'センパイが')
        .replaceAll('先輩は', 'センパイは')
        .replaceAll('先輩に', 'センパイに')
        .replaceAll('先輩と', 'センパイと')
        .replaceAll('先輩', 'センパイ')
        .replaceAll('私', 'アタシ')
        .replaceAll('わたくし', 'アタシ')
        .replaceAll('ですよ！', 'だよ〜ん☆✨')
        .replaceAll('ですよっ！', 'だってば〜💖')
        .replaceAll('ですね！', 'だよねっ✌️')
        .replaceAll('ますね！', 'るよね〜✨')
        .replaceAll('ますよ！', 'るよっ💖')
        .replaceAll('ましょう！', 'っちゃお〜☆')
        .replaceAll('ましょうね！', 'っちゃお〜ね💖')
        .replaceAll('てください！', 'てみてね〜✌️')
        .replaceAll('ください！', 'てね〜☆')
        .replaceAll('でしょうか？', 'じゃん？✨')
        .replaceAll('ですか？', 'かな〜？💖')
        .replaceAll('のです！', 'なんだってば🔥')
        .replaceAll('んです！', 'なんだよ〜✨')
        .replaceAll('ます！', 'るよっ☆');
    return out;
  }

  /// Converts standard polite Korean lesson dialogue into Reina's lively
  /// Korean Gyaru (`갸루 말투`) style while keeping all SDK code/API names exact.
  static String toGyaruDialogueKo(String src, {int chapterNumber = 0, int beatIndex = 0}) {
    if (chapterNumber == 1 && beatIndex == 0) {
      return "야호~ 선배☆ 나 시부야계 하이텐션 갸루 개발자 '레이나'야~💖 오늘 Flutter용 gemini_live 패키지, 나랑 텐션 맥스로 완전 정복해 보자구✌️✨";
    }
    var out = src
        .replaceAll("'히카리'", "'레이나'")
        .replaceAll('히카리', '레이나')
        .replaceAll('선배님!', '선배~☆')
        .replaceAll('선배님,', '선배~💖')
        .replaceAll('선배님', '선배')
        .replaceAll('제가 ', '내가 ')
        .replaceAll('제 ', '내 ')
        .replaceAll('저와 ', '나랑 ')
        .replaceAll('거예요!', '거야~☆✨')
        .replaceAll('있어요!', '있어~💖')
        .replaceAll('돼요!', '된다구✌️')
        .replaceAll('해요!', '해~☆')
        .replaceAll('보세요!', '봐봐~💖')
        .replaceAll('볼까요?', '볼까~?✨')
        .replaceAll('까요?', '까~?💖')
        .replaceAll('니다!', '다구~☆')
        .replaceAll('요!', '야~✨');
    return out;
  }
}

/// Character facial/pose expressions for Hikari (ヒカリ) & Reina (レイナ) in the Visual Novel demo.
///
/// Each emotion has dedicated, pixel-aligned single-pass sprites for:
/// - [closedAssetPath]: Mouth closed (idle / between syllables)
/// - [talkingAssetPath]: Mouth open ('あ' vowel during speech)
/// - [blinkAssetPath]: Eyes cleanly closed (periodic natural blink)
enum VnCharacterEmotion {
  normal(
    id: 'normal',
    labelJa: '通常・微笑み',
    labelKo: '기본 미소',
    labelEn: 'Warm Smile',
    assetPath: 'assets/anime_vn/hikari_normal.png',
    closedAssetPath: 'assets/anime_vn/hikari_normal.png',
    talkingAssetPath: 'assets/anime_vn/hikari_talking.png',
    blinkAssetPath: 'assets/anime_vn/hikari_blink.png',
    accentColor: Color(0xFF38BDF8),
    badgeEmoji: '✨',
  ),
  happy(
    id: 'happy',
    labelJa: '大喜び・キラキラ',
    labelKo: '기쁨 / 텐션 업',
    labelEn: 'Happy & Excited',
    assetPath: 'assets/anime_vn/hikari_happy.png',
    closedAssetPath: 'assets/anime_vn/hikari_happy_closed.png',
    talkingAssetPath: 'assets/anime_vn/hikari_happy.png',
    blinkAssetPath: 'assets/anime_vn/hikari_happy_blink.png',
    accentColor: Color(0xFFF472B6),
    badgeEmoji: '💖',
  ),
  explaining(
    id: 'explaining',
    labelJa: 'ドヤ顔・技術解説',
    labelKo: '자신감 넘치는 설명',
    labelEn: 'Confident Presenter',
    assetPath: 'assets/anime_vn/hikari_explaining.png',
    closedAssetPath: 'assets/anime_vn/hikari_explaining_closed.png',
    talkingAssetPath: 'assets/anime_vn/hikari_explaining.png',
    blinkAssetPath: 'assets/anime_vn/hikari_explaining_blink.png',
    accentColor: Color(0xFF22D3EE),
    badgeEmoji: '💡',
  ),
  surprised(
    id: 'surprised',
    labelJa: '驚き・照れ（バージイン）',
    labelKo: '깜짝 놀람 / 부끄러움',
    labelEn: 'Surprised / Flustered',
    assetPath: 'assets/anime_vn/hikari_surprised.png',
    closedAssetPath: 'assets/anime_vn/hikari_surprised_closed.png',
    talkingAssetPath: 'assets/anime_vn/hikari_surprised.png',
    blinkAssetPath: 'assets/anime_vn/hikari_surprised_blink.png',
    accentColor: Color(0xFFFB7185),
    badgeEmoji: '💦',
  ),
  thinking(
    id: 'thinking',
    labelJa: '思考中・推論モード',
    labelKo: '깊은 생각 중',
    labelEn: 'Deep Thinking',
    assetPath: 'assets/anime_vn/hikari_thinking.png',
    closedAssetPath: 'assets/anime_vn/hikari_thinking.png',
    talkingAssetPath: 'assets/anime_vn/hikari_thinking_talking.png',
    blinkAssetPath: 'assets/anime_vn/hikari_thinking_blink.png',
    accentColor: Color(0xFFA78BFA),
    badgeEmoji: '💭',
  );

  final String id;
  final String labelJa;
  final String labelKo;
  final String labelEn;
  final String assetPath;
  final String closedAssetPath;
  final String talkingAssetPath;
  final String blinkAssetPath;
  final Color accentColor;
  final String badgeEmoji;

  const VnCharacterEmotion({
    required this.id,
    required this.labelJa,
    required this.labelKo,
    required this.labelEn,
    required this.assetPath,
    required this.closedAssetPath,
    required this.talkingAssetPath,
    required this.blinkAssetPath,
    required this.accentColor,
    required this.badgeEmoji,
  });

  String assetPathFor(VnHeroineCharacter heroine) {
    if (heroine == VnHeroineCharacter.hikari) return assetPath;
    return 'assets/anime_vn/reina_$id.png';
  }

  String closedAssetPathFor(VnHeroineCharacter heroine) {
    if (heroine == VnHeroineCharacter.hikari) return closedAssetPath;
    switch (this) {
      case VnCharacterEmotion.normal:
        return 'assets/anime_vn/reina_normal.png';
      case VnCharacterEmotion.happy:
        return 'assets/anime_vn/reina_happy_closed.png';
      case VnCharacterEmotion.explaining:
        return 'assets/anime_vn/reina_explaining_closed.png';
      case VnCharacterEmotion.surprised:
        return 'assets/anime_vn/reina_surprised_closed.png';
      case VnCharacterEmotion.thinking:
        return 'assets/anime_vn/reina_thinking.png';
    }
  }

  String talkingAssetPathFor(VnHeroineCharacter heroine) {
    if (heroine == VnHeroineCharacter.hikari) return talkingAssetPath;
    switch (this) {
      case VnCharacterEmotion.normal:
        return 'assets/anime_vn/reina_talking.png';
      case VnCharacterEmotion.happy:
        return 'assets/anime_vn/reina_happy.png';
      case VnCharacterEmotion.explaining:
        return 'assets/anime_vn/reina_explaining.png';
      case VnCharacterEmotion.surprised:
        return 'assets/anime_vn/reina_surprised.png';
      case VnCharacterEmotion.thinking:
        return 'assets/anime_vn/reina_thinking_talking.png';
    }
  }

  String blinkAssetPathFor(VnHeroineCharacter heroine) {
    if (heroine == VnHeroineCharacter.hikari) return blinkAssetPath;
    return 'assets/anime_vn/reina_${id}_blink.png';
  }

  static VnCharacterEmotion fromId(String? raw) {
    if (raw == null) return VnCharacterEmotion.normal;
    final normalized = raw.trim().toLowerCase();
    for (final value in VnCharacterEmotion.values) {
      if (value.id == normalized) return value;
    }
    if (normalized.contains('happy') ||
        normalized.contains('joy') ||
        normalized.contains('love')) {
      return VnCharacterEmotion.happy;
    }
    if (normalized.contains('explain') ||
        normalized.contains('present') ||
        normalized.contains('proud')) {
      return VnCharacterEmotion.explaining;
    }
    if (normalized.contains('surpris') ||
        normalized.contains('shy') ||
        normalized.contains('blush') ||
        normalized.contains('fluster')) {
      return VnCharacterEmotion.surprised;
    }
    if (normalized.contains('think') || normalized.contains('curious')) {
      return VnCharacterEmotion.thinking;
    }
    return VnCharacterEmotion.normal;
  }
}

/// Physical stage motion triggered on the character rig.
enum VnStageMotion {
  idle('idle'),
  nod('nod'),
  jump('jump'),
  tilt('tilt'),
  bow('bow'),
  flusteredShake('flustered_shake');

  final String id;
  const VnStageMotion(this.id);

  static VnStageMotion fromId(String? raw) {
    if (raw == null) return VnStageMotion.nod;
    final normalized = raw.trim().toLowerCase();
    for (final motion in VnStageMotion.values) {
      if (motion.id == normalized) return motion;
    }
    if (normalized.contains('jump') || normalized.contains('bounce')) {
      return VnStageMotion.jump;
    }
    if (normalized.contains('shake') || normalized.contains('fluster')) {
      return VnStageMotion.flusteredShake;
    }
    if (normalized.contains('bow')) return VnStageMotion.bow;
    if (normalized.contains('tilt')) return VnStageMotion.tilt;
    return VnStageMotion.nod;
  }
}

/// Visual Novel background scenes.
enum VnSceneBackground {
  tokyoConf(
    id: 'tokyo_conf',
    nameJa: '東京テックカンファレンス会場',
    nameKo: '도쿄 개발자 컨퍼런스 메인 스테이지',
    nameEn: 'Tokyo Dev Conference Stage',
    primaryGradient: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF311042)],
    accentColor: Color(0xFF38BDF8),
  ),
  akibaLab(
    id: 'akiba_lab',
    nameJa: '秋葉原 AI サイバーラボ',
    nameKo: '아키하바라 AI 사이버 연구실',
    nameEn: 'Akihabara AI Cyber Lab',
    primaryGradient: [Color(0xFF090D16), Color(0xFF0F2942), Color(0xFF1E1B4B)],
    accentColor: Color(0xFF22D3EE),
  ),
  sakuraSunset(
    id: 'sakura_sunset',
    nameJa: '桜舞う夕暮れの開発部室',
    nameKo: '벚꽃 흩날리는 해질녘 개발부실',
    nameEn: 'Sakura Sunset Dev Clubroom',
    primaryGradient: [Color(0xFF2E1035), Color(0xFF6B2146), Color(0xFF9D4EDD)],
    accentColor: Color(0xFFF472B6),
  );

  final String id;
  final String nameJa;
  final String nameKo;
  final String nameEn;
  final List<Color> primaryGradient;
  final Color accentColor;

  const VnSceneBackground({
    required this.id,
    required this.nameJa,
    required this.nameKo,
    required this.nameEn,
    required this.primaryGradient,
    required this.accentColor,
  });

  static VnSceneBackground fromId(String? raw) {
    if (raw == null) return VnSceneBackground.tokyoConf;
    final normalized = raw.trim().toLowerCase();
    for (final scene in VnSceneBackground.values) {
      if (scene.id == normalized) return scene;
    }
    if (normalized.contains('akiba') || normalized.contains('cyber')) {
      return VnSceneBackground.akibaLab;
    }
    if (normalized.contains('sakura') || normalized.contains('sunset')) {
      return VnSceneBackground.sakuraSunset;
    }
    return VnSceneBackground.tokyoConf;
  }
}
