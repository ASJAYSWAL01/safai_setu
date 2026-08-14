import 'package:flutter/material.dart';

import '../../data/app_repository.dart';
import '../../models/collection_task.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dashboard_action_card.dart';
import '../../widgets/list_tiles.dart';
import '../../widgets/summary_stat_card.dart';
import 'worker_live_map_page.dart';
import 'worker_task_detail_page.dart';
import 'worker_tasks_page.dart';

class WorkerDashboardPage extends StatefulWidget {
  const WorkerDashboardPage({super.key});

  @override
  State<WorkerDashboardPage> createState() => _WorkerDashboardPageState();
}

class _WorkerDashboardPageState extends State<WorkerDashboardPage> {
  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final worker = AuthService.instance.user!;
    final tasks = AppRepository.instance.tasksForWorker(worker.workerId!);
    final pending =
        tasks.where((t) => t.status != CollectionTaskStatus.completed).length;
    final active = tasks
        .where((t) =>
            t.status == CollectionTaskStatus.enRoute ||
            t.status == CollectionTaskStatus.collecting)
        .length;
    final completed =
        tasks.where((t) => t.status == CollectionTaskStatus.completed).length;
    final location = AppRepository.instance.lastLocation(worker.workerId!);

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
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.paleGreen,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.local_shipping_rounded,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      AppCard(
                        child: Row(
                          children: [
                            Icon(
                              location == null
                                  ? Icons.location_off_outlined
                                  : Icons.location_on,
                              color: location == null
                                  ? AppColors.textSecondary
                                  : AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    location == null
                                        ? 'Location not shared yet'
                                        : 'Location shared with Head',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    location == null
                                        ? 'Open the Live Map tab to start sharing'
                                        : '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
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
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.28,
                        children: [
                          SummaryStatCard(
                            icon: Icons.assignment_outlined,
                            label: 'Assigned Tasks',
                            value: '$pending',
                            color: const Color(0xFF1565C0),
                            onTap: () =>
                                _push(context, const WorkerTasksPage()),
                          ),
                          SummaryStatCard(
                            icon: Icons.local_shipping_rounded,
                            label: 'In Progress',
                            value: '$active',
                            color: Colors.orange,
                            onTap: () =>
                                _push(context, const WorkerTasksPage()),
                          ),
                          SummaryStatCard(
                            icon: Icons.check_circle_outline,
                            label: 'Completed',
                            value: '$completed',
                            color: AppColors.primaryGreen,
                            onTap: () =>
                                _push(context, const WorkerTasksPage()),
                          ),
                          SummaryStatCard(
                            icon: Icons.photo_camera_outlined,
                            label: 'Proofs Submitted',
                            value: '$completed',
                            color: const Color(0xFF6A1B9A),
                            onTap: () =>
                                _push(context, const WorkerTasksPage()),
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
                      if (tasks.isEmpty)
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

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final CollectionTask task;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WorkerTaskDetailPage(taskId: task.id),
          ),
        );
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
