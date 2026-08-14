import '../models/app_models.dart';
import '../models/complaint.dart';

/// Central mock data source — replace with real backend services later.
class MockDataRepository {
  MockDataRepository._();
  static final MockDataRepository instance = MockDataRepository._();

  static const List<String> wasteCategories = [
    'Overflowing Dustbin',
    'Garbage on Road',
    'Illegal Dumping',
    'Uncollected Waste',
    'Plastic Waste',
    'Drainage / Sewage',
    'Construction Waste',
    'Other',
  ];

  static const String mockLocation = 'Sector 10, Gandhinagar';

  CitizenProfile get profile => const CitizenProfile(
        name: 'Ashish Kumar',
        mobile: '+91 98765 43210',
        email: 'citizen@safaisetu.in',
        totalComplaints: 4,
        resolvedComplaints: 3,
      );

  DashboardSummary get dashboardSummary => const DashboardSummary(
        myComplaints: 4,
        resolved: 3,
        inProgress: 1,
        nearbyIssues: 6,
      );

  List<Complaint> get complaints => List.unmodifiable(_complaints);
  final List<Complaint> _complaints = [
    Complaint(
      id: 'SS1024',
      category: 'Overflowing Dustbin',
      description:
          'The public dustbin near the community park is overflowing with mixed waste and causing foul smell.',
      location: 'Sector 10, Gandhinagar',
      dateReported: DateTime(2026, 8, 13),
      status: ComplaintStatus.inProgress,
      assignedTo: 'Municipal Waste Collection Team',
      estimatedResolution: '2 hours',
      timelineStep: 3,
    ),
    Complaint(
      id: 'SS1018',
      category: 'Garbage on Road',
      description:
          'Garbage bags were left on the roadside after collection, blocking pedestrian movement.',
      location: 'Sector 7, Gandhinagar',
      dateReported: DateTime(2026, 8, 10),
      status: ComplaintStatus.resolved,
      assignedTo: 'Municipal Waste Collection Team',
      estimatedResolution: 'Resolved',
      timelineStep: 4,
    ),
    Complaint(
      id: 'SS1012',
      category: 'Plastic Waste',
      description:
          'Large amount of plastic waste accumulated near the market area.',
      location: 'Sector 21, Gandhinagar',
      dateReported: DateTime(2026, 8, 8),
      status: ComplaintStatus.resolved,
      assignedTo: 'Green Clean Squad',
      estimatedResolution: 'Resolved',
      timelineStep: 4,
    ),
    Complaint(
      id: 'SS1005',
      category: 'Illegal Dumping',
      description: 'Construction debris dumped illegally on vacant plot.',
      location: 'Sector 5, Gandhinagar',
      dateReported: DateTime(2026, 8, 5),
      status: ComplaintStatus.pending,
      timelineStep: 0,
    ),
  ];

  List<NearbyIssue> get nearbyIssues => const [
        NearbyIssue(
          category: 'Overflowing Dustbin',
          location: 'Sector 10',
          distance: '250 m away',
          status: 'Reported',
        ),
        NearbyIssue(
          category: 'Garbage on Road',
          location: 'Sector 7',
          distance: '480 m away',
          status: 'In Progress',
        ),
        NearbyIssue(
          category: 'Plastic Waste',
          location: 'Sector 21',
          distance: '1.1 km away',
          status: 'Assigned',
        ),
      ];

  List<RecentActivity> get recentActivities => const [
        RecentActivity(
          message: 'Complaint SS1018 was resolved',
          icon: 'check',
          timeAgo: '2 hours ago',
        ),
        RecentActivity(
          message: 'Collection vehicle is approaching your area',
          icon: 'truck',
          timeAgo: '45 min ago',
        ),
        RecentActivity(
          message: 'Complaint SS1024 assigned to collection team',
          icon: 'assignment',
          timeAgo: '1 hour ago',
        ),
      ];

  List<AppNotificationItem> get notifications => const [
        AppNotificationItem(
          title: 'Complaint Assigned',
          message: 'Complaint SS1024 has been assigned to a collection team.',
          timeAgo: '1 hour ago',
          isRead: false,
        ),
        AppNotificationItem(
          title: 'Vehicle Approaching',
          message:
              'Waste collection vehicle will arrive in approximately 8 minutes.',
          timeAgo: '45 min ago',
          isRead: false,
        ),
        AppNotificationItem(
          title: 'Complaint Resolved',
          message: 'Your complaint SS1018 has been successfully resolved.',
          timeAgo: '2 hours ago',
          isRead: true,
        ),
      ];

  CollectionVehicle get activeVehicle => const CollectionVehicle(
        vehicleNumber: 'GJ-18-WM-1024',
        status: 'On Route',
        driver: 'Municipal Collection Team',
        distance: '1.2 km away',
        estimatedArrival: '8 minutes',
      );

  /// Mock/demo AI prediction data — not real ML output.
  List<WasteHotspot> get wasteHotspots => const [
        WasteHotspot(
          sector: 'Sector 10',
          riskLevel: HotspotRisk.high,
          expectedWastePercent: 85,
          recommendedCollection: 'Within 1 Hour',
        ),
        WasteHotspot(
          sector: 'Sector 7',
          riskLevel: HotspotRisk.medium,
          expectedWastePercent: 62,
          recommendedCollection: 'Within 3 Hours',
        ),
        WasteHotspot(
          sector: 'Sector 21',
          riskLevel: HotspotRisk.low,
          expectedWastePercent: 32,
          recommendedCollection: 'Normal Schedule',
        ),
      ];

  static const List<String> timelineSteps = [
    'Complaint Submitted',
    'Complaint Verified',
    'Worker Assigned',
    'Collection In Progress',
    'Resolved',
  ];

  /// Marks a complaint as resolved (called when a worker completes the
  /// linked collection task with proof).
  void resolveComplaint(String id) {
    final index = _complaints.indexWhere((c) => c.id == id);
    if (index == -1) return;
    _complaints[index] = _complaints[index].copyWith(
      status: ComplaintStatus.resolved,
      timelineStep: 4,
      assignedTo: 'Municipal Waste Collection Team',
      estimatedResolution: 'Resolved',
    );
  }

  Complaint? getComplaintById(String id) {
    try {
      return _complaints.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  String _nextComplaintId() {
    var maxNum = 1000;
    for (final complaint in _complaints) {
      final num = int.tryParse(complaint.id.replaceAll(RegExp(r'[^0-9]'), ''));
      if (num != null && num > maxNum) maxNum = num;
    }
    return 'SS${maxNum + 1}';
  }

  Complaint addComplaint({
    required String category,
    required String description,
    required String location,
    bool hasPhoto = false,
    String? photoPath,
    double? latitude,
    double? longitude,
  }) {
    final newComplaint = Complaint(
      id: _nextComplaintId(),
      category: category,
      description: description,
      location: location,
      dateReported: DateTime.now(),
      status: ComplaintStatus.pending,
      assignedTo: 'Municipal Waste Collection Team',
      estimatedResolution: '2 hours',
      timelineStep: 0,
      hasPhoto: hasPhoto,
      photoPath: photoPath,
      latitude: latitude,
      longitude: longitude,
    );
    _complaints.insert(0, newComplaint);
    return newComplaint;
  }
}
