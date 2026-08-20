/// App-wide configuration.
///
/// Values are resolved in this order:
///   1. `--dart-define` flags passed at build/run time, e.g.
///      `flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co`
///   2. [LocalConfig] (lib/utils/local_config.dart) — a gitignored file where
///      you paste your real credentials once so you don't need flags.
///
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ... \
///   --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com \
///   --dart-define=GOOGLE_ANDROID_CLIENT_ID=xxx.apps.googleusercontent.com \
///   --dart-define=GOOGLE_IOS_CLIENT_ID=xxx.apps.googleusercontent.com \
///   --dart-define=GOOGLE_MAPS_ANDROID_API_KEY=AIza...
/// ```
///
/// For Android Maps, the key must also be set in `android/local.properties`
/// (`GOOGLE_MAPS_ANDROID_API_KEY=AIza...`) — the native map reads it from the
/// merged AndroidManifest at build time.
import 'local_config.dart';

class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: LocalConfig.supabaseUrl,
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: LocalConfig.supabaseAnonKey,
  );

  /// Web OAuth client ID — used as `serverClientId` for native Google Sign-In.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: LocalConfig.googleWebClientId,
  );

  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: LocalConfig.googleAndroidClientId,
  );

  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: LocalConfig.googleIosClientId,
  );

  static const String googleMapsAndroidApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_ANDROID_API_KEY',
    defaultValue: LocalConfig.googleMapsAndroidApiKey,
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.startsWith('SUPABASE_') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.startsWith('SUPABASE_');

  static bool get isGoogleSignInConfigured =>
      googleWebClientId.isNotEmpty && !googleWebClientId.startsWith('GOOGLE_WEB_');

  static bool get isGoogleMapsConfigured =>
      googleMapsAndroidApiKey.isNotEmpty &&
      !googleMapsAndroidApiKey.startsWith('GOOGLE_MAPS_');

  /// Fallback camera position (India) before GPS is available — never stored
  /// as a complaint location unless the user explicitly selects it.
  static const double fallbackLatitude = 23.0225;
  static const double fallbackLongitude = 72.5714;
}
