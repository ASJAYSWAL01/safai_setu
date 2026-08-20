enum CollectionTaskStatus { assigned, enRoute, collecting, completed, rejected, revoked }

extension CollectionTaskStatusX on CollectionTaskStatus {
  String get label {
    switch (this) {
      case CollectionTaskStatus.assigned:
        return 'Assigned';
      case CollectionTaskStatus.enRoute:
        return 'En Route';
      case CollectionTaskStatus.collecting:
        return 'Collecting';
      case CollectionTaskStatus.completed:
        return 'Completed';
      case CollectionTaskStatus.rejected:
        return 'Rejected';
      case CollectionTaskStatus.revoked:
        return 'Revoked';
    }
  }

  /// Maps the task status onto the shared complaint timeline
  /// (0 Submitted, 1 Verified, 2 Worker Assigned, 3 Collection In Progress,
  /// 4 Resolved). Completed only reaches 4 once the Head approves (handled
  /// in the UI via `reviewedByHead`).
  int get progressStep {
    switch (this) {
      case CollectionTaskStatus.assigned:
      case CollectionTaskStatus.enRoute:
      case CollectionTaskStatus.rejected:
      case CollectionTaskStatus.revoked:
        return 2;
      case CollectionTaskStatus.collecting:
      case CollectionTaskStatus.completed:
        return 3;
    }
  }
}

/// A waste-collection assignment for a pickup truck worker.
class CollectionTask {
  const CollectionTask({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.assignedAt,
    required this.status,
    this.workerId,
    this.citizenComplaintId,
    this.completedAt,
    this.proofPhotoPath,
    this.proofNote,
    this.reviewedByHead = false,
  });

  final String id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String? workerId;

  /// Links this collection task to the citizen complaint it resolves, so the
  /// citizen can see the worker's proof photo.
  final String? citizenComplaintId;

  final DateTime assignedAt;
  final CollectionTaskStatus status;
  final DateTime? completedAt;

  /// Path of the proof photo the worker took after completing the work.
  final String? proofPhotoPath;
  final String? proofNote;
  final bool reviewedByHead;

  CollectionTask copyWith({
    String? workerId,
    CollectionTaskStatus? status,
    DateTime? completedAt,
    String? proofPhotoPath,
    String? proofNote,
    bool? reviewedByHead,
  }) {
    return CollectionTask(
      id: id,
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      workerId: workerId ?? this.workerId,
      citizenComplaintId: citizenComplaintId,
      assignedAt: assignedAt,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      proofPhotoPath: proofPhotoPath ?? this.proofPhotoPath,
      proofNote: proofNote ?? this.proofNote,
      reviewedByHead: reviewedByHead ?? this.reviewedByHead,
    );
  }

  factory CollectionTask.fromJson(Map<String, dynamic> json) {
    return CollectionTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      workerId: json['worker_id'] as String?,
      citizenComplaintId: json['citizen_complaint_id'] as String?,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      status: statusFromString(json['status'] as String?),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      proofPhotoPath: json['proof_photo_url'] as String?,
      proofNote: json['proof_note'] as String?,
      reviewedByHead: (json['reviewed_by_head'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'worker_id': workerId,
        'citizen_complaint_id': citizenComplaintId,
        'assigned_at': assignedAt.toUtc().toIso8601String(),
        'status': statusToDb(status),
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'proof_photo_url': proofPhotoPath,
        'proof_note': proofNote,
        'reviewed_by_head': reviewedByHead,
      };

  static CollectionTaskStatus statusFromString(String? value) {
    switch (value) {
      case 'en_route':
        return CollectionTaskStatus.enRoute;
      case 'collecting':
        return CollectionTaskStatus.collecting;
      case 'completed':
        return CollectionTaskStatus.completed;
      case 'rejected':
        return CollectionTaskStatus.rejected;
      case 'revoked':
        return CollectionTaskStatus.revoked;
      default:
        return CollectionTaskStatus.assigned;
    }
  }

  static String statusToDb(CollectionTaskStatus status) {
    switch (status) {
      case CollectionTaskStatus.assigned:
        return 'assigned';
      case CollectionTaskStatus.enRoute:
        return 'en_route';
      case CollectionTaskStatus.collecting:
        return 'collecting';
      case CollectionTaskStatus.completed:
        return 'completed';
      case CollectionTaskStatus.rejected:
        return 'rejected';
      case CollectionTaskStatus.revoked:
        return 'revoked';
    }
  }
}
