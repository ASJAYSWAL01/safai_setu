import 'package:flutter/material.dart';

import '../../models/collection_task.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_tour.dart';
import '../../widgets/dashboard_action_card.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/summary_stat_card.dart';
import 'worker_live_map_page.dart';
import 'worker_profile_page.dart';
import 'worker_task_detail_page.dart';
import 'worker_tasks_page.dart';

class WorkerDashboardPage extends StatefulWidget {
  const WorkerDashboardPage({super.key});

  @override
  State<WorkerDashboardPage> createState() => _WorkerDashboardPageState();
}

class _WorkerDashboardPageState extends State<WorkerDashboardPage>
    with SingleTickerProviderStateMixin {
  List<CollectionTask> _tasks = [];
  bool _loading = true;
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
    _loadTasks();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final workerId = AuthService.instance.user?.workerId;
    List<CollectionTask> tasks;
    if (workerId == null) {
      tasks = [];
    } else {
      try {
        tasks = await TaskService.instance.fetchTasksForWorker(workerId);
      } on Object {
        tasks = [];
      }
    }
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
    _animCtrl.forward();
  }

  Future<void> _refresh() async {
    await _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final worker = AuthService.instance.user!;
    final tasks = _tasks;
    final pending =
        tasks.where((t) => t.status != CollectionTaskStatus.completed).length;
    final active = tasks
        .where((t) =>
            t.status == CollectionTaskStatus.enRoute ||
            t.status == CollectionTaskStatus.collecting)
        .length;
    final completed =
        tasks.where((t) => t.status == CollectionTaskStatus.completed).length;

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
                                  'Worker Portal',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Worker ID: ${worker.workerId}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary
                                        .withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Hello, ${worker.name.split(' ').first} 👋',
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
                            onTap: () =>
                                _push(context, const WorkerProfilePage()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      AppCard(
                        child: Row(
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${tasks.length} tasks assigned',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    tasks.isEmpty
                                        ? 'Your Head will assign tasks to your Worker ID'
                                        : '$pending pending · $completed completed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                              icon: Icons.assignment_outlined,
                              label: 'Assigned Tasks',
                              value: '$pending',
                              color: const Color(0xFF1565C0),
                              onTap: () =>
                                  _push(context, const WorkerTasksPage()),
                            ),
                          ),
                          _AnimatedStatTile(
                            opacity: _tileOpacities[1],
                            offset: _tileOffsets[1],
                            child: SummaryStatCard(
                              key: TourKeys.statTileKeys[1],
                              icon: Icons.local_shipping_rounded,
                              label: 'In Progress',
                              value: '$active',
                              color: Colors.orange,
                              onTap: () =>
                                  _push(context, const WorkerTasksPage()),
                            ),
                          ),
                          _AnimatedStatTile(
                            opacity: _tileOpacities[2],
                            offset: _tileOffsets[2],
                            child: SummaryStatCard(
                              key: TourKeys.statTileKeys[2],
                              icon: Icons.check_circle_outline,
                              label: 'Completed',
                              value: '$completed',
                              color: AppColors.primaryGreen,
                              onTap: () =>
                                  _push(context, const WorkerTasksPage()),
                            ),
                          ),
                          _AnimatedStatTile(
                            opacity: _tileOpacities[3],
                            offset: _tileOffsets[3],
                            child: SummaryStatCard(
                              key: TourKeys.statTileKeys[3],
                              icon: Icons.photo_camera_outlined,
                              label: 'Proofs Submitted',
                              value: '$completed',
                              color: const Color(0xFF6A1B9A),
                              onTap: () =>
                                  _push(context, const WorkerTasksPage()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Quick Actions'),
                      const SizedBox(height: 12),
                      DashboardActionCard(
                        icon: Icons.map_outlined,
                        title: 'Share Live Location',
                        subtitle:
                            'Show your coordinates on Google Map for the Head',
                        color: const Color(0xFF1565C0),
                        onTap: () => _push(context, const WorkerLiveMapPage()),
                      ),
                      const SizedBox(height: 12),
                      DashboardActionCard(
                        icon: Icons.assignment_outlined,
                        title: 'My Collection Tasks',
                        subtitle:
                            'View and update assigned waste collection tasks',
                        color: AppColors.primaryGreen,
                        onTap: () => _push(context, const WorkerTasksPage()),
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: "Today's Tasks"),
                      const SizedBox(height: 8),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (tasks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No tasks assigned yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        ...tasks.take(3).map((task) => _TaskTile(task: task)),
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

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
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

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final CollectionTask task;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WorkerTaskDetailPage(taskId: task.id),
          ),
        );
        // Reflect status changes made in the detail page (e.g. completed).
        final state =
            context.findAncestorStateOfType<_WorkerDashboardPageState>();
        state?._loadTasks();
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: task.status == CollectionTaskStatus.completed
                  ? AppColors.paleGreen
                  : const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              task.status == CollectionTaskStatus.completed
                  ? Icons.check_circle
                  : Icons.delete_outline,
              color: task.status == CollectionTaskStatus.completed
                  ? AppColors.primaryGreen
                  : const Color(0xFF1565C0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${task.latitude.toStringAsFixed(4)}, ${task.longitude.toStringAsFixed(4)}',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            task.status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: task.status == CollectionTaskStatus.completed
                  ? AppColors.primaryGreen
                  : const Color(0xFF1565C0),
            ),
          ),
        ],
      ),
    );
  }
}
