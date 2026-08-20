import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safai_setu/models/complaint.dart';
import 'package:safai_setu/models/user.dart';
import 'package:safai_setu/models/user_profile.dart';
import 'package:safai_setu/screens/login_page.dart';
import 'package:safai_setu/services/theme_service.dart';
import 'package:safai_setu/theme/app_theme.dart';

void main() {
  group('AppUser role gating', () {
    test('roles gate which shell each user may access', () {
      const citizen = AppUser(
        id: 'u1',
        name: 'Citizen',
        email: 'citizen@example.com',
        role: UserRole.citizen,
      );
      const worker = AppUser(
        id: 'u2',
        name: 'Worker',
        email: 'worker@example.com',
        role: UserRole.worker,
      );
      const head = AppUser(
        id: 'u3',
        name: 'Head',
        email: 'head@example.com',
        role: UserRole.head,
      );

      expect(citizen.isCitizen, isTrue);
      expect(citizen.isWorker, isFalse);
      expect(citizen.isHead, isFalse);
      expect(worker.isWorker, isTrue);
      expect(head.isHead, isTrue);
    });

    test('UserProfile.fromJson parses database rows safely', () {
      final profile = UserProfile.fromJson({
        'id': 'abc-123',
        'full_name': 'Aarav Patel',
        'email': 'aarav@example.com',
        'avatar_url': 'https://example.com/avatar.png',
        'role': 'worker',
        'phone': '9876543210',
        'worker_id': 'WK-1001',
        'vehicle_number': 'GJ-18-WM-1024',
        'created_at': '2026-01-01T10:00:00.000Z',
        'updated_at': '2026-01-02T10:00:00.000Z',
      });

      expect(profile.fullName, 'Aarav Patel');
      expect(profile.email, 'aarav@example.com');
      expect(profile.role, UserRole.worker);
      expect(profile.workerId, 'WK-1001');
      expect(profile.avatarUrl, 'https://example.com/avatar.png');
      expect(profile.createdAt, isNotNull);

      // Missing/unknown fields must not crash.
      final minimal = UserProfile.fromJson({'id': 'x', 'full_name': ''});
      expect(minimal.role, UserRole.citizen);
      expect(minimal.fullName, isNotEmpty);
      expect(minimal.email, '');
      expect(minimal.avatarUrl, isNull);

      // A database row can never create a head/worker without a real role.
      expect(UserProfile.fromJson({'id': 'y', 'role': 'head'}).role,
          UserRole.head);
      expect(
          UserProfile.fromJson({'id': 'z', 'role': 'not-a-role'}).role,
          UserRole.citizen);
    });
  });

  group('Complaint model', () {
    test('status strings map to enum values', () {
      expect(ComplaintStatus.values, hasLength(5));
      expect(ComplaintStatus.pending.label, 'Pending');
      expect(ComplaintStatus.resolved.label, 'Resolved');
      expect(ComplaintStatus.rejected.label, 'Rejected');
    });
  });

  group('Login page', () {
    testWidgets('shows the Google sign-in button and Safai Setu branding',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.text('Welcome to Safai Setu'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });
  });

  group('Theme', () {
    test('theme toggle switches the app palette between light and dark', () {
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
  });
}
