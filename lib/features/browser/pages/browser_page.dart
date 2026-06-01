import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/ui_helpers.dart';
import '../controllers/browser_controller.dart';
import '../models/browser_history_item.dart';
import '../models/browser_tab.dart';
import '../models/video_source.dart';
import '../widgets/browser_address_bar.dart';
import '../widgets/browser_bottom_toolbar.dart';
import '../widgets/browser_error_view.dart';
import '../widgets/browser_menu_button.dart';
import '../widgets/video_download_confirm_dialog.dart';
import '../widgets/video_intercept_dialog.dart';
import 'browser_home_page.dart';
import 'browser_tabs_page.dart';
import 'native_video_player_page.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  late final BrowserController _controller;
  bool _editingAddress = false;
  String _addressInput = '';

  @override
  void initState() {
    super.initState();
    _controller = context.read<BrowserController>();
    _controller.onVideoIntercept = _handleVideoIntercept;
    _controller.onDownloadIntercept = _handleDownloadIntercept;
    _controller.onMessage = _handleMessage;
  }

  @override
  void dispose() {
    // Detach hooks so a disposed State is never invoked.
    if (_controller.onVideoIntercept == _handleVideoIntercept) {
      _controller.onVideoIntercept = null;
    }
    if (_controller.onDownloadIntercept == _handleDownloadIntercept) {
      _controller.onDownloadIntercept = null;
    }
    if (_controller.onMessage == _handleMessage) {
      _controller.onMessage = null;
    }
    super.dispose();
  }

  void _handleMessage(String message) {
    if (mounted) showMessage(context, message);
  }

  Future<void> _handleVideoIntercept(VideoSource source) async {
    if (!mounted) return;
    final settings = _controller.settings;
    if (!settings.askBeforeOpeningNativeVideo) {
      _openNativePlayer(source);
      return;
    }
    final choice = await VideoInterceptDialog.show(context, source: source);
    if (!mounted || choice == null) return;
    switch (choice) {
      case VideoInterceptChoice.nativePlayer:
        _openNativePlayer(source);
      case VideoInterceptChoice.webPage:
        _controller.openUrlAllowingVideo(source.url);
      case VideoInterceptChoice.cancel:
        break;
    }
  }

  void _openNativePlayer(VideoSource source) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NativeVideoPlayerPage(source: source),
      ),
    );
  }

  Future<void> _handleDownloadIntercept(
      String url, String fileName, String domain) async {
    if (!mounted) return;
    final confirmed = await VideoDownloadConfirmDialog.show(
      context,
      fileName: fileName,
      domain: domain,
      url: url,
    );
    if (!confirmed || !mounted) return;
    final ok = await _controller.openExternalUrl(url);
    if (!mounted) return;
    if (ok) {
      showMessage(context, '已在外部应用打开下载');
    } else {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) showMessage(context, '无法外部打开，已复制链接');
    }
  }

  Future<void> _onWillPop() async {
    if (_editingAddress) {
      FocusScope.of(context).unfocus();
      return;
    }
    final webBack = await _controller.handleBackButton();
    if (webBack || !mounted) return;
    final tab = _controller.currentTab;
    if (tab != null && !tab.isHome) {
      _controller.goHomeCurrentTab();
      return;
    }
    if (_controller.tabCount > 1 && tab != null) {
      _controller.closeTab(tab.id);
      return;
    }
    await SystemNavigator.pop();
  }

  void _openTabs() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BrowserTabsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BrowserController>();
    final tab = controller.currentTab;
    final isLoading = controller.isCurrentLoading;
    final progress = controller.currentProgress;
    final showProgress = isLoading && progress > 0 && progress < 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onWillPop();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: BrowserAddressBar(
                  value: tab?.url ?? '',
                  isLoading: isLoading,
                  isPrivate: tab?.isPrivate ?? false,
                  isBookmarked: controller.isCurrentBookmarked(),
                  canBookmark: tab != null && tab.url.trim().isNotEmpty,
                  onSubmit: (value) {
                    setState(() => _editingAddress = false);
                    controller.openInput(value);
                  },
                  onReloadStop: () {
                    if (isLoading) {
                      controller.stopLoading();
                    } else {
                      controller.reload();
                    }
                  },
                  onToggleBookmark: () {
                    final added = controller.toggleBookmark();
                    showMessage(context, added ? '已收藏' : '已取消收藏');
                  },
                  onFocusChange: (focused) {
                    setState(() {
                      _editingAddress = focused;
                      if (focused) _addressInput = tab?.url ?? '';
                    });
                  },
                  onChanged: (text) => setState(() => _addressInput = text),
                ),
              ),
              SizedBox(
                height: 3,
                child: showProgress
                    ? LinearProgressIndicator(value: progress)
                    : null,
              ),
              Expanded(
                child: Stack(
                  children: [
                    _buildContent(controller, tab),
                    if (_editingAddress)
                      _SuggestionsPanel(
                        controller: controller,
                        query: _addressInput,
                        onSelect: (value) {
                          FocusScope.of(context).unfocus();
                          controller.openInput(value);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BrowserBottomToolbar(
          canGoBack: controller.canGoBack,
          canGoForward: controller.canGoForward,
          tabCount: controller.tabCount,
          onBack: controller.goBack,
          onForward: controller.goForward,
          onHome: () {
            FocusScope.of(context).unfocus();
            controller.goHomeCurrentTab();
          },
          onTabs: _openTabs,
          onMenu: () {
            FocusScope.of(context).unfocus();
            BrowserMenu.show(context, controller);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BrowserController controller, BrowserTab? tab) {
    if (tab == null) return const BrowserHomePage();
    if (tab.hasError) {
      return BrowserErrorView(
        url: tab.url,
        message: tab.errorMessage ?? '页面加载失败。',
        onRetry: () {
          if (tab.url.trim().isEmpty) {
            controller.goHomeCurrentTab();
          } else {
            controller.openUrl(tab.url);
          }
        },
        onCopyLink: () async {
          await Clipboard.setData(ClipboardData(text: tab.url));
          if (mounted) showMessage(context, '链接已复制');
        },
        onOpenExternally: () async {
          final ok = await controller.openExternalUrl(tab.url);
          if (mounted && !ok) showMessage(context, '无法打开外部浏览器');
        },
      );
    }
    if (tab.isHome) {
      return const BrowserHomePage();
    }
    return WebViewWidget(
      key: ValueKey(tab.id),
      controller: controller.webViewControllerFor(tab),
    );
  }
}

/// A simple suggestions panel shown over the content while editing the address
/// bar. Lists matching search history and history entries.
class _SuggestionsPanel extends StatelessWidget {
  const _SuggestionsPanel({
    required this.controller,
    required this.query,
    required this.onSelect,
  });

  final BrowserController controller;
  final String query;
  final void Function(String value) onSelect;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final searches = controller.searchHistory
        .where((k) => q.isEmpty || k.toLowerCase().contains(q))
        .take(10)
        .toList();
    final histories = controller.isCurrentPrivate
        ? const <BrowserHistoryItem>[]
        : controller.history
            .where((h) =>
                q.isEmpty ||
                h.url.toLowerCase().contains(q) ||
                h.title.toLowerCase().contains(q))
            .take(5)
            .toList();

    if (searches.isEmpty && histories.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surface,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (searches.isNotEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('搜索历史'),
            ),
          ...searches.map(
            (keyword) => ListTile(
              dense: true,
              leading: const Icon(Icons.history, size: 20),
              title:
                  Text(keyword, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => controller.removeSearchHistory(keyword),
              ),
              onTap: () => onSelect(keyword),
            ),
          ),
          if (histories.isNotEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('历史记录'),
            ),
          ...histories.map(
            (item) => ListTile(
              dense: true,
              leading: const Icon(Icons.public, size: 20),
              title: Text(
                item.title.isEmpty ? item.url : item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                item.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onSelect(item.url),
            ),
          ),
        ],
      ),
    );
  }
}
