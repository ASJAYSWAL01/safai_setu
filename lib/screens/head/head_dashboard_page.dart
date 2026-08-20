import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/collection_task.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_tour.dart';
import '../../widgets/dashboard_action_card.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/summary_stat_card.dart';
import '../../widgets/worker_avatar.dart';
import 'head_assign_task_page.dart';
import 'head_citizen_complaints_page.dart';
import 'head_generate_worker_id_page.dart';
import 'head_live_map_page.dart';
import 'head_profile_page.dart';
import 'head_proofs_page.dart';
import 'head_tasks_page.dart';
import 'head_worker_detail_page.dart';
import 'head_workers_page.dart';

class HeadDashboardPage extends StatefulWidget {
  const HeadDashboardPage({super.key});

  @override
  State<HeadDashboardPage> createState() => _HeadDashboardPageState();
}

class _HeadDashboardPageState extends State<HeadDashboardPage>
    with SingleTickerProviderStateMixin {
  List<AppUser> _workers = [];
  List<CollectionTask> _tasks = [];
  int _pendingProofs = 0;
  late final AnimationController _animCtrl;
  late final List<Animation<double>> _tileOpacities;
  late final List<Animation<Offset>> _tileOffsets;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _tileOpacities = List.generate(
      4,
      (i) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animCtrl,
          curve: Interval(
            0.05 + 0.12 * i,
            0.05 + 0.12 * i + 0.55,
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
    _tileOffsets = List.generate(
      4,
      (i) => Tween<Offset>(
        begin: const Offset(0.0, 0.25),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animCtrl,
          curve: Interval(
            0.05 + 0.12 * i,
            0.05 + 0.12 * i + 0.55,
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
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
    int pendingProofs;
    try {
      pendingProofs = await TaskService.instance
          .fetchProofTasks(reviewedByHead: false)
          .then((t) => t.length);
    } on Object {
      pendingProofs = 0;
    }
    if (!mounted) return;
    setState(() {
      _workers = workers;
      _tasks = tasks;
      _pendingProofs = pendingProofs;
    });
    _animCtrl.forward();
  }

  Future<void> _refresh() async {
    await _loadData();
    if (mounted) setState(() {});
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final head = AuthService.instance.user!;
    final workers = _workers;
    final tasks = _tasks;
    final activeTasks = tasks
        .where((t) =>
            t.status != CollectionTaskStatus.completed &&
            t.status != CollectionTaskStatus.revoked)
        .length;
    final pendingProofs = _pendingProofs;

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primaryGreen,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Head Portal',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Manage workers, tasks & proofs',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary
                                        .withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Welcome, ${head.name.split(' ').first} 🏛️',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ProfileAvatar(
                            radius: 22,
                            accent: const Color(0xFF6A1B9A),
                            onTap: () =>
                                _push(context, const HeadProfilePage()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        key: TourKeys.statGridKey,
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.28,
                        children: [
                          _AnimatedStatTile(
                            opacity: _tileOpacities[0],
                            offset: _tileOffsets[0],
                            child: SummaryStatCard(
                              key: TourKeys.statTileKeys[0],
                              icon: Icons.groups_outlined,
                              label: 'Workers',
                              value: '${workers.length}',
                              color: const Color(0xFF6A1B9A),
                              onTap: () =>
                                  _push(context, const HeadWorkersPage()),
                            ),
                          ),
                          _AnimatedStatTile(
                            opacity: _tileOpacities[1],
                            offset: _tileOffsets[1],
                            child: SummaryStatCard(
                              key: TourKeys.statTileKeys[1],
                              icon: Icons.assignment_outlined,
                              label: 'Active Tasks',
                              value: '$activeTasks',
                              color: const Color(0xFF1565C0),
                              onTap: () => _push(context, const HeadTasksPage()),
                            ),
                          ),
                          _AnimatedStatTile(
                            opacity: _tileOpacities[2],
                            offset: _tileOffsets[2],
                            child: SummaryStatCard(
                              key: TourKeys.statTileKeys[2],
                              icon: Icons.check_circle_outline,
                              label: 'Completed',
                              value:
                                  '${tasks.where((t) => t.status == CollectionTaskStatus.completed).length}',
                              color: AppColors.primaryGreen,
                              onTap: () => _push(
                                context,
                                const HeadTasksPage(initialFilter: 'Completed'),
                              ),
                            ),
                          ),
                          _AnimatedStatTile(
                            opacity: _tileOpacities[3],
                            offset: _tileOffsets[3],
                            child: SummaryStatCard(
                              key: TourKeys.statTileKeys[3],
                              icon: Icons.photo_library_outlined,
                              label: 'Pending Proofs',
                              value: '$pendingProofs',
                              color: pendingProofs > 0
                                  ? Colors.orange
                                  : AppColors.primaryGreen,
                              onTap: () => _push(context, const HeadProofsPage()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Quick Actions'),
                      const SizedBox(height: 12),
                      DashboardActionCard(
                        icon: Icons.badge_outlined,
                        title: 'Generate Worker ID',
                        subtitle:
                            'Create a new worker account with a unique ID',
                        color: const Color(0xFF6A1B9A),
                        onTap: () =>
                            _push(context, const HeadGenerateWorkerIdPage()),
                      ),
                      const SizedBox(height: 12),
                      DashboardActionCard(
                        icon: Icons.add_task_rounded,
                        title: 'Assign Collection Task',
                        subtitle:
                            'Create a task with coordinates and assign a worker',
                        color: const Color(0xFF1565C0),
                        onTap: () => _push(context, const HeadAssignTaskPage()),
                      ),
                      const SizedBox(height: 12),
                      DashboardActionCard(
                        icon: Icons.contact_support_outlined,
                        title: 'Citizen Complaints',
                        subtitle:
                            'See reported photos and create collection tasks from complaints',
                        color: const Color(0xFF00838F),
                        onTap: () =>
                            _push(context, const HeadCitizenComplaintsPage()),
                      ),
                      const SizedBox(height: 12),
                      DashboardActionCard(
                        icon: Icons.photo_library_outlined,
                        title: 'Review Proof Photos',
                        subtitle: pendingProofs > 0
                            ? '$pendingProofs proof(s) waiting for your review'
                            : 'No pending proof reviews',
                        color: pendingProofs > 0
                            ? Colors.orange
                            : AppColors.primaryGreen,
                        onTap: () => _push(context, const HeadProofsPage()),
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(
                        title: 'Worker Live Locations',
                        actionLabel: 'View All',
                        onActionTap: () =>
                            _push(context, const HeadLiveMapPage()),
                      ),
                      const SizedBox(height: 8),
                      ...workers.map(
                        (worker) => AppCard(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 10),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    HeadWorkerDetailPage(workerId: worker.id),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              WorkerAvatar(
                                name: worker.name,
                                photoUrl: worker.photoUrl,
                                radius: 20,
                                accent: const Color(0xFF1565C0),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      worker.name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                    ),
                                    Text(
                                      '${worker.workerId} · ${worker.vehicleNumber}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              _LocationStatus(workerId: worker.workerId),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const SectionHeader(title: 'Worker Activity'),
                      const SizedBox(height: 8),
                      ...tasks.take(3).map(
                            (task) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Icon(
                                    task.status ==
                                            CollectionTaskStatus.completed
                                        ? Icons.check_circle
                                        : Icons.schedule,
                                    size: 18,
                                    color: task.status ==
                                            CollectionTaskStatus.completed
                                        ? AppColors.primaryGreen
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${task.title} — ${task.status.label}',
                                      style: TextStyle(fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedStatTile extends StatelessWidget {
  const _AnimatedStatTile({
    required this.opacity,
    required this.offset,
    required this.child,
  });

  final Animation<double> opacity;
  final Animation<Offset> offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        position: offset,
        child: child,
      ),
    );
  }
}

class _LocationStatus extends StatefulWidget {
  const _LocationStatus({required this.workerId});

  final String? workerId;

  @override
  State<_LocationStatus> createState() => _LocationStatusState();
}

class _LocationStatusState extends State<_LocationStatus> {
  WorkerLocation? _location;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.workerId != null) {
      _refresh();
      _timer =
          Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
    }
  }

  Future<void> _refresh() async {
    final workerId = widget.workerId;
    if (workerId == null) return;
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

  @override
  Widget build(BuildContext context) {
    final location = _location;
    final isLive = location?.isLive ?? false;
    final isSharing = location?.isSharing ?? false;

    final color = isLive
        ? AppColors.primaryGreen
        : (isSharing ? Colors.orange : AppColors.textSecondary);
    final label = isLive
        ? 'Live'
        : (isSharing ? 'Paused' : 'Offline');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isLive
            ? AppColors.paleGreen
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLive ? Icons.sensors : Icons.sensors_off,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
