class SessionItem {
  final int id;
  final String name;
  final String? type;
  final String? startTime;
  final String? endTime;
  final String? status;
  final bool assigned;

  SessionItem({
    required this.id,
    required this.name,
    this.type,
    this.startTime,
    this.endTime,
    this.status,
    this.assigned = false,
  });

  factory SessionItem.fromJson(Map<String, dynamic> json) {
    return SessionItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? 'Untitled',
      type: json['type'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      status: json['status'] as String?,
      assigned: json['assigned'] as bool? ?? false,
    );
  }

  bool get isDemo => type == 'demo';
}
