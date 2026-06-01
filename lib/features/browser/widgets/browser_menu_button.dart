import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/ui_helpers.dart';
import '../controllers/browser_controller.dart';
import '../pages/browser_bookmarks_page.dart';
import '../pages/browser_history_page.dart';
import '../pages/browser_settings_page.dart';

/// The "more" menu shown as a modal bottom sheet from the bottom toolbar.
class BrowserMenu {
  static Future<void> show(
    BuildContext pageContext,
    BrowserController controller,
  ) async {
    final tab = controller.currentTab;
    final hasUrl = tab != null && tab.url.trim().isNotEmpty;
    final isBookmarked = controller.isCurrentBookmarked();

    await showModalBottomSheet<void>(
      context: pageContext,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        void close() => Navigator.of(sheetContext).pop();
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tab?.isPrivate ?? false)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '隐私模式',
                      style: TextStyle(
                        color: Theme.of(sheetContext).colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                _QuickRow(
                  hasUrl: hasUrl,
                  isLoading: tab?.isLoading ?? false,
                  isBookmarked: isBookmarked,
                  onNewTab: () {
                    close();
                    controller.newTab();
                  },
                  onPrivateTab: () {
                    close();
                    controller.newPrivateTab();
                  },
                  onReloadStop: () {
                    close();
                    if (tab?.isLoading ?? false) {
                      controller.stopLoading();
                    } else {
                      controller.reload();
                    }
                  },
                  onBookmark: () {
                    close();
                    final added = controller.toggleBookmark();
                    showMessage(pageContext, added ? '已收藏' : '已取消收藏');
                  },
                ),
                const Divider(height: 1),
                if (hasUrl)
                  _item(sheetContext, Icons.copy_outlined, '复制链接', () async {
                    close();
                    await Clipboard.setData(ClipboardData(text: tab.url));
                    if (pageContext.mounted) {
                      showMessage(pageContext, '链接已复制');
                    }
                  }),
                if (hasUrl)
                  _item(sheetContext, Icons.open_in_browser, '在系统浏览器中打开',
                      () async {
                    close();
                    final ok = await controller.openExternalUrl(tab.url);
                    if (pageContext.mounted && !ok) {
                      showMessage(pageContext, '无法打开外部浏览器');
                    }
                  }),
                if (hasUrl)
                  _item(sheetContext, Icons.find_in_page_outlined, '在页面中查找',
                      () async {
                    close();
                    final query = await _promptFind(pageContext);
                    if (query != null && query.trim().isNotEmpty) {
                      await controller.findInPage(query);
                    }
                  }),
                _item(
                  sheetContext,
                  controller.settings.desktopMode
                      ? Icons.phone_android
                      : Icons.desktop_windows_outlined,
                  controller.settings.desktopMode ? '移动版网站' : '桌面版网站',
                  () {
                    close();
                    controller.updateSettings(controller.settings.copyWith(
                        desktopMode: !controller.settings.desktopMode));
                    if (hasUrl) controller.reload();
                  },
                ),
                if (hasUrl)
                  _item(sheetContext, Icons.chrome_reader_mode_outlined, '阅读模式',
                      () {
                    close();
                    showMessage(pageContext, '阅读模式后续支持');
                  }),
                const Divider(height: 1),
                _item(sheetContext, Icons.history, '历史记录', () {
                  close();
                  Navigator.of(pageContext).push(
                    MaterialPageRoute(
                        builder: (_) => const BrowserHistoryPage()),
                  );
                }),
                _item(sheetContext, Icons.star_border, '书签', () {
                  close();
                  Navigator.of(pageContext).push(
                    MaterialPageRoute(
                        builder: (_) => const BrowserBookmarksPage()),
                  );
                }),
                const Divider(height: 1),
                if (hasUrl)
                  _item(sheetContext, Icons.close, '关闭当前标签页', () {
                    close();
                    controller.closeTab(tab.id);
                  }),
                if (controller.tabCount > 1)
                  _item(sheetContext, Icons.clear_all, '关闭其他标签页', () {
                    close();
                    if (tab != null) controller.closeOtherTabs(tab.id);
                  }),
                _item(sheetContext, Icons.settings_outlined, '设置', () {
                  close();
                  Navigator.of(pageContext).push(
                    MaterialPageRoute(
                        builder: (_) => const BrowserSettingsPage()),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }

  static Future<String?> _promptFind(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('在页面中查找'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '输入关键词'),
            onSubmitted: (v) => Navigator.of(context).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('查找'),
            ),
          ],
        );
      },
    );
  }
}

class _QuickRow extends StatelessWidget {
  const _QuickRow({
    required this.hasUrl,
    required this.isLoading,
    required this.isBookmarked,
    required this.onNewTab,
    required this.onPrivateTab,
    required this.onReloadStop,
    required this.onBookmark,
  });

  final bool hasUrl;
  final bool isLoading;
  final bool isBookmarked;
  final VoidCallback onNewTab;
  final VoidCallback onPrivateTab;
  final VoidCallback onReloadStop;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _QuickAction(icon: Icons.add, label: '新标签页', onTap: onNewTab),
          _QuickAction(
              icon: Icons.shield_outlined, label: '隐私标签', onTap: onPrivateTab),
          _QuickAction(
            icon: isLoading ? Icons.close : Icons.refresh,
            label: isLoading ? '停止' : '刷新',
            onTap: hasUrl ? onReloadStop : null,
          ),
          _QuickAction(
            icon: isBookmarked ? Icons.star : Icons.star_border,
            label: isBookmarked ? '已收藏' : '收藏',
            onTap: hasUrl ? onBookmark : null,
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: enabled
                    ? scheme.onSurface
                    : scheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: enabled
                    ? scheme.onSurface
                    : scheme.onSurfaceVariant.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
