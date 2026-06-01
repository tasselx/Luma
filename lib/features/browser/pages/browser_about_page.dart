import 'package:flutter/material.dart';

/// Static about / privacy page. No network access required.
class BrowserAboutPage extends StatelessWidget {
  const BrowserAboutPage({super.key});

  // Kept static to avoid a package_info_plus dependency for the build number.
  static const String appName = 'Luma 浏览器';
  static const String version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.travel_explore,
                size: 44,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(appName, style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '版本 $version',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('一个简洁的 Flutter 浏览器。', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          _section(
            theme,
            Icons.lock_outline,
            '隐私',
            '历史、书签、设置默认保存在本地，不会上传到任何服务器。隐私模式下不保存历史记录和搜索历史。',
          ),
          _section(
            theme,
            Icons.play_circle_outline,
            '视频功能',
            '仅支持普通公开直链视频（mp4、mov、webm、m4v 等）的原生播放与外部下载，不支持 DRM、blob、加密流或绕过任何访问限制。',
          ),
          _section(
            theme,
            Icons.download_outlined,
            '下载',
            '下载能力仅用于你有权访问和保存的普通直链资源，必要时会调用系统浏览器或外部下载器处理。',
          ),
        ],
      ),
    );
  }

  Widget _section(ThemeData theme, IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
