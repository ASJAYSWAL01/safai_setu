import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/live_map_view.dart';
import '../../widgets/worker_avatar.dart';

/// Shows every worker's last known position on one map, refreshing
/// automatically so the Head can watch the fleet in real time.
class HeadLiveMapPage extends StatefulWidget {
  const HeadLiveMapPage({super.key});

  @override
  State<HeadLiveMapPage> createState() => _HeadLiveMapPageState();
}

class _HeadLiveMapPageState extends State<HeadLiveMapPage> {
  List<AppUser> _workers = [];
  List<WorkerLocation> _locations = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  Future<void> _load() async {
    List<AppUser> workers;
    try {
      workers = await AuthService.instance.workers;
    } on Object {
      workers = [];
    }
    List<WorkerLocation> locations;
    try {
      locations = await LocationService.instance.fetchLocations();
    } on Object {
      locations = [];
    }
    if (!mounted) return;
    setState(() {
      _workers = workers;
      _locations = locations;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Map<String, WorkerLocation> get _locationByWorkerId => {
        for (final loc in _locations) loc.workerId: loc,
      };

  @override
  Widget build(BuildContext context) {
    final workers = _workers;
    final locations = _locations;

    final withPosition = workers
        .where((w) => w.workerId != null && _locationByWorkerId[w.workerId] != null)
        .toList();
    final liveCount =
        locations.where((loc) => loc.isLive).length;

    final markers = <LiveMapMarker>[];
    for (final worker in withPosition) {
      final loc = _locationByWorkerId[worker.workerId!]!;
      markers.add(LiveMapMarker(
        LatLng(loc.latitude, loc.longitude),
        label: '${worker.name} (${worker.workerId})',
        icon: loc.isLive ? Icons.local_shipping : Icons.local_shipping_outlined,
        color: loc.isLive ? AppColors.primaryGreen : AppColors.textSecondary,
      ));
    }

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'Worker Live Map',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primaryGreen,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.paleGreen,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryGreen),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sensors,
                              color: AppColors.primaryGreen),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$liveCount of ${workers.length} workers live right now',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (markers.isEmpty)
                      AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'No live positions yet. Workers see their positions here once they open "Live Location Map" in their app and tap Share Location.',
                            style:
                                TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else ...[
                      LiveMapView(
                        height: 320,
                        title: 'Workers on map',
                        center: markers.first.position,
                        markers: markers,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Workers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...workers.map((worker) {
                        final loc = worker.workerId == null
                            ? null
                            : _locationByWorkerId[worker.workerId];
                        final isLive = loc?.isLive ?? false;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                WorkerAvatar(
                                  name: worker.name,
                                  photoUrl: worker.photoUrl,
                                  radius: 16,
                                  accent: const Color(0xFF1565C0),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        worker.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13.5),
                                      ),
                                      Text(
                                        loc == null
                                            ? 'Not sharing yet'
                                            : '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}',
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isLive
                                        ? AppColors.paleGreen
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isLive
                                        ? 'Live'
                                        : (loc?.isSharing ?? false)
                                            ? 'Paused'
                                            : 'Offline',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isLive
                                          ? AppColors.primaryGreen
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}
