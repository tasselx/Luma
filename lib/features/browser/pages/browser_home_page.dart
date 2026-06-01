import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/browser_controller.dart';
import '../models/browser_history_item.dart';
import '../widgets/quick_site_grid.dart';

/// The home content shown inside the browser when the current tab has no URL.
/// Embedded (not a Scaffold) — the surrounding [BrowserPage] owns the chrome.
class BrowserHomePage extends StatelessWidget {
  const BrowserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BrowserController>();
    final settings = controller.settings;
    final isPrivate = controller.isCurrentPrivate;
    final theme = Theme.of(context);

    final recentHistory = isPrivate
        ? const <BrowserHistoryItem>[]
        : controller.history.take(5).toList();
    final recentBookmarks = controller.bookmarks.take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              Icon(
                isPrivate ? Icons.shield_outlined : Icons.travel_explore,
                size: 56,
                color: isPrivate
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                isPrivate ? '隐私模式' : 'Luma 浏览器',
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (isPrivate) _PrivacyNotice(theme: theme),
        if (settings.showQuickSites) ...[
          const _SectionTitle(title: '常用网站'),
          const SizedBox(height: 12),
          QuickSiteGrid(
            sites: controller.quickSites,
            onTap: (site) => controller.openUrl(site.url),
          ),
          const SizedBox(height: 24),
        ],
        if (recentHistory.isNotEmpty) ...[
          const _SectionTitle(title: '最近访问'),
          const SizedBox(height: 4),
          ...recentHistory.map(
            (item) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, size: 20),
              title: Text(
                item.title.isEmpty ? item.url : item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                item.domain.isEmpty ? item.url : item.domain,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => controller.openUrl(item.url),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (recentBookmarks.isNotEmpty) ...[
          const _SectionTitle(title: '书签'),
          const SizedBox(height: 4),
          ...recentBookmarks.map(
            (item) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading:
                  Icon(Icons.star, size: 20, color: theme.colorScheme.primary),
              title: Text(
                item.title.isEmpty ? item.url : item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                item.domain.isEmpty ? item.url : item.domain,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => controller.openUrl(item.url),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: theme.colorScheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '隐私模式下不会保存历史记录和搜索历史，关闭标签页后不保留浏览痕迹。',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
