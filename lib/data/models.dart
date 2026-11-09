// Modelos de datos que devuelven la base de datos y las funciones RPC.

int _i(dynamic v, [int d = 0]) {
  if (v == null) return d;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? double.tryParse(v.toString())?.toInt() ?? d;
}

double _d(dynamic v, [double d = 0]) {
  if (v == null) return d;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? d;
}

double? _dn(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

bool _b(dynamic v) => v == true || v == 'true' || v == 1;

Map<String, dynamic> _m(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<dynamic> _l(dynamic v) => v is List ? v : const [];

List<String> _sl(dynamic v) => _l(v).map((e) => e.toString()).toList();

class Profile {
  final String id;
  final String? displayName;
  final int currentDay;
  final int currentLevel;
  final int xp;
  final int streak;
  final int bestStreak;
  final String? lastPassDate;
  final String timezone;

  const Profile({
    required this.id,
    required this.displayName,
    required this.currentDay,
    required this.currentLevel,
    required this.xp,
    required this.streak,
    required this.bestStreak,
    required this.lastPassDate,
    required this.timezone,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id']?.toString() ?? '',
        displayName: j['display_name'] as String?,
        currentDay: _i(j['current_day'], 1),
        currentLevel: _i(j['current_level'], 1),
        xp: _i(j['xp']),
        streak: _i(j['streak']),
        bestStreak: _i(j['best_streak']),
        lastPassDate: j['last_pass_date'] as String?,
        timezone: j['timezone'] as String? ?? 'Europe/Madrid',
      );
}

class LessonSummary {
  final int dayNumber;
  final String title;
  final String? objective;
  final bool isReady;
  final int estimatedMinutes;
  final String moduleId;
  final String moduleTitle;
  final String? moduleColor;
  final int phaseId;
  final int questionCount;

  const LessonSummary({
    required this.dayNumber,
    required this.title,
    required this.objective,
    required this.isReady,
    required this.estimatedMinutes,
    required this.moduleId,
    required this.moduleTitle,
    required this.moduleColor,
    required this.phaseId,
    required this.questionCount,
  });

  factory LessonSummary.fromJson(Map<String, dynamic> j) => LessonSummary(
        dayNumber: _i(j['day_number']),
        title: j['title'] as String? ?? '',
        objective: j['objective'] as String?,
        isReady: _b(j['is_ready']),
        estimatedMinutes: _i(j['estimated_minutes'], 60),
        moduleId: j['module_id'] as String? ?? '',
        moduleTitle: j['module_title'] as String? ?? '',
        moduleColor: j['module_color'] as String?,
        phaseId: _i(j['phase_id'], 1),
        questionCount: _i(j['question_count']),
      );
}

class Dashboard {
  final Profile profile;
  final String today;
  final int effectiveStreak;
  final bool passedToday;
  final bool programCompleted;
  final int totalDays;
  final int examsToday;
  final int reviewsDue;
  final LessonSummary? lesson;

  const Dashboard({
    required this.profile,
    required this.today,
    required this.effectiveStreak,
    required this.passedToday,
    required this.programCompleted,
    required this.totalDays,
    required this.examsToday,
    required this.reviewsDue,
    required this.lesson,
  });

  factory Dashboard.fromJson(Map<String, dynamic> j) => Dashboard(
        profile: Profile.fromJson(_m(j['profile'])),
        today: j['today']?.toString() ?? '',
        effectiveStreak: _i(j['effective_streak']),
        passedToday: _b(j['passed_today']),
        programCompleted: _b(j['program_completed']),
        totalDays: _i(j['total_days'], 455),
        examsToday: _i(j['exams_today']),
        reviewsDue: _i(j['reviews_due']),
        lesson: j['lesson'] is Map ? LessonSummary.fromJson(_m(j['lesson'])) : null,
      );
}

class Phase {
  final int id;
  final String title;
  final String? description;

  const Phase({required this.id, required this.title, this.description});

  factory Phase.fromJson(Map<String, dynamic> j) => Phase(
        id: _i(j['id']),
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
      );
}

class ModuleInfo {
  final String id;
  final int phaseId;
  final int position;
  final String title;
  final String? description;
  final int dayStart;
  final int dayEnd;
  final String color;
  final List<String> tools;

  const ModuleInfo({
    required this.id,
    required this.phaseId,
    required this.position,
    required this.title,
    required this.description,
    required this.dayStart,
    required this.dayEnd,
    required this.color,
    required this.tools,
  });

  int get length => dayEnd - dayStart + 1;

  factory ModuleInfo.fromJson(Map<String, dynamic> j) => ModuleInfo(
        id: j['id'] as String? ?? '',
        phaseId: _i(j['phase_id']),
        position: _i(j['position']),
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        dayStart: _i(j['day_start']),
        dayEnd: _i(j['day_end']),
        color: j['color'] as String? ?? '#4FD1FF',
        tools: _sl(j['tools']),
      );
}

class DaySummary {
  final int dayNumber;
  final String moduleId;
  final String title;
  final String? objective;
  final bool isReady;

  const DaySummary({
    required this.dayNumber,
    required this.moduleId,
    required this.title,
    required this.objective,
    required this.isReady,
  });

  factory DaySummary.fromJson(Map<String, dynamic> j) => DaySummary(
        dayNumber: _i(j['day_number']),
        moduleId: j['module_id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        objective: j['objective'] as String?,
        isReady: _b(j['is_ready']),
      );
}

class DayContent {
  final int dayNumber;
  final String moduleId;
  final String title;
  final String? objective;
  final String? bodyMd;
  final String? practiceMd;
  final int estimatedMinutes;

  const DayContent({
    required this.dayNumber,
    required this.moduleId,
    required this.title,
    required this.objective,
    required this.bodyMd,
    required this.practiceMd,
    required this.estimatedMinutes,
  });

  bool get isReady => bodyMd != null;

  factory DayContent.fromJson(Map<String, dynamic> j) => DayContent(
        dayNumber: _i(j['day_number']),
        moduleId: j['module_id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        objective: j['objective'] as String?,
        bodyMd: j['body_md'] as String?,
        practiceMd: j['practice_md'] as String?,
        estimatedMinutes: _i(j['estimated_minutes'], 60),
      );
}

class ExamQuestion {
  final String id;
  final String qtype; // 'mcq' | 'numeric'
  final String promptMd;
  final List<String> options;
  final String? unit;
  final int difficulty;
  final bool isReview;
  final int sourceDay;

  const ExamQuestion({
    required this.id,
    required this.qtype,
    required this.promptMd,
    required this.options,
    required this.unit,
    required this.difficulty,
    required this.isReview,
    required this.sourceDay,
  });

  bool get isNumeric => qtype == 'numeric';

  factory ExamQuestion.fromJson(Map<String, dynamic> j) => ExamQuestion(
        id: j['id']?.toString() ?? '',
        qtype: j['qtype'] as String? ?? 'mcq',
        promptMd: j['prompt_md'] as String? ?? '',
        options: _sl(j['options']),
        unit: j['unit'] as String?,
        difficulty: _i(j['difficulty_level'], 1),
        isReview: _b(j['is_review']),
        sourceDay: _i(j['source_day']),
      );
}

class Exam {
  final String examId;
  final int dayNumber;
  final int difficultyLevel;
  final String mode; // 'daily' | 'practice'
  final List<ExamQuestion> questions;

  const Exam({
    required this.examId,
    required this.dayNumber,
    required this.difficultyLevel,
    required this.mode,
    required this.questions,
  });

  bool get isPractice => mode == 'practice';

  factory Exam.fromJson(Map<String, dynamic> j) => Exam(
        examId: j['exam_id']?.toString() ?? '',
        dayNumber: _i(j['day_number']),
        difficultyLevel: _i(j['difficulty_level'], 1),
        mode: j['mode'] as String? ?? 'daily',
        questions: _l(j['questions']).map((e) => ExamQuestion.fromJson(_m(e))).toList(),
      );
}

class QuestionResult {
  final String questionId;
  final String qtype;
  final String promptMd;
  final List<String> options;
  final int? correctIndex;
  final double? answerValue;
  final double tolerancePct;
  final String? unit;
  final String explanationMd;
  final int difficulty;
  final int sourceDay;
  final bool isReview;
  final int? yourChoice;
  final double? yourValue;
  final bool isCorrect;

  const QuestionResult({
    required this.questionId,
    required this.qtype,
    required this.promptMd,
    required this.options,
    required this.correctIndex,
    required this.answerValue,
    required this.tolerancePct,
    required this.unit,
    required this.explanationMd,
    required this.difficulty,
    required this.sourceDay,
    required this.isReview,
    required this.yourChoice,
    required this.yourValue,
    required this.isCorrect,
  });

  bool get isNumeric => qtype == 'numeric';
  bool get answered => yourChoice != null || yourValue != null;

  factory QuestionResult.fromJson(Map<String, dynamic> j) {
    final ya = _m(j['your_answer']);
    return QuestionResult(
      questionId: j['question_id']?.toString() ?? '',
      qtype: j['qtype'] as String? ?? 'mcq',
      promptMd: j['prompt_md'] as String? ?? '',
      options: _sl(j['options']),
      correctIndex: j['correct_index'] == null ? null : _i(j['correct_index']),
      answerValue: _dn(j['answer_value']),
      tolerancePct: _d(j['tolerance_pct'], 2),
      unit: j['unit'] as String?,
      explanationMd: j['explanation_md'] as String? ?? '',
      difficulty: _i(j['difficulty_level'], 1),
      sourceDay: _i(j['source_day']),
      isReview: _b(j['is_review']),
      yourChoice: ya['choice'] == null ? null : _i(ya['choice']),
      yourValue: _dn(ya['value']),
      isCorrect: _b(j['is_correct']),
    );
  }
}

class ExamResult {
  final String examId;
  final String mode;
  final int dayNumber;
  final double score;
  final bool passed;
  final int correct;
  final int total;
  final int xpEarned;
  final int levelChange;
  final bool dayAdvanced;
  final Profile profile;
  final List<QuestionResult> results;

  const ExamResult({
    required this.examId,
    required this.mode,
    required this.dayNumber,
    required this.score,
    required this.passed,
    required this.correct,
    required this.total,
    required this.xpEarned,
    required this.levelChange,
    required this.dayAdvanced,
    required this.profile,
    required this.results,
  });

  factory ExamResult.fromJson(Map<String, dynamic> j) => ExamResult(
        examId: j['exam_id']?.toString() ?? '',
        mode: j['mode'] as String? ?? 'daily',
        dayNumber: _i(j['day_number']),
        score: _d(j['score']),
        passed: _b(j['passed']),
        correct: _i(j['correct']),
        total: _i(j['total']),
        xpEarned: _i(j['xp_earned']),
        levelChange: _i(j['level_change']),
        dayAdvanced: _b(j['day_advanced']),
        profile: Profile.fromJson(_m(j['profile'])),
        results: _l(j['results']).map((e) => QuestionResult.fromJson(_m(e))).toList(),
      );
}

class HistoryEntry {
  final String id;
  final int dayNumber;
  final String mode;
  final double score;
  final bool passed;
  final int xpEarned;
  final int levelChange;
  final int difficultyLevel;
  final DateTime? completedAt;

  const HistoryEntry({
    required this.id,
    required this.dayNumber,
    required this.mode,
    required this.score,
    required this.passed,
    required this.xpEarned,
    required this.levelChange,
    required this.difficultyLevel,
    required this.completedAt,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: j['id']?.toString() ?? '',
        dayNumber: _i(j['day_number']),
        mode: j['mode'] as String? ?? 'daily',
        score: _d(j['score']),
        passed: _b(j['passed']),
        xpEarned: _i(j['xp_earned']),
        levelChange: _i(j['level_change']),
        difficultyLevel: _i(j['difficulty_level'], 1),
        completedAt: j['completed_at'] == null ? null : DateTime.tryParse(j['completed_at'].toString())?.toLocal(),
      );
}

class ModuleStat {
  final String moduleId;
  final int exams;
  final int passed;
  final double avgScore;
  final double bestScore;

  const ModuleStat({
    required this.moduleId,
    required this.exams,
    required this.passed,
    required this.avgScore,
    required this.bestScore,
  });

  factory ModuleStat.fromJson(Map<String, dynamic> j) => ModuleStat(
        moduleId: j['module_id'] as String? ?? '',
        exams: _i(j['exams']),
        passed: _i(j['passed']),
        avgScore: _d(j['avg_score']),
        bestScore: _d(j['best_score']),
      );
}
