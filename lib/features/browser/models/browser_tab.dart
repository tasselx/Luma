import 'dart:math';

/// A single browser tab. This is a serializable data model; live objects such
/// as the [WebViewController] are kept separately in the controller so this
/// model stays cheap to copy and persist.
class BrowserTab {
  BrowserTab({
    required this.id,
    this.title = '',
    this.url = '',
    this.isPrivate = false,
    this.isLoading = false,
    this.progress = 0,
    this.canGoBack = false,
    this.canGoForward = false,
    this.errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String title;
  String url;
  bool isPrivate;
  bool isLoading;
  double progress;
  bool canGoBack;
  bool canGoForward;
  String? errorMessage;
  DateTime createdAt;
  DateTime updatedAt;

  /// Whether this tab currently shows the home page (no loaded url).
  bool get isHome => url.trim().isEmpty;

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  static String generateId() {
    final rand = Random();
    return '${DateTime.now().microsecondsSinceEpoch}_${rand.nextInt(1 << 32)}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'isPrivate': isPrivate,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory BrowserTab.fromJson(Map<String, dynamic> json) {
    return BrowserTab(
      id: (json['id'] as String?) ?? generateId(),
      title: (json['title'] as String?) ?? '',
      url: (json['url'] as String?) ?? '',
      isPrivate: (json['isPrivate'] as bool?) ?? false,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
