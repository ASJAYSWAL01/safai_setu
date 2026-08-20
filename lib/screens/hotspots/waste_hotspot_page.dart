import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/complaint.dart';
import '../../services/complaint_service.dart';
import '../../services/hotspot_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/config.dart';
import '../../widgets/app_card.dart';
import '../../widgets/live_map_view.dart';
import '../../widgets/status_badge.dart';

/// Waste hotspots computed live from recent complaints (last 7 days,
/// 500 m clustering). Shows the full complaint map with hotspot radius
/// circles on top, and the hotspot detail cards below.
class WasteHotspotPage extends StatefulWidget {
  const WasteHotspotPage({super.key});

  @override
  State<WasteHotspotPage> createState() => _WasteHotspotPageState();
}

class _WasteHotspotPageState extends State<WasteHotspotPage> {
  late Future<List<Complaint>> _complaintsFuture;

  @override
  void initState() {
    super.initState();
    _complaintsFuture = _load();
  }

  Future<List<Complaint>> _load() async {
    return ComplaintService.instance.fetchComplaintsWithCoordinates();
  }

  Future<void> _reload() async {
    final future = _load();
    setState(() {
      _complaintsFuture = future;
    });
    try {
      await future;
    } on Object {
      // Errors surface in the FutureBuilder.
    }
  }

  List<WasteHotspot> _hotspotsFor(List<Complaint> complaints) =>
      HotspotService.instance.detectHotspots(complaints);

  Color _riskColor(HotspotLevel level) {
    switch (level) {
      case HotspotLevel.high:
        return const Color(0xFFD32F2F);
      case HotspotLevel.medium:
        return Colors.orange;
      case HotspotLevel.low:
        return AppColors.primaryGreen;
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

  void _showHotspotDetails(WasteHotspot hotspot) {
    final color = _riskColor(hotspot.level);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.whatshot_rounded, color: color),
                const SizedBox(width: 8),
                Text(
                  'Waste Hotspot',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _HotspotRow(
              label: 'Severity',
              value: hotspot.level.label,
              color: color,
            ),
            const SizedBox(height: 8),
            _HotspotRow(
              label: 'Complaints',
              value: '${hotspot.complaintCount}',
              color: AppColors.textPrimary,
            ),
            const SizedBox(height: 8),
            _HotspotRow(
              label: 'Period',
              value: 'Last 7 days',
              color: AppColors.textPrimary,
            ),
            const SizedBox(height: 8),
            _HotspotRow(
              label: 'Radius',
              value: '500 m',
              color: AppColors.textPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              'Complaints grouped by proximity within the last 7 days.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'Waste Hotspots',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          color: AppColors.primaryGreen,
          child: FutureBuilder<List<Complaint>>(
            future: _complaintsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    const SizedBox(height: 80),
                    const Icon(Icons.cloud_off_outlined,
                        size: 48, color: Colors.orange),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load hotspots. Pull down to retry.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                );
              }

              final complaints = snapshot.data ?? [];
              final hotspots = _hotspotsFor(complaints);

              // Map center: first complaint with coordinates, else fallback.
              LatLng mapCenter;
              if (complaints.isEmpty) {
                mapCenter = const LatLng(
                    AppConfig.fallbackLatitude, AppConfig.fallbackLongitude);
              } else {
                final first = complaints.firstWhere(
                  (c) => c.latitude != null && c.longitude != null,
                  orElse: () => complaints.first,
                );
                mapCenter = LatLng(
                  first.latitude ?? AppConfig.fallbackLatitude,
                  first.longitude ?? AppConfig.fallbackLongitude,
                );
              }

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

              final circles = hotspots
                  .map((h) => LiveMapCircle(
                        id:
                            'hotspot-${h.level.name}-${h.center.latitude},${h.center.longitude}',
                        center: h.center,
                        radiusMeters: HotspotService.radiusMeters,
                        color: _riskColor(h.level),
                        label:
                            '${h.level.label} · ${h.complaintCount} complaints',
                      ))
                  .toList();

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Waste Hotspots',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Areas with multiple complaints reported within the last 7 days '
                    '(500 m radius)',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (complaints.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LiveMapView(
                        height: 280,
                        title: 'Hotspot Map',
                        center: mapCenter,
                        markers: markers,
                        circles: circles,
                        onCircleTap: (circle) {
                          final hotspot = hotspots.firstWhere(
                            (h) =>
                                'hotspot-${h.level.name}-${h.center.latitude},${h.center.longitude}' ==
                                circle.id,
                            orElse: () => hotspots.isNotEmpty
                                ? hotspots.first
                                : WasteHotspot(
                                    center: circle.center,
                                    complaintIds: const [],
                                    level: HotspotLevel.low,
                                  ),
                          );
                          _showHotspotDetails(hotspot);
                        },
                        showUserLocation: false,
                      ),
                    ),
                  _HotspotLegendRow(),
                  const SizedBox(height: 16),
                  if (hotspots.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.whatshot_outlined,
                              size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'No hotspots in the last 7 days.\nPull down to refresh.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    ...hotspots.map((hotspot) {
                      final color = _riskColor(hotspot.level);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.whatshot_rounded, color: color),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Waste Hotspot',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  RiskBadge(
                                      label: hotspot.level.label,
                                      color: color),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _HotspotRow(
                                label: 'Severity',
                                value: hotspot.level.label,
                                color: color,
                              ),
                              const SizedBox(height: 6),
                              _HotspotRow(
                                label: 'Complaints',
                                value: '${hotspot.complaintCount}',
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(height: 6),
                              _HotspotRow(
                                label: 'Period',
                                value: 'Last 7 days',
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(height: 6),
                              _HotspotRow(
                                label: 'Radius',
                                value: '500 m',
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(height: 6),
                              _HotspotRow(
                                label: 'Center',
                                value:
                                    '${hotspot.center.latitude.toStringAsFixed(5)}, '
                                    '${hotspot.center.longitude.toStringAsFixed(5)}',
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HotspotLegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: const Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          _LegendDot(color: Color(0xFF2E7D32), label: 'Low: 1–2'),
          _LegendDot(color: Colors.orange, label: 'Medium: 3–5'),
          _LegendDot(color: Color(0xFFD32F2F), label: 'High: 6+'),
        ],
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
          style: TextStyle(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
