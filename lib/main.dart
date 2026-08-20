import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/language_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';
import 'utils/config.dart';

/// Used by push-notification taps to open the right screen from anywhere.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Paint the Flutter splash screen immediately — no blocking native waits.
  // Firebase / Supabase are initialized in the background and the splash
  // stays visible until they finish (AuthGate shows it while initializing).
  runApp(const SafaiSetuApp());
  _initServices();
}

Future<void> _initServices() async {
  try {
    // Restore the saved language (English default) before the UI shows.
    await LanguageService.instance.load();

    // Firebase (FCM push notifications). Uses android/app/google-services.json.
    try {
      await Firebase.initializeApp();
      await NotificationService.instance.initialize(navigatorKey: navigatorKey);
    } on Object catch (e) {
      debugPrint('Firebase init failed (notifications disabled): $e');
    }

    if (AppConfig.isSupabaseConfigured) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      await AuthService.instance.initialize();
    } else {
      debugPrint(
        'Supabase not configured — set SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
      AuthService.instance.isInitializing.value = false;
    }
  } on Object catch (e) {
    // Never leave the app stuck on the splash screen.
    debugPrint('App init failed: $e');
    AuthService.instance.isInitializing.value = false;
  }
}

class SafaiSetuApp extends StatelessWidget {
  const SafaiSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageService.instance.current,
      builder: (context, language, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: ThemeService.instance.isDark,
          builder: (context, isDark, _) {
            AppColors.isDark = isDark;
            return MaterialApp(
              title: 'Safai Setu',
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              // Language picked on the login screen — the whole tree rebuilds
              // instantly when it changes (the outer ValueListenableBuilder).
              locale: language.locale,
              supportedLocales: const [
                Locale('en'),
                Locale('hi'),
                Locale('gu'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const AuthGate(),
            );
          },
        );
      },
    );
  }
}
