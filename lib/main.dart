import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/navigation/bottom_nav.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/firebase_service.dart';
import 'services/jump_ai_service.dart';
import 'services/notification_service.dart';
import 'services/nutrition_service.dart';
import 'services/training_recommendation_service.dart';
import 'theme/app_theme.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseService.bootstrap();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final firebaseEnabled = await FirebaseService.bootstrap();
  if (firebaseEnabled) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  final notificationService = NotificationService();
  await notificationService.initialize();

  final appState = AppState(
    firebaseService: FirebaseService(isCloudEnabled: firebaseEnabled),
    nutritionService: NutritionService(),
    jumpAiService: JumpAiService(),
    notificationService: notificationService,
    trainingRecommendationService: TrainingRecommendationService(),
  );
  await appState.initialize();

  runApp(JumpTrackApp(appState: appState));
}

class JumpTrackApp extends StatelessWidget {
  const JumpTrackApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        title: 'JumpTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppBootstrap(),
      ),
    );
  }
}

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        if (!app.isReady) {
          return const _SplashScreen();
        }
        if (!app.isAuthenticated) {
          return const AuthScreen();
        }
        if (app.needsOnboarding) {
          return const OnboardingScreen();
        }
        return const BottomNavShell();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.sports_volleyball_rounded, size: 78, color: AppTheme.primary),
              SizedBox(height: 18),
              Text(
                'JumpTrack',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 1.1),
              ),
              SizedBox(height: 8),
              Text(
                'Volleyball performance, nutrition, hydration and jump tracking',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.subtleText),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: AppTheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
