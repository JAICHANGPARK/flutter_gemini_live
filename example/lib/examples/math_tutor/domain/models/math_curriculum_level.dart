import 'package:example/app_translations.dart';
import 'package:flutter/material.dart';

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
    description:
        '수학, 국어, 이과/과학, 사회/역사, 외국어, 정보(컴퓨터) 등 모든 시험 문제와 과목을 AI가 100% 자동 판별합니다.',
    badgeIcon: Icons.auto_awesome,
    promptHint:
        'Automatically detect the subject (Mathematics, Native Languages/Literature, Natural Sciences, Social Studies/History, Foreign Languages, Informatics/CS) and academic level (Elementary to College Entrance Exams: Korean CSAT, Japanese Common Test DNC, US SAT/AP, and University Courses). Tailor the depth, terminology, and analysis accordingly.',
  ),
  math(
    id: 'math',
    labelKo: '수학 (수능·공통테스트·AP/대학)',
    labelEn: 'Mathematics (CSAT/DNC/AP)',
    labelJa: '数学 (共通テスト・数ⅠA/ⅡBC)',
    labelZh: '数学 (高考・大学统考・高等数学)',
    description: '수학I·II, 미적분, 확률과 통계, 기하, 선형대수학 등 수능/공통테스트 킬러 문항 및 계산·증명 전개.',
    badgeIcon: Icons.functions_rounded,
    promptHint:
        'Focus on Mathematics (Algebra, Geometry, Calculus, Probability & Statistics, Discrete Math, Linear Algebra). Explain theorems, formulas with LaTeX, calculation steps, and examiner pitfalls.',
  ),
  languages(
    id: 'languages',
    labelKo: '국어·현대문·고전문학·독해',
    labelEn: 'Native Languages & Literature',
    labelJa: '国語 (現代文・古文・漢文)',
    labelZh: '语文 (现代文・古文・诗词鉴赏)',
    description:
        '수능 국어(비문학 독서, 문학, 화작/언매), 일본 공통테스트 국어(현대문, 고문, 한문) 지문 구조 분석 및 문맥 추론.',
    badgeIcon: Icons.auto_stories_rounded,
    promptHint:
        'Focus on Native Language, Reading Comprehension, and Classical Literature (Korean CSAT Korean, Japanese DNC Kokugo including Modern, Classical Japanese Kobun, and Kanbun). Analyze passage structure, main themes, rhetorical devices, examiner intention, and sentence-by-sentence contextual evidence.',
  ),
  science(
    id: 'science',
    labelKo: '과학·이과 (물리·화학·생물·지학)',
    labelEn: 'Natural Sciences (Phys/Chem/Bio/Earth)',
    labelJa: '理科 (物理・化学・生物・地学)',
    labelZh: '理科综合 (物理・化学・生物・地学)',
    description:
        '물리(역학/전자기학), 화학(몰농도/평형), 생명과학(유전/물질대사), 지구과학(천문/대기해양) 실험 및 도표 심층 분석.',
    badgeIcon: Icons.biotech_rounded,
    promptHint:
        'Focus on Natural Sciences (Physics, Chemistry, Biology, Earth & Space Science). Analyze experimental setups, charts, diagrams, chemical equations, physical laws, and quantitative data interpretations step-by-step.',
  ),
  social(
    id: 'social',
    labelKo: '사회·역사·지리·윤리·정치경제',
    labelEn: 'Social Studies & History',
    labelJa: '地理歴史・公民 (地理・日本史・世界史・公共)',
    labelZh: '文科综合 (历史・地理・政治・哲学)',
    description:
        '지리(기후/지형도), 역사(사료/연표), 일반사회(법과정치/경제), 윤리(사상가 비교) 등 사료와 통계 자료 완벽 해석.',
    badgeIcon: Icons.public_rounded,
    promptHint:
        'Focus on Social Studies, History, Geography, and Civics/Ethics (Korean Ethics/History/Geog, Japanese Geography Inquiry, Japanese/World History Inquiry, Public/Politics & Economy, US History/Gov). Deconstruct historical sources, timelines, map data, philosophical arguments, and legal/economic frameworks.',
  ),
  foreignLang(
    id: 'foreignLang',
    labelKo: '외국어 (영어·독어·불어·중국어·일본어)',
    labelEn: 'Foreign Languages (Eng/Ger/Fr/Ch/Jp)',
    labelJa: '外国語 (英語・独・仏・中・韓)',
    labelZh: '外国语 (英语・德语・法语・日语・韩语)',
    description:
        '수능/공통테스트 영어 리딩 및 리스닝 스크립트 분석, 빈칸추론, 어법, 다국어(제2외국어) 문법과 번역 해설.',
    badgeIcon: Icons.translate_rounded,
    promptHint:
        'Focus on Foreign Languages (English Reading & Listening, German, French, Chinese, Japanese, Korean). Provide accurate translation, grammatical breakdowns, vocabulary nuances, paragraph logic flow, and audio script comprehension.',
  ),
  information(
    id: 'information',
    labelKo: '정보·컴퓨터·프로그래밍',
    labelEn: 'Informatics & CS (DN-CL / AP CS)',
    labelJa: '情報Ⅰ (プログラミング・データ・アルゴリズム)',
    labelZh: '信息技术与编程 (算法・数据・计算机)',
    description:
        '일본 공통테스트 정보I(의사코드 DN-CL, Python, 네트워크, 데이터 분석) 및 알고리즘 시뮬레이션 완벽 추적.',
    badgeIcon: Icons.terminal_rounded,
    promptHint:
        'Focus on Informatics, Computer Science, and Programming (Japanese DNC Joho I pseudo-code DN-CL, Python, Algorithm tracing, Data structures, Digital logic, and Network security). Provide dry-run state tables, variable tracing, and time complexity insights.',
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
