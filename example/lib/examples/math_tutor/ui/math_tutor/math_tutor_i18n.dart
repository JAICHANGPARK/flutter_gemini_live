import 'package:example/app_translations.dart';

/// Comprehensive multilingual translation helper for Live Math Tutor (ko, en, ja, zh).
class MathTutorI18n {
  final AppLanguage lang;
  const MathTutorI18n(this.lang);

  String get appTitle => switch (lang) {
    AppLanguage.ko => 'AI 만능 시험 튜터',
    AppLanguage.en => 'Live Exam Tutor',
    AppLanguage.ja => 'AI 万能受験チューター',
    AppLanguage.zh => 'AI 全能考试私教',
  };

  String get modelSubtitle => switch (lang) {
    AppLanguage.ko => 'Gemini 3.8 Live Extended Thinking (전과목 심층 추론)',
    AppLanguage.en =>
      'Gemini 3.8 Live Extended Thinking (All-Subject High Reasoning)',
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
    AppLanguage.en => 'Solution Notes',
    AppLanguage.ja => '解答・解説ノート',
    AppLanguage.zh => '题解与答案记录',
  };

  String get tabTranscript => switch (lang) {
    AppLanguage.ko => '실시간 대화 로그',
    AppLanguage.en => 'Live Dialog Log',
    AppLanguage.ja => '対話ログ',
    AppLanguage.zh => '实时对话记录',
  };

  String get tabThinking => switch (lang) {
    AppLanguage.ko => 'AI 생각 과정',
    AppLanguage.en => 'Thinking Process',
    AppLanguage.ja => '思考プロセス',
    AppLanguage.zh => '思考过程',
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
    AppLanguage.en =>
      'Point camera at or scan a problem to watch real-time thoughts stream here.',
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
    AppLanguage.ko =>
      '저장된 모든 시험 문제 풀이 이력과 오답 노트를 삭제하시겠습니까?\n삭제 후에는 복구할 수 없습니다.',
    AppLanguage.en =>
      'Delete all saved exam solution records and review notes?\nThis action cannot be undone.',
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
    AppLanguage.en =>
      '🖼️ Photo sent from gallery. Solving with Extended Thinking...',
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
