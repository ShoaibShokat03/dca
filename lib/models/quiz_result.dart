class QuizResultQuestion {
  final int qn;
  final String questionText;
  final String correctAnswer;
  final String? studentAnswer;
  final String status; // correct | incorrect | unattempted

  QuizResultQuestion({
    required this.qn,
    required this.questionText,
    required this.correctAnswer,
    this.studentAnswer,
    required this.status,
  });

  factory QuizResultQuestion.fromJson(Map<String, dynamic> json) => QuizResultQuestion(
        qn: (json['qn'] as num?)?.toInt() ?? 0,
        questionText: (json['question_text'] as String?) ?? '',
        correctAnswer: (json['correct_answer'] as String?) ?? 'N/A',
        studentAnswer: json['student_answer'] as String?,
        status: (json['status'] as String?) ?? 'unattempted',
      );
}

class QuizResult {
  final int quizId;
  final String quizTitle;
  final int totalQuestions;
  final int totalCorrect;
  final int totalIncorrect;
  final int unattempted;
  final int percentage;
  final List<QuizResultQuestion> questions;

  QuizResult({
    required this.quizId,
    required this.quizTitle,
    required this.totalQuestions,
    required this.totalCorrect,
    required this.totalIncorrect,
    required this.unattempted,
    required this.percentage,
    required this.questions,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    final list = (json['questions'] as List?) ?? [];
    return QuizResult(
      quizId: (json['quiz_id'] as num?)?.toInt() ?? 0,
      quizTitle: (json['quiz_title'] as String?) ?? '',
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      totalCorrect: (json['total_correct'] as num?)?.toInt() ?? 0,
      totalIncorrect: (json['total_incorrect'] as num?)?.toInt() ?? 0,
      unattempted: (json['unattempted'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
      questions: list.map((q) => QuizResultQuestion.fromJson(q as Map<String, dynamic>)).toList(),
    );
  }
}

class QuizTimeInfo {
  final int totalSeconds;
  final int spentSeconds;
  final int remainingSeconds;
  final String? startTimeUtc;
  final String? serverNowUtc;

  QuizTimeInfo({
    required this.totalSeconds,
    required this.spentSeconds,
    required this.remainingSeconds,
    this.startTimeUtc,
    this.serverNowUtc,
  });

  factory QuizTimeInfo.fromJson(Map<String, dynamic> json) => QuizTimeInfo(
        totalSeconds: (json['total_seconds'] as num?)?.toInt() ?? 0,
        spentSeconds: (json['spent_seconds'] as num?)?.toInt() ?? 0,
        remainingSeconds: (json['remaining_seconds'] as num?)?.toInt() ?? 0,
        startTimeUtc: json['start_time_utc'] as String?,
        serverNowUtc: json['server_now_utc'] as String?,
      );
}
