import 'package:flutter/material.dart';

import '../../models/collection_task.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/call_utils.dart';
import '../../widgets/app_card.dart';
import '../../widgets/worker_avatar.dart';
import 'head_edit_worker_page.dart';
import 'head_generate_worker_id_page.dart';
import 'head_worker_detail_page.dart';

class HeadWorkersPage extends StatefulWidget {
  const HeadWorkersPage({super.key});

  @override
  State<HeadWorkersPage> createState() => _HeadWorkersPageState();
}

class _HeadWorkersPageState extends State<HeadWorkersPage> {
  List<AppUser> _workers = [];
  Map<String, int> _activeTaskCounts = {};
  Map<String, WorkerLocation> _locations = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    List<AppUser> workers;
    try {
      workers = await AuthService.instance.workers;
    } on Object {
      workers = [];
    }
    if (!mounted) return;
    setState(() {
      _workers = workers;
      _loading = false;
    });
    _loadActiveCounts(workers);
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    List<WorkerLocation> locations;
    try {
      locations = await LocationService.instance.fetchLocations();
    } on Object {
      locations = [];
    }
    if (!mounted) return;
    setState(() {
      _locations = {
        for (final loc in locations) loc.workerId: loc,
      };
    });
  }

  Future<void> _loadActiveCounts(List<AppUser> workers) async {
    final counts = <String, int>{};
    for (final worker in workers) {
      final id = worker.workerId;
      if (id == null) continue;
      try {
        final tasks = await TaskService.instance.fetchTasksForWorker(id);
        counts[id] = tasks
            .where((t) => t.status != CollectionTaskStatus.completed)
            .length;
      } on Object {
        counts[id] = 0;
      }
    }
    if (!mounted) return;
    setState(() => _activeTaskCounts = counts);
  }

  Future<void> _openEdit(AppUser worker) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HeadEditWorkerPage(workerId: worker.id),
      ),
    );
    if (mounted) _loadWorkers();
  }

  Future<void> _deleteWorker(AppUser worker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Worker?'),
        content: Text(
          'Remove ${worker.name} (${worker.workerId})?\n\nTheir open collection tasks will be unassigned and the Worker ID cannot be reused.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await AuthService.instance.deleteWorker(worker.id);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final workerId = worker.workerId;
    if (workerId != null) {
      try {
        await LocationService.instance.clearLocation(workerId);
      } on Object catch (e) {
        debugPrint('Failed to clear location for $workerId: $e');
      }
    }
    await _loadWorkers();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${worker.name} deleted. Tasks unassigned.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workers = _workers;

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'My Workers',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Generate Worker ID',
            icon: const Icon(Icons.badge_outlined, color: Color(0xFF6A1B9A)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const HeadGenerateWorkerIdPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : workers.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No workers registered yet.\nTap the badge icon to generate the first Worker ID.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: workers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final worker = workers[index];
                  final workerId = worker.workerId;
                  final activeTasks = _activeTaskCounts[workerId] ?? 0;
                  final location = workerId == null
                      ? null
                      : _locations[workerId];
                  final isLive = location?.isLive ?? false;

                  return AppCard(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              HeadWorkerDetailPage(workerId: worker.id),
                        ),
                      );
                      if (mounted) _loadWorkers();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            WorkerAvatar(
                              name: worker.name,
                              photoUrl: worker.photoUrl,
                              radius: 22,
                              accent: const Color(0xFF6A1B9A),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    worker.name,
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${worker.workerId} · ${worker.phone ?? '—'}',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            _LivePill(isLive: isLive),
                            const SizedBox(width: 4),
                            if (worker.phone?.trim().isNotEmpty == true)
                              IconButton(
                                tooltip: 'Call ${worker.name}',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                    width: 34, height: 34),
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.call_outlined,
                                    size: 20, color: Color(0xFF1565C0)),
                                onPressed: () => callPhoneNumber(context,
                                    phone: worker.phone!),
                              ),
                            PopupMenuButton<String>(
                              tooltip: 'Worker actions',
                              onSelected: (value) {
                                if (value == 'edit') _openEdit(worker);
                                if (value == 'delete') _deleteWorker(worker);
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Icons.edit_outlined,
                                        color: Color(0xFF1565C0)),
                                    title: Text('Edit Profile'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Icons.delete_outline,
                                        color: Colors.redAccent),
                                    title: Text('Delete Worker'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatChip(
                                icon: Icons.local_shipping_outlined,
                                label: worker.vehicleNumber ?? 'No vehicle',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatChip(
                                icon: Icons.assignment_outlined,
                                label: '$activeTasks active task(s)',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.isLive});

  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isLive ? AppColors.paleGreen : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLive ? Icons.sensors : Icons.sensors_off,
            size: 14,
            color: isLive ? AppColors.primaryGreen : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            isLive ? 'Live' : 'Offline',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isLive ? AppColors.primaryGreen : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6A1B9A).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF6A1B9A)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
