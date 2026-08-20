import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/live_map_view.dart';

class VehicleTrackingPage extends StatefulWidget {
  const VehicleTrackingPage({super.key});

  @override
  State<VehicleTrackingPage> createState() => _VehicleTrackingPageState();
}

/// A worker joined with their live location (if any).
class _VehicleInfo {
  const _VehicleInfo({
    required this.worker,
    this.location,
  });

  final AppUser worker;
  final WorkerLocation? location;

  bool get isOnline =>
      location != null &&
      location!.isSharing &&
      DateTime.now().toUtc().difference(location!.updatedAt) <
          const Duration(seconds: 60);
}

class _VehicleTrackingPageState extends State<VehicleTrackingPage> {
  bool _loading = true;
  String? _error;
  List<_VehicleInfo> _vehicles = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final workers = await AuthService.instance.workers;
      final locations = await LocationService.instance.fetchLocations();

      final byWorkerId = <String, WorkerLocation>{
        for (final loc in locations) loc.workerId: loc,
      };

      final vehicles = workers
          .where((w) => w.workerId != null && w.workerId!.isNotEmpty)
          .map((w) => _VehicleInfo(
                worker: w,
                location: byWorkerId[w.workerId],
              ))
          .toList();

      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    // Keep the spinner visible until the refetch completes.
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(          title: Text(
            'Track Collection Vehicle',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        centerTitle: true,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primaryGreen,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _vehicles.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }

    if (_loading && _vehicles.isNotEmpty) {
      // Refreshing with data already on screen — show a thin progress bar
      // at the top instead of blanking the page.
      return LinearProgressIndicator(
        color: AppColors.primaryGreen,
        minHeight: 2,
      );
    }

    if (_error != null && _vehicles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.cloud_off_rounded, size: 56),
          const SizedBox(height: 12),
          Text(
            'Could not load vehicles.\nPull down to retry.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    final online = _vehicles.where((v) => v.isOnline).toList();
    final offline = _vehicles.where((v) => !v.isOnline).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Waste Collection Vehicle Tracking',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Live location of all collection vehicles',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        // Live map with a truck marker for every online worker.
        LiveMapView(
          height: 280,
          title: 'Live Vehicles Map',
          showUserLocation: false,
          markers: online.map((v) {
            final loc = v.location!;
            return LiveMapMarker(
              LatLng(loc.latitude, loc.longitude),
              id: 'truck-${v.worker.workerId}',
              label: '${v.worker.name} (${_vehicleLabel(v.worker)})',
              icon: Icons.local_shipping_rounded,
              color: AppColors.primaryGreen,
            );
          }).toList(),
          center: online.isNotEmpty
              ? LatLng(online.first.location!.latitude,
                  online.first.location!.longitude)
              : null,
        ),
        const SizedBox(height: 20),
        // Vehicle cards: online first, then offline.
        if (online.isNotEmpty) ...[
          _SectionHeader(title: 'On Duty (${online.length})'),
          const SizedBox(height: 8),
          ...online.map((v) => _VehicleCard(vehicle: v, online: true)),
          const SizedBox(height: 20),
        ],
        if (offline.isNotEmpty) ...[
          _SectionHeader(title: 'Off Duty (${offline.length})'),
          const SizedBox(height: 8),
          ...offline.map((v) => _VehicleCard(vehicle: v, online: false)),
          const SizedBox(height: 20),
        ],
        if (_vehicles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No workers registered yet.\nPull down to refresh.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.online,
  });

  final _VehicleInfo vehicle;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final worker = vehicle.worker;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: online ? AppColors.paleGreen : AppColors.borderColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_shipping_rounded,
                color: online ? AppColors.primaryGreen : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle: ${_vehicleLabel(worker)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: online
                              ? AppColors.primaryGreen
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        online ? 'Status: On Duty' : 'Status: Off Duty',
                        style: TextStyle(
                          color: online
                              ? AppColors.primaryGreen
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  worker.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (worker.workerId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    worker.workerId!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _vehicleLabel(AppUser worker) =>
    (worker.vehicleNumber != null && worker.vehicleNumber!.trim().isNotEmpty)
        ? worker.vehicleNumber!
        : 'N/A';
