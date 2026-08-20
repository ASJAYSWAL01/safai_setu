enum ComplaintStatus { pending, assigned, inProgress, resolved, rejected }

extension ComplaintStatusX on ComplaintStatus {
  String get label {
    switch (this) {
      case ComplaintStatus.pending:
        return 'Pending';
      case ComplaintStatus.assigned:
        return 'Assigned';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.rejected:
        return 'Rejected';
    }
  }
}

class Complaint {
  const Complaint({
    required this.id,
    required this.category,
    required this.description,
    required this.location,
    required this.dateReported,
    required this.status,
    this.complaintNumber,
    this.citizenId,
    this.assignedTo,
    this.estimatedResolution,
    this.rejectionReason,
    this.timelineStep = 0,
    this.hasPhoto = true,
    this.photoPath,
    this.latitude,
    this.longitude,
  });

  /// Internal UUID — used for routing, queries and links. Never shown to
  /// users; see [displayId].
  final String id;

  /// Short human-readable number (e.g. SS-260815-001) shown to users.
  /// Null until the database assigns one (old rows get one via backfill).
  final String? complaintNumber;
  final String category;
  final String description;
  final String location;
  final DateTime dateReported;
  final ComplaintStatus status;

  /// Supabase user id of the citizen who reported.
  final String? citizenId;
  final String? assignedTo;
  final String? estimatedResolution;

  /// Reason recorded by the Head when the complaint was rejected.
  final String? rejectionReason;
  final int timelineStep;
  final bool hasPhoto;

  /// Path of the photo the citizen took when reporting (stored on-device).
  final String? photoPath;

  /// GPS coordinates captured by the citizen when reporting.
  final double? latitude;
  final double? longitude;

  /// The ID shown to users — the readable complaint number when available,
  /// falling back to the internal id so nothing breaks before the database
  /// has assigned numbers.
  String get displayId => complaintNumber ?? id;

  Complaint copyWith({
    ComplaintStatus? status,
    int? timelineStep,
    String? assignedTo,
    String? estimatedResolution,
  }) {
    return Complaint(
      id: id,
      category: category,
      description: description,
      location: location,
      dateReported: dateReported,
      status: status ?? this.status,
      citizenId: citizenId,
      assignedTo: assignedTo ?? this.assignedTo,
      estimatedResolution: estimatedResolution ?? this.estimatedResolution,
      rejectionReason: rejectionReason,
      timelineStep: timelineStep ?? this.timelineStep,
      hasPhoto: hasPhoto,
      photoPath: photoPath ?? this.photoPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
