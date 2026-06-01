import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ui_helpers.dart';
import '../controllers/browser_controller.dart';
import '../widgets/bookmark_list_item.dart';
import '../widgets/browser_empty_view.dart';

class BrowserBookmarksPage extends StatefulWidget {
  const BrowserBookmarksPage({super.key});

  @override
  State<BrowserBookmarksPage> createState() => _BrowserBookmarksPageState();
}

class _BrowserBookmarksPageState extends State<BrowserBookmarksPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BrowserController>();
    final all = controller.bookmarks;
    final query = _query.trim().toLowerCase();
    final bookmarks = query.isEmpty
        ? all
        : all
            .where((b) =>
                b.title.toLowerCase().contains(query) ||
                b.url.toLowerCase().contains(query) ||
                b.domain.toLowerCase().contains(query))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('书签'),
        actions: [
          if (all.isNotEmpty)
            IconButton(
              tooltip: '清空',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, controller),
            ),
        ],
      ),
      body: Column(
        children: [
          if (all.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '搜索书签',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          Expanded(
            child: bookmarks.isEmpty
                ? BrowserEmptyView(
                    icon: Icons.star_border,
                    title: all.isEmpty ? '暂无书签' : '没有匹配的书签',
                    subtitle: all.isEmpty ? '收藏的网页会显示在这里' : null,
                  )
                : ListView.builder(
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final item = bookmarks[index];
                      return BookmarkListItem(
                        item: item,
                        onTap: () {
                          controller.openUrl(item.url);
                          Navigator.of(context).pop();
                        },
                        onDelete: () => controller.removeBookmark(item.url),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(
      BuildContext context, BrowserController controller) async {
    final ok = await confirmDialog(
      context,
      title: '清空书签',
      message: '确定要删除全部书签吗？此操作无法撤销。',
      confirmLabel: '清空',
    );
    if (!ok || !context.mounted) return;
    await controller.clearBookmarks();
    if (context.mounted) showMessage(context, '书签已清空');
  }
}
