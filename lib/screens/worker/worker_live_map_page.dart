import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/app_repository.dart';
import '../../models/collection_task.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/live_map_view.dart';

class WorkerLiveMapPage extends StatefulWidget {
  const WorkerLiveMapPage({super.key});

  @override
  State<WorkerLiveMapPage> createState() => _WorkerLiveMapPageState();
}

class _WorkerLiveMapPageState extends State<WorkerLiveMapPage> {
  Position? _position;
  bool _isLoading = false;
  bool _sharing = false;
  String _error = 'Location not fetched yet';
  Timer? _shareTimer;

  String get _workerId => AuthService.instance.user!.workerId!;

  @override
  void dispose() {
    _shareTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permission is denied.';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permission is permanently denied.';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _position = position;
        _error = '';
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Shares the worker's live location with the Head every 10 seconds.
  void _startSharing() {
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fetch your location first.')),
      );
      return;
    }
    setState(() => _sharing = true);
    _share();
    _shareTimer?.cancel();
    _shareTimer = Timer.periodic(const Duration(seconds: 10), (_) => _share());
  }

  void _share() {
    final position = _position;
    if (position == null) return;
    AppRepository.instance.updateWorkerLocation(
      _workerId,
      position.latitude,
      position.longitude,
    );
  }

  void _stopSharing() {
    _shareTimer?.cancel();
    setState(() => _sharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = AppRepository.instance.tasksForWorker(_workerId);

    final markers = <LiveMapMarker>[];
    if (_position != null) {
      markers.add(LiveMapMarker(
        LatLng(_position!.latitude, _position!.longitude),
        label: 'My Location',
        icon: Icons.person_pin_circle,
        color: AppColors.primaryGreen,
      ));
    }
    for (final task
        in tasks.where((t) => t.status != CollectionTaskStatus.completed)) {
      markers.add(LiveMapMarker(
        LatLng(task.latitude, task.longitude),
        label: task.title,
        icon: Icons.delete_outline,
        color: const Color(0xFF1565C0),
      ));
    }

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'Live Location Map',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _sharing
                      ? AppColors.paleGreen
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _sharing ? AppColors.primaryGreen : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _sharing ? Icons.sensors : Icons.sensors_off,
                      color: _sharing ? AppColors.primaryGreen : Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _sharing
                            ? 'Live location is being shared with the Head'
                            : 'Location sharing is OFF',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _sharing ? AppColors.darkGreen : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (markers.isEmpty)
                AppCard(
                  child: Text(
                    _error.isEmpty
                        ? 'Tap "Get My Coordinates" to fetch your GPS location.'
                        : _error,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                LiveMapView(
                  height: 300,
                  title: 'My Live Location',
                  center: markers.first.position,
                  markers: markers,
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _fetchLocation,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 18),
                      label: Text(
                          _isLoading ? 'Fetching...' : 'Get My Coordinates'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      label: _sharing ? 'Stop Sharing' : 'Share Location',
                      icon: _sharing
                          ? Icons.stop_circle_outlined
                          : Icons.share_location_outlined,
                      onPressed: _sharing ? _stopSharing : _startSharing,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Coordinates',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.pin_drop_outlined,
                            color: AppColors.primaryGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _position == null
                                ? 'Not available'
                                : '${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (_position != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Shared with Head · ${_sharing ? "ON" : "OFF"}',
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
