import 'package:flutter/material.dart';

import '../models/browser_tab.dart';

/// A card representing a single tab in the tabs overview page.
class BrowserTabCard extends StatelessWidget {
  const BrowserTabCard({
    super.key,
    required this.tab,
    required this.isCurrent,
    required this.onTap,
    required this.onClose,
  });

  final BrowserTab tab;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = tab.title.trim().isNotEmpty
        ? tab.title
        : (tab.url.trim().isNotEmpty ? tab.url : '新标签页');
    return Card(
      color: isCurrent
          ? scheme.primaryContainer.withOpacity(0.6)
          : scheme.surfaceContainerHighest.withOpacity(0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrent
            ? BorderSide(color: scheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              Icon(
                tab.isPrivate ? Icons.shield_outlined : Icons.public,
                size: 20,
                color:
                    tab.isPrivate ? scheme.tertiary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (tab.isPrivate)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              '隐私',
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.tertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tab.url.trim().isEmpty ? '首页' : tab.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (tab.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              IconButton(
                tooltip: '关闭',
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
