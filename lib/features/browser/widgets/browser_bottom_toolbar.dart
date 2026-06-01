import 'package:flutter/material.dart';

/// The bottom navigation toolbar: back, forward, home, tabs and menu.
class BrowserBottomToolbar extends StatelessWidget {
  const BrowserBottomToolbar({
    super.key,
    required this.canGoBack,
    required this.canGoForward,
    required this.tabCount,
    required this.onBack,
    required this.onForward,
    required this.onHome,
    required this.onTabs,
    required this.onMenu,
  });

  final bool canGoBack;
  final bool canGoForward;
  final int tabCount;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onHome;
  final VoidCallback onTabs;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                tooltip: '后退',
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: canGoBack ? onBack : null,
              ),
              IconButton(
                tooltip: '前进',
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: canGoForward ? onForward : null,
              ),
              IconButton(
                tooltip: '首页',
                icon: const Icon(Icons.home_outlined),
                onPressed: onHome,
              ),
              _TabCountButton(count: tabCount, onTap: onTabs),
              IconButton(
                tooltip: '菜单',
                icon: const Icon(Icons.menu),
                onPressed: onMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabCountButton extends StatelessWidget {
  const _TabCountButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: '标签页',
      onPressed: onTap,
      icon: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: scheme.onSurface, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: TextStyle(
            fontSize: count > 9 ? 10 : 12,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
