class VideoItem {
  final int id;
  final String title;
  final String? filePath;
  final int? quizId;
  final String? quizTitle;
  final String? sessionName;

  VideoItem({
    required this.id,
    required this.title,
    this.filePath,
    this.quizId,
    this.quizTitle,
    this.sessionName,
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    String? qTitle;
    String? sName;
    final quiz = json['quiz'];
    if (quiz is Map<String, dynamic>) {
      qTitle = quiz['title'] as String?;
      final sess = quiz['session'];
      if (sess is Map<String, dynamic>) {
        sName = sess['name'] as String?;
      }
    }
    return VideoItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? (json['name'] as String?) ?? 'Untitled',
      filePath: json['file_path'] as String?,
      quizId: (json['quiz_id'] as num?)?.toInt(),
      quizTitle: qTitle,
      sessionName: sName,
    );
  }

  bool get isHls => filePath != null && (filePath!.contains('.m3u8') || filePath!.contains('/hls/'));
}
