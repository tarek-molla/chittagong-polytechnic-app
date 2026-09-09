// =============================================================================
// lib/main.dart
// CPI - Campus Management System Entry Point
// =============================================================================

import 'package:flutter/material.dart';
import 'core/router.dart';
import 'core/theme_provider.dart';
import 'services/offline_storage_service.dart';
import 'services/supabase_service.dart';
import 'widgets/loading_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize offline local storage & network watcher
  await OfflineStorageService.init();
  
  // Initialize theme from storage
  AppThemeController.initialize();
  
  // Initialize Supabase backend
  await SupabaseService.initialize();

  runApp(const CPIApp());
}

class CPIApp extends StatelessWidget {
  const CPIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'CPI',
          debugShowCheckedModeBanner: false,
          theme: AppThemeController.lightTheme,
          darkTheme: AppThemeController.darkTheme,
          themeMode: themeMode,
          initialRoute: AppRoutes.welcome,
          onGenerateRoute: AppRouter.generateRoute,
          // Wrap whole App tree inside the LoadingScreen overlay
          builder: (context, child) {
            return LoadingScreen(
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}