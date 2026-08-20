class CitizenProfile {
  const CitizenProfile({
    required this.name,
    required this.mobile,
    required this.email,
    required this.totalComplaints,
    required this.resolvedComplaints,
  });

  final String name;
  final String mobile;
  final String email;
  final int totalComplaints;
  final int resolvedComplaints;
}

class DashboardSummary {
  const DashboardSummary({
    required this.myComplaints,
    required this.resolved,
    required this.inProgress,
    required this.nearbyIssues,
  });

  final int myComplaints;
  final int resolved;
  final int inProgress;
  final int nearbyIssues;
}

class NearbyIssue {
  const NearbyIssue({
    required this.category,
    required this.location,
    required this.distance,
    required this.status,
  });

  final String category;
  final String location;
  final String distance;
  final String status;
}

class RecentActivity {
  const RecentActivity({
    required this.message,
    required this.icon,
    required this.timeAgo,
  });

  final String message;
  final String icon;
  final String timeAgo;
}

class AppNotificationItem {
  const AppNotificationItem({
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.route,
  });

  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  /// Tap-routing payload (`screen|id`) used when the user opens the
  /// notification from the history list.
  final String? route;

  /// Human-friendly relative time, e.g. "just now", "5 min ago", "2 h ago".
  String get timeAgo {
    final diff = DateTime.now().toUtc().difference(createdAt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    final days = diff.inDays;
    return days == 1 ? '1 day ago' : '$days days ago';
  }
}

enum HotspotRisk { high, medium, low }

extension HotspotRiskX on HotspotRisk {
  String get label {
    switch (this) {
      case HotspotRisk.high:
        return 'High';
      case HotspotRisk.medium:
        return 'Medium';
      case HotspotRisk.low:
        return 'Low';
    }
  }
}

class WasteHotspot {
  const WasteHotspot({
    required this.sector,
    required this.riskLevel,
    required this.expectedWastePercent,
    required this.recommendedCollection,
  });

  final String sector;
  final HotspotRisk riskLevel;
  final int expectedWastePercent;
  final String recommendedCollection;
}

class CollectionVehicle {
  const CollectionVehicle({
    required this.vehicleNumber,
    required this.status,
    required this.driver,
    required this.distance,
    required this.estimatedArrival,
  });

  final String vehicleNumber;
  final String status;
  final String driver;
  final String distance;
  final String estimatedArrival;
}
