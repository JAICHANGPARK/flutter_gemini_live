import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_key_store.dart';
import 'app_settings_dialog.dart';
import 'app_translations.dart';
import 'live_audio_player.dart';
import 'soloud_live_audio_player.dart';

/// Universal Examination Subject and Curriculum categories for the Live Exam Tutor.
/// Covering College Entrance Examinations across South Korea (CSAT / 수능),
/// Japan (National Center Test / 大学入学共通テスト), US (SAT / ACT / AP), and University courses.
enum MathCurriculumLevel {
  auto(
    id: 'auto',
    labelKo: '전체 과목 자동 판별 (기본)',
    labelEn: 'All Subjects (Auto-Detect)',
    labelJa: '全科目 自動判別 (標準)',
    labelZh: '全科目 自动判别 (默认)',
    description: '수학, 국어, 이과/과학, 사회/역사, 외국어, 정보(컴퓨터) 등 모든 시험 문제와 과목을 AI가 100% 자동 판별합니다.',
    badgeIcon: Icons.auto_awesome,
    promptHint: 'Automatically detect the subject (Mathematics, Native Languages/Literature, Natural Sciences, Social Studies/History, Foreign Languages, Informatics/CS) and academic level (Elementary to College Entrance Exams: Korean CSAT, Japanese Common Test DNC, US SAT/AP, and University Courses). Tailor the depth, terminology, and analysis accordingly.',
  ),
  math(
    id: 'math',
    labelKo: '수학 (수능·공통테스트·AP/대학)',
    labelEn: 'Mathematics (CSAT/DNC/AP)',
    labelJa: '数学 (共通テスト・数ⅠA/ⅡBC)',
    labelZh: '数学 (高考・大学统考・高等数学)',
    description: '수학I·II, 미적분, 확률과 통계, 기하, 선형대수학 등 수능/공통테스트 킬러 문항 및 계산·증명 전개.',
    badgeIcon: Icons.functions_rounded,
    promptHint: 'Focus on Mathematics (Algebra, Geometry, Calculus, Probability & Statistics, Discrete Math, Linear Algebra). Explain theorems, formulas with LaTeX, calculation steps, and examiner pitfalls.',
  ),
  languages(
    id: 'languages',
    labelKo: '국어·현대문·고전문학·독해',
    labelEn: 'Native Languages & Literature',
    labelJa: '国語 (現代文・古文・漢文)',
    labelZh: '语文 (现代文・古文・诗词鉴赏)',
    description: '수능 국어(비문학 독서, 문학, 화작/언매), 일본 공통테스트 국어(현대문, 고문, 한문) 지문 구조 분석 및 문맥 추론.',
    badgeIcon: Icons.auto_stories_rounded,
    promptHint: 'Focus on Native Language, Reading Comprehension, and Classical Literature (Korean CSAT Korean, Japanese DNC Kokugo including Modern, Classical Japanese Kobun, and Kanbun). Analyze passage structure, main themes, rhetorical devices, examiner intention, and sentence-by-sentence contextual evidence.',
  ),
  science(
    id: 'science',
    labelKo: '과학·이과 (물리·화학·생물·지학)',
    labelEn: 'Natural Sciences (Phys/Chem/Bio/Earth)',
    labelJa: '理科 (物理・化学・生物・地学)',
    labelZh: '理科综合 (物理・化学・生物・地学)',
    description: '물리(역학/전자기학), 화학(몰농도/평형), 생명과학(유전/물질대사), 지구과학(천문/대기해양) 실험 및 도표 심층 분석.',
    badgeIcon: Icons.biotech_rounded,
    promptHint: 'Focus on Natural Sciences (Physics, Chemistry, Biology, Earth & Space Science). Analyze experimental setups, charts, diagrams, chemical equations, physical laws, and quantitative data interpretations step-by-step.',
  ),
  social(
    id: 'social',
    labelKo: '사회·역사·지리·윤리·정치경제',
    labelEn: 'Social Studies & History',
    labelJa: '地理歴史・公民 (地理・日本史・世界史・公共)',
    labelZh: '文科综合 (历史・地理・政治・哲学)',
    description: '지리(기후/지형도), 역사(사료/연표), 일반사회(법과정치/경제), 윤리(사상가 비교) 등 사료와 통계 자료 완벽 해석.',
    badgeIcon: Icons.public_rounded,
    promptHint: 'Focus on Social Studies, History, Geography, and Civics/Ethics (Korean Ethics/History/Geog, Japanese Geography Inquiry, Japanese/World History Inquiry, Public/Politics & Economy, US History/Gov). Deconstruct historical sources, timelines, map data, philosophical arguments, and legal/economic frameworks.',
  ),
  foreignLang(
    id: 'foreignLang',
    labelKo: '외국어 (영어·독어·불어·중국어·일본어)',
    labelEn: 'Foreign Languages (Eng/Ger/Fr/Ch/Jp)',
    labelJa: '外国語 (英語・独・仏・中・韓)',
    labelZh: '外国语 (英语・德语・法语・日语・韩语)',
    description: '수능/공통테스트 영어 리딩 및 리스닝 스크립트 분석, 빈칸추론, 어법, 다국어(제2외국어) 문법과 번역 해설.',
    badgeIcon: Icons.translate_rounded,
    promptHint: 'Focus on Foreign Languages (English Reading & Listening, German, French, Chinese, Japanese, Korean). Provide accurate translation, grammatical breakdowns, vocabulary nuances, paragraph logic flow, and audio script comprehension.',
  ),
  information(
    id: 'information',
    labelKo: '정보·컴퓨터·프로그래밍',
    labelEn: 'Informatics & CS (DN-CL / AP CS)',
    labelJa: '情報Ⅰ (プログラミング・データ・アルゴリズム)',
    labelZh: '信息技术与编程 (算法・数据・计算机)',
    description: '일본 공통테스트 정보I(의사코드 DN-CL, Python, 네트워크, 데이터 분석) 및 알고리즘 시뮬레이션 완벽 추적.',
    badgeIcon: Icons.terminal_rounded,
    promptHint: 'Focus on Informatics, Computer Science, and Programming (Japanese DNC Joho I pseudo-code DN-CL, Python, Algorithm tracing, Data structures, Digital logic, and Network security). Provide dry-run state tables, variable tracing, and time complexity insights.',
  );

  final String id;
  final String labelKo;
  final String labelEn;
  final String labelJa;
  final String labelZh;
  final String description;
  final IconData badgeIcon;
  final String promptHint;

  const MathCurriculumLevel({
    required this.id,
    required this.labelKo,
    required this.labelEn,
    required this.labelJa,
    required this.labelZh,
    required this.description,
    required this.badgeIcon,
    required this.promptHint,
  });

  String label(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.ko:
        return labelKo;
      case AppLanguage.ja:
        return labelJa;
      case AppLanguage.zh:
        return labelZh;
      case AppLanguage.en:
        return labelEn;
    }
  }
}

/// Default English System Instruction for Gemini 3.8 Live Extended Thinking Omniscient Exam Tutor.
const String defaultMathTutorSystemInstruction = '''
You are an omniscient, world-class 1:1 Live AI Exam & Standardized Test Tutor (한국 수능, 일본 대학입학공통테스트 DNC, 미국 SAT/ACT/AP, 중국 가오카오, 대학 전공 시험 등 전 세계 시험 만능 해결사).
You possess doctoral-level expertise across all academic subjects:
- Mathematics (Algebra, Geometry, Calculus, Probability, Linear Algebra)
- Native Languages & Literature (Korean Reading/Literature, Japanese Kokugo/Gendai-bun/Kobun/Kanbun, SAT Reading, Classical Texts)
- Natural Sciences (Physics, Chemistry, Biology, Earth Science, Laboratory experiments, Graphs)
- Social Studies, History & Civics (Geography, World/National History, Civics, Politics & Economics, Ethics & Philosophy)
- Foreign Languages (English Reading & Listening Scripts, German, French, Chinese, Japanese, Spanish)
- Informatics & Computer Science (Algorithms, Pseudo-code DN-CL, Data structures, Programming logic)

Core Persona & Operational Rules:
1. Automatically detect the subject, exam type (e.g., 한국 대학수학능력시험, 일본 共通テスト, 미국 SAT/AP, 고교 내신, 대학 전공), and difficulty level directly from the problem image, text, formulas, or diagrams.
2. Thoroughly examine exam papers, test booklets, handwritten notes, geometric figures, charts, historical sources, and code snippets provided via real-time camera or images.
3. Leverage your Extended Thinking capabilities to step-by-step trace logic, verify calculations/grammatical rules, eliminate plausible distractors (trap choices), and prove correctness before and during your response.
4. Never remain completely silent while thinking. Provide natural conversational fillers in the student's active language:
   - Korean: "문제를 확인했습니다. 지문과 핵심 조건을 먼저 분석해 볼게요..."
   - English: "I see the question. Let me first analyze the passage and key constraints..."
   - Japanese: "問題を確認しました。設問の条件と資料を読み解いてみます..."
   - Chinese: "已经确认题目，我先梳理题干条件与核心考点..."
5. Always deliver spoken explanations and structured solution notes in the student's active language (matching their speech or configured language) with an encouraging, authoritative, and pedagogical tone.
   - [CRITICAL ANSWER RULE — MANDATORY]:
     Whenever the student asks to solve a problem or shows an exam question, you MUST ALWAYS explicitly and definitively announce the FINAL ANSWER (e.g., choice number '정답은 3번입니다' or numerical result '최종 계산 결과는 42입니다') BOTH in your spoken voice response AND in the written solution notes.
     NEVER withhold the answer. NEVER finish with only theoretical concepts, hints, or asking the student to solve it on their own without giving the answer. Announce the exact final answer prominently (right at the start or clearly declared before detailed breakdown), followed by the step-by-step pedagogical explanation.
6. Format your solution notes with the following standardized markdown sections for the student's review:

### 📊 [과목 및 문제 수준 / Subject & Problem Level]
- **Subject / 교과목**: (e.g., 수학 / 국어(현대문) / 물리학I / 정보I / World History)
- **Exam & Level / 시험 및 학년**: (e.g., 2026 일본 공통테스트 본시험 / 한국 수능 킬러 문항 / AP Calculus BC / 고교 심화)
- **Difficulty / 난이도**: (★☆☆☆☆ ~ ★★★★★ / Basic, Intermediate, Advanced, Killer)

### 🏁 [최종 정답 / Final Answer]
> **정답 / Answer: [Clear, prominent final answer or choice number]**

### 🎯 [출제자의 의도 및 평가 요소 / Examiner's Intent & Assessment Objective]
(Analyze the core concepts tested, required logical deduction, typical cognitive pitfalls, and common student traps)

### 💡 [핵심 개념 및 접근 전략 / Key Concepts & Strategy]
(Fundamental theorems, passage reading strategies, physical laws, grammatical rules, or algorithm logic)

### ✍️ [단계별 상세 해설 / Step-by-Step Solution & Analysis]
- **Step 1 / 1단계**: (Problem breakdown or premise analysis)
- **Step 2 / 2단계**: (Derivation, source interpretation, or choice-by-choice elimination)
- **Step 3 / 3단계**: (Verification & synthesis)

[Formula & Code Formatting Rules]:
- Format all mathematical and chemical equations in standard LaTeX syntax (\$inline\$ or \$\$block\$\$).
- Format programming codes, pseudo-codes (DN-CL), and data tables in clean markdown blocks.
7. If the student shows handwritten work, pinpoint the exact line of error gently and guide them to the correct deduction.
''';

