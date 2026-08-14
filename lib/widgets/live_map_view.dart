import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_theme.dart';
import '../utils/config.dart';
import 'map_placeholder.dart';

class LiveMapMarker {
  const LiveMapMarker(this.position, {this.label, this.icon, this.color});

  final LatLng position;
  final String? label;
  final IconData? icon;
  final Color? color;
}

/// Shows a real Google Map when [AppConfig.googleMapsApiKey] is configured.
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
  });

  final double height;
  final List<LiveMapMarker> markers;
  final LatLng? center;
  final String? title;
  final bool showUserLocation;

  bool get _hasRealMap => AppConfig.googleMapsApiKey.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasRealMap) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: center ?? markers.first.position,
              zoom: 14,
            ),
            myLocationEnabled: showUserLocation,
            myLocationButtonEnabled: showUserLocation,
            markers: markers
                .map((m) => Marker(
                      markerId: MarkerId(
                          '${m.position.latitude},${m.position.longitude}'),
                      position: m.position,
                      infoWindow: InfoWindow(title: m.label ?? ''),
                    ))
                .toSet(),
          ),
        ),
      );
    }

    // Offline fallback — no API key configured.
    return Column(
      children: [
        MapPlaceholder(
          height: height,
          title: title ?? 'Live Map View',
          showLegend: true,
          showHotspots: false,
          showUserLocation: showUserLocation,
        ),
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
}
