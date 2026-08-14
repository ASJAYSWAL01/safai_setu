import 'package:flutter/material.dart';

import '../../data/mock_data_repository.dart';
import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/map_placeholder.dart';
import '../../widgets/status_badge.dart';

class WasteHotspotPage extends StatelessWidget {
  const WasteHotspotPage({super.key});

  Color _riskColor(HotspotRisk risk) {
    switch (risk) {
      case HotspotRisk.high:
        return Colors.redAccent;
      case HotspotRisk.medium:
        return Colors.orange;
      case HotspotRisk.low:
        return AppColors.lightGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotspots = MockDataRepository.instance.wasteHotspots;

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: const Text(
          'Waste Hotspots',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Predicted Waste Hotspots',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Areas requiring higher collection priority',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Text(
                  'Demo prediction data — AI/ML integration pending',
                  style: TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ),
              const SizedBox(height: 16),
              const MapPlaceholder(
                height: 240,
                title: 'Hotspot Map Preview',
                showLegend: true,
                showHotspots: true,
                showVehicle: false,
                showUserLocation: true,
              ),
              const SizedBox(height: 20),
              ...hotspots.map((hotspot) {
                final color = _riskColor(hotspot.riskLevel);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                hotspot.sector,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            RiskBadge(label: hotspot.riskLevel.label, color: color),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _HotspotRow(
                          label: 'Expected Waste',
                          value: '${hotspot.expectedWastePercent}%',
                          color: color,
                        ),
                        const SizedBox(height: 6),
                        _HotspotRow(
                          label: 'Recommended Collection',
                          value: hotspot.recommendedCollection,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _HotspotRow extends StatelessWidget {
  const _HotspotRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