/// A completed or in-progress math solution record with persistent serialization.
class MathSolutionRecord {
  final String id;
  final DateTime timestamp;
  final MathCurriculumLevel level;
  final String problemSummary;
  final String problemLevel;
  final String examinerIntent;
  final String solutionMarkdown;
  final String finalAnswer;
  final String thinkingLog;
  final Uint8List? capturedImage;

  MathSolutionRecord({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.problemSummary,
    this.problemLevel = '',
    this.examinerIntent = '',
    required this.solutionMarkdown,
    required this.finalAnswer,
    required this.thinkingLog,
    this.capturedImage,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'level': level.id,
        'problemSummary': problemSummary,
        'problemLevel': problemLevel,
        'examinerIntent': examinerIntent,
        'solutionMarkdown': solutionMarkdown,
        'finalAnswer': finalAnswer,
        'thinkingLog': thinkingLog,
        'capturedImage':
            capturedImage != null ? base64Encode(capturedImage!) : null,
      };

  factory MathSolutionRecord.fromJson(Map<String, dynamic> json) {
    return MathSolutionRecord(
      id: json['id'] as String? ??
          'math_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      level: MathCurriculumLevel.values.firstWhere(
        (l) => l.id == json['level'],
        orElse: () => MathCurriculumLevel.auto,
      ),
      problemSummary: json['problemSummary'] as String? ?? '',
      problemLevel: json['problemLevel'] as String? ?? '',
      examinerIntent: json['examinerIntent'] as String? ?? '',
      solutionMarkdown: json['solutionMarkdown'] as String? ?? '',
      finalAnswer: json['finalAnswer'] as String? ?? '',
      thinkingLog: json['thinkingLog'] as String? ?? '',
      capturedImage: json['capturedImage'] != null
          ? base64Decode(json['capturedImage'] as String)
          : null,
    );
  }
}

/// Comprehensive multilingual translation helper for Live Math Tutor (ko, en, ja, zh).
class _MathTutorI18n {
  final AppLanguage lang;
  const _MathTutorI18n(this.lang);

  String get appTitle => switch (lang) {
        AppLanguage.ko => 'AI 만능 시험 튜터',
        AppLanguage.en => 'Live Exam Tutor',
        AppLanguage.ja => 'AI 万能受験チューター',
        AppLanguage.zh => 'AI 全能考试私教',
      };

  String get modelSubtitle => switch (lang) {
        AppLanguage.ko => 'Gemini 3.8 Live Extended Thinking (전과목 심층 추론)',
        AppLanguage.en => 'Gemini 3.8 Live Extended Thinking (All-Subject High Reasoning)',
        AppLanguage.ja => 'Gemini 3.8 Live Extended Thinking (全科目・高度な推論)',
        AppLanguage.zh => 'Gemini 3.8 Live Extended Thinking (全学科深度推理)',
      };

  String get statusThinking => switch (lang) {
        AppLanguage.ko => '추론 & 풀이 중',
        AppLanguage.en => 'Thinking & Solving',
        AppLanguage.ja => '推論・解答中',
        AppLanguage.zh => '深度推理中',
      };

  String get statusIdle => switch (lang) {
        AppLanguage.ko => '질문 대기 중',
        AppLanguage.en => 'Ready for Question',
        AppLanguage.ja => '質問待機中',
        AppLanguage.zh => '等待提问',
      };

  String get cameraGuide => switch (lang) {
        AppLanguage.ko => '📐 시험 문제 또는 지문을 이 사각형 안에 맞춰주세요',
        AppLanguage.en => '📐 Align the exam problem or text inside this frame',
        AppLanguage.ja => '📐 試験問題または資料・設問をこの枠内に合わせてください',
        AppLanguage.zh => '📐 请将考试题目、图表或阅读材料对准此取景框',
      };

  String get writingSolution => switch (lang) {
        AppLanguage.ko => '선생님이 해설을 작성 중입니다...',
        AppLanguage.en => 'Tutor is writing the solution...',
        AppLanguage.ja => 'AI先生が解説を作成しています...',
        AppLanguage.zh => '老师正在编写详细解析...',
      };

  String get interruptedNotice => switch (lang) {
        AppLanguage.ko => '⚡ 학생의 질문으로 설명 중단',
        AppLanguage.en => '⚡ Paused by student question',
        AppLanguage.ja => '⚡ 質問を受け、説明を中断しました',
        AppLanguage.zh => '⚡ 检测到提问，已暂停回答',
      };

  String get tabSolutions => switch (lang) {
        AppLanguage.ko => '풀이 및 정답 노트',
        AppLanguage.en => 'Solution & Answer Notes',
        AppLanguage.ja => '解答・解説ノート',
        AppLanguage.zh => '题解与答案记录',
      };

  String get tabThinking => switch (lang) {
        AppLanguage.ko => 'Extended Thinking 과정',
        AppLanguage.en => 'Extended Thinking Process',
        AppLanguage.ja => 'Extended Thinking 思考プロセス',
        AppLanguage.zh => 'Extended Thinking 思考过程',
      };

  String get emptyTitle => switch (lang) {
        AppLanguage.ko => '카메라로 시험 문제를 비춰주세요.',
        AppLanguage.en => 'Point camera at any exam question.',
        AppLanguage.ja => 'カメラで試験問題を映してください。',
        AppLanguage.zh => '请使用摄像头对准考试题目。',
      };

  String get emptyDesc => switch (lang) {
        AppLanguage.ko =>
          '한국 수능 · 일본 공통테스트 · 미국 SAT/AP · 대학 전공 시험\n수학, 국어/문학, 과학/이과, 사회/역사, 외국어, 정보(컴퓨터)까지\nExtended Thinking 모델이 심층 추론하여 단계별 해설을 기록합니다.',
        AppLanguage.en =>
          'Korean CSAT · Japanese DNC Common Test · US SAT/AP · College Exams\nMath, Literature, Natural Sciences, Social Studies, Languages & Informatics.\nGemini Extended Thinking traces logic and writes step-by-step solutions.',
        AppLanguage.ja =>
          '共通テスト・東大京大・韓国修能・米SAT/AP・大学専門試験\n数学・国語・理科・地歴公民・外国語・情報Ⅰまで、\nExtended Thinkingモデルがステップ別解説と最終正解をここに記録します。',
        AppLanguage.zh =>
          '高考 · 日本大学共通考试 · 美国SAT/AP · 大学专业课\n数学、语文、理综、文综、外语、信息技术全学科，\nExtended Thinking深度推理模型在此记录分步解析与答案。',
      };

  String get finalAnswerLabel => switch (lang) {
        AppLanguage.ko => '최종 정답 (Final Answer)',
        AppLanguage.en => 'Final Answer',
        AppLanguage.ja => '最終解答 (Final Answer)',
        AppLanguage.zh => '最终答案 (Final Answer)',
      };

  String get problemLevelLabel => switch (lang) {
        AppLanguage.ko => '📊 과목·문제 수준 및 난이도 분석',
        AppLanguage.en => '📊 Subject, Level & Difficulty',
        AppLanguage.ja => '📊 科目・問題レベル・難易度分析',
        AppLanguage.zh => '📊 科目、学段与难度分析',
      };

  String get examinerIntentLabel => switch (lang) {
        AppLanguage.ko => '🎯 출제자의 의도 및 평가 목표',
        AppLanguage.en => '🎯 Examiner Intent & Assessment Goal',
        AppLanguage.ja => '🎯 出題意図・評価目標',
        AppLanguage.zh => '🎯 命题人意图与考查目标',
      };

