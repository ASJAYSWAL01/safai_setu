import 'package:flutter/material.dart';

import '../../data/mock_data_repository.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
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
  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() {});
  }

  void _openReportComplaint(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ReportComplaintPage()),
    );
  }

  void _openMyComplaints(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MyComplaintsPage()),
    );
  }

  String _firstName() {
    final user = AuthService.instance.user;
    if (user == null) return 'Citizen';
    final parts = user.name.trim().split(' ');
    return parts.isEmpty ? 'Citizen' : parts.first;
  }

  @override
  Widget build(BuildContext context) {
    final data = MockDataRepository.instance;
    final summary = data.dashboardSummary;

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
                                  'Together for a Cleaner City',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary
                                        .withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Hello, ${_firstName()} 👋',
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
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.paleGreen,
                              child: Icon(
                                Icons.person,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const AwarenessBanner(),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.28,
                        children: [
                          SummaryStatCard(
                            icon: Icons.report_outlined,
                            label: 'My Complaints',
                            value: '${summary.myComplaints}',
                            color: AppColors.primaryGreen,
                            onTap: () => _openMyComplaints(context),
                          ),
                          SummaryStatCard(
                            icon: Icons.check_circle_outline,
                            label: 'Resolved',
                            value: '${summary.resolved}',
                            color: const Color(0xFF388E3C),
                            onTap: () => _openMyComplaints(context),
                          ),
                          SummaryStatCard(
                            icon: Icons.hourglass_top_rounded,
                            label: 'In Progress',
                            value: '${summary.inProgress}',
                            color: const Color(0xFF3949AB),
                            onTap: () => _openMyComplaints(context),
                          ),
                          SummaryStatCard(
                            icon: Icons.near_me_outlined,
                            label: 'Nearby Issues',
                            value: '${summary.nearbyIssues}',
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
                      const SectionHeader(title: 'Quick Actions'),
                      const SizedBox(height: 12),
                      DashboardActionCard(
                        icon: Icons.camera_alt_outlined,
                        title: 'Report Waste',
                        subtitle: 'Report garbage or cleanliness issues',
                        color: AppColors.primaryGreen,
                        onTap: () => _openReportComplaint(context),
                      ),
                      const SizedBox(height: 12),
                      DashboardActionCard(
                        icon: Icons.assignment_outlined,
                        title: 'My Complaints',
                        subtitle: 'Track your reported issues',
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
                        title: 'Track Vehicle',
                        subtitle: 'View nearby waste collection vehicles',
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
                        title: 'Waste Hotspots',
                        subtitle: 'View areas with high waste accumulation',
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
                      const SectionHeader(title: 'Nearby Waste Issues'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: data.nearbyIssues.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            return NearbyIssueCard(
                                issue: data.nearbyIssues[index]);
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                      const SectionHeader(title: 'Recent Activity'),
                      const SizedBox(height: 8),
                      ...data.recentActivities.map(
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
