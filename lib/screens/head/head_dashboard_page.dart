import 'package:flutter/material.dart';

import '../../data/app_repository.dart';
import '../../models/collection_task.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dashboard_action_card.dart';
import '../../widgets/summary_stat_card.dart';
import 'head_assign_task_page.dart';
import 'head_citizen_complaints_page.dart';
import 'head_generate_worker_id_page.dart';
import 'head_proofs_page.dart';
import 'head_tasks_page.dart';
import 'head_worker_detail_page.dart';
import 'head_workers_page.dart';

class HeadDashboardPage extends StatefulWidget {
  const HeadDashboardPage({super.key});

  @override
  State<HeadDashboardPage> createState() => _HeadDashboardPageState();
}

class _HeadDashboardPageState extends State<HeadDashboardPage> {
  Future<void> _refresh() async {
    // Simulate a short refresh; singletons are re-read on rebuild.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() {});
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final head = AuthService.instance.user!;
    final workers = AuthService.instance.workers;
    final tasks = AppRepository.instance.tasks;
    final activeTasks =
        tasks.where((t) => t.status != CollectionTaskStatus.completed).length;
    final pendingProofs = AppRepository.instance.pendingProofs.length;

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
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6A1B9A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_outlined,
                              color: Color(0xFF6A1B9A),
                            ),
                          ),
                        ],
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
                            icon: Icons.groups_outlined,
                            label: 'Workers',
                            value: '${workers.length}',
                            color: const Color(0xFF6A1B9A),
                            onTap: () =>
                                _push(context, const HeadWorkersPage()),
                          ),
                          SummaryStatCard(
                            icon: Icons.assignment_outlined,
                            label: 'Active Tasks',
                            value: '$activeTasks',
                            color: const Color(0xFF1565C0),
                            onTap: () => _push(context, const HeadTasksPage()),
                          ),
                          SummaryStatCard(
                            icon: Icons.check_circle_outline,
                            label: 'Completed',
                            value:
                                '${AppRepository.instance.completedTasks.length}',
                            color: AppColors.primaryGreen,
                            onTap: () => _push(
                              context,
                              const HeadTasksPage(initialFilter: 'Completed'),
                            ),
                          ),
                          SummaryStatCard(
                            icon: Icons.photo_library_outlined,
                            label: 'Pending Proofs',
                            value: '$pendingProofs',
                            color: pendingProofs > 0
                                ? Colors.orange
                                : AppColors.primaryGreen,
                            onTap: () => _push(context, const HeadProofsPage()),
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
                      const SectionHeader(
                        title: 'Worker Live Locations',
                        actionLabel: 'View All',
                        onActionTap: null,
                      ),
                      const SizedBox(height: 8),
                      ...workers.map(
                        (worker) => AppCard(
                          padding: const EdgeInsets.all(14),
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
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    const Color(0xFF1565C0).withOpacity(0.1),
                                child: Text(
                                  worker.name[0],
                                  style: TextStyle(
                                    color: Color(0xFF1565C0),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                              _LocationStatus(workerId: worker.id),
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

class _LocationStatus extends StatelessWidget {
  const _LocationStatus({required this.workerId});

  final String workerId;

  @override
  Widget build(BuildContext context) {
    final location = AppRepository.instance.lastLocation(workerId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: location == null
            ? Colors.grey.withOpacity(0.1)
            : AppColors.paleGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        location == null ? 'Offline' : 'Live',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: location == null
              ? AppColors.textSecondary
              : AppColors.primaryGreen,
        ),
      ),
    );
  }
}
