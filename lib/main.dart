import 'package:flutter/material.dart';
import 'core/router.dart';
import 'core/theme_provider.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  runApp(const CPIApp());
}

class CPIApp extends StatelessWidget {
  const CPIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CPI Portal',
      debugShowCheckedModeBanner: false,
      theme: AppThemeController.lightTheme,
      darkTheme: AppThemeController.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.welcome,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}