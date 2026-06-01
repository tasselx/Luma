import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ui_helpers.dart';
import '../controllers/browser_controller.dart';
import '../models/browser_history_item.dart';
import '../widgets/browser_empty_view.dart';
import '../widgets/history_list_item.dart';

class BrowserHistoryPage extends StatelessWidget {
  const BrowserHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BrowserController>();
    final history = controller.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              tooltip: '清空',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, controller),
            ),
        ],
      ),
      body: history.isEmpty
          ? const BrowserEmptyView(
              icon: Icons.history,
              title: '暂无历史记录',
              subtitle: '你访问过的网页会显示在这里',
            )
          : _HistoryList(controller: controller, history: history),
    );
  }

  Future<void> _confirmClear(
      BuildContext context, BrowserController controller) async {
    final ok = await confirmDialog(
      context,
      title: '清空历史记录',
      message: '确定要清空全部历史记录吗？此操作无法撤销。',
      confirmLabel: '清空',
    );
    if (!ok || !context.mounted) return;
    await controller.clearHistory();
    if (context.mounted) showMessage(context, '历史记录已清空');
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.controller, required this.history});

  final BrowserController controller;
  final List<BrowserHistoryItem> history;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay(history);
    return ListView.builder(
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped[index];
        if (entry.isHeader) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              entry.label!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          );
        }
        final item = entry.item!;
        return HistoryListItem(
          item: item,
          onTap: () {
            controller.openUrl(item.url);
            Navigator.of(context).pop();
          },
          onDelete: () => controller.removeHistory(item.url),
        );
      },
    );
  }

  List<_Row> _groupByDay(List<BrowserHistoryItem> items) {
    final rows = <_Row>[];
    String? currentKey;
    for (final item in items) {
      final key = _dayKey(item.visitedAt);
      if (key != currentKey) {
        currentKey = key;
        rows.add(_Row.header(_dayLabel(item.visitedAt)));
      }
      rows.add(_Row.item(item));
    }
    return rows;
  }

  String _dayKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    return '${date.year}-${_two(date.month)}-${_two(date.day)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');
}

class _Row {
  _Row.header(this.label)
      : item = null,
        isHeader = true;
  _Row.item(this.item)
      : label = null,
        isHeader = false;

  final bool isHeader;
  final String? label;
  final BrowserHistoryItem? item;
}
