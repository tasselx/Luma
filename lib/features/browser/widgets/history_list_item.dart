import 'package:flutter/material.dart';

import '../models/browser_history_item.dart';

/// A single row in the history list.
class HistoryListItem extends StatelessWidget {
  const HistoryListItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final BrowserHistoryItem item;
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
        backgroundColor: scheme.primaryContainer,
        child: Icon(Icons.history, color: scheme.onPrimaryContainer, size: 20),
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
