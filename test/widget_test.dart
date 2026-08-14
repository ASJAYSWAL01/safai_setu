import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safai_setu/data/app_repository.dart';
import 'package:safai_setu/data/mock_data_repository.dart';
import 'package:safai_setu/main.dart';
import 'package:safai_setu/services/auth_service.dart';
import 'package:safai_setu/services/theme_service.dart';
import 'package:safai_setu/theme/app_theme.dart';

void main() {
  testWidgets('Role select page renders with all three portals', (WidgetTester tester) async {
    await tester.pumpWidget(const SafaiSetuApp());

    expect(find.text('Safai Setu'), findsOneWidget);
    expect(find.text('Who are you?'), findsOneWidget);
    expect(find.text('Citizen'), findsOneWidget);
    expect(find.text('Worker'), findsOneWidget);
    expect(find.text('Head'), findsOneWidget);
  });

  test('Citizen cannot login on the Head portal', () {
    final error = AuthService.instance.loginHead(
      identifier: 'citizen@safaisetu.in',
      password: 'citizen123',
    );
    expect(error, isNotNull);
    expect(error, contains('not authorized as Head'));
    expect(AuthService.instance.user, isNull);
  });

  test('Worker cannot login on the Head portal', () {
    final error = AuthService.instance.loginHead(
      identifier: 'ramesh.worker@safaisetu.in',
      password: 'worker123',
    );
    expect(error, isNotNull);
    expect(error, contains('not authorized as Head'));
    expect(AuthService.instance.user, isNull);
  });

  test('Worker logs in with Worker ID, not email', () {
    final error = AuthService.instance.loginWorker(
      workerId: 'WK-1001',
      password: 'worker123',
    );
    expect(error, isNull);
    expect(AuthService.instance.user?.isWorker, isTrue);
    AuthService.instance.logout();
  });

  test('Head logs in with Head credentials and gets full access', () {
    final error = AuthService.instance.loginHead(
      identifier: 'head@safaisetu.in',
      password: 'head123',
    );
    expect(error, isNull);
    expect(AuthService.instance.user?.isHead, isTrue);
    AuthService.instance.logout();
  });

  test('Head generates Worker IDs — citizens cannot', () {
    // Citizen cannot generate.
    AuthService.instance.loginCitizen(
      emailOrMobile: 'citizen@safaisetu.in',
      password: 'citizen123',
    );
    final asCitizen = AuthService.instance.registerWorker(
      name: 'Test Worker',
      phone: '9876500099',
      vehicleNumber: 'GJ-18-WM-9999',
    );
    expect(asCitizen, isNull);

    // Head can generate.
    AuthService.instance.logout();
    AuthService.instance.loginHead(
      identifier: 'head@safaisetu.in',
      password: 'head123',
    );
    final asHead = AuthService.instance.registerWorker(
      name: 'New Worker',
      phone: '9876500098',
      vehicleNumber: 'GJ-18-WM-9998',
    );
    expect(asHead, isNotNull);
    expect(asHead!.workerId, startsWith('WK-'));
    AuthService.instance.logout();
  });

  test('Head can edit a worker profile; Worker ID stays unchanged', () {
    AuthService.instance.loginHead(
      identifier: 'head@safaisetu.in',
      password: 'head123',
    );
    final before = AuthService.instance.getWorkerByWorkerId('WK-1001');
    final error = AuthService.instance.updateWorker(
      id: before!.id,
      name: 'Ramesh Kumar Updated',
      phone: '9876500999',
      vehicleNumber: 'GJ-18-WM-7777',
    );
    expect(error, isNull);

    final after = AuthService.instance.getWorkerByWorkerId('WK-1001');
    expect(after!.name, 'Ramesh Kumar Updated');
    expect(after.vehicleNumber, 'GJ-18-WM-7777');
    expect(after.workerId, 'WK-1001'); // Worker ID never changes
    AuthService.instance.logout();
  });

  test('Head can delete a worker; tasks unassigned and live location cleared', () {
    AuthService.instance.loginHead(
      identifier: 'head@safaisetu.in',
      password: 'head123',
    );
    final worker = AuthService.instance.getWorkerByWorkerId('WK-1002');
    expect(worker, isNotNull);

    // Worker shared a live location first.
    AppRepository.instance.updateWorkerLocation('WK-1002', 23.21, 72.63);
    expect(AppRepository.instance.lastLocation('WK-1002'), isNotNull);

    final error = AuthService.instance.deleteWorker(worker!.id);
    expect(error, isNull);
    expect(AuthService.instance.getWorkerByWorkerId('WK-1002'), isNull);

    // WK-1002 had task T-2003 — it must now be unassigned.
    final task = AppRepository.instance.getTaskById('T-2003');
    expect(task!.workerId, isNull);

    // No stale live location should remain after deleting the worker.
    expect(AppRepository.instance.lastLocation('WK-1002'), isNull);
    AuthService.instance.logout();
  });

  test('Theme toggle switches the app palette between light and dark', () {
    // Reset to light first.
    ThemeService.instance.setDark(false);
    expect(ThemeService.instance.darkMode, isFalse);
    expect(AppColors.isDark, isFalse);

    ThemeService.instance.setDark(true);
    expect(ThemeService.instance.darkMode, isTrue);

    // The palette getters must flip with the flag.
    AppColors.isDark = true;
    expect(AppColors.mintBackground, isNot(const Color(0xFFF1F8F4)));
    expect(AppColors.textPrimary, isNot(const Color(0xFF1A1A1A)));

    // And back.
    ThemeService.instance.setDark(false);
    AppColors.isDark = false;
    expect(AppColors.mintBackground, const Color(0xFFF1F8F4));
  });

  test('Citizen complaint keeps its photo path for worker and head', () {
    final complaint = MockDataRepository.instance.addComplaint(
      category: 'Plastic Waste',
      description: 'Plastic dumped near the market.',
      location: 'Lat: 23.2070, Long: 72.6510',
      hasPhoto: true,
      photoPath: 'C:/demo/waste_photo.jpg',
      latitude: 23.2070,
      longitude: 72.6510,
    );
    expect(complaint.id, isNot('SS1024')); // unique ID
    expect(complaint.photoPath, 'C:/demo/waste_photo.jpg');
    expect(complaint.latitude, 23.2070);

    // A task created from this complaint carries the link to the head/worker.
    final task = AppRepository.instance.addTask(
      title: complaint.category,
      description: complaint.description,
      latitude: complaint.latitude!,
      longitude: complaint.longitude!,
      workerId: 'WK-1001',
      citizenComplaintId: complaint.id,
    );
    expect(task.citizenComplaintId, complaint.id);
    expect(
      MockDataRepository.instance
          .getComplaintById(task.citizenComplaintId!)!
          .photoPath,
      'C:/demo/waste_photo.jpg',
    );
  });
}
