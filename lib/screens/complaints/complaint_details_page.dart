import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/app_repository.dart';
import '../../data/mock_data_repository.dart';
import '../../models/collection_task.dart';
import '../../models/complaint.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/progress_timeline.dart';
import '../../widgets/status_badge.dart';

class ComplaintDetailsPage extends StatelessWidget {
  const ComplaintDetailsPage({super.key, required this.complaintId});

  final String complaintId;

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final complaint = MockDataRepository.instance.getComplaintById(complaintId);

    if (complaint == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Complaint Details')),
        body: const Center(child: Text('Complaint not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'Complaint Details',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            complaint.category,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        StatusBadge(status: complaint.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(label: 'Complaint ID', value: complaint.id),
                    _DetailRow(label: 'Location', value: complaint.location),
                    _DetailRow(
                      label: 'Date Reported',
                      value: _formatDate(complaint.dateReported),
                    ),
                    if (complaint.assignedTo != null)
                      _DetailRow(
                          label: 'Assigned To', value: complaint.assignedTo!),
                    if (complaint.estimatedResolution != null)
                      _DetailRow(
                        label: 'Estimated Resolution',
                        value: complaint.estimatedResolution!,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      complaint.description,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reported Photo',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    _buildPhoto(complaint),
                    const SizedBox(height: 4),
                    Text(
                      'This photo is shared with the collection worker and the department Head when a task is created from this complaint.',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (complaint.status == ComplaintStatus.resolved)
                _ProofSection(complaintId: complaint.id),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tracking Progress',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ProgressTimeline(currentStep: complaint.timelineStep),
                    if (complaint.assignedTo != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.paleGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Assigned to ${complaint.assignedTo}',
                          style: TextStyle(
                            color: AppColors.darkGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(Complaint complaint) {
    final path = complaint.photoPath;
    if (path != null && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(path),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.paleGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 40,
            color: AppColors.primaryGreen.withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            complaint.hasPhoto
                ? 'Photo unavailable on this device'
                : 'No photo attached',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Shows the worker's proof-of-work photo once the waste has been collected
/// and the linked collection task completed by the pickup-truck worker.
class _ProofSection extends StatelessWidget {
  const _ProofSection({required this.complaintId});

  final String complaintId;

  @override
  Widget build(BuildContext context) {
    final task = AppRepository.instance.getProofForComplaint(complaintId);
    if (task == null) {
      return const SizedBox.shrink();
    }

    final path = task.proofPhotoPath;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: AppColors.primaryGreen, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Work Completed — Proof Photo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            task.status == CollectionTaskStatus.rejected
                ? 'The proof was rejected by the department Head. The worker has been asked to redo the work.'
                : 'The collection worker uploaded this photo after completing the work at the reported location.',
            style: TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          if (path != null && File(path).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(path),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.paleGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    task.status == CollectionTaskStatus.rejected
                        ? Icons.gpp_bad_outlined
                        : Icons.verified_outlined,
                    size: 36,
                    color: task.status == CollectionTaskStatus.rejected
                        ? Colors.redAccent
                        : AppColors.primaryGreen,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task.status == CollectionTaskStatus.rejected
                        ? 'Proof rejected by Head'
                        : 'Waste collected & work verified ✓',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: task.status == CollectionTaskStatus.rejected
                          ? Colors.redAccent
                          : AppColors.darkGreen,
                    ),
                  ),
                ],
              ),
            ),
          if (task.proofNote != null) ...[
            const SizedBox(height: 10),
            Text(
              task.proofNote!,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            )
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
