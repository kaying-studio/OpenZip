import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/app_controller.dart';
import 'theme/app_theme.dart';
import 'ui/main_shell.dart';

class OpenZipApp extends StatelessWidget {
  const OpenZipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppController(),
      child: Consumer<AppController>(
        builder: (context, app, _) {
          return MaterialApp(
            title: app.displayTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: const MainShell(),
          );
        },
      ),
    );
  }
}
