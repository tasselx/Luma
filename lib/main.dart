import 'package:flutter/material.dart';

import 'app.dart';
import 'features/browser/controllers/browser_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = BrowserController();
  await controller.init();
  runApp(LumaBrowserApp(controller: controller));
}
