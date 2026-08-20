import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/complaint.dart';
import '../../services/complaint_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/config.dart';
import '../../widgets/dashboard_action_card.dart';
import '../../widgets/live_map_view.dart';
import '../../widgets/app_card.dart';
import '../hotspots/waste_hotspot_page.dart';
import '../tracking/vehicle_tracking_page.dart';

class MapDashboardPage extends StatefulWidget {
  const MapDashboardPage({super.key});

  @override
  State<MapDashboardPage> createState() => _MapDashboardPageState();
}

class _MapDashboardPageState extends State<MapDashboardPage> {
  late Future<List<Complaint>> _complaintsFuture;

  @override
  void initState() {
    super.initState();
    _complaintsFuture = ComplaintService.instance.fetchComplaintsWithCoordinates();
  }

  Future<void> _reload() async {
    final future =
        ComplaintService.instance.fetchComplaintsWithCoordinates();
    setState(() {
      _complaintsFuture = future;
    });
    try {
      await future;
    } on Object {
      // Errors surface in the FutureBuilder (retry card shown).
    }
  }

  Color _statusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Colors.orange;
      case ComplaintStatus.assigned:
        return const Color(0xFF1565C0);
      case ComplaintStatus.inProgress:
        return const Color(0xFF3949AB);
      case ComplaintStatus.resolved:
        return AppColors.primaryGreen;
      case ComplaintStatus.rejected:
        return const Color(0xFFC62828);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          color: AppColors.primaryGreen,
          child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'City Map Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Reported waste complaints on a live map',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<Complaint>>(
                future: _complaintsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 280,
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off_outlined,
                              size: 36, color: Colors.orange),
                          const SizedBox(height: 10),
                          Text(
                            'Could not load complaints. Check your internet connection.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _reload,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final complaints = snapshot.data ?? [];

                  if (complaints.isEmpty) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.map_outlined,
                              size: 40, color: Colors.orange),
                          const SizedBox(height: 10),
                          Text(
                            'No complaints with locations yet.\nReport waste to see it here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  final center = complaints.firstWhere(
                    (c) => c.latitude != null && c.longitude != null,
                    orElse: () => complaints.first,
                  );

                  final markers = complaints
                      .where((c) => c.latitude != null && c.longitude != null)
                      .map((c) => LiveMapMarker(
                            LatLng(c.latitude!, c.longitude!),
                            id: c.id,
                            label: c.category,
                            icon: Icons.delete_outline,
                            color: _statusColor(c.status),
                          ))
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LiveMapView(
                        height: 280,
                        title: 'Complaint Map',
                        center: LatLng(
                          center.latitude ?? AppConfig.fallbackLatitude,
                          center.longitude ?? AppConfig.fallbackLongitude,
                        ),
                        markers: markers,
                        showUserLocation: false,
                      ),
                      const SizedBox(height: 8),
                      AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${complaints.length} reported complaint(s) on the map',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 14,
                              runSpacing: 6,
                              children: [
                                _LegendDot(
                                    color: Colors.orange, label: 'Pending'),
                                _LegendDot(
                                    color: const Color(0xFF1565C0),
                                    label: 'Assigned'),
                                _LegendDot(
                                    color: const Color(0xFF3949AB),
                                    label: 'In Progress'),
                                _LegendDot(
                                    color: AppColors.primaryGreen,
                                    label: 'Resolved'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Map Features'),
              const SizedBox(height: 12),
              DashboardActionCard(
                icon: Icons.local_shipping_outlined,
                title: 'Track Collection Vehicle',
                subtitle: 'View live vehicle location and ETA',
                color: const Color(0xFF1565C0),
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
                icon: Icons.whatshot_outlined,
                title: 'Waste Hotspots',
                subtitle: 'View predicted high-waste areas',
                color: Colors.orange,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WasteHotspotPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
