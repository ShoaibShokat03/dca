class Quiz {
  final int id;
  final String title;
  final String? description;
  final String? startAt;
  final String? endAt;
  final int? durationMinutes;
  final String? status;
  final int? sessionId;
  final String? sessionName;
  final int questionCount;
  final int attempted;

  Quiz({
    required this.id,
    required this.title,
    this.description,
    this.startAt,
    this.endAt,
    this.durationMinutes,
    this.status,
    this.sessionId,
    this.sessionName,
    this.questionCount = 0,
    this.attempted = 0,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? 'Untitled',
      description: json['description'] as String?,
      startAt: json['start_at'] as String?,
      endAt: json['end_at'] as String?,
      durationMinutes: (json['duration_in_minutes'] as num?)?.toInt(),
      status: json['status'] as String?,
      sessionId: (json['session_id'] as num?)?.toInt(),
      sessionName: json['session_name'] as String?,
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
      attempted: (json['attempted'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isAttempted => attempted > 0;

  DateTime? get endDateTime {
    if (endAt == null) return null;
    try {
      return DateTime.parse(endAt!.replaceAll(' ', 'T'));
    } catch (_) {
      return null;
    }
  }

  bool get isActive {
    final end = endDateTime;
    if (end == null) return true;
    return DateTime.now().isBefore(end);
  }
}
