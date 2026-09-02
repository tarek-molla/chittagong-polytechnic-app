import 'package:flutter/material.dart';
import 'core/router.dart';
import 'core/theme_provider.dart';
import 'services/supabase_service.dart';
import 'widgets/loading_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  runApp(const CPIApp());
}

class CPIApp extends StatefulWidget {
  const CPIApp({super.key});

  @override
  State<CPIApp> createState() => _CPIAppState();
}

class _CPIAppState extends State<CPIApp> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: LoadingScreen(
            onComplete: () {
              setState(() => _isLoading = false);
            },
          ),
        ),
      );
    }
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