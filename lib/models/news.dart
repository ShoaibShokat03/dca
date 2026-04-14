class NewsItem {
  final int id;
  final String title;
  final String? description;
  final String? createdAt;

  NewsItem({required this.id, required this.title, this.description, this.createdAt});

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: (json['title'] as String?) ?? '',
        description: json['description'] as String?,
        createdAt: json['created_at'] as String?,
      );
}
