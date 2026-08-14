/// App-wide configuration.
///
/// To enable the real Google Map view for workers, replace [googleMapsApiKey]
/// with your own Google Maps Platform API key (and set the same key in
/// `android/app/src/main/AndroidManifest.xml` under
/// `com.google.android.geo.API_KEY`).
///
/// While this key is empty, the app gracefully falls back to an offline
/// styled map placeholder that still shows live coordinates.
class AppConfig {
  static const String googleMapsApiKey = '';
}
