import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/collection_task.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/route_optimization_service.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/call_utils.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/live_map_view.dart';

class WorkerLiveMapPage extends StatefulWidget {
  const WorkerLiveMapPage({super.key});

  @override
  State<WorkerLiveMapPage> createState() => _WorkerLiveMapPageState();
}

class _WorkerLiveMapPageState extends State<WorkerLiveMapPage> {
  final LocationService _location = LocationService.instance;

  bool _isLoading = false;
  bool _loadingTasks = true;
  bool _lastShareFailed = false;
  bool _optimizing = false;
  String _error = 'Location not fetched yet';
  List<CollectionTask> _tasks = [];
  OptimizedRoute? _route;
  LatLng? _cameraTarget;

  String? get _workerId => AuthService.instance.user?.workerId;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    // Sharing state lives in LocationService so every instance of this page
    // (bottom-nav tab AND the dashboard Quick Action) stays in sync.
    _location.isSharing.addListener(_onStateChanged);
    _location.shareFailed.addListener(_onStateChanged);
    _location.sharedPosition.addListener(_onStateChanged);
    _lastShareFailed = _location.shareFailed.value;
  }

  void _onStateChanged() {
    if (!mounted) return;
    final failed = _location.shareFailed.value;
    if (failed && !_lastShareFailed) {
      // Only nag once per failure, not every 10-second retry.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Could not share location (Worker ID: ${_workerId ?? "—"}). Check supabase_setup.sql was run and the Worker ID matches the database.'),
          backgroundColor: Colors.redAccent.shade200,
        ),
      );
    }
    _lastShareFailed = failed;
    setState(() {});
  }

  Future<void> _loadTasks() async {
    final workerId = _workerId;
    List<CollectionTask> tasks;
    if (workerId == null) {
      tasks = [];
    } else {
      try {
        tasks = await TaskService.instance.fetchTasksForWorker(workerId);
      } on Object {
        tasks = [];
      }
    }
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _loadingTasks = false;
    });
  }

  bool _isActiveTask(CollectionTask task) =>
      task.status == CollectionTaskStatus.assigned ||
      task.status == CollectionTaskStatus.enRoute ||
      task.status == CollectionTaskStatus.collecting;

  String _formatKm(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  /// Fetches the real GPS position, loads the worker's assigned tasks, runs
  /// Nearest-Neighbor optimization, and draws the numbered route + polyline.
  Future<void> _optimizeRoute() async {
    final workerId = _workerId;
    if (workerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No Worker ID on this account yet. Ask your Head.')),
      );
      return;
    }
    setState(() => _optimizing = true);
    try {
      // 1. Real device GPS (handles permission / service errors).
      final locResult = await _location.getCurrentPosition();
      final position = locResult.position;
      if (position == null) {
        var message = locResult.errorMessage ?? 'Could not fetch your location.';
        if (locResult.isPermanentlyDenied) {
          message =
              'Location permission is permanently denied. Enable it in app settings.';
        } else if (locResult.isServiceDisabled) {
          message =
              'Location services are disabled. Turn them on and try again.';
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        return;
      }
      // Keep the shared position in sync so the marker matches the route.
      _location.sharedPosition.value = position;

      // 2. Latest assigned tasks, only the ones still to be serviced.
      final tasks = await TaskService.instance.fetchTasksForWorker(workerId);
      final active = tasks.where(_isActiveTask).toList();
      if (active.isEmpty) {
        if (!mounted) return;
        setState(() => _route = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No active assigned complaints available for route optimization.'),
          ),
        );
        return;
      }

      // 3. Nearest-Neighbor from the real GPS start point.
      final start = LatLng(position.latitude, position.longitude);
      final route = RouteOptimizationService.instance
          .optimize(start: start, tasks: active);
      if (!mounted) return;
      setState(() => _route = route);
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Route optimization failed: $e')));
    } finally {
      if (mounted) setState(() => _optimizing = false);
    }
  }

  @override
  void dispose() {
    _location.isSharing.removeListener(_onStateChanged);
    _location.shareFailed.removeListener(_onStateChanged);
    _location.sharedPosition.removeListener(_onStateChanged);
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
      // Stored in the shared service so every page instance shows it, and the
      // next 10-second share tick uploads it.
      _location.sharedPosition.value = position;
      _error = '';
      // If the map is pointing somewhere else, glide the camera to this spot
      // (same behavior as the complaint-location picker).
      setState(() {
        _cameraTarget = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startSharing() {
    if (_location.sharedPosition.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fetch your location first.')),
      );
      return;
    }
    _location.startSharing();
  }

  void _stopSharing() {
    _location.stopSharing();
  }

  @override
  Widget build(BuildContext context) {
    final workerId = _workerId;
    final tasks = _tasks;
    final position = _location.sharedPosition.value;
    final sharing = _location.isSharing.value;
    final shareFailed = _location.shareFailed.value;

    if (workerId == null) {
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No Worker ID on this account yet.\nAsk your Head to generate one before sharing your location.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      );
    }

    if (_loadingTasks) {
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final route = _route;
    final markers = <LiveMapMarker>[];
    if (position != null) {
      markers.add(LiveMapMarker(
        LatLng(position.latitude, position.longitude),
        label: 'My Location',
        icon: Icons.person_pin_circle,
        color: AppColors.primaryGreen,
      ));
    }
    final polylines = <LiveMapPolyline>[];
    LatLngBounds? bounds;
    if (route != null && route.stopCount > 0) {
      // Numbered route stops in visiting order.
      for (var i = 0; i < route.stops.length; i++) {
        final stop = route.stops[i];
        markers.add(LiveMapMarker(
          LatLng(stop.task.latitude, stop.task.longitude),
          id: stop.task.id,
          label: '${i + 1}. ${stop.task.title}',
          number: i + 1,
          color: const Color(0xFF1565C0),
        ));
      }
      // Straight-line sequence: worker -> stop1 -> stop2 -> ...
      polylines.add(LiveMapPolyline(
        id: 'optimized-route',
        points: route.polylinePoints,
        color: const Color(0xFF1565C0),
        width: 4,
      ));
      // Frame everything (worker + stops) so the whole route is visible.
      final points = route.polylinePoints;
      var swLat = points.first.latitude;
      var neLat = points.first.latitude;
      var swLng = points.first.longitude;
      var neLng = points.first.longitude;
      for (final p in points.skip(1)) {
        if (p.latitude < swLat) swLat = p.latitude;
        if (p.latitude > neLat) neLat = p.latitude;
        if (p.longitude < swLng) swLng = p.longitude;
        if (p.longitude > neLng) neLng = p.longitude;
      }
      bounds = LatLngBounds(
        southwest: LatLng(swLat, swLng),
        northeast: LatLng(neLat, neLng),
      );
    } else {
      for (final task
          in tasks.where((t) => t.status != CollectionTaskStatus.completed)) {
        markers.add(LiveMapMarker(
          LatLng(task.latitude, task.longitude),
          label: task.title,
          icon: Icons.delete_outline,
          color: const Color(0xFF1565C0),
        ));
      }
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
                  color: shareFailed
                      ? Colors.redAccent.withOpacity(0.1)
                      : (sharing
                          ? AppColors.paleGreen
                          : Colors.orange.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: shareFailed
                        ? Colors.redAccent
                        : (sharing ? AppColors.primaryGreen : Colors.orange),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      shareFailed
                          ? Icons.error_outline
                          : (sharing ? Icons.sensors : Icons.sensors_off),
                      color: shareFailed
                          ? Colors.redAccent
                          : (sharing
                              ? AppColors.primaryGreen
                              : Colors.orange),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        shareFailed
                            ? 'Sharing failed — the Head cannot see you. Check the supabase_setup.sql was run.'
                            : (sharing
                                ? 'Live location is being shared with the Head'
                                : 'Location sharing is OFF'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: shareFailed
                              ? Colors.redAccent
                              : (sharing
                                  ? AppColors.darkGreen
                                  : Colors.orange),
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
                  polylines: polylines,
                  initialBounds: bounds,
                  cameraTarget: _cameraTarget,
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
                      label: sharing ? 'Stop Sharing' : 'Share Location',
                      icon: sharing
                          ? Icons.stop_circle_outlined
                          : Icons.share_location_outlined,
                      onPressed: sharing ? _stopSharing : _startSharing,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomButton(
                label: _optimizing
                    ? 'Optimizing route...'
                    : (route == null ? 'Optimize Route' : 'Re-Optimize Route'),
                icon: Icons.route,
                isLoading: _optimizing,
                onPressed: _optimizing ? null : _optimizeRoute,
              ),
              if (route != null) ...[const SizedBox(height: 16), _routeCard(route)],
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
                            position == null
                                ? 'Not available'
                                : '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (position != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Shared with Head · ${sharing ? "ON" : "OFF"}',
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

  Widget _routeCard(OptimizedRoute route) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Optimized Route',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _route = null),
                child: const Text('Clear'),
              ),
            ],
          ),
          Text(
            '${route.stopCount} ${route.stopCount == 1 ? 'Stop' : 'Stops'} · '
            'Approx. Direct Distance: ${_formatKm(route.totalDistanceMeters)}',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < route.stops.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: const Color(0xFF1565C0),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      route.stops[i].task.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '~${_formatKm(route.stops[i].distanceFromPreviousMeters)}',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  // Open Google Maps turn-by-turn directions to this stop.
                  IconButton(
                    tooltip: 'Directions to this stop',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints.tightFor(width: 32, height: 32),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.directions,
                        size: 20, color: Color(0xFF1565C0)),
                    onPressed: () => openDirections(
                      context,
                      latitude: route.stops[i].task.latitude,
                      longitude: route.stops[i].task.longitude,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
