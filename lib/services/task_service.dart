import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/collection_task.dart';
import 'auth_service.dart';
import 'complaint_service.dart';
import 'notification_service.dart';
import 'profile_service.dart';

/// Supabase-backed collection tasks.
///
/// RLS makes this cross-device safe: the Head creates/assigns tasks, workers
/// only see (and may update) tasks assigned to their Worker ID, and citizens
/// see the task linked to their own complaint (the proof photo).
class TaskService {
  TaskService._();
  static final TaskService instance = TaskService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<CollectionTask>> fetchAllTasks() async {
    final rows = await _client
        .from('tasks')
        .select()
        .order('assigned_at', ascending: false);
    return rows
        .map((row) => CollectionTask.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<CollectionTask>> fetchTasksForWorker(String workerId) async {
    final rows = await _client
        .from('tasks')
        .select()
        .eq('worker_id', workerId)
        .order('assigned_at', ascending: false);
    return rows
        .map((row) => CollectionTask.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<CollectionTask?> getTaskById(String id) async {
    final row =
        await _client.from('tasks').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return CollectionTask.fromJson(Map<String, dynamic>.from(row));
  }

  /// Proof photo linked to a citizen complaint (task completed with photo).
  Future<CollectionTask?> getProofForComplaint(String complaintId) async {
    final rows = await _client
        .from('tasks')
        .select()
        .eq('citizen_complaint_id', complaintId)
        .order('assigned_at', ascending: false);
    for (final row in rows) {
      final task = CollectionTask.fromJson(Map<String, dynamic>.from(row));
      if (task.status == CollectionTaskStatus.completed &&
          task.proofPhotoPath != null) {
        return task;
      }
    }
    return null;
  }

  /// Tasks completed with a proof photo, pending (or not) Head review.
  Future<List<CollectionTask>> fetchProofTasks({
    bool? reviewedByHead,
  }) async {
    final base = _client
        .from('tasks')
        .select()
        .eq('status', 'completed')
        .not('proof_photo_url', 'is', null);
    final query = reviewedByHead == null
        ? base
        : base.eq('reviewed_by_head', reviewedByHead);
    final rows = await query.order('completed_at', ascending: false);
    return rows
        .map((row) => CollectionTask.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<CollectionTask> createTask({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    String? workerId,
    String? citizenComplaintId,
  }) async {
    final row = await _client
        .from('tasks')
        .insert({
          'title': title,
          'description': description,
          'latitude': latitude,
          'longitude': longitude,
          'worker_id': workerId,
          'citizen_complaint_id': citizenComplaintId,
          'status': 'assigned',
        })
        .select()
        .single();

    // The Head verified and assigned this complaint — advance the citizen's
    // progress bar to 'Worker Assigned' (step 2).
    if (citizenComplaintId != null && workerId != null) {
      try {
        await ComplaintService.instance
            .assignComplaint(citizenComplaintId, workerId: workerId);
      } on Object catch (e) {
        debugPrint('Failed to mark complaint $citizenComplaintId assigned: $e');
      }
      _notifyWorkerAssigned(workerId, citizenComplaintId, title);
    }

    return CollectionTask.fromJson(Map<String, dynamic>.from(row));
  }

  /// Assigns (or re-assigns) a task to a worker. Also resets the status to
  /// 'assigned' — needed when re-assigning a task that was previously
  /// revoked (which cleared its worker) — and re-advances the linked
  /// citizen complaint to the 'Worker Assigned' stage.
  Future<void> assignTask(String taskId, String workerId) async {
    await _client.from('tasks').update({
      'worker_id': workerId,
      'status': 'assigned',
      'completed_at': null,
    }).eq('id', taskId);

    try {
      final task = await getTaskById(taskId);
      final complaintId = task?.citizenComplaintId;
      if (complaintId != null) {
        await ComplaintService.instance
            .assignComplaint(complaintId, workerId: workerId);
      }
      _notifyWorkerAssigned(workerId, complaintId, task?.title);
    } on Object catch (e) {
      debugPrint('Failed to mark linked complaint $taskId assigned: $e');
    }
  }

  /// Sends the worker a push: task waste category + who reported it.
  Future<void> _notifyWorkerAssigned(
    String workerId,
    String? complaintId,
    String? taskTitle,
  ) async {
    try {
      var category = taskTitle;
      var reportedBy = '';
      if (complaintId != null) {
        final complaint =
            await ComplaintService.instance.getComplaintById(complaintId);
        category = complaint?.category ?? category;
        final citizenId = complaint?.citizenId;
        if (citizenId != null) {
          final profile = await ProfileService.instance.getProfile(citizenId);
          reportedBy = profile?.fullName ?? '';
        }
      }
      await NotificationService.instance.sendToWorkerId(
        workerId: workerId,
        title: 'New Task Assigned',
        body: '${category ?? 'Collection task'} waste — '
            'reported by ${reportedBy.isEmpty ? 'a citizen' : reportedBy}',
        route: 'tasks',
      );
    } on Object catch (e) {
      debugPrint('Worker assignment notification failed: $e');
    }
  }

  /// Revokes a task that has been assigned to a worker but not yet started
  /// (status is still 'assigned'). Clears the worker so the task leaves the
  /// worker's queue, marks the task 'revoked' so the Head can re-assign it,
  /// and resets the linked citizen complaint back to the unassigned state.
  Future<void> revokeTask(String taskId) async {
    await _client.from('tasks').update({
      'status': 'revoked',
      'worker_id': null,
      'completed_at': null,
    }).eq('id', taskId);

    try {
      final task = await getTaskById(taskId);
      final complaintId = task?.citizenComplaintId;
      if (complaintId != null) {
        await ComplaintService.instance.revokeAssignment(complaintId);
      }
    } on Object catch (e) {
      debugPrint('Failed to reset linked complaint for $taskId: $e');
    }
  }

  /// Updates a task's status. When completing with a photo, the photo is
  /// uploaded to Supabase Storage first and its public URL is stored, so the
  /// Head and the citizen can see it from their own devices.
  Future<void> updateTaskStatus(
    String taskId,
    CollectionTaskStatus status, {
    String? localProofPhotoPath,
    String? proofNote,
  }) async {
    final updates = <String, dynamic>{
      'status': CollectionTask.statusToDb(status),
      // Any worker status change invalidates the previous Head review (e.g.
      // restarting a rejected task, or submitting a new proof photo). Reset it
      // so a re-submitted proof lands back in the Head's Pending queue instead
      // of being treated as already reviewed/approved.
      'reviewed_by_head': false,
      if (status == CollectionTaskStatus.completed)
        'completed_at': DateTime.now().toUtc().toIso8601String()
      else ...{
        'completed_at': null,
        'proof_photo_url': null,
      },
      if (proofNote != null && proofNote.isNotEmpty) 'proof_note': proofNote,
    };

    if (status == CollectionTaskStatus.completed &&
        localProofPhotoPath != null &&
        localProofPhotoPath.isNotEmpty) {
      updates['proof_photo_url'] =
          await _uploadProofPhoto(localProofPhotoPath);
    }

    await _client.from('tasks').update(updates).eq('id', taskId);

    // A completed task with a fresh proof photo -> notify the Head(s) that a
    // proof is waiting for review.
    if (status == CollectionTaskStatus.completed &&
        localProofPhotoPath != null &&
        localProofPhotoPath.isNotEmpty) {
      try {
        final task = await getTaskById(taskId);
        final workerName = AuthService.instance.user?.name ?? 'A worker';
        await NotificationService.instance.sendToRole(
          role: 'head',
          title: 'Proof Arrived',
          body: '$workerName submitted proof for "${task?.title ?? 'a task'}".',
          route: 'proofs',
        );
      } on Object catch (e) {
        debugPrint('Proof notification failed: $e');
      }
    }

    // When the worker starts collecting, advance the linked citizen complaint
    // to 'Collection In Progress' (step 3) so the citizen sees it live.
    if (status == CollectionTaskStatus.collecting) {
      try {
        final task = await getTaskById(taskId);
        final complaintId = task?.citizenComplaintId;
        if (complaintId != null) {
          await ComplaintService.instance.markComplaintInProgress(complaintId);
        }
      } on Object catch (e) {
        debugPrint('Failed to mark linked complaint in progress: $e');
      }
    }
  }

  Future<void> markProofReviewed(String taskId) async {
    await _client
        .from('tasks')
        .update({'reviewed_by_head': true}).eq('id', taskId);
  }

  Future<void> rejectProof(String taskId) async {
    await _client.from('tasks').update({
      'status': 'rejected',
      'reviewed_by_head': true,
      'completed_at': null,
    }).eq('id', taskId);
  }

  Future<String> _uploadProofPhoto(String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw StorageException('Proof photo file not found.');
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('You must be signed in to upload a photo.');
    }

    final ext = localPath.split('.').last.toLowerCase();
    final objectPath = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('complaint-photos').upload(
          objectPath,
          file,
          fileOptions: FileOptions(
            upsert: false,
            contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
          ),
        );

    return _client.storage.from('complaint-photos').getPublicUrl(objectPath);
  }
}
