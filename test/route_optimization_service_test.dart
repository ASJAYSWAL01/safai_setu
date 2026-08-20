import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safai_setu/models/collection_task.dart';
import 'package:safai_setu/services/route_optimization_service.dart';

void main() {
  final service = RouteOptimizationService.instance;

  CollectionTask task(
    String id,
    double lat,
    double lng, {
    CollectionTaskStatus status = CollectionTaskStatus.assigned,
  }) {
    return CollectionTask(
      id: id,
      title: 'Task $id',
      description: '',
      latitude: lat,
      longitude: lng,
      assignedAt: DateTime(2026, 8, 17),
      status: status,
    );
  }

  final start = const LatLng(0, 0);

  group('RouteOptimizationService', () {
    test('Test 1: no assigned complaints -> empty route, no crash', () {
      final route = service.optimize(start: start, tasks: []);
      expect(route.isEmpty, isTrue);
      expect(route.stopCount, 0);
      expect(route.totalDistanceMeters, 0);
      expect(route.polylinePoints, [start]);
    });

    test('Test 2: one complaint -> worker -> C1', () {
      final route = service.optimize(
        start: start,
        tasks: [task('c1', 1, 0)],
      );
      expect(route.stopCount, 1);
      expect(route.stops.single.task.id, 'c1');
      expect(route.polylinePoints.length, 2);
      expect(route.polylinePoints.first, start);
      expect(route.polylinePoints.last, const LatLng(1, 0));
    });

    test(
        'Test 3 & 4: nearest neighbor re-picks from each stop, '
        'not always from the worker start', () {
      // A is closest to the start, then C, then B. But B is much closer to A
      // than C is (B is a "buddy" just past A). A naive sort by distance from
      // the START would give A, C, B — nearest neighbor must give A, B, C
      // because after visiting A it re-measures from A, where B wins.
      final a = task('a', 1, 0);
      final b = task('b', 1.05, 0.02);
      final c = task('c', 1, 0.2);

      final route = service.optimize(start: start, tasks: [a, b, c]);

      expect(route.stops.map((s) => s.task.id).toList(), ['a', 'b', 'c']);
      // Total must equal the SUM of the segments (start->a->b->c).
      final total = route.stops.fold<double>(
          0, (sum, s) => sum + s.distanceFromPreviousMeters);
      expect(route.totalDistanceMeters, closeTo(total, 0.001));
      expect(route.totalDistanceMeters, greaterThan(100000));
    });

    test('Test 5: complaint with missing coordinates (0,0) is skipped safely',
        () {
      final route = service.optimize(
        start: start,
        tasks: [task('bad', 0, 0), task('good', 1, 0)],
      );
      expect(route.stopCount, 1);
      expect(route.stops.single.task.id, 'good');
    });

    test('Test 6: completed/rejected/revoked complaints are excluded', () {
      final route = service.optimize(
        start: start,
        tasks: [
          task('done', 1, 0, status: CollectionTaskStatus.completed),
          task('rej', 2, 0, status: CollectionTaskStatus.rejected),
          task('rev', 3, 0, status: CollectionTaskStatus.revoked),
          task('active', 4, 0, status: CollectionTaskStatus.enRoute),
          task('collecting', 5, 0, status: CollectionTaskStatus.collecting),
        ],
      );
      expect(route.stops.map((s) => s.task.id).toList(),
          ['active', 'collecting']);
    });

    test('Test 10 & 11: re-optimizing is stateless and uses the new start', () {
      final tasks = [task('a', 1, 0), task('b', 2, 0)];
      final first = service.optimize(start: start, tasks: tasks);
      final second = service.optimize(start: start, tasks: tasks);
      // Same inputs -> same order, nothing duplicated.
      expect(second.stops.map((s) => s.task.id).toList(),
          first.stops.map((s) => s.task.id).toList());
      expect(second.polylinePoints.length, 3);

      // Different start -> different first pick (a is now far away).
      final nearB = service.optimize(
        start: const LatLng(1.8, 0),
        tasks: tasks,
      );
      expect(nearB.stops.first.task.id, 'b');
    });

    test('Haversine distance matches a known value', () {
      // 0.01 degrees of latitude is ~1111 meters.
      final d = service.distanceBetween(0, 0, 0.01, 0);
      expect(d, closeTo(1112, 5));
    });
  });
}
