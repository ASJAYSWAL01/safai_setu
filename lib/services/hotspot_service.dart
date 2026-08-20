import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/complaint.dart';

/// Severity of a waste hotspot cluster.
enum HotspotLevel { low, medium, high }

extension HotspotLevelX on HotspotLevel {
  String get label {
    switch (this) {
      case HotspotLevel.low:
        return 'LOW';
      case HotspotLevel.medium:
        return 'MEDIUM';
      case HotspotLevel.high:
        return 'HIGH';
    }
  }
}

/// A geographic cluster of recent waste complaints.
class WasteHotspot {
  const WasteHotspot({
    required this.center,
    required this.complaintIds,
    required this.level,
  });

  /// Average latitude/longitude of the clustered complaints.
  final LatLng center;

  final List<String> complaintIds;

  final HotspotLevel level;

  int get complaintCount => complaintIds.length;
}

/// Detects waste hotspots from complaint data.
///
/// Pure Dart (no Flutter/plugin calls) so the clustering logic is trivially
/// unit-testable. Complaints within a [radiusMeters] geographic radius that
/// are connected (directly or transitively) form ONE cluster and ONE
/// hotspot circle — nearby complaints never produce duplicate overlapping
/// circles.
class HotspotService {
  HotspotService._();

  static final HotspotService instance = HotspotService._();

  /// The hotspot time window: complaints older than this are not eligible.
  static const Duration timeWindow = Duration(days: 7);

  /// Hotspot geographic radius (meters).
  static const double radiusMeters = 500;

  /// Rejected/cancelled complaints must not contribute to hotspot activity.
  static bool isEligibleStatus(ComplaintStatus status) =>
      status != ComplaintStatus.rejected;

  /// Severity thresholds: 1–2 LOW, 3–5 MEDIUM, 6+ HIGH.
  static HotspotLevel levelForCount(int count) {
    if (count >= 6) return HotspotLevel.high;
    if (count >= 3) return HotspotLevel.medium;
    return HotspotLevel.low;
  }

  /// Great-circle distance between two coordinates, in meters (Haversine).
  static double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusM = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusM * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;

  /// Computes hotspots from a complaint list.
  ///
  /// Eligibility:
  /// * created within the last [timeWindow] (7 days)
  /// * valid (non-null, in-range) coordinates
  /// * not rejected (resolved complaints still count — the hotspot reflects
  ///   recent waste-generation activity, not only currently unresolved waste)
  ///
  /// Clustering: connected-components over the 500 m radius graph. Each
  /// cluster produces exactly ONE hotspot centered at the average coordinate.
  List<WasteHotspot> detectHotspots(List<Complaint> complaints) {
    final now = DateTime.now();
    final cutoff = now.subtract(timeWindow);

    final eligible = <Complaint>[];
    for (final c in complaints) {
      if (!_hasValidCoordinates(c)) continue;
      if (c.dateReported.isBefore(cutoff)) continue;
      if (!isEligibleStatus(c.status)) continue;
      eligible.add(c);
    }

    if (eligible.isEmpty) return const [];

    final processed = List<bool>.filled(eligible.length, false);
    final hotspots = <WasteHotspot>[];

    for (var i = 0; i < eligible.length; i++) {
      if (processed[i]) continue;

      // BFS/connected-component from complaint i.
      final cluster = <int>[i];
      processed[i] = true;
      var head = 0;
      while (head < cluster.length) {
        final a = eligible[cluster[head]];
        head++;
        for (var j = 0; j < eligible.length; j++) {
          if (processed[j]) continue;
          final b = eligible[j];
          final d = distanceMeters(
            a.latitude!,
            a.longitude!,
            b.latitude!,
            b.longitude!,
          );
          if (d <= radiusMeters) {
            processed[j] = true;
            cluster.add(j);
          }
        }
      }

      hotspots.add(_buildHotspot(cluster.map((k) => eligible[k]).toList()));
    }

    return hotspots;
  }

  WasteHotspot _buildHotspot(List<Complaint> cluster) {
    var latSum = 0.0;
    var lngSum = 0.0;
    for (final c in cluster) {
      latSum += c.latitude!;
      lngSum += c.longitude!;
    }
    final count = cluster.length;
    final center = LatLng(latSum / count, lngSum / count);
    return WasteHotspot(
      center: center,
      complaintIds: cluster.map((c) => c.id).toList(),
      level: levelForCount(count),
    );
  }

  bool _hasValidCoordinates(Complaint c) {
    final lat = c.latitude;
    final lng = c.longitude;
    if (lat == null || lng == null) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    return true;
  }
}
