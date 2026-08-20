import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../theme/map_style.dart';
import '../utils/config.dart';
import 'map_placeholder.dart';

class LiveMapMarker {
  const LiveMapMarker(
    this.position, {
    this.id,
    this.label,
    this.icon,
    this.color,
    this.number,
  });

  final LatLng position;

  /// Optional unique key. Without it, two markers at the exact same
  /// coordinates would collide (same MarkerId) and overwrite each other.
  final String? id;
  final String? label;
  final IconData? icon;
  final Color? color;

  /// When set, the marker icon shows this number instead of an icon glyph
  /// (used for numbered route stops).
  final int? number;
}

/// A straight-line polyline overlay (e.g. an optimized visiting sequence).
class LiveMapPolyline {
  const LiveMapPolyline({
    required this.id,
    required this.points,
    required this.color,
    this.width = 4,
  });

  final String id;
  final List<LatLng> points;
  final Color color;
  final int width;
}

/// A semi-transparent circle overlay (e.g. a waste hotspot).
class LiveMapCircle {
  const LiveMapCircle({
    required this.id,
    required this.center,
    required this.radiusMeters,
    required this.color,
    this.label,
  });

  final String id;
  final LatLng center;

  /// Circle radius in meters.
  final double radiusMeters;
  final Color color;

  /// Shown in the info bubble / legend. E.g. 'HIGH · 8 complaints'.
  final String? label;
}

/// Shows a real Google Map when [AppConfig.googleMapsAndroidApiKey] is configured.
/// Otherwise falls back to an offline styled map that still displays the
/// marker coordinates, so the app works without any API key.
class LiveMapView extends StatelessWidget {
  const LiveMapView({
    super.key,
    required this.height,
    required this.markers,
    this.center,
    this.title,
    this.showUserLocation = true,
    this.circles = const [],
    this.onCircleTap,
    this.polylines = const [],
    this.initialBounds,
    this.cameraTarget,
  });

  final double height;
  final List<LiveMapMarker> markers;
  final LatLng? center;
  final String? title;
  final bool showUserLocation;

  /// Optional circle overlays (e.g. waste hotspots). Rendered under the
  /// markers on the real Google Map.
  final List<LiveMapCircle> circles;

  /// Called when a circle overlay is tapped (e.g. to show hotspot details).
  final void Function(LiveMapCircle circle)? onCircleTap;

  /// Optional straight-line polylines (e.g. an optimized route).
  final List<LiveMapPolyline> polylines;

  /// When set, the camera fits these bounds once the map is ready (used to
  /// show the whole optimized route at once).
  final LatLngBounds? initialBounds;

  /// When this value changes, the camera animates to it — lets buttons like
  /// "Get My Coordinates" move the map back to a spot.
  final LatLng? cameraTarget;

