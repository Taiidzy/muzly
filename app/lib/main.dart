import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/services.dart';
import 'providers/providers.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'utils/app_theme.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.i('════════════════════════════════════════', tag: 'App');
  Logger.i('Muzly App Starting...', tag: 'App');
  Logger.i('════════════════════════════════════════', tag: 'App');

  // Initialize services
  Logger.d('Initializing services...', tag: 'App');
  await ApiConfig.load();
  final apiService = ApiService();
  final audioPlayerService = AudioPlayerService(apiService: apiService);
  Logger.d('Services initialized', tag: 'App');

  runApp(
    MuzlyApp(apiService: apiService, audioPlayerService: audioPlayerService),
  );
}

/// Main App Widget
class MuzlyApp extends StatelessWidget {
  final ApiService apiService;
  final AudioPlayerService audioPlayerService;

  const MuzlyApp({
    super.key,
    required this.apiService,
    required this.audioPlayerService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth provider (must be first)
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService: apiService),
        ),
        // Player provider
        ChangeNotifierProvider(
          create: (context) => PlayerProvider(
            apiService: apiService,
            audioService: audioPlayerService,
          ),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // Check if user is logged in
          if (auth.isLoggedIn) {
            return MaterialApp(
              title: 'Muzly',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              home: const MainScreen(),
            );
          } else {
            return MaterialApp(
              title: 'Muzly',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              home: const LoginScreen(),
            );
          }
        },
      ),
    );
  }
}
