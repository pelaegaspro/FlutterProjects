import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_bootstrap.dart';
import 'core/app_theme.dart';
import 'providers/app_providers.dart';
import 'screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrapState = await AppBootstrap.initialize();

  runApp(
    ProviderScope(
      overrides: [
        appBootstrapProvider.overrideWithValue(bootstrapState),
      ],
      child: const WizardXiApp(),
    ),
  );
}

class WizardXiApp extends StatelessWidget {
  const WizardXiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wizard XI',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}
