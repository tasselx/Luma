/// A visited page recorded in the browsing history.
class BrowserHistoryItem {
  BrowserHistoryItem({
    required this.title,
    required this.url,
    required this.domain,
    DateTime? visitedAt,
  }) : visitedAt = visitedAt ?? DateTime.now();

  final String title;
  final String url;
  final String domain;
  DateTime visitedAt;

  BrowserHistoryItem copyWith({String? title, DateTime? visitedAt}) {
    return BrowserHistoryItem(
      title: title ?? this.title,
      url: url,
      domain: domain,
      visitedAt: visitedAt ?? this.visitedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'domain': domain,
        'visitedAt': visitedAt.millisecondsSinceEpoch,
      };

  factory BrowserHistoryItem.fromJson(Map<String, dynamic> json) {
    final visited = json['visitedAt'];
    return BrowserHistoryItem(
      title: (json['title'] as String?) ?? '',
      url: (json['url'] as String?) ?? '',
      domain: (json['domain'] as String?) ?? '',
      visitedAt: visited is int
          ? DateTime.fromMillisecondsSinceEpoch(visited)
          : DateTime.tryParse('${visited ?? ''}') ?? DateTime.now(),
    );
  }
}
