/// =============================================================================
/// YOUR LOCAL CONFIGURATION — fill in your real values here.
///
/// This file is listed in .gitignore, so it is NEVER committed. Paste your
/// values below and run the app normally (no --dart-define flags needed).
///
/// If you prefer, you can instead pass --dart-define flags at build/run time
/// (e.g. `flutter run --dart-define=SUPABASE_URL=...`). Dart-define values
/// take precedence over this file.
///
/// How to find each value:
///   SUPABASE_URL             Supabase Dashboard → Settings → API → Project URL
///   SUPABASE_ANON_KEY        Supabase Dashboard → Settings → API → anon public key
///   GOOGLE_WEB_CLIENT_ID     Google Cloud Console → Credentials → OAuth 2.0
///                            Client IDs → pick the entry of type "Web application"
///   GOOGLE_ANDROID_CLIENT_ID ... pick the entry of type "Android"
///   GOOGLE_IOS_CLIENT_ID     ... pick the entry of type "iOS"
///   GOOGLE_MAPS_ANDROID_API_KEY — ALSO add this one to android/local.properties:
///                            GOOGLE_MAPS_ANDROID_API_KEY=AIza...
///                            (Android renders maps from the manifest, so it
///                            needs it there too — the value below only drives
///                            the in-app "maps configured" check.)
/// =============================================================================
class LocalConfig {
  LocalConfig._();

  static const String supabaseUrl = 'https://xwxhqbwjdpkbsiubernj.supabase.co';

  static const String supabaseAnonKey = 'sb_publishable_qOvRa1G818pIoQD1EObsOQ_t3Xm_QhP';

  static const String googleWebClientId = '630754582577-4tqrovmuja8ebep35h8i0he7bj70j5tb.apps.googleusercontent.com';

  static const String googleAndroidClientId = '630754582577-t90bhgkeflb6duh8j501t2ig0ll4igf1.apps.googleusercontent.com';

  static const String googleIosClientId = '630754582577-fi885iar8id95q047s8s3klo7d50n84h.apps.googleusercontent.com';

  static const String googleMapsAndroidApiKey = 'AIzaSyAUQlznf2ulo9oaMnr8t-Kdjkyj8eZxw_g';
}
