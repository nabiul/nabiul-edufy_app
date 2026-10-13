class NoticeItem {
  const NoticeItem({
    required this.id,
    required this.title,
    required this.typeLabel,
    this.shortDescription,
    this.description,
    this.publishedAt,
  });

  final int id;
  final String title;
  final String typeLabel;
  final String? shortDescription;
  final String? description;
  final DateTime? publishedAt;

  factory NoticeItem.fromJson(Map<String, dynamic> json) => NoticeItem(
    id: json['id'] as int,
    title: json['title'] as String? ?? 'Untitled notice',
    typeLabel: json['type_label'] as String? ?? 'Notice',
    shortDescription: json['short_description'] as String?,
    description: json['description'] as String?,
    publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
  );
}