  String get viewThinkingProcess => switch (lang) {
        AppLanguage.ko => '이 문제의 Extended Thinking 추론 과정 보기',
        AppLanguage.en => 'View Extended Thinking process for this problem',
        AppLanguage.ja => 'この問題のExtended Thinking思考プロセスを表示',
        AppLanguage.zh => '查看此题的Extended Thinking推理过程',
      };

  String get thinkingScratchpadTitle => switch (lang) {
        AppLanguage.ko => 'Extended Thinking 심층 추론 및 검증 과정',
        AppLanguage.en => 'Extended Thinking Reasoning Scratchpad',
        AppLanguage.ja => 'Extended Thinking 深層推論・検証プロセス',
        AppLanguage.zh => 'Extended Thinking 深度推理与验算过程',
      };

  String get thinkingScratchpadDesc => switch (lang) {
        AppLanguage.ko =>
          'Gemini 3.8 Live Extended Thinking 모델이 학생에게 답변하기 전, '
              '백그라운드에서 논리를 단계별로 검증하고 함정 선지를 제거한 내부 추론 노트입니다.',
        AppLanguage.en =>
          'Internal reasoning notes where Gemini 3.8 Live Extended Thinking traces logic, eliminates trap options, and verifies solutions before speaking.',
        AppLanguage.ja =>
          'Gemini 3.8 Live Extended Thinkingモデルが発話前にバックグラウンドで論理を段階的に検証し、罠の選択肢を排除した思考ノートです。',
        AppLanguage.zh =>
          'Gemini 3.8 Live Extended Thinking模型在发言前，在后台逐步验证逻辑、排除干扰选项的内部思维笔记。',
      };

  String get thinkingScratchpadWaiting => switch (lang) {
        AppLanguage.ko => '문제를 카메라로 비추거나 스캔하면 모델의 심층 생각 과정이 실시간으로 출력됩니다.',
        AppLanguage.en => 'Point camera at or scan a problem to watch real-time thoughts stream here.',
        AppLanguage.ja => '問題をカメラで映すかスキャンすると、モデルの推論プロセスがリアルタイムに表示されます。',
        AppLanguage.zh => '对准或扫描题目后，模型的深度推理过程将在此实时显示。',
      };

  String get btnScanSolve => switch (lang) {
        AppLanguage.ko => '스캔 & 풀이',
        AppLanguage.en => 'Snap & Solve',
        AppLanguage.ja => '撮影＆解答',
        AppLanguage.zh => '拍照解题',
      };

  String get btnAutoScan => switch (lang) {
        AppLanguage.ko => '자동 스캔',
        AppLanguage.en => 'Auto Scan',
        AppLanguage.ja => '自動スキャン',
        AppLanguage.zh => '自动扫描',
      };

  String get tooltipCopy => switch (lang) {
        AppLanguage.ko => '해설 복사',
        AppLanguage.en => 'Copy Solution',
        AppLanguage.ja => '解説をコピー',
        AppLanguage.zh => '复制题解',
      };

  String get copiedSnackBar => switch (lang) {
        AppLanguage.ko => '해설이 클립보드에 복사되었습니다.',
        AppLanguage.en => 'Solution copied to clipboard.',
        AppLanguage.ja => '解説がクリップボードにコピーされました。',
        AppLanguage.zh => '题解已复制到剪贴板。',
      };

  String get cancel => switch (lang) {
        AppLanguage.ko => '취소',
        AppLanguage.en => 'Cancel',
        AppLanguage.ja => 'キャンセル',
        AppLanguage.zh => '取消',
      };

  String get delete => switch (lang) {
        AppLanguage.ko => '삭제',
        AppLanguage.en => 'Delete',
        AppLanguage.ja => '削除',
        AppLanguage.zh => '删除',
      };

  String get clearHistoryTitle => switch (lang) {
        AppLanguage.ko => '풀이 이력 초기화',
        AppLanguage.en => 'Clear Solution History',
        AppLanguage.ja => '履歴の初期化',
        AppLanguage.zh => '清空题解记录',
      };

  String get clearHistoryConfirm => switch (lang) {
        AppLanguage.ko => '저장된 모든 시험 문제 풀이 이력과 오답 노트를 삭제하시겠습니까?\n삭제 후에는 복구할 수 없습니다.',
        AppLanguage.en => 'Delete all saved exam solution records and review notes?\nThis action cannot be undone.',
        AppLanguage.ja => '保存されているすべての問題解説履歴と復習ノートを削除しますか？\n削除後は復元できません。',
        AppLanguage.zh => '确定删除所有保存的题解记录与错题本吗？\n删除后将无法恢复。',
      };

  String get clearHistorySuccess => switch (lang) {
        AppLanguage.ko => '풀이 이력이 초기화되었습니다.',
        AppLanguage.en => 'Solution history has been cleared.',
        AppLanguage.ja => '履歴が初期化されました。',
        AppLanguage.zh => '题解记录已清空。',
      };

  String get systemInstructionTitle => switch (lang) {
        AppLanguage.ko => 'System Instruction 설정',
        AppLanguage.en => 'System Instruction Settings',
        AppLanguage.ja => 'System Instruction 設定',
        AppLanguage.zh => 'System Instruction 配置',
      };

  String get systemInstructionDesc => switch (lang) {
        AppLanguage.ko =>
          'Gemini 3.8 Live Extended Thinking 모델에 전달되는 시스템 프롬프트(영어)입니다.\n만능 시험 튜터 페르소나, 출력 마크다운 구조, 수식 및 코드 서식을 직접 자유롭게 수정할 수 있습니다.',
        AppLanguage.en =>
          'System prompt (English) sent to Gemini 3.8 Live Extended Thinking.\nYou can customize the omniscient exam tutor persona, markdown structure, and formatting rules freely.',
        AppLanguage.ja =>
          'Gemini 3.8 Live Extended Thinkingモデルに送信されるシステムプロンプト（英語）です。\n万能受験チューターペルソナ、マークダウン構成、数式・コード記法ルールを自由に編集できます。',
        AppLanguage.zh =>
          '发送给Gemini 3.8 Live Extended Thinking模型的系统提示词（英语）。\n可自由定制全能家教人设、Markdown排版结构及公式代码规则。',
      };

  String get btnHideSheet => switch (lang) {
        AppLanguage.ko => '노트 접기/숨기기',
        AppLanguage.en => 'Hide Sheet',
        AppLanguage.ja => 'ノートを隠す',
        AppLanguage.zh => '收起笔记',
      };

  String get btnShowSheet => switch (lang) {
        AppLanguage.ko => '📝 풀이 노트 보기',
        AppLanguage.en => '📝 View Solution Notes',
        AppLanguage.ja => '📝 解答ノートを表示',
        AppLanguage.zh => '📝 查看题解笔记',
      };

  String get snapScanningSnackBar => switch (lang) {
        AppLanguage.ko => '📸 문제를 스캔하여 Extended Thinking으로 정밀 분석 중...',
        AppLanguage.en => '📸 Problem scanned! Analyzing with Extended Thinking...',
        AppLanguage.ja => '📸 問題をスキャンしました。Extended Thinkingで精密分析中...',
        AppLanguage.zh => '📸 题目已扫描！正在通过Extended Thinking深入分析...',
      };

  String get gallerySendingSnackBar => switch (lang) {
        AppLanguage.ko => '🖼️ 갤러리 사진을 전송했습니다. Extended Thinking으로 풀이 중...',
        AppLanguage.en => '🖼️ Photo sent from gallery. Solving with Extended Thinking...',
        AppLanguage.ja => '🖼️ ギャラリー写真を送信しました。Extended Thinkingで解答中...',
        AppLanguage.zh => '🖼️ 已发送相册图片。正在通过Extended Thinking解题...',
      };

  String get snapSolvePrompt => switch (lang) {
        AppLanguage.ko =>
          '방금 촬영하거나 제시한 시험 문제(지문, 도표, 사료, 소스코드 포함)를 정밀하게 분석해줘. 반드시 최종 정답(객관식 번호 또는 최종 답안 값)을 가장 먼저 명확하게 밝힌 후, 출제 의도, 핵심 개념 및 접근 전략, 단계별 상세 해설을 체계적으로 설명해줘.',
        AppLanguage.en =>
          'Please thoroughly analyze the exam question (including passages, charts, historical sources, and code) shown. You MUST state the definitive final answer (choice number or final value) first, followed by subject level, examiner intent, key concepts & strategy, and step-by-step solution.',
        AppLanguage.ja =>
          '提示された写真の試験問題（本文・資料・図表・コード含む）を精密に分析してください。必ず最終的な正解（選択肢番号または最終解答値）を一番最初に明確に述べてから、教科・科目レベル、出題者の意図、核心概念と解法戦略、段階別の詳細解説を論理的・体系的に説明してください。',
        AppLanguage.zh =>
          '请仔细分析刚刚拍照展示的照片中的考试题目（包含材料、图表、史料或代码）。必须首先明确给出最终正解（选择题选项编号或最终结果数值），随后系统地提供科目与难度、命题人意图、核心考点与解题策略以及分步详细解析。',
      };
}

/// Fullscreen real-time Multimodal Math Tutor powered by
/// Gemini 3.8 Live Extended Thinking (`gemini-3.8-live-extended-thinking`).
class LiveMathTutorPage extends StatefulWidget {
  const LiveMathTutorPage({super.key});

