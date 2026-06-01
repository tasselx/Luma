import 'package:flutter/material.dart';

/// Confirms a direct-media download, showing the file name, source domain and
/// URL plus a reminder that the user must have the right to save the file.
class VideoDownloadConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String fileName,
    required String domain,
    required String url,
    String fileType = '',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('下载确认'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row(theme, '文件名', fileName.isEmpty ? '(未知)' : fileName),
              if (fileType.isNotEmpty) _row(theme, '类型', fileType),
              _row(theme, '来源', domain.isEmpty ? '(未知)' : domain),
              const SizedBox(height: 8),
              Text(
                url,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '仅在你有权保存该视频时继续。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('继续'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  static Widget _row(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
