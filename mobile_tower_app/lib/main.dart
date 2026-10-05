import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'services/api_config.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API configuration and load persistent backend URL.
  await ApiConfig.init();

  runApp(const MTMMSApp());
}

class MTMMSApp extends StatelessWidget {
  const MTMMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MTMMS - Mobile Tower Monitoring and Management System',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}