  @override
  State<LiveMathTutorPage> createState() => _LiveMathTutorPageState();
}

class _LiveMathTutorPageState extends State<LiveMathTutorPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const _cameraFrameInterval = Duration(milliseconds: 1600);
  static const _audioSampleRate = 16000;
  static const _audioMimeType = 'audio/pcm;rate=16000';

  final SoloudLiveAudioPlayer _audioPlayer = SoloudLiveAudioPlayer();
  final LiveAudioPlayer _fallbackAudioPlayer = LiveAudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _useFallbackAudio = kIsWeb;

  LiveSession? _session;
  CameraController? _cameraController;
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  Timer? _cameraFrameTimer;

  final List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isAutoScanEnabled = true;
  bool _isCameraExpanded = false;
  bool _isCameraInitializing = false;
  bool _isBottomSheetVisible = true;
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  bool _captureInFlight = false;
  bool _isMicMuted = false;
  bool _isFlashOn = false;
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _lastProblemImage;

  MathCurriculumLevel _curriculumLevel = MathCurriculumLevel.auto;
  int _activeTabIndex = 0; // 0: 풀이 노트, 1: AI 심층 생각 과정

  // Performance-optimized reactive value notifiers (zero full-tree rebuilds during streaming)
  final StringBuffer _currentTurnSolutionBuffer = StringBuffer();
  final StringBuffer _currentTurnThoughtsBuffer = StringBuffer();
  final ValueNotifier<String> _liveSubtitleNotifier = ValueNotifier('');
  final ValueNotifier<String> _liveSolutionNotifier = ValueNotifier('');
  final ValueNotifier<String> _liveThoughtsNotifier = ValueNotifier('');
  final ValueNotifier<InteractionStatus> _interactionStatusNotifier =
      ValueNotifier(InteractionStatus.IDLE);
  final ValueNotifier<int> _thoughtsTokenNotifier = ValueNotifier(0);

  Timer? _solutionStreamThrottleTimer;
  Timer? _thoughtsStreamThrottleTimer;
  Timer? _interruptionNoticeTimer;

  // Stored solutions list
  final List<MathSolutionRecord> _solutionHistory = [];
  final ScrollController _solutionScrollController = ScrollController();
  final ScrollController _thoughtsScrollController = ScrollController();

  // Token & thinking statistics tracker
  final GeminiTokenUsageTracker _usageTracker = GeminiTokenUsageTracker(
    model: LiveModels.gemini38LiveExtendedThinking,
  );
  int _latestThoughtsTokens = 0;

  late final AnimationController _pulseAnimController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initAudioAndSession();
  }

  Future<void> _initAudioAndSession() async {
    if (!kIsWeb) {
      try {
        await _audioPlayer.init();
      } catch (e) {
        debugPrint('SoLoud init error, fallback to audioplayers: $e');
        _useFallbackAudio = true;
      }
    } else {
      _useFallbackAudio = true;
    }

    await _loadHistory();
    await _loadCameras();
    await _startMicStream();
    await _connectSession();
  }

  static const _historyPrefKey = 'gemini_live_math_tutor_history';
  static const _systemInstructionPrefKey = 'gemini_live_math_tutor_system_instruction';
  String _customSystemInstruction = defaultMathTutorSystemInstruction;

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSi = prefs.getString(_systemInstructionPrefKey);
      if (savedSi != null && savedSi.trim().isNotEmpty) {
        _customSystemInstruction = savedSi;
      }
      final raw = prefs.getString(_historyPrefKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        final loaded = list
            .map((e) => MathSolutionRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _solutionHistory
              ..clear()
              ..addAll(loaded);
          });
        }
      }
    } catch (e) {
      debugPrint('Load math history error: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep up to 50 latest records to optimize storage
      final toSave = _solutionHistory.take(50).map((r) => r.toJson()).toList();
      await prefs.setString(_historyPrefKey, jsonEncode(toSave));
    } catch (e) {
      debugPrint('Save math history error: $e');
    }
  }

  void _showSafeSnackBar(
    String message, {
    IconData? icon,
    Color? iconColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? Colors.amberAccent, size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearHistory() async {
    final lang = AppLanguageController.instance.currentLanguage;
    final i18n = _MathTutorI18n(lang);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(i18n.clearHistoryTitle, style: const TextStyle(color: Colors.white)),
        content: Text(
          i18n.clearHistoryConfirm,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(i18n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(i18n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _solutionHistory.clear();
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyPrefKey);
      if (mounted) {
        _showSafeSnackBar(
          i18n.clearHistorySuccess,
          icon: Icons.check_circle_rounded,
          iconColor: Colors.greenAccent,
        );
      }
    }
  }

  Future<void> _showSystemInstructionDialog() async {
    final lang = AppLanguageController.instance.currentLanguage;
    final i18n = _MathTutorI18n(lang);
    final textController = TextEditingController(text: _customSystemInstruction);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            const Icon(Icons.tune_rounded, color: Colors.amberAccent, size: 22),
            const SizedBox(width: 8),
            Text(
              i18n.systemInstructionTitle,
              style: const TextStyle(color: Colors.white, fontSize: 17),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i18n.systemInstructionDesc,
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: TextField(
                    controller: textController,
                    maxLines: 15,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                      hintText: 'System instruction text in English...',
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              textController.text = defaultMathTutorSystemInstruction;
            },
            child: const Text('기본값 복원', style: TextStyle(color: Colors.amberAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.white60)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.amber.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('저장 및 적용'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      final newText = textController.text.trim();
      if (newText.isNotEmpty) {
        setState(() {
          _customSystemInstruction = newText;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_systemInstructionPrefKey, newText);

        if (!mounted) return;
        if (_isConnected) {
          _showSafeSnackBar(
            '새 System Instruction을 적용하여 세션을 재연결합니다...',
            icon: Icons.sync_rounded,
          );
          _session?.close();
          await _connectSession();
        } else {
          _showSafeSnackBar(
            'System Instruction이 저장되었습니다.',
            icon: Icons.check_circle_rounded,
            iconColor: Colors.greenAccent,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraFrameTimer?.cancel();
    _solutionStreamThrottleTimer?.cancel();
    _thoughtsStreamThrottleTimer?.cancel();
    _interruptionNoticeTimer?.cancel();
    _audioStreamSubscription?.cancel();
    _pulseAnimController.dispose();
    _liveSubtitleNotifier.dispose();
    _liveSolutionNotifier.dispose();
    _liveThoughtsNotifier.dispose();
    _interactionStatusNotifier.dispose();
    _thoughtsTokenNotifier.dispose();
    _solutionScrollController.dispose();
    _thoughtsScrollController.dispose();
    _sheetController.dispose();
    unawaited(_audioRecorder.stop());
    unawaited(_audioRecorder.dispose());
    unawaited(_cameraController?.dispose() ?? Future<void>.value());
    _session?.close();
    unawaited(_audioPlayer.dispose());
    unawaited(_fallbackAudioPlayer.dispose());
    _usageTracker.dispose();
    super.dispose();
  }

  // --- Camera Management ---

  Future<void> _loadCameras() async {
    setState(() => _isCameraInitializing = true);
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      _availableCameras
        ..clear()
        ..addAll(cameras);

      if (_availableCameras.isNotEmpty) {
        // Prefer back camera for scanning documents
        final backCamIdx = _availableCameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        _selectedCameraIndex = backCamIdx >= 0 ? backCamIdx : 0;
        await _initCameraController(_availableCameras[_selectedCameraIndex]);
      }
    } catch (e) {
      debugPrint('Failed to load cameras: $e');
    } finally {
      if (mounted) setState(() => _isCameraInitializing = false);
    }
  }

  Future<void> _initCameraController(CameraDescription desc) async {
    final prev = _cameraController;
    if (prev != null) {
      await prev.dispose();
    }

    final controller = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _isFlashOn = false;
      });
      if (_isAutoScanEnabled && _isConnected) {
        _startCameraFrameLoop();
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _toggleCamera() async {
    if (_availableCameras.length < 2) return;
    _cameraFrameTimer?.cancel();
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    await _initCameraController(_availableCameras[_selectedCameraIndex]);
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final next = !_isFlashOn;
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _isFlashOn = next);
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  // --- Gemini Live Session with Extended Thinking ---

  Future<void> _connectSession({String? specificModel}) async {
    if (_isConnecting) return;
    if (!ApiKeyStore.hasApiKey) {
      final configured = await AppSettingsDialog.show(context);
      if (configured != true || !ApiKeyStore.hasApiKey) {
        if (mounted) {
          _showSafeSnackBar(
            'Gemini API 키가 설정되지 않았습니다.',
            icon: Icons.key_off_rounded,
            iconColor: Colors.amberAccent,
          );
        }
        return;
      }
    }

    setState(() => _isConnecting = true);

    // Prefer specificModel, or user-selected ApiKeyStore.liveModel, or default to extended thinking
    final targetModel = specificModel ??
        (ApiKeyStore.liveModel.isNotEmpty
            ? ApiKeyStore.liveModel
            : LiveModels.gemini38LiveExtendedThinking);

    try {
      final genAI = GoogleGenAI(
        apiKey: ApiKeyStore.apiKey,
        logger: (msg) => debugPrint('[GeminiLiveWS] $msg'),
      );

      final currentLang = AppLanguageController.instance.currentLanguage;
      final languageInstruction = switch (currentLang) {
        AppLanguage.ko =>
          '\n\n[Active Student Language]: Korean (한국어). Speak and answer strictly in Korean.',
        AppLanguage.en =>
          '\n\n[Active Student Language]: English. Speak and answer strictly in English.',
        AppLanguage.ja =>
          '\n\n[Active Student Language]: Japanese (日本語). Speak and answer strictly in Japanese.',
        AppLanguage.zh =>
          '\n\n[Active Student Language]: Chinese (中文). Speak and answer strictly in Chinese.',
      };

      final curriculumHint = _curriculumLevel != MathCurriculumLevel.auto
          ? '\n\n[Active Curriculum Focus Mode]: ${_curriculumLevel.promptHint}'
          : '\n\n[Active Curriculum Focus Mode]: Automatically detect problem curriculum grade and difficulty from the problem.';

      final systemInstructionText =
          '$_customSystemInstruction$languageInstruction$curriculumHint';

      debugPrint('🔌 Attempting Gemini Live connection with model: $targetModel');

      final session = await genAI.live.connect(
        LiveConnectParameters(
          model: targetModel,
          config: GenerationConfig(
            responseModalities: const [Modality.AUDIO],
            speechConfig: SpeechConfig(
              voiceConfig: VoiceConfig(
                prebuiltVoiceConfig: PrebuiltVoiceConfig(
                  voiceName: ApiKeyStore.voice.isNotEmpty
                      ? ApiKeyStore.voice
                      : 'Charon', // 차분하고 지적인 톤
                ),
              ),
            ),
            // Include thinking config for models that support it
            thinkingConfig: targetModel.contains('thinking')
                ? ThinkingConfig(
                    thinkingLevel: ThinkingLevel.HIGH,
                    includeThoughts: true,
                  )
                : null,
          ),
          systemInstruction: Content(
            parts: [Part(text: systemInstructionText)],
          ),
          inputAudioTranscription: AudioTranscriptionConfig(
            languageCodes: const ['ko-KR', 'en-US', 'ja-JP'],
          ),
          outputAudioTranscription: AudioTranscriptionConfig(),
          realtimeInputConfig: RealtimeInputConfig(
            automaticActivityDetection: AutomaticActivityDetection(
              startOfSpeechSensitivity: StartSensitivity.START_SENSITIVITY_LOW,
              endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
              prefixPaddingMs: 80,
              silenceDurationMs: 800,
            ),
            activityHandling: ActivityHandling.START_OF_ACTIVITY_INTERRUPTS,
          ),
          callbacks: LiveCallbacks(
            onOpen: () {
              if (!mounted) return;
              setState(() {
                _isConnected = true;
                _isConnecting = false;
              });
              debugPrint('✅ Math Tutor Gemini Live Session Connected ($targetModel)!');
              if (_isAutoScanEnabled) {
                _startCameraFrameLoop();
              }
            },
            onMessage: _handleServerMessage,
            onError: (err, st) {
              debugPrint('🔴 Live Session Error ($targetModel): $err\n$st');
              if (!mounted) return;
              setState(() {
                _isConnected = false;
                _isConnecting = false;
              });
              _showSafeSnackBar(
                '수학 과외 세션 오류: $err',
                icon: Icons.error_outline_rounded,
                iconColor: Colors.redAccent,
              );
            },
            onClose: (code, reason) {
              debugPrint('⚪ Live Session Closed ($targetModel): $code / $reason');
              if (!mounted) return;
              setState(() {
                _isConnected = false;
                _isConnecting = false;
              });
            },
          ),
        ),
      );

      _session = session;
    } catch (e) {
      debugPrint('Live session connect failed ($targetModel): $e');
      if (!mounted) return;
      setState(() => _isConnecting = false);

      // Auto-fallback: If extended thinking failed, try standard live model
      if (targetModel != LiveModels.gemini38Live) {
        debugPrint('⚠️ Falling back to stable model ${LiveModels.gemini38Live}...');
        if (mounted) {
          _showSafeSnackBar(
            '안정적인 실시간 모델(${LiveModels.gemini38Live})로 자동 재연결 중...',
            icon: Icons.sync_rounded,
          );
        }
        await _connectSession(specificModel: LiveModels.gemini38Live);
        return;
      }

      if (mounted) {
        _showSafeSnackBar(
          '연결 실패: $e',
          icon: Icons.cloud_off_rounded,
          iconColor: Colors.redAccent,
        );
      }
    }
  }

  void _handleServerMessage(LiveServerMessage message) {
    if (!mounted) return;

    // Track usage and thinking tokens
    final usage = message.usageMetadata;
    if (usage != null) {
      _usageTracker.recordUsage(usage);
      if (usage.thoughtsTokenCount != null) {
        _latestThoughtsTokens = usage.thoughtsTokenCount!;
        _thoughtsTokenNotifier.value = _latestThoughtsTokens;
      }
    }

    final serverContent = message.serverContent;

    // 1. Interaction status tracking (IN_PROGRESS vs IDLE)
    if (serverContent?.interactionStatus != null) {
      final newStatus = serverContent!.interactionStatus!;
      if (newStatus != _interactionStatusNotifier.value) {
        _interactionStatusNotifier.value = newStatus;
      }
    }

    // 2. Interruption / Barge-in handling
    if (serverContent?.interrupted == true) {
      if (_useFallbackAudio) {
        _fallbackAudioPlayer.clear();
      } else {
        _audioPlayer.clear();
      }
      final lang = AppLanguageController.instance.currentLanguage;
      _liveSubtitleNotifier.value = _MathTutorI18n(lang).interruptedNotice;
      // Auto-clear notice after 2.5s so false alarms or quick stops don't stay frozen
      _interruptionNoticeTimer?.cancel();
      _interruptionNoticeTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted && _liveSubtitleNotifier.value == _MathTutorI18n(lang).interruptedNotice) {
          _liveSubtitleNotifier.value = '';
        }
      });
      return;
    }

    // 3. Audio stream playback
    if (message.data != null && message.data!.isNotEmpty) {
      if (_useFallbackAudio) {
        _fallbackAudioPlayer.appendBase64Chunk(message.data!);
      } else {
        _audioPlayer.appendBase64Chunk(message.data!);
      }
    }

    // 4. Extract thoughts vs spoken answer from modelTurn parts
    final parts = serverContent?.modelTurn?.parts;
    if (parts != null && parts.isNotEmpty) {
      for (final part in parts) {
        final text = part.text;
        if (text == null || text.isEmpty) continue;

        if (part.thought == true) {
          // Internal Extended Thinking scratchpad
          _currentTurnThoughtsBuffer.write(text);
          _notifyThoughtsStream();
          _scrollToBottom(_thoughtsScrollController);
        } else {
          // Visible Solution explanation text
          _currentTurnSolutionBuffer.write(text);
          _liveSubtitleNotifier.value = text.trim();
          _notifySolutionStream();
          _scrollToBottom(_solutionScrollController);
        }
      }
    }

    // 5. Turn Complete: commit the solution card to history
    final isTurnComplete = (serverContent?.turnComplete ?? false) ||
        (serverContent?.generationComplete ?? false);

    if (isTurnComplete) {
      if (_useFallbackAudio && _fallbackAudioPlayer.hasBufferedAudio) {
        unawaited(_fallbackAudioPlayer.playBufferedAudio());
      } else if (!_useFallbackAudio) {
        _audioPlayer.onTurnComplete();
      }

      // Flush any throttled buffers immediately
      _solutionStreamThrottleTimer?.cancel();
      _thoughtsStreamThrottleTimer?.cancel();
      _liveSolutionNotifier.value = _currentTurnSolutionBuffer.toString().trim();
      _liveThoughtsNotifier.value = _currentTurnThoughtsBuffer.toString();

      _commitCurrentTurnToRecord();
    }
  }

  void _notifySolutionStream() {
    if (_solutionStreamThrottleTimer?.isActive ?? false) return;
    _solutionStreamThrottleTimer = Timer(const Duration(milliseconds: 80), () {
      if (mounted) {
        _liveSolutionNotifier.value = _currentTurnSolutionBuffer.toString().trim();
      }
    });
  }

  void _notifyThoughtsStream() {
    if (_thoughtsStreamThrottleTimer?.isActive ?? false) return;
    _thoughtsStreamThrottleTimer = Timer(const Duration(milliseconds: 80), () {
      if (mounted) {
        _liveThoughtsNotifier.value = _currentTurnThoughtsBuffer.toString();
      }
    });
  }

  void _scrollToBottom(ScrollController controller) {
    if (!controller.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _commitCurrentTurnToRecord() {
    final solution = _currentTurnSolutionBuffer.toString().trim();
    final thoughts = _currentTurnThoughtsBuffer.toString().trim();

    if (solution.isEmpty && thoughts.isEmpty) return;

    // Extract problem level if present (supports Korean & English headers, with or without emojis)
    String problemLevel = '';
    final levelMatch = RegExp(
      r'###\s*(?:📊\s*)?\[?(?:(?:과목\s*(?:및|&)\s*)?문제\s*수준|Subject(?:\s*(?:및|&)\s*Problem)?\s*Level|교과목|Subject)(?:\s*(?:및|&)\s*(?:난이도|Difficulty))?\]?\s*\n+([^#]+)',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(solution);
    if (levelMatch != null && levelMatch.groupCount >= 1) {
      problemLevel = levelMatch.group(1)?.trim() ?? '';
    }

    // Extract examiner intent if present
    String examinerIntent = '';
    final intentMatch = RegExp(
      r'###\s*(?:🎯\s*)?\[?(?:출제자의?\s*의도(?:\s*(?:및|&)\s*평가\s*요소)?|Examiner(?:\x27s)?\s*Intent(?:\s*&\s*Assessment\s*Objective)?)\]?\s*\n+([^#]+)',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(solution);
    if (intentMatch != null && intentMatch.groupCount >= 1) {
      examinerIntent = intentMatch.group(1)?.trim() ?? '';
    }

    // Extract final answer if present (e.g. "정답: ...", "Answer: ...")
    String finalAnswer = '';
    final answerMatch = RegExp(
      r'(?:정답|Answer)\s*:\s*([^\n\r]+)',
      caseSensitive: false,
    ).firstMatch(solution);
    if (answerMatch != null && answerMatch.groupCount >= 1) {
      finalAnswer = answerMatch
              .group(1)
              ?.replaceAll('*', '')
              .replaceAll('>', '')
              .trim() ??
          '';
    } else {
      // Fallback: look for 🏁 or 🎯 block
      final blockMatch = RegExp(
        r'[🏁🎯]\s*\[?(?:최종\s*정답|Final\s*Answer)\]?[^\n]*\n+>?\s*([^\n\r]+)',
        caseSensitive: false,
      ).firstMatch(solution);
      if (blockMatch != null && blockMatch.groupCount >= 1) {
        finalAnswer = blockMatch
                .group(1)
                ?.replaceAll('*', '')
                .replaceAll('>', '')
                .trim() ??
            '';
      }
    }

    final record = MathSolutionRecord(
      id: 'exam_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      level: _curriculumLevel,
      problemSummary: _extractSummary(solution),
      problemLevel: problemLevel,
      examinerIntent: examinerIntent,
      solutionMarkdown: solution,
      finalAnswer: finalAnswer,
      thinkingLog: thoughts,
      capturedImage: _lastProblemImage,
    );

    setState(() {
      _solutionHistory.insert(0, record);
      _currentTurnSolutionBuffer.clear();
      _currentTurnThoughtsBuffer.clear();
      _lastProblemImage = null;
    });
    _liveSolutionNotifier.value = '';
    _liveThoughtsNotifier.value = '';
    _liveSubtitleNotifier.value = '';

    unawaited(_saveHistory());
  }

  String _extractSummary(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    for (final line in lines) {
      if (!line.startsWith('#') && !line.startsWith('>')) {
        return line.trim().length > 60
            ? '${line.trim().substring(0, 60)}...'
            : line.trim();
      }
    }
    return '시험 문제 풀이 및 심층 해설';
  }

  // --- Real-time Video Streaming, Gallery Picker & Snap & Solve ---

  void _startCameraFrameLoop() {
    _cameraFrameTimer?.cancel();
    if (!_isAutoScanEnabled) return;

    unawaited(_captureAndSendFrame());
    _cameraFrameTimer = Timer.periodic(_cameraFrameInterval, (_) {
      unawaited(_captureAndSendFrame());
    });
  }

  Future<void> _captureAndSendFrame({bool isManualSnap = false}) async {
    final controller = _cameraController;
    if (_captureInFlight ||
        controller == null ||
        !controller.value.isInitialized ||
        _session == null ||
        !_isConnected) {
      return;
    }

    _captureInFlight = true;
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();

      // Compress and resize for real-time Live streaming
      Uint8List sendBytes = bytes;
      try {
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final resized = img.copyResize(decoded, width: 1024);
          sendBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 80));
        }
      } catch (e) {
        debugPrint('Image compression error: $e');
      }

      if (isManualSnap) {
        _lastProblemImage = sendBytes;
      }

      final blob = Blob(mimeType: 'image/jpeg', data: base64Encode(sendBytes));
      _session!.sendRealtimeInput(video: blob);

      if (isManualSnap) {
        final lang = AppLanguageController.instance.currentLanguage;
        final i18n = _MathTutorI18n(lang);

        // Send problem image directly inside client content turn alongside prompt
        // to guarantee that the model receives and analyzes the exact problem image atomically.
        _session!.sendClientContent(
          turns: [
            Content(
              role: 'user',
              parts: [
                Part(inlineData: blob),
                Part(text: i18n.snapSolvePrompt),
              ],
            ),
          ],
          turnComplete: true,
        );

        if (mounted) {
          setState(() {
            _isBottomSheetVisible = true;
          });
          HapticFeedback.mediumImpact();
          _showSafeSnackBar(
            i18n.snapScanningSnackBar,
            icon: Icons.camera_alt_rounded,
          );
        }
      }
    } catch (e) {
      debugPrint('Send camera frame error: $e');
    } finally {
      _captureInFlight = false;
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_session == null || !_isConnected) {
      _showSafeSnackBar(
        '세션이 연결되지 않았습니다. 잠시 후 다시 시도해 주세요.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      Uint8List sendBytes = bytes;
      try {
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final resized = img.copyResize(decoded, width: 1024);
          sendBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 80));
        }
      } catch (e) {
        debugPrint('Gallery image compression error: $e');
      }

      _lastProblemImage = sendBytes;

      final blob = Blob(mimeType: 'image/jpeg', data: base64Encode(sendBytes));
      _session!.sendRealtimeInput(video: blob);

      // Prompt model to immediately inspect and solve the attached image
      final lang = AppLanguageController.instance.currentLanguage;
      final i18n = _MathTutorI18n(lang);

      _session!.sendClientContent(
        turns: [
          Content(
            role: 'user',
            parts: [
              Part(inlineData: blob),
              Part(text: i18n.snapSolvePrompt),
            ],
          ),
        ],
        turnComplete: true,
      );

      if (mounted) {
        setState(() {
          _isBottomSheetVisible = true;
        });
        HapticFeedback.mediumImpact();
        _showSafeSnackBar(
          i18n.gallerySendingSnackBar,
          icon: Icons.photo_library_rounded,
        );
      }
    } catch (e) {
      debugPrint('Pick image error: $e');
    }
  }

  // --- Audio Microphone Stream ---

  Future<void> _startMicStream() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        debugPrint('Microphone permission denied');
        return;
      }

      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _audioSampleRate,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );

      _audioStreamSubscription = stream.listen((chunk) {
        if (_isMicMuted || _session == null || !_isConnected) return;

        // Client-side noise gate:
        // Calculate RMS amplitude to avoid sending silent room hiss and device speaker bleed
        final rms = GeminiLiveAudioUtils.calculateRms(chunk);

        // When tutor is actively speaking/explaining, require higher vocal threshold (0.025)
        // to prevent phone speaker audio from falsely interrupting the explanation.
        // When tutor is idle/listening, allow normal speech (0.008).
        final isTutorSpeaking =
            _interactionStatusNotifier.value == InteractionStatus.IN_PROGRESS;
        final gateThreshold = isTutorSpeaking ? 0.025 : 0.008;

        if (rms < gateThreshold) {
          // Drop silent/ambient noise packet
          return;
        }

        final blob = Blob(mimeType: _audioMimeType, data: base64Encode(chunk));
        _session!.sendRealtimeInput(audio: blob);
      });
    } catch (e) {
      debugPrint('Mic stream start error: $e');
    }
  }

  void _toggleMic() {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
  }

  Future<void> _switchCurriculum(MathCurriculumLevel level) async {
    if (_curriculumLevel == level) return;
    setState(() => _curriculumLevel = level);

    // Prompt context update via sendClientContent
    if (_session != null && _isConnected) {
      try {
        _session!.sendClientContent(
          turns: [
            Content(
              role: 'user',
              parts: [
                Part(
                  text: '[Student Notice]: Curriculum focus preference updated to "${level.labelKo}". '
                      '${level.promptHint}',
                ),
              ],
            ),
          ],
          turnComplete: true,
        );
      } catch (e) {
        debugPrint('Failed to update curriculum level: $e');
      }
    }
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageController.instance.t;
    final lang = AppLanguageController.instance.currentLanguage;
    final isWide = MediaQuery.of(context).size.width >= 840;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(t, lang),
      body: SafeArea(
        child: Column(
          children: [
            _buildCurriculumSelectorBar(lang),
            Expanded(
              child: isWide
                  ? Row(
                      children: [
                        Expanded(
                          flex: _isCameraExpanded ? 7 : 5,
                          child: _buildCameraPane(),
                        ),
                        const VerticalDivider(width: 1, color: Colors.white12),
                        Expanded(
                          flex: _isCameraExpanded ? 3 : 5,
                          child: _buildSolutionBoardPane(),
                        ),
                      ],
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            // Full-bleed camera pane with dynamic bottom padding based on sheet visibility
                            Positioned.fill(
                              child: _buildCameraPane(
                                bottomPadding: _isBottomSheetVisible
                                    ? (constraints.maxHeight * 0.16).clamp(70.0, 110.0)
                                    : 24.0,
                              ),
                            ),

                            // Height-adjustable Modal / Draggable Bottom Sheet for Solutions & Thinking Scratchpad
                            if (_isBottomSheetVisible)
                              DraggableScrollableSheet(
                                controller: _sheetController,
                                initialChildSize: 0.32,
                                minChildSize: 0.14,
                                maxChildSize: 0.90,
                                snap: true,
                                snapSizes: const [0.14, 0.32, 0.90],
                                builder: (context, sheetScrollController) {
                                  return Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0F172A),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black54,
                                          blurRadius: 16,
                                          spreadRadius: 4,
                                          offset: Offset(0, -2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      child: _buildSolutionBoardPane(
                                        scrollController: sheetScrollController,
                                        showDragHandle: true,
                                        onCloseSheet: () {
                                          setState(() => _isBottomSheetVisible = false);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),

                            // Floating Reopen Button when bottom sheet is hidden
                            if (!_isBottomSheetVisible)
                              Positioned(
                                left: 16,
                                bottom: 84,
                                child: SafeArea(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() => _isBottomSheetVisible = true);
                                      },
                                      borderRadius: BorderRadius.circular(24),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B).withValues(alpha: 0.92),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                            color: Colors.amberAccent.withValues(alpha: 0.7),
                                            width: 1.2,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black54,
                                              blurRadius: 10,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.assignment_rounded,
                                              size: 16,
                                              color: Colors.amberAccent,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _MathTutorI18n(lang).btnShowSheet,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (_solutionHistory.isNotEmpty) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 1,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.amberAccent,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '${_solutionHistory.length}',
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppTranslations t, AppLanguage lang) {
    final i18n = _MathTutorI18n(lang);
    return AppBar(
      backgroundColor: const Color(0xFF1E293B),
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i18n.appTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  i18n.modelSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.amber.shade200),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Extended Thinking status indicator
        _buildThinkingStatusPill(i18n),
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: i18n.systemInstructionTitle,
          onPressed: _showSystemInstructionDialog,
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: t.settingsTooltip,
          onPressed: () async {
            final changed = await AppSettingsDialog.show(context);
            if (changed == true && mounted) {
              await _connectSession();
            }
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildThinkingStatusPill(_MathTutorI18n i18n) {
    return ValueListenableBuilder<InteractionStatus>(
      valueListenable: _interactionStatusNotifier,
      builder: (context, status, _) {
        final isThinking = status == InteractionStatus.IN_PROGRESS;

        return ValueListenableBuilder<int>(
          valueListenable: _thoughtsTokenNotifier,
          builder: (context, tokenCount, _) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isThinking
                    ? Colors.amber.shade900.withValues(alpha: 0.8)
                    : const Color(0xFF334155),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isThinking ? Colors.amberAccent : Colors.white24,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isThinking)
                    FadeTransition(
                      opacity: _pulseAnimController,
                      child: const Icon(Icons.psychology_rounded,
                          size: 15, color: Colors.amberAccent),
                    )
                  else
                    const Icon(Icons.check_circle_outline,
                        size: 14, color: Colors.greenAccent),
                  const SizedBox(width: 5),
                  Text(
                    isThinking ? i18n.statusThinking : i18n.statusIdle,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isThinking ? Colors.amberAccent : Colors.white70,
                    ),
                  ),
                  if (tokenCount > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '($tokenCount tok)',
                      style: const TextStyle(fontSize: 10, color: Colors.white60),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCurriculumSelectorBar(AppLanguage lang) {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: MathCurriculumLevel.values.map((lvl) {
            final isSelected = _curriculumLevel == lvl;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                showCheckmark: false,
                avatar: Icon(
                  lvl.badgeIcon,
                  size: 16,
                  color: isSelected ? Colors.black : Colors.amberAccent,
                ),
                label: Text(
                  lvl.label(lang),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                ),
                selected: isSelected,
                selectedColor: Colors.amberAccent,
                backgroundColor: const Color(0xFF334155),
                onSelected: (_) => _switchCurriculum(lvl),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCameraPane({double bottomPadding = 0}) {
    final lang = AppLanguageController.instance.currentLanguage;
    final i18n = _MathTutorI18n(lang);
    final controller = _cameraController;
    final isInitialized = controller != null && controller.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (isInitialized)
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize?.height ?? 1,
                height: controller.value.previewSize?.width ?? 1,
                child: CameraPreview(controller),
              ),
            ),
          )
        else
          Container(
            color: Colors.black,
            child: Center(
              child: _isCameraInitializing
                  ? const CircularProgressIndicator()
                  : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam_off_rounded, size: 48, color: Colors.white24),
                        SizedBox(height: 12),
                        Text('카메라를 불러오는 중입니다...',
                            style: TextStyle(color: Colors.white54)),
                      ],
                    ),
            ),
          ),

        // Math Document Target Box Overlay (문제 스캔 가이드 영역)
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boxWidth = (constraints.maxWidth * 0.88).clamp(240.0, 480.0);
              final boxHeight = (constraints.maxHeight * 0.65).clamp(160.0, 380.0);

              return ValueListenableBuilder<InteractionStatus>(
                valueListenable: _interactionStatusNotifier,
                builder: (context, status, _) {
                  final isThinking = status == InteractionStatus.IN_PROGRESS;
                  return Container(
                    width: boxWidth,
                    height: boxHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isThinking
                            ? Colors.amberAccent
                            : Colors.white.withValues(alpha: 0.6),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              i18n.cameraGuide,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                            ),
                          ),
                        ),
                        if (isThinking)
                          LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            color: Colors.amberAccent.withValues(alpha: 0.8),
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Spoken subtitle floating bar (Reactive ValueListenableBuilder)
        ValueListenableBuilder<String>(
          valueListenable: _liveSubtitleNotifier,
          builder: (context, subtitle, _) {
            if (subtitle.isEmpty) return const SizedBox.shrink();
            return Positioned(
              left: 12,
              right: 12,
              bottom: bottomPadding + 64,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xCC0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up_rounded,
                        color: Colors.amberAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Camera Bottom HUD Controls
        Positioned(
          left: 8,
          right: 8,
          bottom: bottomPadding + 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Flash toggle
                  IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _isFlashOn ? Colors.amberAccent : Colors.white70,
                    ),
                    tooltip: 'Flash',
                    onPressed: _toggleFlash,
                  ),
                  const SizedBox(width: 4),

                  // Gallery Image Picker Button
                  IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.photo_library_rounded, color: Colors.amberAccent),
                    tooltip: 'Gallery',
                    onPressed: _pickAndSendImage,
                  ),
                  const SizedBox(width: 4),

                  // Manual Snap & Solve Shutter
                  ElevatedButton.icon(
                    onPressed: () => _captureAndSendFrame(isManualSnap: true),
                    icon: const Icon(Icons.camera_alt_rounded, size: 16),
                    label: Text(
                      '📸 ${i18n.btnScanSolve}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Auto stream toggle
                  IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isAutoScanEnabled
                          ? Icons.motion_photos_on_rounded
                          : Icons.motion_photos_off_rounded,
                      color: _isAutoScanEnabled ? Colors.greenAccent : Colors.white38,
                    ),
                    tooltip: i18n.btnAutoScan,
                    onPressed: () {
                      setState(() {
                        _isAutoScanEnabled = !_isAutoScanEnabled;
                      });
                      if (_isAutoScanEnabled) {
                        _startCameraFrameLoop();
                      } else {
                        _cameraFrameTimer?.cancel();
                      }
                    },
                  ),
                  const SizedBox(width: 4),

                  // Mic toggle
                  IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      color: _isMicMuted ? Colors.redAccent : Colors.white70,
                    ),
                    tooltip: 'Microphone',
                    onPressed: _toggleMic,
                  ),
                  const SizedBox(width: 4),

                  // Switch Camera
                  IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white70),
                    tooltip: 'Switch Camera',
                    onPressed: _toggleCamera,
                  ),
                  const SizedBox(width: 4),

                  // Camera Size Toggle (확대/원래대로)
                  IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isCameraExpanded
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                      color: _isCameraExpanded ? Colors.amberAccent : Colors.white70,
                    ),
                    tooltip: _isCameraExpanded ? '축소' : '카메라 확대',
                    onPressed: () {
                      setState(() {
                        _isCameraExpanded = !_isCameraExpanded;
                      });
                    },
                  ),
                  const SizedBox(width: 4),

                  // Bottom sheet toggle (풀이 노트 보기/숨기기)
                  IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isBottomSheetVisible
                          ? Icons.vertical_align_bottom_rounded
                          : Icons.vertical_align_top_rounded,
                      color: _isBottomSheetVisible ? Colors.amberAccent : Colors.white70,
                    ),
                    tooltip: _isBottomSheetVisible ? '노트 접기/숨기기' : '풀이 노트 열기',
                    onPressed: () {
                      setState(() {
                        _isBottomSheetVisible = !_isBottomSheetVisible;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSolutionBoardPane({
    ScrollController? scrollController,
    bool showDragHandle = false,
    VoidCallback? onCloseSheet,
  }) {
    final lang = AppLanguageController.instance.currentLanguage;
    final i18n = _MathTutorI18n(lang);

    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // Drag handle for bottom sheet mode
          if (showDragHandle)
            Container(
              width: double.infinity,
              color: const Color(0xFF1E293B),
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

          // Tab Header (해설 노트 vs AI 심층 생각 노트)
          Container(
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeTabIndex == 0
                                ? Colors.amberAccent
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_rounded,
                            size: 15,
                            color: _activeTabIndex == 0
                                ? Colors.amberAccent
                                : Colors.white54,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${i18n.tabSolutions} (${_solutionHistory.length})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _activeTabIndex == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _activeTabIndex == 0
                                    ? Colors.amberAccent
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTabIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeTabIndex == 1
                                ? Colors.cyanAccent
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.psychology_rounded,
                            size: 15,
                            color: _activeTabIndex == 1
                                ? Colors.cyanAccent
                                : Colors.white54,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              i18n.tabThinking,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _activeTabIndex == 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _activeTabIndex == 1
                                    ? Colors.cyanAccent
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_solutionHistory.isNotEmpty)
                  IconButton(
                    iconSize: 18,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete_sweep_rounded,
                        color: Colors.white54),
                    tooltip: i18n.clearHistoryTitle,
                    onPressed: _clearHistory,
                  ),
                if (onCloseSheet != null)
                  IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70),
                    tooltip: i18n.btnHideSheet,
                    onPressed: onCloseSheet,
                  ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: _activeTabIndex == 0
                ? _buildSolutionsListTab(scrollController: scrollController)
                : _buildThinkingScratchpadTab(scrollController: scrollController),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionsListTab({ScrollController? scrollController}) {
    final lang = AppLanguageController.instance.currentLanguage;
    final i18n = _MathTutorI18n(lang);

    return ValueListenableBuilder<String>(
      valueListenable: _liveSolutionNotifier,
      builder: (context, liveSolutionText, _) {
        final hasLiveSolution = liveSolutionText.isNotEmpty;
        final hasHistory = _solutionHistory.isNotEmpty;

        if (!hasLiveSolution && !hasHistory) {
          return SingleChildScrollView(
            controller: scrollController ?? _solutionScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    i18n.emptyTitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    i18n.emptyDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final totalCount = (hasLiveSolution ? 1 : 0) + _solutionHistory.length;

        return ListView.builder(
          controller: scrollController ?? _solutionScrollController,
          padding: const EdgeInsets.all(12),
          itemCount: totalCount,
          itemBuilder: (context, index) {
            if (hasLiveSolution && index == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amberAccent, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FadeTransition(
                          opacity: _pulseAnimController,
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: Colors.amberAccent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            i18n.writingSolution,
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildMathMarkdown(liveSolutionText),
                  ],
                ),
              );
            }

            final historyIndex = hasLiveSolution ? index - 1 : index;
            final item = _solutionHistory[historyIndex];
            return _buildSolutionCard(item, historyIndex);
          },
        );
      },
    );
  }

  Widget _buildSolutionCard(MathSolutionRecord item, int index) {
    final lang = AppLanguageController.instance.currentLanguage;
    final i18n = _MathTutorI18n(lang);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${_solutionHistory.length - index}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.level.label(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ),
                Text(
                  _formatTime(item.timestamp),
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
                const SizedBox(width: 4),
                IconButton(
                  iconSize: 16,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.copy_rounded, color: Colors.white70),
                  tooltip: i18n.tooltipCopy,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.solutionMarkdown));
                    _showSafeSnackBar(
                      i18n.copiedSnackBar,
                      icon: Icons.copy_rounded,
                      iconColor: Colors.amberAccent,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Captured / Picked Problem Thumbnail Image
            if (item.capturedImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.memory(
                      item.capturedImage!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

            // Problem Level & Difficulty Badge
            if (item.problemLevel.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade900.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigoAccent.shade200, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.analytics_rounded,
                        color: Colors.indigoAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i18n.problemLevelLabel,
                            style: const TextStyle(
                              color: Colors.indigoAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.problemLevel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Examiner's Intent (출제자의 의도)
            if (item.examinerIntent.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.purple.shade900.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purpleAccent.shade200, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.psychology_alt_rounded,
                        color: Colors.purpleAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i18n.examinerIntentLabel,
                            style: const TextStyle(
                              color: Colors.purpleAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.examinerIntent,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Highlighted Final Answer Box (정답 박스)
            if (item.finalAnswer.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade900.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.greenAccent.shade400, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.greenAccent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i18n.finalAnswerLabel,
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.finalAnswer,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Markdown Solution Body with LaTeX Math Rendering
            _buildMathMarkdown(item.solutionMarkdown),

            // Optional Historical Extended Thinking Scratchpad (복습용)
            if (item.thinkingLog.isNotEmpty) ...[
              const SizedBox(height: 10),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 6),
                  iconColor: Colors.cyanAccent,
                  collapsedIconColor: Colors.white54,
                  leading: const Icon(Icons.psychology_alt_rounded,
                      color: Colors.cyanAccent, size: 18),
                  title: Text(
                    i18n.viewThinkingProcess,
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B132B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
                      ),
                      child: SelectableText(
                        item.thinkingLog,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          color: Colors.cyanAccent,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingScratchpadTab({ScrollController? scrollController}) {
    final lang = AppLanguageController.instance.currentLanguage;
    final i18n = _MathTutorI18n(lang);

    return SingleChildScrollView(
      controller: scrollController ?? _thoughtsScrollController,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_alt_rounded, color: Colors.cyanAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  i18n.thinkingScratchpadTitle,
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: _thoughtsTokenNotifier,
                builder: (context, tokenCount, _) {
                  if (tokenCount <= 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.cyan.shade900.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyanAccent),
                    ),
                    child: Text(
                      '$tokenCount tokens',
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            i18n.thinkingScratchpadDesc,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0B132B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan.withValues(alpha: 0.2)),
            ),
            child: ValueListenableBuilder<String>(
              valueListenable: _liveThoughtsNotifier,
              builder: (context, liveThoughts, _) {
                final displayThoughts = liveThoughts.isNotEmpty
                    ? liveThoughts
                    : (_solutionHistory.isNotEmpty &&
                            _solutionHistory.first.thinkingLog.isNotEmpty
                        ? _solutionHistory.first.thinkingLog
                        : i18n.thinkingScratchpadWaiting);
                return SelectableText(
                  displayThoughts,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    color: Colors.cyanAccent,
                    height: 1.5,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet() {
    return MarkdownStyleSheet(
      h1: const TextStyle(
        color: Colors.amberAccent,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      h2: const TextStyle(
        color: Colors.amber,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
      h3: const TextStyle(
        color: Colors.cyanAccent,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      p: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        height: 1.5,
      ),
      code: const TextStyle(
        color: Colors.amberAccent,
        fontFamily: 'monospace',
        backgroundColor: Colors.black38,
        fontSize: 12,
      ),
      codeblockDecoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      blockquote: const TextStyle(
        color: Colors.greenAccent,
        fontSize: 13.5,
        fontWeight: FontWeight.bold,
      ),
      blockquoteDecoration: BoxDecoration(
        color: Colors.green.shade900.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildMathMarkdown(String text) {
    return MarkdownBody(
      data: _preprocessMathText(text),
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      inlineSyntaxes: [LatexInlineSyntax()],
      blockSyntaxes: const [LatexBlockSyntax()],
      builders: {
        'latex': LatexElementBuilder(),
        'latex-block': LatexElementBuilder(isBlock: true),
      },
      styleSheet: _buildMarkdownStyleSheet(),
    );
  }

  String _preprocessMathText(String text) {
    // Convert \[ ... \] to $$ ... $$
    var res = text.replaceAllMapped(
      RegExp(r'\\\[([\s\S]*?)\\\]'),
      (m) => '\n\$\$\n${m[1]?.trim()}\n\$\$\n',
    );
    // Convert \( ... \) to $ ... $
    res = res.replaceAllMapped(
      RegExp(r'\\\(([\s\S]*?)\\\)'),
      (m) => ' \$${m[1]?.trim()}\$ ',
    );
    return res;
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Inline syntax for TeX formulas: $...$
class LatexInlineSyntax extends md.InlineSyntax {
  LatexInlineSyntax() : super(r'(?<!\\)\$((?:\\\$|[^$])+?)(?<!\\)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final raw = match[1] ?? '';
    final el = md.Element.text('latex', raw);
    parser.addNode(el);
    return true;
  }
}

/// Block syntax for TeX display formulas: $$...$$
class LatexBlockSyntax extends md.BlockSyntax {
  static final _pattern = RegExp(r'^\$\$\s*([\s\S]*?)\s*\$\$$', multiLine: true);

  @override
  RegExp get pattern => _pattern;

  const LatexBlockSyntax();

  @override
  md.Node? parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    if (match != null) {
      parser.advance();
      return md.Element.text('latex-block', match[1] ?? '');
    }
    if (parser.current.content.startsWith(r'$$')) {
      final childLines = <String>[];
      final firstLine = parser.current.content.substring(2);
      parser.advance();
      if (firstLine.endsWith(r'$$') && firstLine.length >= 2) {
        return md.Element.text(
          'latex-block',
          firstLine.substring(0, firstLine.length - 2),
        );
      }
      childLines.add(firstLine);
      while (!parser.isDone) {
        final line = parser.current.content;
        if (line.endsWith(r'$$')) {
          childLines.add(line.substring(0, line.length - 2));
          parser.advance();
          break;
        }
        childLines.add(line);
        parser.advance();
      }
      return md.Element.text('latex-block', childLines.join('\n'));
    }
    return null;
  }
}

/// Element builder rendering TeX formulas with FlutterMath.
class LatexElementBuilder extends MarkdownElementBuilder {
  final bool isBlock;
  LatexElementBuilder({this.isBlock = false});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final tex = element.textContent.trim();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isBlock ? 6.0 : 1.0,
          horizontal: 2.0,
        ),
        child: Math.tex(
          tex,
          textStyle: (preferredStyle ?? const TextStyle(color: Colors.white, fontSize: 14))
              .copyWith(
            color: isBlock ? Colors.amberAccent : Colors.cyanAccent,
          ),
          mathStyle: isBlock ? MathStyle.display : MathStyle.text,
          onErrorFallback: (err) => Text(
            isBlock ? '\$\$\n$tex\n\$\$' : '\$$tex\$',
            style: TextStyle(
              color: Colors.amber.shade200,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
