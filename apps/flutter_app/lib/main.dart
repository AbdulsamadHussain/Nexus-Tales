import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/routing/app_router.dart';
import 'app/theme/theme.dart';

void main() {
  runApp(const ProviderScope(child: NexusTalesApp()));
}

class NexusTalesApp extends StatelessWidget {
  const NexusTalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Nexus Tales',
      theme: AppTheme.darkTheme,
      routerConfig: createRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}

