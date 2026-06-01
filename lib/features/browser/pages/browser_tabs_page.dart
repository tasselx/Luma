import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ui_helpers.dart';
import '../controllers/browser_controller.dart';
import '../widgets/browser_tab_card.dart';

class BrowserTabsPage extends StatelessWidget {
  const BrowserTabsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BrowserController>();
    final tabs = controller.tabs;
    final current = controller.currentTab;

    return Scaffold(
      appBar: AppBar(
        title: Text('标签页 (${tabs.length})'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'closeOthers' && current != null) {
                controller.closeOtherTabs(current.id);
              } else if (value == 'closeNormal') {
                final ok = await confirmDialog(
                  context,
                  title: '关闭全部普通标签页',
                  message: '确定要关闭所有普通标签页吗？',
                  confirmLabel: '关闭',
                );
                if (ok) controller.closeAllNormalTabs();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'closeOthers',
                child: Text('关闭其他标签页'),
              ),
              const PopupMenuItem(
                value: 'closeNormal',
                child: Text('关闭全部普通标签页'),
              ),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: BrowserTabCard(
              tab: tab,
              isCurrent: tab.id == current?.id,
              onTap: () {
                controller.switchTab(tab.id);
                Navigator.of(context).pop();
              },
              onClose: () => controller.closeTab(tab.id),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('隐私标签'),
                  onPressed: () {
                    controller.newPrivateTab();
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('新建标签'),
                  onPressed: () {
                    controller.newTab();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
