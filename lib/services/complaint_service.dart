import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/complaint.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class ComplaintService {
  ComplaintService._();
  static final ComplaintService instance = ComplaintService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Complaint>> fetchMyComplaints() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('complaints')
        .select()
        .eq('citizen_id', userId)
        .order('created_at', ascending: false);

    return rows
        .map((row) => _fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  /// All complaints — RLS restricts this to heads (and workers see their
  /// assigned ones via their own query).
  Future<List<Complaint>> fetchAllComplaints() async {
    final rows = await _client
        .from('complaints')
        .select()
        .order('created_at', ascending: false);
    return rows
        .map((row) => _fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<Complaint>> fetchComplaintsWithCoordinates() async {
    final rows = await _client
        .from('complaints')
        .select()
        .not('latitude', 'is', null)
        .not('longitude', 'is', null)
        .order('created_at', ascending: false);

    return rows
        .map((row) => _fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Complaint?> getComplaintById(String id) async {
    final row =
        await _client.from('complaints').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return _fromRow(Map<String, dynamic>.from(row));
  }

  /// Marks a complaint as resolved (called by the Head when they approve a
  /// worker's proof photo for the linked task) and notifies the citizen.
  Future<void> resolveComplaint(String id) async {
    await _client.from('complaints').update({
      'status': 'resolved',
      'timeline_step': 4,
    }).eq('id', id);

    try {
      final complaint = await getComplaintById(id);
      final citizenId = complaint?.citizenId;
      if (citizenId != null) {
        await NotificationService.instance.sendToUser(
          userId: citizenId,
          title: 'Complaint Resolved 🎉',
          body: 'Your ${complaint?.category ?? 'waste'} complaint '
              'has been resolved. Thank you for reporting!',
          route: 'complaint|$id',
        );
      }
    } on Object catch (e) {
      debugPrint('Citizen resolved notification failed: $e');
    }
  }

  /// Rejects a complaint (Head action) and records the reason, which the
  /// citizen can read on their complaint details page.
  Future<void> rejectComplaint(String id, String reason) async {
    await _client.from('complaints').update({
      'status': 'rejected',
      'rejection_reason': reason.trim().isEmpty ? null : reason.trim(),
    }).eq('id', id);
  }

  /// Advances a verified complaint to the 'Worker Assigned' stage when the
  /// Head creates/assigns a collection task from it.
  Future<void> assignComplaint(
    String id, {
    required String workerId,
  }) async {
    await _client.from('complaints').update({
      'status': 'assigned',
      'timeline_step': 2,
      'assigned_to': workerId,
    }).eq('id', id);
  }

  /// Advances a complaint to 'Collection In Progress' when the assigned
  /// worker starts collecting waste.
  Future<void> markComplaintInProgress(String id) async {
    await _client.from('complaints').update({
      'status': 'in_progress',
      'timeline_step': 3,
    }).eq('id', id);
  }

  /// Undoes an assignment when the Head revokes the task before the worker
  /// started. The complaint returns to the unassigned state so the Head can
  /// verify and assign it to another worker.
  Future<void> revokeAssignment(String id) async {
    await _client.from('complaints').update({
      'status': 'pending',
      'timeline_step': 0,
      'assigned_to': null,
    }).eq('id', id);
  }

  Future<ComplaintStats> fetchMyStats() async {
    final complaints = await fetchMyComplaints();
    final resolved =
        complaints.where((c) => c.status == ComplaintStatus.resolved).length;
    // Everything not yet resolved (and not rejected) counts as in progress,
    // including freshly reported (pending) complaints.
    final inProgress = complaints
        .where((c) =>
            c.status != ComplaintStatus.resolved &&
            c.status != ComplaintStatus.rejected)
        .length;
    return ComplaintStats(
      total: complaints.length,
      resolved: resolved,
      inProgress: inProgress,
    );
  }

  /// Uploads photo (if any) then inserts the complaint. Throws on failure.
  Future<Complaint> submitComplaint({
    required String category,
    required String description,
    required double latitude,
    required double longitude,
    String? locationText,
    String? localPhotoPath,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('You must be signed in to submit a complaint.');
    }

    String? photoUrl;
    if (localPhotoPath != null && localPhotoPath.isNotEmpty) {
      photoUrl = await _uploadPhoto(userId, localPhotoPath);
    }

    final row = await _client
        .from('complaints')
        .insert({
          'citizen_id': userId,
          'category': category,
          'description': description,
          'location_text': locationText ??
              'Lat: ${latitude.toStringAsFixed(6)}, Long: ${longitude.toStringAsFixed(6)}',
          'latitude': latitude,
          'longitude': longitude,
          'photo_url': photoUrl,
          'status': 'pending',
          'timeline_step': 0,
        })
        .select()
        .single();

    // Notify the Head(s) that a new complaint arrived.
    try {
      final reporter = AuthService.instance.user?.name ?? 'a citizen';
      await NotificationService.instance.sendToRole(
        role: 'head',
        title: 'New Complaint Reported',
        body: '$category waste reported by $reporter.',
        route: 'complaints',
      );
    } on Object catch (e) {
      debugPrint('Head complaint notification failed: $e');
    }

    return _fromRow(Map<String, dynamic>.from(row));
  }

  Future<String> _uploadPhoto(String userId, String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw StorageException('Photo file not found.');
    }

    final ext = localPath.split('.').last.toLowerCase();
    final objectPath =
        '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

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

  Complaint _fromRow(Map<String, dynamic> row) {
    return Complaint(
      id: row['id'] as String,
      complaintNumber: row['complaint_number'] as String?,
      category: row['category'] as String,
      description: row['description'] as String,
      location: (row['location_text'] as String?) ?? '',
      dateReported: DateTime.parse(row['created_at'] as String),
      status: _statusFromString(row['status'] as String?),
      citizenId: row['citizen_id'] as String?,
      assignedTo: row['assigned_to'] as String?,
      estimatedResolution: row['estimated_resolution'] as String?,
      rejectionReason: row['rejection_reason'] as String?,
      timelineStep: (row['timeline_step'] as int?) ?? 0,
      hasPhoto: (row['photo_url'] as String?)?.isNotEmpty == true,
      photoPath: row['photo_url'] as String?,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
    );
  }

  ComplaintStatus _statusFromString(String? value) {
    switch (value) {
      case 'assigned':
        return ComplaintStatus.assigned;
      case 'in_progress':
        return ComplaintStatus.inProgress;
      case 'resolved':
        return ComplaintStatus.resolved;
      case 'rejected':
        return ComplaintStatus.rejected;
      default:
        return ComplaintStatus.pending;
    }
  }
}

class ComplaintStats {
  const ComplaintStats({
    required this.total,
    required this.resolved,
    required this.inProgress,
  });

  final int total;
  final int resolved;
  final int inProgress;
}
