import 'package:flutter/material.dart';

/// A home page shortcut to a commonly used site.
class QuickSite {
  const QuickSite({
    required this.name,
    required this.url,
    required this.iconName,
  });

  final String name;
  final String url;

  /// A logical icon name kept in the model so it stays serialisable / easy to
  /// extend later. Mapped to a concrete [IconData] by [icon].
  final String iconName;

  IconData get icon => _iconMap[iconName] ?? Icons.public;

  static const Map<String, IconData> _iconMap = {
    'search': Icons.search,
    'video': Icons.smart_display_outlined,
    'code': Icons.code,
    'forum': Icons.forum_outlined,
    'tag': Icons.tag,
    'book': Icons.menu_book_outlined,
    'stack': Icons.layers_outlined,
    'flutter': Icons.flutter_dash,
    'public': Icons.public,
  };

  /// Default built-in shortcuts. Kept as a simple list so user customisation
  /// can be layered on later.
  static const List<QuickSite> defaults = [
    QuickSite(
        name: 'Google', url: 'https://www.google.com', iconName: 'search'),
    QuickSite(
        name: 'YouTube', url: 'https://www.youtube.com', iconName: 'video'),
    QuickSite(name: 'GitHub', url: 'https://github.com', iconName: 'code'),
    QuickSite(name: 'Reddit', url: 'https://www.reddit.com', iconName: 'forum'),
    QuickSite(name: 'X', url: 'https://x.com', iconName: 'tag'),
    QuickSite(
        name: 'Wikipedia', url: 'https://www.wikipedia.org', iconName: 'book'),
    QuickSite(
        name: 'Stack Overflow',
        url: 'https://stackoverflow.com',
        iconName: 'stack'),
    QuickSite(name: 'Flutter', url: 'https://flutter.dev', iconName: 'flutter'),
  ];
}
