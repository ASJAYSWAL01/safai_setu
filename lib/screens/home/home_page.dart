import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../l10n/app_strings.dart';
import '../../models/app_models.dart';
import '../../models/complaint.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_tour.dart';
import '../../widgets/awareness_banner.dart';
import '../../widgets/dashboard_action_card.dart';
import '../../widgets/list_tiles.dart';
import '../../widgets/app_card.dart';
import '../../widgets/summary_stat_card.dart';
import '../complaints/my_complaints_page.dart';
import '../complaints/report_complaint_page.dart';
import '../hotspots/waste_hotspot_page.dart';
import '../notifications/notifications_page.dart';
import '../profile/profile_page.dart';
import '../tracking/vehicle_tracking_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ComplaintStats? _stats;
  bool _loadingStats = true;

  List<NearbyIssue> _nearbyIssues = [];
  List<RecentActivity> _activities = [];
  bool _loadingHome = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadStats(), _loadHomeData()]);
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ComplaintService.instance.fetchMyStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _loadingStats = false;
        });
      }
    } on Object {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  /// Loads nearby waste issues (all citizens' complaints, sorted by distance
  /// from the user when GPS is available) and the user's recent activity
  /// (their own complaints, status-driven).
  Future<void> _loadHomeData() async {
    try {
      final position = await LocationService.instance.tryGetCurrentPosition();
      final myFuture = ComplaintService.instance.fetchMyComplaints();
      final allFuture =
          ComplaintService.instance.fetchComplaintsWithCoordinates();
      final my = await myFuture;
      final all = await allFuture;
      if (!mounted) return;
      setState(() {
        _nearbyIssues = _buildNearbyIssues(all, position);
        _activities = _buildActivities(my);
        _loadingHome = false;
      });
    } on Object {
      if (mounted) setState(() => _loadingHome = false);
    }
  }

  Future<void> _refresh() async {
    await _loadAll();
    if (mounted) setState(() {});
  }

  void _openReportComplaint(BuildContext context) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
              builder: (_) => const ReportComplaintPage()),
        )
        .then((_) => _loadAll());
  }

  void _openMyComplaints(BuildContext context) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
              builder: (_) => const MyComplaintsPage()),
        )
        .then((_) => _loadAll());
  }

  String _firstName() {
    final user = AuthService.instance.user;
    if (user == null) return 'Citizen';
    final parts = user.name.trim().split(' ');
    return parts.isEmpty ? 'Citizen' : parts.first;
  }

  /// Haversine distance in meters between [position] and a coordinate.
  double _metersBetween(Position position, double lat, double lng) {
    const earthRadius = 6371000.0;
    final dLat = _deg2rad(lat - position.latitude);
    final dLng = _deg2rad(lng - position.longitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(position.latitude)) *
            math.cos(_deg2rad(lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earthRadius * math.asin(math.sqrt(h));
  }

  double _deg2rad(double deg) => deg * math.pi / 180.0;

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m away';
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().toUtc().difference(time.toUtc());
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    final days = diff.inDays;
    return days == 1 ? '1 day ago' : '$days days ago';
  }

  /// Complaints with GPS coordinates, sorted by distance from the user's
  /// current position (when available) — the "Nearby Waste Issues" cards.
  List<NearbyIssue> _buildNearbyIssues(
    List<Complaint> complaints,
    Position? position,
  ) {
    final withCoords = complaints
        .where((c) => c.latitude != null && c.longitude != null)
        .toList();
    if (position != null) {
      withCoords.sort((a, b) => _metersBetween(
            position,
            a.latitude!,
            a.longitude!,
          ).compareTo(
            _metersBetween(position, b.latitude!, b.longitude!),
          ));
    }
    return withCoords.take(6).map((c) {
      final meters = position == null
          ? null
          : _metersBetween(position, c.latitude!, c.longitude!);
      return NearbyIssue(
        category: c.category,
        location: c.location,
        distance: meters == null ? 'Recently reported' : _formatDistance(meters),
        status: c.status.label,
      );
    }).toList();
  }

  /// The user's own complaints as a status-driven activity timeline.
  List<RecentActivity> _buildActivities(List<Complaint> my) {
    return my.take(8).map((c) {
      final (icon, message) = switch (c.status) {
        ComplaintStatus.pending => (
            'pending',
            'Complaint "${c.category}" reported — awaiting verification'),
        ComplaintStatus.assigned => (
            'assignment',
            'Complaint "${c.category}" assigned to a collection worker'),
        ComplaintStatus.inProgress => (
            'truck',
            'Collection in progress for "${c.category}" complaint'),
        ComplaintStatus.resolved => (
            'check',
            'Complaint "${c.category}" was resolved'),
        ComplaintStatus.rejected => (
            'rejected',
            'Complaint "${c.category}" was rejected'),
      };
      return RecentActivity(
        message: message,
        icon: icon,
        timeAgo: _timeAgo(c.dateReported),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primaryGreen,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Safai Setu',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppStrings.of(context).appTagline,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary
                                        .withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  '${AppStrings.of(context).hello}, '
                                  '${_firstName()} 👋',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const NotificationsPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.notifications_outlined),
                            tooltip: 'Notifications',
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ProfilePage(),
                                ),
                              );
                            },
                            child: _HomeAvatar(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const AwarenessBanner(),
                      const SizedBox(height: 20),
                      GridView.count(
                        key: TourKeys.statGridKey,
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.28,
                        children: [
                          SummaryStatCard(
                            key: TourKeys.statTileKeys[0],
                            icon: Icons.report_outlined,
                            label: AppStrings.of(context).myComplaints,
                            value: _loadingStats ? '…' : '${_stats?.total ?? 0}',
                            color: AppColors.primaryGreen,
                            onTap: () => _openMyComplaints(context),
                          ),
                          SummaryStatCard(
                            key: TourKeys.statTileKeys[1],
                            icon: Icons.check_circle_outline,
                            label: AppStrings.of(context).resolved,
                            value:
                                _loadingStats ? '…' : '${_stats?.resolved ?? 0}',
                            color: const Color(0xFF388E3C),
                            onTap: () => _openMyComplaints(context),
                          ),
                          SummaryStatCard(
                            key: TourKeys.statTileKeys[2],
                            icon: Icons.hourglass_top_rounded,
                            label: AppStrings.of(context).inProgress,
                            value: _loadingStats
                                ? '…'
                                : '${_stats?.inProgress ?? 0}',
                            color: const Color(0xFF3949AB),
                            onTap: () => _openMyComplaints(context),
                          ),
                          SummaryStatCard(
                            key: TourKeys.statTileKeys[3],
                            icon: Icons.near_me_outlined,
                            label: AppStrings.of(context).nearbyIssues,
                            value: _loadingHome ? '…' : '${_nearbyIssues.length}',
                            color: const Color(0xFFE65100),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const WasteHotspotPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(title: AppStrings.of(context).quickActions),
                      const SizedBox(height: 12),
                      DashboardActionCard(
                        icon: Icons.camera_alt_outlined,
                        title: AppStrings.of(context).reportWaste,
                        subtitle: AppStrings.of(context).reportWasteSub,
                        color: AppColors.primaryGreen,
                        onTap: () => _openReportComplaint(context),
                      ),
                      const SizedBox(height: 12),
                      DashboardActionCard(
                        icon: Icons.assignment_outlined,
                        title: AppStrings.of(context).myComplaints,
                        subtitle: AppStrings.of(context).trackYourIssues,
                        color: const Color(0xFF1565C0),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const MyComplaintsPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      DashboardActionCard(
                        icon: Icons.local_shipping_outlined,
                        title: AppStrings.of(context).trackVehicle,
                        subtitle: AppStrings.of(context).trackVehicleSub,
                        color: const Color(0xFF6A1B9A),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const VehicleTrackingPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      DashboardActionCard(
                        icon: Icons.map_outlined,
                        title: AppStrings.of(context).wasteHotspots,
                        subtitle: AppStrings.of(context).wasteHotspotsSub,
                        color: const Color(0xFFE65100),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const WasteHotspotPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      SectionHeader(
                          title: AppStrings.of(context).nearbyWasteIssues),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        child: _loadingHome
                            ? const Center(child: CircularProgressIndicator())
                            : _nearbyIssues.isEmpty
                                ? const _EmptyNearbyCard()
                                : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _nearbyIssues.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (context, index) {
                                      return NearbyIssueCard(
                                          issue: _nearbyIssues[index]);
                                    },
                                  ),
                      ),
                      const SizedBox(height: 28),
                      SectionHeader(title: AppStrings.of(context).recentActivity),
                      const SizedBox(height: 8),
                      if (_loadingHome)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_activities.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              Icon(Icons.history,
                                  size: 36, color: AppColors.textSecondary),
                              const SizedBox(height: 8),
                              Text(
                                AppStrings.of(context).noActivity,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._activities.map(
                          (activity) => ActivityTile(activity: activity),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openReportComplaint(context),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Report Waste'),
      ),
    );
  }
}

/// Friendly placeholder shown in the "Nearby Waste Issues" strip when there
/// are no complaints with GPS coordinates yet.
class _EmptyNearbyCard extends StatelessWidget {
  const _EmptyNearbyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.7)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.travel_explore_outlined,
              size: 32, color: AppColors.primaryGreen),
          const SizedBox(height: 10),
          Text(
            'No nearby issues reported yet.\nBe the first to report!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Top-right avatar on the citizen home screen — shows the user's Google
/// profile photo (the same one shown on the Profile page), falling back to
/// their initial letter when no photo is available.
class _HomeAvatar extends StatelessWidget {
  const _HomeAvatar();

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.user;
    final photoUrl = user?.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.paleGreen,
        backgroundImage: NetworkImage(photoUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    final name = user?.name.trim() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.paleGreen,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }
}
