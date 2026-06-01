import 'package:flutter/material.dart';

import '../models/video_source.dart';

enum VideoInterceptChoice { nativePlayer, webPage, cancel }

/// Asks the user how to open a tapped direct video link.
class VideoInterceptDialog {
  static Future<VideoInterceptChoice?> show(
    BuildContext context, {
    required VideoSource source,
  }) {
    return showModalBottomSheet<VideoInterceptChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('检测到视频', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      source.url,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('原生播放'),
                onTap: () => Navigator.of(context)
                    .pop(VideoInterceptChoice.nativePlayer),
              ),
              ListTile(
                leading: const Icon(Icons.public),
                title: const Text('在网页中打开'),
                onTap: () =>
                    Navigator.of(context).pop(VideoInterceptChoice.webPage),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('取消'),
                onTap: () =>
                    Navigator.of(context).pop(VideoInterceptChoice.cancel),
              ),
            ],
          ),
        );
      },
    );
  }
}
