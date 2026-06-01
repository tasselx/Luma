import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'features/browser/controllers/browser_controller.dart';
import 'features/browser/pages/browser_page.dart';

class LumaBrowserApp extends StatelessWidget {
  const LumaBrowserApp({super.key, required this.controller});

  final BrowserController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BrowserController>.value(
      value: controller,
      child: MaterialApp(
        title: 'Luma 浏览器',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const BrowserPage(),
      ),
    );
  }
}
