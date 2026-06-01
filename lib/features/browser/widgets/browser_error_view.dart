import 'package:flutter/material.dart';

/// Shown inside the browser content area when a page fails to load.
class BrowserErrorView extends StatelessWidget {
  const BrowserErrorView({
    super.key,
    required this.url,
    required this.message,
    required this.onRetry,
    required this.onCopyLink,
    required this.onOpenExternally,
  });

  final String url;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCopyLink;
  final VoidCallback onOpenExternally;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 64, color: scheme.error),
            const SizedBox(height: 20),
            Text(
              '页面加载失败',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            if (url.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                url,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: onCopyLink,
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('复制链接'),
                ),
                TextButton.icon(
                  onPressed: onOpenExternally,
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('系统浏览器打开'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