  bool get _hasRealMap => AppConfig.googleMapsAndroidApiKey.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasRealMap) {
      return _RealGoogleMap(
        height: height,
        center: center ?? (markers.isNotEmpty ? markers.first.position : null),
        markers: markers,
        circles: circles,
        onCircleTap: onCircleTap,
        polylines: polylines,
        initialBounds: initialBounds,
        cameraTarget: cameraTarget,
        showUserLocation: showUserLocation,
      );
    }

    // Offline fallback — no API key configured.
    return Column(
      children: [
        MapPlaceholder(
          height: height,
          title: title ?? 'Live Map View',
          showLegend: true,
          showHotspots: circles.isNotEmpty,
          showUserLocation: showUserLocation,
        ),
        if (circles.isNotEmpty) _offlineHotspotLegend(circles),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coordinates',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              ...markers.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: m.color ?? AppColors.primaryGreen),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${m.label ?? 'Point'}: ${m.position.latitude.toStringAsFixed(6)}, ${m.position.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _offlineHotspotLegend(List<LiveMapCircle> circles) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hotspots (${circles.length})',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          ...circles.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: c.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        c.label ?? c.id,
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

/// Real Google Map that renders custom (colored icon) markers. Marker icons
/// are drawn off-thread into PNG bytes, so this is a StatefulWidget that
/// builds the descriptors before showing the map.
class _RealGoogleMap extends StatefulWidget {
  const _RealGoogleMap({
    required this.height,
    required this.markers,
    required this.center,
    required this.showUserLocation,
    required this.circles,
    this.onCircleTap,
    this.polylines = const [],
    this.initialBounds,
    this.cameraTarget,
  });

  final double height;
  final List<LiveMapMarker> markers;
  final LatLng? center;
  final bool showUserLocation;
  final List<LiveMapCircle> circles;
  final void Function(LiveMapCircle circle)? onCircleTap;
  final List<LiveMapPolyline> polylines;
  final LatLngBounds? initialBounds;

  /// When this value changes, the camera animates to it — lets buttons like
  /// "Get My Coordinates" move the map back to a spot.
  final LatLng? cameraTarget;

  @override
  State<_RealGoogleMap> createState() => _RealGoogleMapState();
}

class _RealGoogleMapState extends State<_RealGoogleMap> {
  Map<String, BitmapDescriptor> _icons = {};
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    _buildIcons();
    // Re-apply the map style when the user toggles dark / light theme.
    ThemeService.instance.isDark.addListener(_applyMapStyle);
  }

  @override
  void dispose() {
    ThemeService.instance.isDark.removeListener(_applyMapStyle);
    super.dispose();
  }

  Future<void> _applyMapStyle() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.setMapStyle(MapTheme.styleForCurrentTheme);
    } on Object {
      // Style is cosmetic — ignore failures.
    }
  }

  @override
  void didUpdateWidget(covariant _RealGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markers != widget.markers) _buildIcons();
    if (oldWidget.initialBounds != widget.initialBounds) _maybeFitBounds();
    // Move the camera to a newly requested target (e.g. "Get My Coordinates").
    final target = widget.cameraTarget;
    if (oldWidget.cameraTarget != target && target != null) {
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _applyMapStyle();
    _maybeFitBounds();
  }

  /// Moves the camera to frame all route points (worker + stops).
  void _maybeFitBounds() {
    final bounds = widget.initialBounds;
    final controller = _controller;
    if (bounds == null || controller == null) return;
    if (bounds.southwest == bounds.northeast) return; // single point
    controller.moveCamera(CameraUpdate.newLatLngBounds(bounds, 90));
  }

  Future<void> _buildIcons() async {
    final markers = widget.markers;
    final descriptors = <String, BitmapDescriptor>{};
    for (final m in markers) {
      final id = m.id ?? '${m.position.latitude},${m.position.longitude}';
      final color = m.color ?? AppColors.primaryGreen;
      try {
        descriptors[id] =
            await _markerIcon(m.icon, color, number: m.number);
      } on Object {
        // Fall back to a colored default pin if icon rendering fails.
        descriptors[id] =
            BitmapDescriptor.defaultMarkerWithHue(_hue(color));
      }
    }
    if (!mounted) return;
    setState(() => _icons = descriptors);
  }

  @override
  Widget build(BuildContext context) {
    final markers = widget.markers;
    final center = widget.center;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: center == null
            ? ColoredBox(
                color: AppColors.cardColor,
                child: const Center(
                  child: Text('No location data to show on the map.'),
                ),
              )
            : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: center,
                  zoom: 14,
                ),
                onMapCreated: _onMapCreated,
                // Let the map win finger gestures (pan, pinch-zoom, rotate,
                // tap) even when it sits inside a scrollable page — otherwise
                // only the +/- zoom buttons work.
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer()),
                },
                myLocationEnabled: widget.showUserLocation,
                myLocationButtonEnabled: widget.showUserLocation,
                markers: markers
                    .map((m) {
                      final id =
                          m.id ?? '${m.position.latitude},${m.position.longitude}';
                      return Marker(
                        markerId: MarkerId(id),
                        position: m.position,
                        infoWindow: InfoWindow(title: m.label ?? ''),
                        icon: _icons[id] ??
                            BitmapDescriptor.defaultMarkerWithHue(
                                _hue(m.color ?? AppColors.primaryGreen)),
                      );
                    })
                    .toSet(),
                circles: widget.circles
                    .map((c) => Circle(
                          circleId: CircleId(c.id),
                          center: c.center,
                          radius: c.radiusMeters,
                          fillColor: c.color.withOpacity(0.2),
                          strokeColor: c.color,
                          strokeWidth: 2,
                          onTap: widget.onCircleTap == null
                              ? null
                              : () => widget.onCircleTap!(c),
                        ))
                    .toSet(),
                polylines: widget.polylines
                    .map((p) => Polyline(
                          polylineId: PolylineId(p.id),
                          points: p.points,
                          color: p.color,
                          width: p.width,
                        ))
                    .toSet(),
              ),
      ),
    );
  }
}

double _hue(Color color) => HSVColor.fromColor(color).hue;

/// Draws a colored round marker with the given Material icon glyph centered
/// on it (e.g. a truck for live vehicles). Returns PNG bytes as a descriptor.
Future<BitmapDescriptor> _markerIcon(
  IconData? icon,
  Color color, {
  int? number,
}) async {
  const size = 72.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // White ring + colored body, so the icon reads on any map style.
  final ring = Paint()..color = Colors.white;
  canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 2, ring);

  final body = Paint()..color = color;
  canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 7, body);

  final glyph = icon ?? Icons.location_on;
  final textPainter = TextPainter(
    text: TextSpan(
      text: number != null
          ? '$number'
          : String.fromCharCode(glyph.codePoint),
      style: TextStyle(
        fontSize: number != null ? 26 : 34,
        fontWeight: number != null ? FontWeight.bold : FontWeight.normal,
        fontFamily: number != null ? null : glyph.fontFamily,
        color: Colors.white,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(
    canvas,
    Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    ),
  );

  final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}
