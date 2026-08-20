import 'package:flutter/material.dart';

import '../../models/collection_task.dart';
import '../../models/complaint.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/citizen_contact_bar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/viewable_image.dart';

class HeadProofsPage extends StatefulWidget {
  const HeadProofsPage({super.key});

  @override
  State<HeadProofsPage> createState() => _HeadProofsPageState();
}

class _HeadProofsPageState extends State<HeadProofsPage> {
  String _tab = 'Pending';
  Map<String, AppUser> _workersById = {};
  Map<String, String> _complaintNumbers = {};
  List<CollectionTask> _pending = [];
  List<CollectionTask> _reviewed = [];
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
    List<CollectionTask> pending;
    List<CollectionTask> reviewed;
    try {
      pending = await TaskService.instance.fetchProofTasks(reviewedByHead: false);
      reviewed = await TaskService.instance.fetchProofTasks(reviewedByHead: true);
    } on Object {
      pending = [];
      reviewed = [];
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
      _pending = pending;
      _reviewed = reviewed;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    final reviewed = _reviewed;

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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                                        color: AppColors.textSecondary,
                                        height: 1.5),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(20),
                                itemCount: pending.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (context, index) =>
                                    _PendingProofCard(
                                  task: pending[index],
                                  onReviewed: () => _loadData(),
                                  workersById: _workersById,
                                  complaintNumbers: _complaintNumbers,
                                ),
                              ))
                        : (reviewed.isEmpty
                            ? Center(
                                child: Text(
                                  'No reviewed proofs yet.',
                                  style: TextStyle(
                                      color: AppColors.textSecondary),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(20),
                                itemCount: reviewed.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) =>
                                    _ReviewedProofCard(
                                        task: reviewed[index]),
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
          color: selected ? const Color(0xFF6A1B9A) : AppColors.cardColor,
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
            color: selected
                ? (AppColors.isDark ? const Color(0xFF111511) : Colors.white)
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PendingProofCard extends StatelessWidget {
  const _PendingProofCard({
    required this.task,
    required this.onReviewed,
    required this.workersById,
    required this.complaintNumbers,
  });

  final CollectionTask task;
  final VoidCallback onReviewed;
  final Map<String, AppUser> workersById;
  final Map<String, String> complaintNumbers;

  String get _workerName {
    final workerId = task.workerId;
    final worker = workerId == null ? null : workersById[workerId];
    return worker?.name ?? (workerId ?? 'Unassigned');
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
              'Resolves citizen complaint #${complaintNumbers[task.citizenComplaintId] ?? task.citizenComplaintId}',
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

    try {
      if (approved) {
        await TaskService.instance.markProofReviewed(task.id);
        // Close the loop for the citizen: their complaint becomes resolved.
        final complaintId = task.citizenComplaintId;
        if (complaintId != null) {
          try {
            await ComplaintService.instance.resolveComplaint(complaintId);
          } on Object catch (e) {
            debugPrint('Failed to resolve complaint $complaintId: $e');
          }
        }
      } else {
        await TaskService.instance.rejectProof(task.id);
      }
    } on Object catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save review: $e'),
          backgroundColor: Colors.redAccent.shade200,
        ),
      );
      return;
    }
    if (!context.mounted) return;
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
/// proof photo during review. The complaint is fetched from Supabase so the
/// photo URL works on the Head's device.
class _CitizenReportedStrip extends StatefulWidget {
  const _CitizenReportedStrip({required this.task});

  final CollectionTask task;

  @override
  State<_CitizenReportedStrip> createState() => _CitizenReportedStripState();
}

class _CitizenReportedStripState extends State<_CitizenReportedStrip> {
  Complaint? _complaint;

  @override
  void initState() {
    super.initState();
    final id = widget.task.citizenComplaintId;
    if (id != null) {
      ComplaintService.instance.getComplaintById(id).then((complaint) {
        if (mounted) setState(() => _complaint = complaint);
      }).catchError((_) {
        if (mounted) setState(() => _complaint = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaint = _complaint;
    if (complaint == null) return const SizedBox.shrink();

    final path = complaint.photoPath;
    final isUrl = path != null &&
        (path.startsWith('http://') || path.startsWith('https://'));

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
                  'Citizen reported · #${complaint.displayId}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00838F),
                  ),
                ),
              ),
            ],
          ),
          if (complaint.citizenId != null) ...[
            const SizedBox(height: 6),
            CitizenContactBar(citizenId: complaint.citizenId!),
          ],
          const SizedBox(height: 8),
          if (isUrl)
            ViewableImage(
              thumbnail: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  path!,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              dialogImage: Image.network(
                path!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
    final isUrl = path != null &&
        (path.startsWith('http://') || path.startsWith('https://'));
    if (path == null || !isUrl) {
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
    return ViewableImage(
      thumbnail: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          path!,
          height: 170,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Photo unavailable on this device',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ),
      ),
      dialogImage: Image.network(
        path!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
