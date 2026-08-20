import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../theme/map_style.dart';
import '../utils/config.dart';

/// Interactive map for selecting / confirming a complaint location.
class ComplaintMapPicker extends StatefulWidget {
  const ComplaintMapPicker({
    super.key,
    this.initialPosition,
    this.height = 260,
    this.onPositionChanged,
  });

  final LatLng? initialPosition;
  final double height;
  final ValueChanged<LatLng>? onPositionChanged;

  @override
  State<ComplaintMapPicker> createState() => _ComplaintMapPickerState();
}

class _ComplaintMapPickerState extends State<ComplaintMapPicker> {
  GoogleMapController? _controller;
  LatLng? _selected;
  bool _loadingLocation = false;
  String? _statusMessage;
  bool _permanentlyDenied = false;
  bool _serviceDisabled = false;
  bool _locationGranted = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialPosition;
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

  Future<void> _useCurrentLocation() async {
    setState(() {
      _loadingLocation = true;
      _statusMessage = 'Detecting your location...';
      _permanentlyDenied = false;
      _serviceDisabled = false;
    });

    final result = await LocationService.instance.getCurrentPosition();
    if (!mounted) return;

    setState(() {
      _loadingLocation = false;
      _permanentlyDenied = result.isPermanentlyDenied;
      _serviceDisabled = result.isServiceDisabled;
      _statusMessage =
          result.isSuccess ? 'Location selected' : result.errorMessage;
      if (result.isSuccess) {
        _selected =
            LatLng(result.position!.latitude, result.position!.longitude);
        _locationGranted = true;
        widget.onPositionChanged?.call(_selected!);
      }
    });

    if (result.isSuccess && _controller != null) {
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(_selected!, 16),
      );
    }
  }

  Future<void> _openSettings() async {
    if (_serviceDisabled) {
      await LocationService.instance.openLocationSettings();
    } else {
      await LocationService.instance.openAppSettings();
    }
    if (mounted) await _useCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isGoogleMapsConfigured) {
      return _buildMapsNotConfigured();
    }

    final target = _selected ??
        LatLng(AppConfig.fallbackLatitude, AppConfig.fallbackLongitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: target, zoom: 15),
              // Let the user pan and pinch-zoom the map with their fingers,
              // even though it sits inside a scrollable form.
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer()),
              },
              myLocationEnabled: _locationGranted,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _controller = controller;
                _applyMapStyle();
              },
              onTap: (position) {
                setState(() {
                  _selected = position;
                  _statusMessage = 'Location selected';
                });
                widget.onPositionChanged?.call(position);
              },
              markers: _selected == null
                  ? {}
                  : {
                      Marker(
                        markerId: const MarkerId('complaint'),
                        position: _selected!,
                        draggable: true,
                        onDragEnd: (position) {
                          setState(() => _selected = position);
                          widget.onPositionChanged?.call(position);
                        },
                      ),
                    },
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_statusMessage != null)
          Text(
            _statusMessage!,
            style: TextStyle(
              color: _statusMessage == 'Location selected'
                  ? AppColors.primaryGreen
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        if (_selected != null) ...[
          const SizedBox(height: 4),
          Text(
            'Latitude: ${_selected!.latitude.toStringAsFixed(6)}  •  Longitude: ${_selected!.longitude.toStringAsFixed(6)}',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _loadingLocation ? null : _useCurrentLocation,
              icon: _loadingLocation
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryGreen,
                      ),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: Text(
                _loadingLocation ? 'Detecting...' : 'Use Current Location',
              ),
            ),
            if (_permanentlyDenied || _serviceDisabled)
              OutlinedButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Open Settings'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Safai Setu uses your location to identify the exact waste location so workers can find it. Tap the map or drag the marker to adjust.',
          style: TextStyle(
              fontSize: 12, color: AppColors.textSecondary, height: 1.35),
        ),
      ],
    );
  }

  Widget _buildMapsNotConfigured() {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 40, color: AppColors.primaryGreen),
          const SizedBox(height: 12),
          const Text(
            'Google Maps is not configured.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Set GOOGLE_MAPS_ANDROID_API_KEY in android/local.properties and rebuild.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
