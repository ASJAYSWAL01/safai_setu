import 'package:flutter/material.dart';

import '../../models/collection_task.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/task_service.dart';
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
  Map<String, AppUser> _workersById = {};

  /// Complaint UUID -> short display number (e.g. SS-260815-001), so task
  /// cards show a small ID instead of the raw UUID.
  Map<String, String> _complaintNumbers = {};
  List<CollectionTask> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    List<AppUser> workers;
    try {
      workers = await AuthService.instance.workers;
    } on Object {
      workers = [];
    }
    List<CollectionTask> tasks;
    try {
      tasks = await TaskService.instance.fetchAllTasks();
    } on Object {
      tasks = [];
    }
    List<dynamic> complaints;
    try {
      complaints = await ComplaintService.instance.fetchAllComplaints();
    } on Object {
      complaints = [];
    }
    if (!mounted) return;
    setState(() {
      _workersById = {
        for (final w in workers)
          if (w.workerId != null) w.workerId!: w,
      };
      _complaintNumbers = {
        for (final c in complaints) c.id: c.displayId,
      };
      _tasks = tasks;
      _loading = false;
    });
  }

  String _complaintNumber(String? complaintId) {
    if (complaintId == null) return '';
    return _complaintNumbers[complaintId] ?? complaintId;
  }

  static const _filters = [
    'All',
    'Assigned',
    'En Route',
    'Collecting',
    'Completed',
    'Rejected',
    'Revoked',
  ];

  List<CollectionTask> get _filteredTasks {
    final all = _tasks;
    if (_filter == 'All') return all;
    return all.where((t) => t.status.label == _filter).toList();
  }

  String _workerName(String? workerId) {
    if (workerId == null) return 'Unassigned';
    final worker = _workersById[workerId];
    return worker == null ? 'Worker $workerId' : worker.name;
  }

  Future<void> _revokeTask(BuildContext context, CollectionTask task) async {
    final workerName = _workerName(task.workerId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Revoke Task?'),
        content: Text(
          'Revoke this task from $workerName?\n\n'
          'It will be removed from the worker\'s queue and the citizen complaint '
          'returns to the unassigned state, so you can assign it to another '
          'worker.\n\nThis is only possible while the worker hasn\'t started '
          '(status: Assigned).',
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
      SnackBar(content: Text('Task revoked. It can be assigned to another worker.')),
    );
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
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
                      color: selected
                          ? (AppColors.isDark
                              ? const Color(0xFF111511)
                              : Colors.white)
                          : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTasks.isEmpty
                      ? Center(
                          child: Text(
                            _tasks.isEmpty
                                ? 'No tasks yet. Tap + to create and assign the first task.'
                                : 'No tasks in this status yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _filteredTasks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _buildTaskCard(context, _filteredTasks[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, CollectionTask task) {
    final isUnassigned = task.workerId == null;

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
          if (task.citizenComplaintId != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.contact_support_outlined,
                    size: 15, color: Color(0xFF00838F)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Resolves citizen complaint '
                    '#${_complaintNumber(task.citizenComplaintId)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00838F),
                    ),
                  ),
                ),
              ],
            ),
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
          if (!isUnassigned &&
              task.status == CollectionTaskStatus.assigned) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _revokeTask(context, task),
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: const Text('Revoke Task'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
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

