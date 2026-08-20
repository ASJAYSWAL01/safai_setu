import 'package:flutter_test/flutter_test.dart';
import 'package:safai_setu/models/complaint.dart';
import 'package:safai_setu/services/hotspot_service.dart';

Complaint _complaint(
  String id,
  double lat,
  double lng, {
  DateTime? date,
  ComplaintStatus status = ComplaintStatus.pending,
}) {
  return Complaint(
    id: id,
    category: 'Garbage',
    description: 'test',
    location: 'test',
    dateReported: date ?? DateTime.now(),
    status: status,
    latitude: lat,
    longitude: lng,
  );
}

void main() {
  final service = HotspotService.instance;

  group('HotspotService severity thresholds', () {
    test('Test 1: 1 complaint in last 7 days → one LOW hotspot', () {
      final hotspots = service.detectHotspots([_complaint('c1', 20.0, 75.0)]);
      expect(hotspots, hasLength(1));
      expect(hotspots.first.level, HotspotLevel.low);
      expect(hotspots.first.complaintCount, 1);
    });

    test('Test 2: 2 nearby complaints within 500m → ONE LOW hotspot (not two)',
        () {
      // ~0.001 deg lat ≈ 111 m apart.
      final hotspots = service.detectHotspots([
        _complaint('c1', 20.0, 75.0),
        _complaint('c2', 20.001, 75.0),
      ]);
      expect(hotspots, hasLength(1));
      expect(hotspots.first.level, HotspotLevel.low);
      expect(hotspots.first.complaintCount, 2);
    });

    test('Test 3: 3 nearby complaints → ONE MEDIUM hotspot', () {
      final hotspots = service.detectHotspots([
        _complaint('c1', 20.0, 75.0),
        _complaint('c2', 20.001, 75.0),
        _complaint('c3', 20.0, 75.001),
      ]);
      expect(hotspots, hasLength(1));
      expect(hotspots.first.level, HotspotLevel.medium);
    });

    test('Test 4: 5 nearby complaints → MEDIUM hotspot', () {
      final hotspots = service.detectHotspots([
        _complaint('c1', 20.0, 75.0),
        _complaint('c2', 20.001, 75.0),
        _complaint('c3', 20.0, 75.001),
        _complaint('c4', 20.001, 75.001),
        _complaint('c5', 20.0005, 75.0005),
      ]);
      expect(hotspots, hasLength(1));
      expect(hotspots.first.level, HotspotLevel.medium);
      expect(hotspots.first.complaintCount, 5);
    });

    test('Test 5: 6 nearby complaints → HIGH hotspot', () {
      final hotspots = service.detectHotspots([
        _complaint('c1', 20.0, 75.0),
        _complaint('c2', 20.001, 75.0),
        _complaint('c3', 20.0, 75.001),
        _complaint('c4', 20.001, 75.001),
        _complaint('c5', 20.0005, 75.0005),
        _complaint('c6', 20.0015, 75.0015),
      ]);
      expect(hotspots, hasLength(1));
      expect(hotspots.first.level, HotspotLevel.high);
      expect(hotspots.first.complaintCount, 6);
    });

    test('Test 6: 10 nearby complaints → ONE HIGH hotspot', () {
      final list = [
        for (var i = 0; i < 10; i++)
          _complaint('c$i', 20.0 + i * 0.0003, 75.0 + i * 0.0003),
      ];
      final hotspots = service.detectHotspots(list);
      expect(hotspots, hasLength(1));
      expect(hotspots.first.level, HotspotLevel.high);
      expect(hotspots.first.complaintCount, 10);
    });
  });

  group('HotspotService clustering', () {
    test('Test 7: two separated complaint groups → TWO separate hotspots', () {
      // Group A near (20.0, 75.0); group B ~5 km away near (20.045, 75.0).
      final hotspots = service.detectHotspots([
        _complaint('a1', 20.0, 75.0),
        _complaint('a2', 20.001, 75.0),
        _complaint('a3', 20.0, 75.001),
        _complaint('b1', 20.045, 75.0),
        _complaint('b2', 20.046, 75.0),
      ]);
      expect(hotspots, hasLength(2));
      expect(hotspots.map((h) => h.level), contains(HotspotLevel.medium));
      expect(hotspots.map((h) => h.level), contains(HotspotLevel.low));
    });

    test('Test 10: complaint farther than 500m from cluster → separate', () {
      final hotspots = service.detectHotspots([
        _complaint('a1', 20.0, 75.0),
        // ~1.1 km south.
        _complaint('far', 20.010, 75.0),
      ]);
      expect(hotspots, hasLength(2));
      expect(hotspots.every((h) => h.complaintCount == 1), isTrue);
    });

    test('transitive connection: A–B and B–C chain forms one cluster', () {
      // A at 0m, B at 450m from A, C at 450m from B but ~900m from A.
      final hotspots = service.detectHotspots([
        _complaint('a', 20.0, 75.0),
        _complaint('b', 20.004, 75.0), // ~444 m from a
        _complaint('c', 20.008, 75.0), // ~444 m from b
      ]);
      expect(hotspots, hasLength(1));
      expect(hotspots.first.complaintCount, 3);
    });

    test('hotspot center is the average of cluster coordinates', () {
      final hotspots = service.detectHotspots([
        _complaint('c1', 20.0, 75.0),
        _complaint('c2', 20.002, 75.002),
      ]);
      final center = hotspots.single.center;
      expect(center.latitude, closeTo(20.001, 0.000001));
      expect(center.longitude, closeTo(75.001, 0.000001));
    });
  });

  group('HotspotService time window', () {
    test('Test 8: complaint older than 7 days does not contribute', () {
      final hotspots = service.detectHotspots([
        _complaint('old', 20.0, 75.0,
            date: DateTime.now().subtract(const Duration(days: 8))),
        _complaint('recent', 20.001, 75.0),
      ]);
      expect(hotspots, hasLength(1));
      expect(hotspots.single.complaintIds, ['recent']);
    });

    test('complaint exactly at the 7-day boundary is eligible', () {
      final hotspots = service.detectHotspots([
        _complaint('edge', 20.0, 75.0,
            date: DateTime.now().subtract(const Duration(days: 7))),
      ]);
      expect(hotspots, hasLength(1));
      expect(hotspots.single.complaintCount, 1);
    });
  });

  group('HotspotService radius behaviour', () {
    test('Test 9: complaint ~450m away joins the cluster', () {
      // 0.0040 deg lat ≈ 445 m at the equator — safely inside 500 m.
      final hotspots = service.detectHotspots([
        _complaint('a', 20.0, 75.0),
        _complaint('b', 20.0040, 75.0),
      ]);
      expect(hotspots, hasLength(1));
      expect(hotspots.single.complaintCount, 2);
    });

    test('Test 9b: just beyond 500m is a separate cluster', () {
      final hotspots = service.detectHotspots([
        _complaint('a', 20.0, 75.0),
        _complaint('b', 20.0045, 75.0), // ~501 m — just outside
      ]);
      expect(hotspots, hasLength(2));
    });
  });

  group('HotspotService eligibility', () {
    test('Test 11: complaint with missing coordinates is ignored safely', () {
      final noLat = _complaint('nolat', 0, 0);
      final hotspots = service.detectHotspots([
        _complaint('ok1', 20.0, 75.0),
        _complaint('ok2', 20.001, 75.0),
        Complaint(
          id: 'nullcoord',
          category: 'Garbage',
          description: 'x',
          location: 'x',
          dateReported: DateTime.now(),
          status: ComplaintStatus.pending,
        ),
      ]);
      expect(hotspots, hasLength(1));
      expect(hotspots.single.complaintIds, isNot(contains('nullcoord')));
      expect(hotspots.single.complaintIds, isNot(contains('nolat')));
    });

    test('Test 12: rejected complaint is excluded', () {
      final hotspots = service.detectHotspots([
        _complaint('rej', 20.0, 75.0, status: ComplaintStatus.rejected),
        _complaint('ok', 20.001, 75.0),
      ]);
      expect(hotspots, hasLength(1));
      expect(hotspots.single.complaintIds, ['ok']);
    });

    test('Test 13: recent resolved complaint still contributes', () {
      final hotspots = service.detectHotspots([
        _complaint('r1', 20.0, 75.0, status: ComplaintStatus.resolved),
        _complaint('r2', 20.001, 75.0, status: ComplaintStatus.resolved),
      ]);
      expect(hotspots, hasLength(1));
      expect(hotspots.single.complaintCount, 2);
    });

    test('Test 16: no eligible complaints → no hotspots, no crash', () {
      expect(service.detectHotspots([]), isEmpty);
      expect(
        service.detectHotspots([
          _complaint('old', 20.0, 75.0,
              date: DateTime.now().subtract(const Duration(days: 10))),
          _complaint('rej', 20.0, 75.0, status: ComplaintStatus.rejected),
        ]),
        isEmpty,
      );
    });
  });
}
