import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/app_repository.dart';
import '../../data/mock_data_repository.dart';
import '../../models/collection_task.dart';
import '../../models/complaint.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import 'head_assign_task_page.dart';

class HeadTasksPage extends StatefulWidget {
  const HeadTasksPage({super.key, this.initialFilter = 'All'});

  /// Filter applied when the page opens (e.g. 'Completed' when opened from
  /// the dashboard stat card).
  final String initialFilter;

  @override
  State<HeadTasksPage> createState() => _HeadTasksPageState();
}

class _HeadTasksPageState extends State<HeadTasksPage> {
  late String _filter = widget.initialFilter;

  static const _filters = [
    'All',
    'Assigned',
    'En Route',
    'Collecting',
    'Completed',
    'Rejected',
  ];

  List<CollectionTask> get _tasks {
    final all = AppRepository.instance.tasks;
    if (_filter == 'All') return all;
    return all.where((t) => t.status.label == _filter).toList();
  }

  String _workerName(String? workerId) {
    if (workerId == null) return 'Unassigned';
    final worker = AuthService.instance.getWorkerByWorkerId(workerId);
    return worker == null ? 'Worker $workerId' : worker.name;
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _tasks;

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'All Collection Tasks',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Create & Assign Task',
            icon: const Icon(Icons.add_task_rounded, color: Color(0xFF1565C0)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const HeadAssignTaskPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final selected = _filter == filter;
                  return ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = filter),
                    selectedColor: AppColors.primaryGreen,
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        'No tasks in this status yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _buildTaskCard(context, tasks[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, CollectionTask task) {
    final isUnassigned = task.workerId == null;
    final linkedComplaint = task.citizenComplaintId == null
        ? null
        : MockDataRepository.instance
            .getComplaintById(task.citizenComplaintId!);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
          ),
          if (linkedComplaint != null) ...[
            const SizedBox(height: 8),
            _LinkedComplaintRow(complaint: linkedComplaint),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isUnassigned ? Icons.person_off_outlined : Icons.person_outline,
                size: 15,
                color: isUnassigned ? Colors.orange : const Color(0xFF6A1B9A),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _workerName(task.workerId),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color:
                        isUnassigned ? Colors.orange : const Color(0xFF6A1B9A),
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
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 15, color: Color(0xFF1565C0)),
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
            ],
          ),
          if (isUnassigned) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          HeadAssignTaskPage(preSelectedTaskId: task.id),
                    ),
                  );
                },
                icon: const Icon(Icons.handyman_outlined, size: 18),
                label: const Text('Assign to Worker'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  side: const BorderSide(color: Color(0xFF1565C0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact row showing the citizen complaint a task resolves, including a
/// thumbnail of the citizen's reported photo when available.
class _LinkedComplaintRow extends StatelessWidget {
  const _LinkedComplaintRow({required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final path = complaint.photoPath;
    final hasPhoto = path != null && File(path).existsSync();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF00838F).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (hasPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(path!),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                complaint.hasPhoto
                    ? Icons.image_not_supported_outlined
                    : Icons.photo_camera_outlined,
                size: 20,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Citizen complaint #${complaint.id}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00838F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${complaint.category} · ${complaint.location}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
