import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/app_repository.dart';
import '../../models/collection_task.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/live_map_view.dart';
import '../../widgets/status_badge.dart';
import 'head_assign_task_page.dart';
import 'head_edit_worker_page.dart';

class HeadWorkerDetailPage extends StatelessWidget {
  const HeadWorkerDetailPage({super.key, required this.workerId});

  final String workerId;

  AppUser? get _worker {
    for (final account in AuthService.instance.workers) {
      if (account.id == workerId) return account;
    }
    return null;
  }

  Future<void> _editWorker(BuildContext context, AppUser worker) async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HeadEditWorkerPage(workerId: worker.id),
      ),
    );
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
    final error = AuthService.instance.deleteWorker(worker.id);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${worker.name} deleted.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final worker = _worker;
    if (worker == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Worker')),
        body: const Center(child: Text('Worker not found')),
      );
    }

    final tasks = AppRepository.instance.tasksForWorker(worker.workerId!);
    final location = AppRepository.instance.lastLocation(worker.workerId!);
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
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFF6A1B9A).withOpacity(0.1),
                      child: Text(
                        worker.name[0],
                        style: TextStyle(
                          color: Color(0xFF6A1B9A),
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          location == null ? Icons.sensors_off : Icons.sensors,
                          size: 18,
                          color: location == null
                              ? AppColors.textSecondary
                              : AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          location == null
                              ? 'No live location shared yet'
                              : 'Live Location',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Spacer(),
                        if (location != null)
                          Text(
                            'Updated ${_formatTime(location.updatedAt)}',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (location != null)
                      LiveMapView(
                        height: 220,
                        title: 'Worker Live Location',
                        center: LatLng(location.latitude, location.longitude),
                        markers: [
                          LiveMapMarker(
                            LatLng(location.latitude, location.longitude),
                            label: '${worker.name} (${worker.workerId})',
                            icon: Icons.local_shipping,
                            color: const Color(0xFF6A1B9A),
                          ),
                        ],
                        showUserLocation: false,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'The worker\'s live GPS position appears here when they enable location sharing in their app.',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4),
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (location != null)
                      Text(
                        'Coordinates: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                  ],
                ),
              ),
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
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => HeadAssignTaskPage(
                              preSelectedWorkerId: worker.workerId),
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

  String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
