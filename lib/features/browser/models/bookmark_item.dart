/// A saved bookmark.
class BookmarkItem {
  BookmarkItem({
    required this.title,
    required this.url,
    required this.domain,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String title;
  final String url;
  final String domain;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'domain': domain,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory BookmarkItem.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    return BookmarkItem(
      title: (json['title'] as String?) ?? '',
      url: (json['url'] as String?) ?? '',
      domain: (json['domain'] as String?) ?? '',
      createdAt: created is int
          ? DateTime.fromMillisecondsSinceEpoch(created)
          : DateTime.tryParse('${created ?? ''}') ?? DateTime.now(),
    );
  }
}
