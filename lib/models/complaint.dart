enum ComplaintStatus { pending, assigned, inProgress, resolved }

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
    this.assignedTo,
    this.estimatedResolution,
    this.timelineStep = 0,
    this.hasPhoto = true,
  });

  final String id;
  final String category;
  final String description;
  final String location;
  final DateTime dateReported;
  final ComplaintStatus status;
  final String? assignedTo;
  final String? estimatedResolution;
  final int timelineStep;
  final bool hasPhoto;

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
      assignedTo: assignedTo ?? this.assignedTo,
      estimatedResolution: estimatedResolution ?? this.estimatedResolution,
      timelineStep: timelineStep ?? this.timelineStep,
      hasPhoto: hasPhoto,
    );
  }
}
