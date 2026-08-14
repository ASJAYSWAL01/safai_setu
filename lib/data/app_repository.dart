import 'dart:math';

import '../models/collection_task.dart';
import 'mock_data_repository.dart';

class WorkerLocation {
  const WorkerLocation(
      {required this.latitude,
      required this.longitude,
      required this.updatedAt});

  final double latitude;
  final double longitude;
  final DateTime updatedAt;
}

/// In-memory data source for collection tasks, worker live locations and
/// proof-of-work photos. Replace with a real backend (e.g. Firebase) later.
class AppRepository {
  AppRepository._() {
    _seedTasks();
  }

  static final AppRepository instance = AppRepository._();

  final List<CollectionTask> _tasks = [];

  /// workerId -> last known GPS position shared by the worker app.
  final Map<String, WorkerLocation> _workerLocations = {};

  // Gandhinagar city center (demo coordinates).
  static const double _baseLat = 23.2156;
  static const double _baseLng = 72.6369;

  void _seedTasks() {
    _tasks.addAll([
      CollectionTask(
        id: 'T-2001',
        title: 'Sector 10 — Community Park',
        description:
            'Overflowing dustbin near the community park. Collect all mixed waste and sweep the area.',
        latitude: 23.2201,
        longitude: 72.6450,
        workerId: 'WK-1001',
        citizenComplaintId: 'SS1024',
        assignedAt: DateTime(2026, 8, 14, 8, 0),
        status: CollectionTaskStatus.assigned,
      ),
      CollectionTask(
        id: 'T-2002',
        title: 'Sector 7 — Main Road',
        description:
            'Garbage bags left on the roadside blocking pedestrian movement.',
        latitude: 23.2115,
        longitude: 72.6310,
        workerId: 'WK-1001',
        assignedAt: DateTime(2026, 8, 14, 8, 15),
        status: CollectionTaskStatus.assigned,
      ),
      CollectionTask(
        id: 'T-2003',
        title: 'Sector 21 — Market Area',
        description: 'Plastic waste accumulated near the vegetable market.',
        latitude: 23.2070,
        longitude: 72.6510,
        workerId: 'WK-1002',
        assignedAt: DateTime(2026, 8, 14, 8, 30),
        status: CollectionTaskStatus.collecting,
      ),
      CollectionTask(
        id: 'T-2004',
        title: 'Sector 5 — Vacant Plot',
        description: 'Construction debris dumped illegally on vacant plot.',
        latitude: 23.2240,
        longitude: 72.6280,
        assignedAt: DateTime(2026, 8, 14, 8, 45),
        status: CollectionTaskStatus.assigned,
      ),
    ]);
  }

  List<CollectionTask> get tasks => List.unmodifiable(_tasks);

  List<CollectionTask> tasksForWorker(String workerId) =>
      _tasks.where((t) => t.workerId == workerId).toList();

  List<CollectionTask> get unassignedTasks =>
      _tasks.where((t) => t.workerId == null).toList();

  List<CollectionTask> get completedTasks =>
      _tasks.where((t) => t.status == CollectionTaskStatus.completed).toList();

  /// Proof photos pending review by the Head.
  List<CollectionTask> get pendingProofs => _tasks
      .where((t) =>
          t.status == CollectionTaskStatus.completed && !t.reviewedByHead)
      .toList();

  CollectionTask? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Proof photo linked to a citizen complaint, if the work is done.
  CollectionTask? getProofForComplaint(String complaintId) {
    for (final task in _tasks) {
      if (task.citizenComplaintId == complaintId &&
          task.status == CollectionTaskStatus.completed &&
          task.proofPhotoPath != null) {
        return task;
      }
    }
    return null;
  }

  CollectionTask addTask({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    String? workerId,
    String? citizenComplaintId,
  }) {
    final task = CollectionTask(
      id: 'T-${2000 + _tasks.length + 1}',
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      workerId: workerId,
      citizenComplaintId: citizenComplaintId,
      assignedAt: DateTime.now(),
      status: CollectionTaskStatus.assigned,
    );
    _tasks.insert(0, task);
    return task;
  }

  void assignTask(String taskId, String workerId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    _tasks[index] = _tasks[index].copyWith(workerId: workerId);
  }

  void updateTaskStatus(
    String taskId,
    CollectionTaskStatus status, {
    String? proofPhotoPath,
    String? proofNote,
  }) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    _tasks[index] = _tasks[index].copyWith(
      status: status,
      completedAt:
          status == CollectionTaskStatus.completed ? DateTime.now() : null,
      proofPhotoPath: proofPhotoPath ?? _tasks[index].proofPhotoPath,
      proofNote: proofNote ?? _tasks[index].proofNote,
    );
    final task = _tasks[index];
    if (status == CollectionTaskStatus.completed &&
        task.citizenComplaintId != null) {
      // Notify the citizen: mark the linked complaint as resolved.
      MockDataRepository.instance.resolveComplaint(task.citizenComplaintId!);
    }
  }

  /// Unassigns every open task of a worker (used when the Head deletes the
  /// worker) so the tasks go back to the unassigned pool.
  ///
  /// Note: builds a fresh task instead of `copyWith(workerId: null)` because
  /// copyWith treats null as "keep the existing value".
  void unassignTasksForWorker(String workerId) {
    for (var i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      if (task.workerId != workerId) continue;
      _tasks[i] = CollectionTask(
        id: task.id,
        title: task.title,
        description: task.description,
        latitude: task.latitude,
        longitude: task.longitude,
        assignedAt: task.assignedAt,
        status: task.status,
        workerId: null,
        citizenComplaintId: task.citizenComplaintId,
        completedAt: task.completedAt,
        proofPhotoPath: task.proofPhotoPath,
        proofNote: task.proofNote,
        reviewedByHead: task.reviewedByHead,
      );
    }
  }

  void markProofReviewed(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    _tasks[index] = _tasks[index].copyWith(reviewedByHead: true);
  }

  /// Rejects the proof photo — sends the task back to the worker with
  /// [CollectionTaskStatus.rejected] so they can redo the work.
  void rejectProof(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    _tasks[index] = _tasks[index].copyWith(
      status: CollectionTaskStatus.rejected,
      reviewedByHead: true,
    );
  }

  WorkerLocation? lastLocation(String workerId) => _workerLocations[workerId];

  /// Removes a worker's cached live location (used when the Head deletes the
  /// worker so no stale location keeps showing).
  void clearWorkerLocation(String workerId) {
    _workerLocations.remove(workerId);
  }

  /// Called periodically by the worker app while sharing location.
  void updateWorkerLocation(
      String workerId, double latitude, double longitude) {
    _workerLocations[workerId] = WorkerLocation(
        latitude: latitude, longitude: longitude, updatedAt: DateTime.now());
  }

  /// Deterministic pseudo-route around the task destination for the demo map.
  List<WorkerLocation> demoRoute(double destLat, double destLng,
      {int points = 6}) {
    final random = Random(destLat.toInt() * 31 + destLng.toInt());
    return List.generate(points, (i) {
      final offset = 0.004 * (i + 1);
      final wobble = (random.nextDouble() - 0.5) * 0.002;
      return WorkerLocation(
        latitude: _baseLat + (destLat - _baseLat) * ((i + 1) / points) + wobble,
        longitude:
            _baseLng + (destLng - _baseLng) * ((i + 1) / points) + wobble,
        updatedAt: DateTime.now(),
      );
    });
  }
}
