import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/collection_task.dart';
import '../../models/complaint.dart';
import '../../services/complaint_service.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/citizen_contact_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/live_map_view.dart';
import '../../widgets/progress_timeline.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/viewable_image.dart';

class WorkerTaskDetailPage extends StatefulWidget {
  const WorkerTaskDetailPage({super.key, required this.taskId});

  final String taskId;

  @override
  State<WorkerTaskDetailPage> createState() => _WorkerTaskDetailPageState();
}

class _WorkerTaskDetailPageState extends State<WorkerTaskDetailPage> {
  final ImagePicker _picker = ImagePicker();
  final _noteController = TextEditingController();
  String? _photoPath;
  bool _isUpdating = false;
  CollectionTask? _task;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    CollectionTask? task;
    try {
      task = await TaskService.instance.getTaskById(widget.taskId);
    } on Object {
      task = null;
    }
    if (!mounted) return;
    setState(() {
      _task = task;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _takeProofPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (photo != null && mounted) {
        setState(() => _photoPath = photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(CollectionTaskStatus status) async {
    setState(() => _isUpdating = true);
    try {
      await TaskService.instance.updateTaskStatus(
        widget.taskId,
        status,
        localProofPhotoPath:
            status == CollectionTaskStatus.completed ? _photoPath : null,
        proofNote: status == CollectionTaskStatus.completed
            ? (_noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim())
            : null,
      );
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update the task: $e'),
          backgroundColor: Colors.redAccent.shade200,
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (status == CollectionTaskStatus.completed) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              const Expanded(child: Text('Task Completed!')),
            ],
          ),
          content: const Text(
            'Proof photo submitted. It has been sent to the citizen and the department Head for review.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    await _loadTask();
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Task Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Task Details')),
        body: const Center(child: Text('Task not found')),
      );
    }

    final isCompleted = task.status == CollectionTaskStatus.completed;
    final showProofInput =
        task.status == CollectionTaskStatus.collecting && !isCompleted;
    // Once the Head approves the proof, the progress timeline advances past
    // 'Collection In Progress' to 'Resolved' (the last timeline step).
    final isResolved = isCompleted && task.reviewedByHead;
    final progressStep =
        isResolved ? 4 : task.status.progressStep;

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'Collection Task',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTask,
          color: AppColors.primaryGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                            task.title,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TaskStatusBadge(status: task.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      task.description,
                      style: TextStyle(
                          color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Destination: ${task.latitude.toStringAsFixed(6)}, ${task.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              if (task.citizenComplaintId != null) ...[
                const SizedBox(height: 16),
                _CitizenPhotoCard(task: task),
              ],
              const SizedBox(height: 16),
              LiveMapView(
                height: 220,
                title: 'Task Destination',
                center: LatLng(task.latitude, task.longitude),
                markers: [
                  LiveMapMarker(
                    LatLng(task.latitude, task.longitude),
                    label: task.title,
                    icon: Icons.delete_outline,
                    color: const Color(0xFF1565C0),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Collection Progress',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ProgressTimeline(currentStep: progressStep),
                  ],
                ),
              ),
              if (showProofInput) ...[
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Proof of Work (Required)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Take a photo of the collected area as proof. It is shared with the citizen and your Head.',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _takeProofPhoto,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: AppColors.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _photoPath != null
                                  ? AppColors.primaryGreen
                                  : AppColors.borderColor,
                              width: _photoPath != null ? 1.5 : 1,
                            ),
                          ),
                          child: _photoPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: Image.file(
                                    File(_photoPath!),
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined,
                                        size: 36,
                                        color: AppColors.primaryGreen),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Take Proof Photo',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryGreen),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _noteController,
                        label: 'Work Note (optional)',
                        hint: 'e.g. Collected 3 bags of waste',
                        prefixIcon: Icons.notes_rounded,
                      ),
                    ],
                  ),
                ),
              ],
              if (isCompleted && task.proofPhotoPath != null) ...[
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Submitted Proof',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sent to citizen and Head on ${_formatTime(task.completedAt)}.',
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      if (task.proofPhotoPath!.startsWith('http'))
                        ViewableImage(
                          thumbnail: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              task.proofPhotoPath!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          dialogImage: Image.network(
                            task.proofPhotoPath!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        )
                      else if (File(task.proofPhotoPath!).existsSync())
                        ViewableImage(
                          thumbnail: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(task.proofPhotoPath!),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          dialogImage:
                              Image.file(File(task.proofPhotoPath!), fit: BoxFit.contain),
                        ),
                      if (task.proofNote != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          task.proofNote!,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: task.reviewedByHead
                              ? AppColors.paleGreen
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          task.reviewedByHead
                              ? '✓ Reviewed by Head'
                              : '⏳ Awaiting Head review',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: task.reviewedByHead
                                ? AppColors.darkGreen
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildActionButtons(task),
              const SizedBox(height: 16),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(CollectionTask task) {
    switch (task.status) {
      case CollectionTaskStatus.assigned:
        return CustomButton(
          label: 'Start — Go En Route',
          icon: Icons.route_outlined,
          isLoading: _isUpdating,
          onPressed: () => _updateStatus(CollectionTaskStatus.enRoute),
        );
      case CollectionTaskStatus.enRoute:
        return CustomButton(
          label: 'Start Collecting Waste',
          icon: Icons.delete_sweep_outlined,
          isLoading: _isUpdating,
          onPressed: () => _updateStatus(CollectionTaskStatus.collecting),
        );
      case CollectionTaskStatus.collecting:
        return Column(
          children: [
            if (_photoPath == null)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Add a proof photo before completing',
                  style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
            CustomButton(
              label: 'Complete Task with Proof',
              icon: Icons.verified_outlined,
              isLoading: _isUpdating,
              onPressed: _photoPath == null
                  ? null
                  : () => _updateStatus(CollectionTaskStatus.completed),
            ),
          ],
        );
      case CollectionTaskStatus.completed:
        return const SizedBox.shrink();
      case CollectionTaskStatus.rejected:
        return CustomButton(
          label: 'Restart Task',
          icon: Icons.refresh_rounded,
          isLoading: _isUpdating,
          onPressed: () => _updateStatus(CollectionTaskStatus.assigned),
        );
      case CollectionTaskStatus.revoked:
        // Revoked tasks leave the worker's queue (the Head clears the worker),
        // so this is only reachable from a stale screen.
        return const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'This task was revoked by your Head and is no longer assigned to you.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.w600),
          ),
        );
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '—';
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Shows the citizen's reported photo for tasks created from a citizen
/// complaint, so the worker can see exactly what was reported. Fetched from
/// Supabase so the URL works on the worker's device.
class _CitizenPhotoCard extends StatefulWidget {
  const _CitizenPhotoCard({required this.task});

  final CollectionTask task;

  @override
  State<_CitizenPhotoCard> createState() => _CitizenPhotoCardState();
}

class _CitizenPhotoCardState extends State<_CitizenPhotoCard> {
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.contact_support_outlined,
                  color: Color(0xFF1565C0), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Citizen Reported — #${complaint.displayId}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          if (complaint.citizenId != null) ...[
            const SizedBox(height: 4),
            CitizenContactBar(citizenId: complaint.citizenId!),
          ],
          const SizedBox(height: 4),
          Text(
            '${complaint.category} · ${complaint.location}',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          if (isUrl)
            ViewableImage(
              thumbnail: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  path!,
                  height: 160,
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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                    size: 18,
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    complaint.hasPhoto
                        ? 'Photo unavailable on this device'
                        : 'Citizen did not attach a photo',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            complaint.description,
            style: TextStyle(
                fontSize: 12.5, color: AppColors.textPrimary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
