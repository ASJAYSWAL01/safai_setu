enum CollectionTaskStatus { assigned, enRoute, collecting, completed, rejected }

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
    }
  }

  int get progressStep {
    switch (this) {
      case CollectionTaskStatus.assigned:
        return 0;
      case CollectionTaskStatus.enRoute:
        return 1;
      case CollectionTaskStatus.collecting:
        return 2;
      case CollectionTaskStatus.completed:
        return 3;
      case CollectionTaskStatus.rejected:
        return 0;
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
}
