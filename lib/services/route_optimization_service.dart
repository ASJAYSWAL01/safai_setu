import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/collection_task.dart';

/// A single stop on the optimized route, carrying the direct (straight-line)
/// distance from the previous point — either the worker's start location or
/// the previous complaint.
class RouteStop {
  const RouteStop({
    required this.task,
    required this.distanceFromPreviousMeters,
  });

  final CollectionTask task;
  final double distanceFromPreviousMeters;
}

/// Result of the Nearest-Neighbor optimization.
///
/// NOTE: all distances here are APPROXIMATE DIRECT (straight-line) geographic
/// distances, NOT road distances. A production version can optionally feed
/// these ordered waypoints to a road-routing provider to convert the sequence
/// into actual road-following navigation.
class OptimizedRoute {
  const OptimizedRoute({
    required this.start,
    required this.stops,
    required this.totalDistanceMeters,
  });

  final LatLng start;
  final List<RouteStop> stops;

  /// Sum of the direct distances: start -> stop1 -> stop2 -> ...
  final double totalDistanceMeters;

  int get stopCount => stops.length;

  bool get isEmpty => stops.isEmpty;

  /// Full polyline points: worker start, then each stop in visiting order.
  List<LatLng> get polylinePoints => [
        start,
        for (final stop in stops)
          LatLng(stop.task.latitude, stop.task.longitude),
      ];
}

/// Computes the visiting order for a worker's assigned collection tasks using
/// the Nearest Neighbor heuristic on geographic (Haversine) distance.
///
/// Runs entirely on-device from task coordinates — no routing API, no OSRM,
/// no paid services, no network calls.
class RouteOptimizationService {
  RouteOptimizationService._();
  static final RouteOptimizationService instance =
      RouteOptimizationService._();

  static const double _earthRadiusMeters = 6371000.0;

  /// Great-circle (Haversine) distance between two coordinates, in meters.
  double distanceBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180.0;

  /// True when the task has usable coordinates. The model defaults missing
  /// coordinates to (0, 0), so that sentinel is treated as invalid.
  bool hasValidCoordinates(CollectionTask task) =>
      task.latitude != 0 || task.longitude != 0;

  /// Statuses the worker still needs to service (route candidates).
  bool isActive(CollectionTask task) =>
      task.status == CollectionTaskStatus.assigned ||
      task.status == CollectionTaskStatus.enRoute ||
      task.status == CollectionTaskStatus.collecting;

  /// Nearest-Neighbor route starting from [start].
  ///
  /// At every step the nearest *remaining* complaint to the CURRENT position
  /// is picked (NOT the complaint nearest to the worker's original location),
  /// the current position advances to that complaint, and the loop repeats.
  OptimizedRoute optimize({
    required LatLng start,
    required List<CollectionTask> tasks,
  }) {
    // Only active complaints with valid coordinates participate.
    final remaining =
        tasks.where(hasValidCoordinates).where(isActive).toList();
    final stops = <RouteStop>[];
    var current = start;
    var total = 0.0;

    while (remaining.isNotEmpty) {
      CollectionTask? best;
      var bestDistance = double.infinity;
      for (final task in remaining) {
        final d = distanceBetween(
          current.latitude,
          current.longitude,
          task.latitude,
          task.longitude,
        );
        if (d < bestDistance) {
          bestDistance = d;
          best = task;
        }
      }
      if (best == null) break;
      remaining.remove(best);
      stops.add(RouteStop(
        task: best,
        distanceFromPreviousMeters: bestDistance,
      ));
      total += bestDistance;
      current = LatLng(best.latitude, best.longitude);
    }

    return OptimizedRoute(
      start: start,
      stops: stops,
      totalDistanceMeters: total,
    );
  }
}
