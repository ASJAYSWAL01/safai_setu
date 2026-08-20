import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/complaint.dart';
import '../../services/complaint_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/citizen_contact_bar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/viewable_image.dart';
import 'head_assign_task_page.dart';

class HeadCitizenComplaintsPage extends StatefulWidget {
  const HeadCitizenComplaintsPage({super.key});

  @override
  State<HeadCitizenComplaintsPage> createState() =>
      _HeadCitizenComplaintsPageState();
}

class _HeadCitizenComplaintsPageState extends State<HeadCitizenComplaintsPage> {
  late Future<List<Complaint>> _complaintsFuture;

  @override
  void initState() {
    super.initState();
    _complaintsFuture = ComplaintService.instance.fetchAllComplaints();
  }

  Future<void> _refresh() async {
    setState(() {
      _complaintsFuture = ComplaintService.instance.fetchAllComplaints();
    });
    await _complaintsFuture;
  }

  @override
  Widget build(BuildContext context) {
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
        child: FutureBuilder<List<Complaint>>(
          future: _complaintsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Could not load complaints.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final complaints = snapshot.data ?? [];

            if (complaints.isEmpty) {
              return Center(
                child: Text(
                  'No complaints yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primaryGreen,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            StatusBadge(status: complaint.status, compact: true),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#${complaint.displayId} · ${_formatDate(complaint.dateReported)}',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        if (complaint.citizenId != null) ...[
                          const SizedBox(height: 6),
                          CitizenContactBar(
                              citizenId: complaint.citizenId!),
                        ],
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
                        if (complaint.status == ComplaintStatus.rejected) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.isDark
                                  ? const Color(0xFFC62828).withOpacity(0.16)
                                  : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.cancel,
                                    size: 16,
                                    color: AppColors.isDark
                                        ? const Color(0xFFE57373)
                                        : const Color(0xFFC62828)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    complaint.rejectionReason == null
                                        ? 'Rejected by the department.'
                                        : 'Rejected: ${complaint.rejectionReason}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.isDark
                                          ? const Color(0xFFE57373)
                                          : const Color(0xFFC62828),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (complaint.status != ComplaintStatus.resolved) ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => HeadAssignTaskPage(
                                          preSelectedComplaintId:
                                              complaint.id,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add_task_rounded,
                                      size: 18),
                                  label: Text(
                                    complaint.status ==
                                            ComplaintStatus.rejected
                                        ? 'Re-assign Task'
                                        : 'Create Collection Task',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF1565C0),
                                    side: const BorderSide(
                                        color: Color(0xFF1565C0)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              if (complaint.status ==
                                  ComplaintStatus.pending) ...[
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: () => _rejectComplaint(complaint),
                                  icon: const Icon(Icons.close, size: 18),
                                  label: const Text('Reject'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(
                                        color: Colors.redAccent),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ],
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

  Future<void> _rejectComplaint(Complaint complaint) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Reject Complaint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject #${complaint.displayId}? The citizen will see the reason on their complaint.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                hintText: 'e.g. Location not found / not a waste issue',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return; // Cancelled.
    if (reason.isEmpty) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a reason for rejection.')),
      );
      return;
    }
    try {
      await ComplaintService.instance.rejectComplaint(complaint.id, reason);
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text('Could not reject complaint: $e'),
          backgroundColor: Colors.redAccent.shade200,
        ),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(this.context).showSnackBar(
      const SnackBar(content: Text('Complaint rejected.')),
    );
    await _refresh();
  }
}

class _ComplaintPhoto extends StatelessWidget {
  const _ComplaintPhoto({required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final path = complaint.photoPath;
    if (path != null &&
        (path.startsWith('http://') || path.startsWith('https://'))) {
      return ViewableImage(
        thumbnail: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            path,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(complaint),
          ),
        ),
        dialogImage: Image.network(
          path,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _placeholder(complaint),
        ),
      );
    }
    if (path != null && File(path).existsSync()) {
      return ViewableImage(
        thumbnail: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        dialogImage: Image.file(File(path), fit: BoxFit.contain),
      );
    }
    return _placeholder(complaint);
  }

  Widget _placeholder(Complaint complaint) {
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
            color: AppColors.textSecondary.withValues(alpha: 0.7),
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

