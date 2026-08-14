import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/mock_data_repository.dart';
import '../../models/complaint.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import 'head_assign_task_page.dart';

class HeadCitizenComplaintsPage extends StatelessWidget {
  const HeadCitizenComplaintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final complaints = MockDataRepository.instance.complaints;

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'Citizen Complaints',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: complaints.isEmpty
            ? Center(
                child: Text(
                  'No complaints yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: complaints.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final complaint = complaints[index];
                  return AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                complaint.category,
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                            StatusBadge(
                                status: complaint.status, compact: true),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${complaint.id} · ${_formatDate(complaint.dateReported)}',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        _ComplaintPhoto(complaint: complaint),
                        const SizedBox(height: 10),
                        Text(
                          complaint.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                              height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 15, color: Colors.orange),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                complaint.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (complaint.status != ComplaintStatus.resolved) ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => HeadAssignTaskPage(
                                      preSelectedComplaintId: complaint.id,
                                    ),
                                  ),
                                );
                              },
                              icon:
                                  const Icon(Icons.add_task_rounded, size: 18),
                              label: const Text('Create Collection Task'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1565C0),
                                side:
                                    const BorderSide(color: Color(0xFF1565C0)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ] else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.paleGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle,
                                    size: 16, color: AppColors.primaryGreen),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Already resolved — task completed by a worker.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

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
}

class _ComplaintPhoto extends StatelessWidget {
  const _ComplaintPhoto({required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final path = complaint.photoPath;
    if (path != null && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(path),
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      height: 70,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.mintBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            complaint.hasPhoto
                ? Icons.image_not_supported_outlined
                : Icons.photo_camera_outlined,
            size: 20,
            color: AppColors.textSecondary.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Text(
            complaint.hasPhoto
                ? 'Photo unavailable on this device'
                : 'No photo attached',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
