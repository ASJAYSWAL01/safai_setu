import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/collection_task.dart';
import '../../models/complaint.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/live_map_view.dart';
import '../../widgets/viewable_image.dart';

class HeadAssignTaskPage extends StatefulWidget {
  const HeadAssignTaskPage({
    super.key,
    this.preSelectedWorkerId,
    this.preSelectedTaskId,
    this.preSelectedComplaintId,
  });

  /// When opened from a worker detail page, preselect that worker.
  final String? preSelectedWorkerId;

  /// When opened from the tasks page, preselect the task coordinates.
  final String? preSelectedTaskId;

  /// When opened from the citizen-complaints page, create a task that resolves
  /// this complaint and carries its reported photo to the worker.
  final String? preSelectedComplaintId;

  @override
  State<HeadAssignTaskPage> createState() => _HeadAssignTaskPageState();
}

class _HeadAssignTaskPageState extends State<HeadAssignTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  String? _selectedWorkerId;
  String? _linkedComplaintId;
  Complaint? _linkedComplaint;
  bool _isCreating = false;
  List<AppUser> _workers = [];

  @override
  void initState() {
    super.initState();
    _loadWorkers();

    if (widget.preSelectedTaskId != null) {
      _loadPresetTask(widget.preSelectedTaskId!);
    }

    if (widget.preSelectedComplaintId != null) {
      _loadLinkedComplaint(widget.preSelectedComplaintId!);
    }
  }

  Future<void> _loadPresetTask(String taskId) async {
    CollectionTask? preset;
    try {
      preset = await TaskService.instance.getTaskById(taskId);
    } on Object {
      preset = null;
    }
    if (!mounted || preset == null) return;
    final title = preset.title;
    final description = preset.description;
    final lat = preset.latitude;
    final lng = preset.longitude;
    setState(() {
      _titleController.text = title;
      _descriptionController.text = description;
      _latController.text = lat.toString();
      _lngController.text = lng.toString();
    });
  }

  Future<void> _loadLinkedComplaint(String complaintId) async {
    Complaint? complaint;
    try {
      complaint =
          await ComplaintService.instance.getComplaintById(complaintId);
    } on Object {
      complaint = null;
    }
    if (!mounted) return;
    setState(() {
      _linkedComplaint = complaint;
      if (complaint != null) {
        _linkedComplaintId = complaint.id;
        _titleController.text = complaint.category;
        _descriptionController.text = complaint.description;
        _latController.text = (complaint.latitude ?? 23.2156).toString();
        _lngController.text = (complaint.longitude ?? 72.6369).toString();
      }
    });
  }

  Future<void> _loadWorkers() async {
    List<AppUser> workers;
    try {
      workers = await AuthService.instance.workers;
    } on Object {
      workers = [];
    }
    if (!mounted) return;
    setState(() {
      _workers = workers;
      _selectedWorkerId = widget.preSelectedWorkerId ??
          (workers.isNotEmpty ? workers.first.workerId : null);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  double? _parseCoord(String value) => double.tryParse(value.trim());

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;
    final lat = _parseCoord(_latController.text);
    final lng = _parseCoord(_lngController.text);
    if (lat == null || lng == null) return;

    setState(() => _isCreating = true);
    try {
      if (widget.preSelectedTaskId != null) {
        // Re-assigning an existing unassigned task.
        await TaskService.instance
            .assignTask(widget.preSelectedTaskId!, _selectedWorkerId!);
      } else {
        await TaskService.instance.createTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          latitude: lat,
          longitude: lng,
          workerId: _selectedWorkerId,
          citizenComplaintId: _linkedComplaintId,
        );
      }
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save the task: $e'),
          backgroundColor: Colors.redAccent.shade200,
        ),
      );
      return;
    }
    if (!mounted) return;

    AppUser? worker;
    try {
      worker =
          await AuthService.instance.getWorkerByWorkerId(_selectedWorkerId!);
    } on Object {
      worker = null;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.preSelectedTaskId != null
              ? 'Task assigned to ${worker?.name ?? _selectedWorkerId}'
              : 'Task created and assigned to ${worker?.name ?? _selectedWorkerId}',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final workers = _workers;
    final lat = _parseCoord(_latController.text);
    final lng = _parseCoord(_lngController.text);
    final showMap = lat != null && lng != null;
    final linkedComplaint = _linkedComplaint;

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          widget.preSelectedTaskId != null
              ? 'Assign Existing Task'
              : linkedComplaint != null
                  ? 'Task from Complaint'
                  : 'Create Collection Task',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (linkedComplaint != null) ...[
                  _ComplaintLinkBanner(complaint: linkedComplaint),
                  const SizedBox(height: 16),
                ],
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        controller: _titleController,
                        label: 'Task Title',
                        hint: 'e.g. Sector 10 — Community Park',
                        prefixIcon: Icons.title_outlined,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Title is required'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'What waste needs to be collected?',
                        prefixIcon: Icons.notes_rounded,
                        maxLines: 3,
                        minLines: 2,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Description is required'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _latController,
                              label: 'Latitude',
                              hint: 'e.g. 23.2156',
                              prefixIcon: Icons.explore_outlined,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true, signed: true),
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.\-]')),
                              ],
                              validator: (value) {
                                final parsed = _parseCoord(value ?? '');
                                if (parsed == null ||
                                    parsed < -90 ||
                                    parsed > 90) {
                                  return 'Invalid latitude';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              controller: _lngController,
                              label: 'Longitude',
                              hint: 'e.g. 72.6369',
                              prefixIcon: Icons.explore_outlined,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true, signed: true),
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.\-]')),
                              ],
                              validator: (value) {
                                final parsed = _parseCoord(value ?? '');
                                if (parsed == null ||
                                    parsed < -180 ||
                                    parsed > 180) {
                                  return 'Invalid longitude';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Assign To (Pickup Truck Worker)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedWorkerId,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person_outline,
                              size: 22, color: AppColors.primaryGreen),
                          hintText: 'Select a worker',
                        ),
                        items: workers
                            .map((w) => DropdownMenuItem<String>(
                                  value: w.workerId,
                                  child: Text(
                                    '${w.name} (${w.workerId})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: workers.isEmpty
                            ? null
                            : (value) =>
                                setState(() => _selectedWorkerId = value),
                        validator: (value) =>
                            value == null ? 'Select a worker' : null,
                      ),
                      if (workers.isEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'No workers registered yet. Generate a Worker ID first from the Workers page.',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (showMap)
                  LiveMapView(
                    height: 200,
                    title: 'Task Location Preview',
                    center: LatLng(lat, lng),
                    markers: [
                      LiveMapMarker(
                        LatLng(lat, lng),
                        label: _titleController.text.trim().isEmpty
                            ? 'Task location'
                            : _titleController.text.trim(),
                        icon: Icons.delete_outline,
                        color: const Color(0xFF1565C0),
                      ),
                    ],
                    showUserLocation: false,
                  ),
                const SizedBox(height: 20),
                CustomButton(
                  label: widget.preSelectedTaskId != null
                      ? 'Assign Task'
                      : linkedComplaint != null
                          ? 'Create & Assign Task'
                          : 'Create & Assign Task',
                  icon: Icons.add_task_rounded,
                  isLoading: _isCreating,
                  onPressed: workers.isEmpty ? null : _createTask,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner shown when creating a task from a citizen complaint — shows the
/// citizen's reported photo so the head can verify it before assigning.
class _ComplaintLinkBanner extends StatelessWidget {
  const _ComplaintLinkBanner({required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final path = complaint.photoPath;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.3)),
      ),
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
                  'From citizen complaint #${complaint.displayId}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'The citizen\'s reported photo will be visible to the worker and in Head reviews.',
            style: TextStyle(
                fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          if (path != null &&
              (path.startsWith('http://') || path.startsWith('https://'))) ...[
            const SizedBox(height: 10),
            ViewableImage(
              thumbnail: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  path,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              dialogImage: Image.network(
                path,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ] else if (path != null && File(path).existsSync()) ...[
            const SizedBox(height: 10),
            ViewableImage(
              thumbnail: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(path),
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              dialogImage: Image.file(File(path), fit: BoxFit.contain),
            ),
          ],
        ],
      ),
    );
  }
}
