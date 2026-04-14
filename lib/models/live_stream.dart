class LiveStream {
  final int id;
  final String? title;
  final String? description;
  final String? streamUrl;
  final String? streamType; // youtube | zoom | hls
  final String? startTime;
  final String? endTime;
  final int? active;
  final String? meetingId;
  final String? meetingPasscode;

  LiveStream({
    required this.id,
    this.title,
    this.description,
    this.streamUrl,
    this.streamType,
    this.startTime,
    this.endTime,
    this.active,
    this.meetingId,
    this.meetingPasscode,
  });

  factory LiveStream.fromJson(Map<String, dynamic> json) => LiveStream(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String?,
        description: json['description'] as String?,
        streamUrl: json['stream_url'] as String?,
        streamType: json['stream_type'] as String?,
        startTime: json['start_time'] as String?,
        endTime: json['end_time'] as String?,
        active: (json['active'] as num?)?.toInt(),
        meetingId: json['meeting_id'] as String?,
        meetingPasscode: json['meeting_passcode'] as String?,
      );
}
