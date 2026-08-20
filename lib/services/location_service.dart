import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

/// Result of a one-shot GPS fetch — mirrors the old geolocator wrapper API.
class LocationResult {
  const LocationResult({
    this.position,
    this.isPermanentlyDenied = false,
    this.isServiceDisabled = false,
    this.errorMessage,
  });

  final Position? position;
  final bool isPermanentlyDenied;
  final bool isServiceDisabled;
  final String? errorMessage;

  bool get isSuccess => position != null;
}

/// A worker's last known GPS position, shared to Supabase so the Head's
/// separate app process can see it (in-memory stores never crossed devices).
class WorkerLocation {
  const WorkerLocation({
    required this.workerId,
    required this.latitude,
    required this.longitude,
    required this.isSharing,
    required this.updatedAt,
  });

  factory WorkerLocation.fromJson(Map<String, dynamic> json) {
    return WorkerLocation(
      workerId: json['worker_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isSharing: json['is_sharing'] as bool? ?? false,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  final String workerId;
  final double latitude;
  final double longitude;
  final bool isSharing;
  final DateTime updatedAt;

  /// True when the worker is actively sharing AND the position is fresh
  /// (updated within the last 60 seconds).
  bool get isLive {
    if (!isSharing) return false;
    return DateTime.now().toUtc().difference(updatedAt) <
        const Duration(seconds: 60);
  }
}

/// Device GPS access + Supabase-backed worker live locations.
///
/// RLS keeps the shared locations cross-device and safe: the worker upserts
/// only their own row (matched via `profiles.worker_id`), the Head reads
/// every row.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // Device GPS (one-shot fetch, used by the complaint map picker)
  // ---------------------------------------------------------------------------

  /// Fetches the current GPS position, handling permission and service state.
  Future<LocationResult> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(isServiceDisabled: true,
            errorMessage: 'Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(
              errorMessage: 'Location permission is denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          isPermanentlyDenied: true,
          errorMessage:
              'Location permission is permanently denied. Enable it in Settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LocationResult(position: position);
    } on Object catch (e) {
      return LocationResult(errorMessage: '$e');
    }
  }

  /// Returns the current position WITHOUT prompting for permission — used by
  /// read-only features like the home dashboard's "nearby issues" list.
  /// Returns null when permission was not granted, GPS is off, or the fetch
  /// fails, so callers never trigger an unwanted permission dialog.
  Future<Position?> tryGetCurrentPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } on Object {
      return null;
    }
  }

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  // ---------------------------------------------------------------------------
  // Worker live locations (Supabase-backed, Head sees them in real time)
  // ---------------------------------------------------------------------------

  /// Whether location sharing is ON. Lives here (not in the page) so every
  /// instance of the live-map page — the bottom-nav tab AND the dashboard's
  /// Quick Action — shows the SAME state.
  final ValueNotifier<bool> isSharing = ValueNotifier<bool>(false);

  /// Flips true when the last upsert failed (e.g. database not set up yet).
  final ValueNotifier<bool> shareFailed = ValueNotifier<bool>(false);

  /// The position currently being shared, shared across all page instances.
  final ValueNotifier<Position?> sharedPosition = ValueNotifier<Position?>(null);

  Timer? _shareTimer;

  /// Worker ID of the currently signed-in worker, or null if the account has
  /// no Worker ID yet (Head has not generated one).
  String? get currentWorkerId => AuthService.instance.user?.workerId;

  /// Starts periodic sharing (every 10 seconds) using the latest value of
  /// [sharedPosition]. Safe to call when already sharing — it just makes sure
  /// the timer is running.
  void startSharing() {
    isSharing.value = true;
    _shareNow();
    _shareTimer ??=
        Timer.periodic(const Duration(seconds: 10), (_) => _shareNow());
  }

  /// Stops the share timer and tells Supabase sharing stopped, so the Head
  /// sees "Paused"/"Offline" instead of a stale "Live".
  Future<void> stopSharing() async {
    _shareTimer?.cancel();
    _shareTimer = null;
    isSharing.value = false;
    try {
      await _client.rpc('stop_worker_location');
    } on Object catch (e) {
      debugPrint('Location stop failed: $e');
    }
  }

  /// Upserts the latest position. Delegates to the `share_worker_location`
  /// database function, which reads the Worker ID from the caller's OWN
  /// profile row — the client never sends a Worker ID, so it can never be
  /// rejected by an RLS mismatch and can never overwrite another worker's row.
  Future<void> _shareNow() async {
    final position = sharedPosition.value;
    if (position == null) return;
    try {
      await _client.rpc('share_worker_location', params: {
        'p_lat': position.latitude,
        'p_lng': position.longitude,
      });
      shareFailed.value = false;
    } on Object catch (e) {
      debugPrint('Location share failed: $e');
      shareFailed.value = true;
    }
  }

  /// All worker locations (Head view).
  Future<List<WorkerLocation>> fetchLocations() async {
    final rows = await _client
        .from('worker_locations')
        .select()
        .order('updated_at', ascending: false);
    return rows
        .map((row) => WorkerLocation.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  /// A single worker's location, or null if never shared.
  Future<WorkerLocation?> fetchLocationForWorker(String workerId) async {
    final row = await _client
        .from('worker_locations')
        .select()
        .eq('worker_id', workerId)
        .maybeSingle();
    if (row == null) return null;
    return WorkerLocation.fromJson(Map<String, dynamic>.from(row));
  }

  /// Removes a worker's location row (used by the Head when deleting a worker
  /// so no stale position keeps showing).
  Future<void> clearLocation(String workerId) async {
    await _client
        .from('worker_locations')
        .delete()
        .eq('worker_id', workerId);
  }
}
