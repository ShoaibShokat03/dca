class Answer {
  final int id;
  final int questionId;
  final String answerText;
  final int isCorrect;

  Answer({required this.id, required this.questionId, required this.answerText, this.isCorrect = 0});

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      questionId: (json['question_id'] as num?)?.toInt() ?? 0,
      answerText: (json['answer_text'] as String?) ?? '',
      isCorrect: (json['is_correct'] as num?)?.toInt() ?? 0,
    );
  }
}

class Question {
  final int id;
  final int quizId;
  final String questionText;
  final String type; // mcq | truefalse | text
  final int qnumber;
  final List<Answer> answers;

  Question({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.type,
    required this.qnumber,
    this.answers = const [],
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final list = (json['answers'] as List?) ?? [];
    return Question(
      id: (json['id'] as num?)?.toInt() ?? 0,
      quizId: (json['quiz_id'] as num?)?.toInt() ?? 0,
      questionText: (json['question_text'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'mcq',
      qnumber: (json['qnumber'] as num?)?.toInt() ?? 0,
      answers: list.map((a) => Answer.fromJson(a as Map<String, dynamic>)).toList(),
    );
  }
}

class StudentResponse {
  final int? id;
  final int questionId;
  final int? quizId;
  final int? sessionId;
  final int? answerId;
  final String? studentAnswer;
  final String? submittedAt;

  StudentResponse({
    this.id,
    required this.questionId,
    this.quizId,
    this.sessionId,
    this.answerId,
    this.studentAnswer,
    this.submittedAt,
  });

  factory StudentResponse.fromJson(Map<String, dynamic> json) {
    return StudentResponse(
      id: (json['id'] as num?)?.toInt(),
      questionId: (json['question_id'] as num?)?.toInt() ?? 0,
      quizId: (json['quiz_id'] as num?)?.toInt(),
      sessionId: (json['session_id'] as num?)?.toInt(),
      answerId: (json['answer_id'] as num?)?.toInt(),
      studentAnswer: json['student_answer'] as String?,
      submittedAt: json['submitted_at'] as String?,
    );
  }
}
