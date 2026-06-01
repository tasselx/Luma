import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ui_helpers.dart';
import '../controllers/browser_controller.dart';
import '../models/browser_search_engine.dart';
import 'browser_about_page.dart';

class BrowserSettingsPage extends StatelessWidget {
  const BrowserSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BrowserController>();
    final settings = controller.settings;
    final engine = controller.currentSearchEngine;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _sectionHeader(context, '通用'),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('默认搜索引擎'),
            subtitle: Text(engine.name),
            onTap: () => _selectSearchEngine(context, controller),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.grid_view_outlined),
            title: const Text('显示快捷入口'),
            value: settings.showQuickSites,
            onChanged: (v) =>
                controller.updateSettings(settings.copyWith(showQuickSites: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.tab_outlined),
            title: const Text('保留标签页'),
            subtitle: const Text('下次启动时恢复普通标签页'),
            value: settings.enableTabPersistence,
            onChanged: (v) => controller
                .updateSettings(settings.copyWith(enableTabPersistence: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.desktop_windows_outlined),
            title: const Text('桌面模式'),
            subtitle: const Text('使用桌面版 User-Agent'),
            value: settings.desktopMode,
            onChanged: (v) =>
                controller.updateSettings(settings.copyWith(desktopMode: v)),
          ),
          _sectionHeader(context, '视频与下载'),
          SwitchListTile(
            secondary: const Icon(Icons.play_circle_outline),
            title: const Text('视频直链原生播放'),
            value: settings.enableNativeVideoPlayer,
            onChanged: (v) => controller
                .updateSettings(settings.copyWith(enableNativeVideoPlayer: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.help_outline),
            title: const Text('点击视频前询问'),
            value: settings.askBeforeOpeningNativeVideo,
            onChanged: settings.enableNativeVideoPlayer
                ? (v) => controller.updateSettings(
                    settings.copyWith(askBeforeOpeningNativeVideo: v))
                : null,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.download_outlined),
            title: const Text('显示下载按钮'),
            value: settings.showDownloadButton,
            onChanged: (v) => controller
                .updateSettings(settings.copyWith(showDownloadButton: v)),
          ),
          _sectionHeader(context, '隐私与数据'),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('清空历史记录'),
            onTap: () => _clear(
              context,
              title: '清空历史记录',
              message: '确定要清空全部历史记录吗？',
              action: controller.clearHistory,
              done: '历史记录已清空',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.star_border),
            title: const Text('清空书签'),
            onTap: () => _clear(
              context,
              title: '清空书签',
              message: '确定要删除全部书签吗？',
              action: controller.clearBookmarks,
              done: '书签已清空',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.manage_search),
            title: const Text('清空搜索历史'),
            onTap: () => _clear(
              context,
              title: '清空搜索历史',
              message: '确定要清空全部搜索历史吗？',
              action: controller.clearSearchHistory,
              done: '搜索历史已清空',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('清空浏览数据'),
            subtitle: const Text('历史、搜索历史和下载记录'),
            onTap: () => _clear(
              context,
              title: '清空浏览数据',
              message: '将清空历史记录、搜索历史和下载记录，书签会保留。',
              action: controller.clearBrowsingData,
              done: '浏览数据已清空',
            ),
          ),
          _sectionHeader(context, '关于'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BrowserAboutPage()),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Future<void> _selectSearchEngine(
      BuildContext context, BrowserController controller) async {
    final selected = await showDialog<BrowserSearchEngine>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('选择搜索引擎'),
          children: controller.searchEngines.map((engine) {
            return RadioListTile<String>(
              value: engine.id,
              groupValue: controller.settings.searchEngineId,
              title: Text(engine.name),
              onChanged: (_) => Navigator.of(context).pop(engine),
            );
          }).toList(),
        );
      },
    );
    if (selected == null || !context.mounted) return;
    await controller.updateSettings(
        controller.settings.copyWith(searchEngineId: selected.id));
    if (context.mounted) showMessage(context, '已切换到 ${selected.name}');
  }

  Future<void> _clear(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() action,
    required String done,
  }) async {
    final ok = await confirmDialog(
      context,
      title: title,
      message: message,
      confirmLabel: '清空',
    );
    if (!ok || !context.mounted) return;
    await action();
    if (context.mounted) showMessage(context, done);
  }
}
