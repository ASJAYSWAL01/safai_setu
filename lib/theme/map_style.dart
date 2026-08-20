import 'app_theme.dart';

/// Dark-mode styling for the Google Map. Returns the JSON style string when
/// dark mode is active, or `null` (standard map) in light mode.
///
/// Apply it after the map is created:
/// ```dart
/// controller.setMapStyle(MapTheme.styleForCurrentTheme);
/// ```
class MapTheme {
  MapTheme._();

  static String? get styleForCurrentTheme =>
      AppColors.isDark ? _darkStyleJson : null;

  /// A dark "night" style: dark land, roads and water, light labels.
  static const String _darkStyleJson = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#242f3e"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8e9cae"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a1f28"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#35404f"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#c6d0dc"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#7d8899"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#2b4b33"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#4f8a5f"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#38414e"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212a37"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#9ca5b3"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3d4a5c"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#1f2835"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#17263c"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4e6d8c"}]},
  {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#7d8899"}]}
]
''';
}
