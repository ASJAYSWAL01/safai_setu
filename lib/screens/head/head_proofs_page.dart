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

class HeadProofsPage extends StatefulWidget {
  const HeadProofsPage({super.key});

  @override
  State<HeadProofsPage> createState() => _HeadProofsPageState();
}

class _HeadProofsPageState extends State<HeadProofsPage> {
  String _tab = 'Pending';

  @override
  Widget build(BuildContext context) {
    final pending = AppRepository.instance.pendingProofs;
    final reviewed = AppRepository.instance.completedTasks
        .where((t) => t.reviewedByHead)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'Proof Reviews',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  _TabButton(
                    label: 'Pending (${pending.length})',
                    selected: _tab == 'Pending',
                    onTap: () => setState(() => _tab = 'Pending'),
                  ),
                  const SizedBox(width: 8),
                  _TabButton(
                    label: 'Reviewed (${reviewed.length})',
                    selected: _tab == 'Reviewed',
                    onTap: () => setState(() => _tab = 'Reviewed'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _tab == 'Pending'
                  ? (pending.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No proofs waiting for review.\nWhen a worker completes a task with a photo, it appears here for your verification.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.textSecondary, height: 1.5),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: pending.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) => _PendingProofCard(
                            task: pending[index],
                            onReviewed: () => setState(() {}),
                          ),
                        ))
                  : (reviewed.isEmpty
                      ? Center(
                          child: Text(
                            'No reviewed proofs yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: reviewed.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _ReviewedProofCard(task: reviewed[index]),
                        )),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6A1B9A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF6A1B9A) : AppColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PendingProofCard extends StatelessWidget {
  const _PendingProofCard({required this.task, required this.onReviewed});

  final CollectionTask task;
  final VoidCallback onReviewed;

  String get _workerName {
    final worker =
        AuthService.instance.getWorkerByWorkerId(task.workerId ?? '');
    return worker?.name ?? (task.workerId ?? 'Unassigned');
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
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
              const TaskStatusBadge(status: CollectionTaskStatus.completed),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Worker: $_workerName (${task.workerId ?? '—'})',
            style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF6A1B9A),
                fontWeight: FontWeight.w600),
          ),
          if (task.citizenComplaintId != null) ...[
            const SizedBox(height: 2),
            Text(
              'Resolves citizen complaint #${task.citizenComplaintId}',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          _CitizenReportedStrip(task: task),
          const SizedBox(height: 12),
          _ProofImage(task: task),
          if (task.proofNote != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.mintBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                task.proofNote!,
                style: TextStyle(
                    fontSize: 12.5, color: AppColors.textPrimary, height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _review(context, approved: false),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _review(context, approved: true),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _review(BuildContext context, {required bool approved}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(approved ? 'Approve Proof?' : 'Reject Proof?'),
        content: Text(
          approved
              ? 'Approve this proof photo. The citizen will see the task as verified by the department.'
              : 'Rejecting sends the task back to the worker to redo the work and resubmit a new photo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  approved ? AppColors.primaryGreen : Colors.redAccent,
            ),
            child: Text(approved ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    if (approved) {
      AppRepository.instance.markProofReviewed(task.id);
    } else {
      AppRepository.instance.rejectProof(task.id);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approved
              ? 'Proof approved. Citizen notified.'
              : 'Proof rejected. Task sent back to the worker.',
        ),
      ),
    );
    onReviewed();
  }
}

class _ReviewedProofCard extends StatelessWidget {
  const _ReviewedProofCard({required this.task});

  final CollectionTask task;

  @override
  Widget build(BuildContext context) {
    final isRejected = task.status == CollectionTaskStatus.rejected;

    return AppCard(
      padding: const EdgeInsets.all(14),
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
          const SizedBox(height: 8),
          _CitizenReportedStrip(task: task),
          const SizedBox(height: 12),
          _ProofImage(task: task),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isRejected ? Icons.cancel : Icons.verified,
                size: 16,
                color: isRejected ? Colors.redAccent : AppColors.primaryGreen,
              ),
              const SizedBox(width: 6),
              Text(
                isRejected
                    ? 'Rejected — sent back to worker'
                    : 'Approved by Head',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isRejected ? Colors.redAccent : AppColors.darkGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shows the citizen's reported photo for comparison against the worker's
/// proof photo during review.
class _CitizenReportedStrip extends StatelessWidget {
  const _CitizenReportedStrip({required this.task});

  final CollectionTask task;

  @override
  Widget build(BuildContext context) {
    final complaint = task.citizenComplaintId == null
        ? null
        : MockDataRepository.instance
            .getComplaintById(task.citizenComplaintId!);
    if (complaint == null) return const SizedBox.shrink();

    final path = complaint.photoPath;
    final hasPhoto = path != null && File(path).existsSync();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF00838F).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00838F).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.contact_support_outlined,
                  size: 15, color: Color(0xFF00838F)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Citizen reported · #${complaint.id}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00838F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(path!),
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Row(
              children: [
                Icon(
                  complaint.hasPhoto
                      ? Icons.image_not_supported_outlined
                      : Icons.photo_camera_outlined,
                  size: 16,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  complaint.hasPhoto
                      ? 'Photo unavailable on this device'
                      : 'Citizen did not attach a photo',
                  style:
                      TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProofImage extends StatelessWidget {
  const _ProofImage({required this.task});

  final CollectionTask task;

  @override
  Widget build(BuildContext context) {
    final path = task.proofPhotoPath;
    if (path == null || !File(path).existsSync()) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.image_not_supported_outlined,
                color: Colors.grey, size: 30),
            const SizedBox(height: 6),
            Text(
              'Photo unavailable on this device',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(path),
        height: 170,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}
