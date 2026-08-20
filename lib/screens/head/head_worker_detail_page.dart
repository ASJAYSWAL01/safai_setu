import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/collection_task.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/call_utils.dart';
import '../../widgets/app_card.dart';
import '../../widgets/live_map_view.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/worker_avatar.dart';
import 'head_assign_task_page.dart';
import 'head_edit_worker_page.dart';

class HeadWorkerDetailPage extends StatefulWidget {
  const HeadWorkerDetailPage({super.key, required this.workerId});

  final String workerId;

  @override
  State<HeadWorkerDetailPage> createState() => _HeadWorkerDetailPageState();
}

class _HeadWorkerDetailPageState extends State<HeadWorkerDetailPage> {
  AppUser? _worker;
  List<CollectionTask> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWorker();
  }

  Future<void> _loadWorker() async {
    List<AppUser> workers;
    try {
      workers = await AuthService.instance.workers;
    } on Object {
      workers = [];
    }
    if (!mounted) return;
    AppUser? found;
    for (final account in workers) {
      if (account.id == widget.workerId) {
        found = account;
        break;
      }
    }
    List<CollectionTask> tasks = [];
    final workerId = found?.workerId;
    if (workerId != null) {
      try {
        tasks = await TaskService.instance.fetchTasksForWorker(workerId);
      } on Object {
        tasks = [];
      }
    }
    if (!mounted) return;
    setState(() {
      _worker = found;
      _tasks = tasks;
      _loading = false;
    });
  }

  Future<void> _revokeTask(
      BuildContext context, CollectionTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Revoke Task?'),
        content: Text(
          'Revoke "${task.title}" from this worker?\n\n'
          'It will be removed from the worker\'s queue and the citizen complaint '
          'returns to the unassigned state, so you can assign it to another '
          'worker.',
          style: TextStyle(
              fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await TaskService.instance.revokeTask(task.id);
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not revoke the task: $e'),
          backgroundColor: Colors.redAccent.shade200,
        ),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task revoked.')),
    );
    await _loadWorker();
  }

  Future<void> _editWorker(BuildContext context, AppUser worker) async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HeadEditWorkerPage(workerId: worker.id),
      ),
    );
    if (mounted) _loadWorker();
  }

  Future<void> _deleteWorker(BuildContext context, AppUser worker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Worker?'),
        content: Text(
          'Remove ${worker.name} (${worker.workerId})? Their open collection tasks will be unassigned.',
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
    if (confirmed != true || !context.mounted) return;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${worker.name} deleted.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Worker')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final worker = _worker;
    if (worker == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Worker')),
        body: const Center(child: Text('Worker not found')),
      );
    }

    final tasks = _tasks;
    final workerId = worker.workerId;
    final completed =
        tasks.where((t) => t.status == CollectionTaskStatus.completed).length;

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'Worker Details',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          if (worker.phone?.trim().isNotEmpty == true)
            IconButton(
              tooltip: 'Call ${worker.name}',
              icon: const Icon(Icons.call_outlined, color: Color(0xFF1565C0)),
              onPressed: () =>
                  callPhoneNumber(context, phone: worker.phone!),
            ),
          PopupMenuButton<String>(
            tooltip: 'Worker actions',
            onSelected: (value) {
              if (value == 'edit') _editWorker(context, worker);
              if (value == 'delete') _deleteWorker(context, worker);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined, color: Color(0xFF1565C0)),
                  title: Text('Edit Profile'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: Text('Delete Worker'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  children: [
                    WorkerAvatar(
                      name: worker.name,
                      photoUrl: worker.photoUrl,
                      radius: 36,
                      accent: const Color(0xFF6A1B9A),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      worker.name,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pickup Truck Worker',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Worker ID', value: worker.workerId ?? '—'),
                    const Divider(height: 18),
                    _InfoRow(
                        label: 'Vehicle', value: worker.vehicleNumber ?? '—'),
                    const Divider(height: 18),
                    _InfoRow(label: 'Mobile', value: worker.phone ?? '—'),
                    const Divider(height: 18),
                    _InfoRow(label: 'Email', value: worker.email),
                    const Divider(height: 18),
                    _InfoRow(
                      label: 'Tasks Done',
                      value: '$completed of ${tasks.length} completed',
                    ),
                    if (workerId == null) ...[
                      const Divider(height: 18),
                      const _InfoRow(
                        label: 'Note',
                        value:
                            'No Worker ID yet — generate one from the Workers page to assign tasks.',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _LiveLocationCard(workerId: worker.workerId),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Assigned Tasks',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: workerId == null
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => HeadAssignTaskPage(
                                    preSelectedWorkerId: workerId),
                              ),
                            );
                          },
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: const Text('Assign Task'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (tasks.isEmpty)
                AppCard(
                  child: Text(
                    'No tasks assigned to this worker yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ...tasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              TaskStatusBadge(status: task.status),
                              if (task.workerId != null &&
                                  task.status ==
                                      CollectionTaskStatus.assigned) ...[
                                IconButton(
                                  tooltip: 'Revoke Task',
                                  icon: const Icon(Icons.undo_rounded,
                                      size: 20, color: Colors.redAccent),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () =>
                                      _revokeTask(context, task),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 15, color: Color(0xFF1565C0)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${task.latitude.toStringAsFixed(5)}, ${task.longitude.toStringAsFixed(5)}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ),
                              if (task.proofPhotoPath != null)
                                Text(
                                  'Proof ✓',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _LiveLocationCard extends StatefulWidget {
  const _LiveLocationCard({required this.workerId});

  final String? workerId;

  @override
  State<_LiveLocationCard> createState() => _LiveLocationCardState();
}

class _LiveLocationCardState extends State<_LiveLocationCard> {
  WorkerLocation? _location;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
  }

  Future<void> _refresh() async {
    final workerId = widget.workerId;
    if (workerId == null) {
      if (mounted && _location != null) setState(() => _location = null);
      return;
    }
    WorkerLocation? location;
    try {
      location = await LocationService.instance
          .fetchLocationForWorker(workerId);
    } on Object {
      location = null;
    }
    if (!mounted) return;
    setState(() => _location = location);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _lastSeenLabel(DateTime updatedAt) {
    final diff = DateTime.now().toUtc().difference(updatedAt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    final hours = diff.inHours;
    return '$hours h ago';
  }

  @override
  Widget build(BuildContext context) {
    final workerId = widget.workerId;
    final location = _location;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                (location?.isLive ?? false)
                    ? Icons.sensors
                    : Icons.sensors_off,
                size: 18,
                color: (location?.isLive ?? false)
                    ? AppColors.primaryGreen
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Live Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (location != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: location.isLive
                        ? AppColors.paleGreen
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    location.isLive
                        ? 'Live'
                        : (location.isSharing ? 'Paused' : 'Offline'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: location.isLive
                          ? AppColors.primaryGreen
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (workerId == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No Worker ID yet — generate one from the Workers page. Live location sharing starts once the worker uses the Live Location Map in their app.',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4),
              ),
            )
          else if (location == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No live position yet. When the worker opens "Live Location Map" in their app and taps Share Location, their position appears here automatically.',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LiveMapView(
                  height: 180,
                  title: '${workerId} position',
                  center: LatLng(location.latitude, location.longitude),
                  markers: [
                    LiveMapMarker(
                      LatLng(location.latitude, location.longitude),
                      label: workerId,
                      icon: Icons.local_shipping,
                      color: AppColors.primaryGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.pin_drop_outlined,
                        size: 16, color: AppColors.primaryGreen),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Last updated ${_lastSeenLabel(location.updatedAt)}',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
