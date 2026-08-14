import 'package:flutter/material.dart';

import '../../data/app_repository.dart';
import '../../models/collection_task.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import 'worker_task_detail_page.dart';

class WorkerTasksPage extends StatelessWidget {
  const WorkerTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final worker = AuthService.instance.user!;
    final tasks = AppRepository.instance.tasksForWorker(worker.workerId!);

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'My Collection Tasks',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: tasks.isEmpty
            ? Center(
                child: Text(
                  'No tasks assigned yet.\nYour Head will assign tasks to your Worker ID.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _TaskCard(task: tasks[index]),
              ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final CollectionTask task;

  @override
  Widget build(BuildContext context) {
    final color = task.status == CollectionTaskStatus.completed
        ? AppColors.primaryGreen
        : const Color(0xFF1565C0);

    return AppCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WorkerTaskDetailPage(taskId: task.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              TaskStatusBadge(status: task.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${task.latitude.toStringAsFixed(6)}, ${task.longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color),
                ),
              ),
              if (task.status == CollectionTaskStatus.completed)
                Text(
                  'Proof ✓',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
