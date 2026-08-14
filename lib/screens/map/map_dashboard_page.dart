import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/dashboard_action_card.dart';
import '../../widgets/map_placeholder.dart';
import '../../widgets/app_card.dart';
import '../hotspots/waste_hotspot_page.dart';
import '../tracking/vehicle_tracking_page.dart';

class MapDashboardPage extends StatelessWidget {
  const MapDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      body: SafeArea(
        child: SingleChildScrollView(
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
                'Track vehicles and waste hotspots',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              const MapPlaceholder(
                height: 280,
                title: 'Combined Map View',
                showLegend: true,
                showVehicle: true,
                showUserLocation: true,
                showHotspots: true,
                showCollectionPoints: true,
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
    );
  }
}
