import 'package:flutter/material.dart';

import '../models/bookmark_item.dart';

/// A single row in the bookmarks list.
class BookmarkListItem extends StatelessWidget {
  const BookmarkListItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final BookmarkItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = item.title.trim().isNotEmpty
        ? item.title
        : (item.domain.isNotEmpty ? item.domain : item.url);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.tertiaryContainer,
        child: Icon(Icons.star, color: scheme.onTertiaryContainer, size: 20),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        item.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        tooltip: '删除',
        icon: const Icon(Icons.close, size: 18),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}
