import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart';
import '../models/user_profile.dart';

/// Syncs and reads `public.profiles` records.
class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<UserProfile?> getProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return UserProfile.fromJson(Map<String, dynamic>.from(row));
  }

  /// After Google sign-in: ensure profile exists and refresh harmless metadata.
  /// Never downgrades an existing worker/head role to citizen.
  Future<UserProfile> syncProfile(User user) async {
    final metadata = user.userMetadata ?? {};

    final fullName = _firstNonEmpty([
      metadata['full_name'] as String?,
      metadata['name'] as String?,
      metadata['display_name'] as String?,
    ]);

    final avatarUrl = _firstNonEmpty([
      metadata['avatar_url'] as String?,
      metadata['picture'] as String?,
    ]);

    final email = user.email ?? metadata['email'] as String? ?? '';

    var existing = await getProfile(user.id);

    if (existing == null) {
      final insert = {
        'id': user.id,
        'full_name': fullName ?? email.split('@').first,
        'email': email,
        'avatar_url': avatarUrl,
        'role': 'citizen',
      };
      try {
        await _client.from('profiles').insert(insert);
      } on PostgrestException catch (e) {
        // Trigger may have created the row concurrently.
        debugPrint('Profile insert skipped: ${e.message}');
      }
      existing = await getProfile(user.id);
      if (existing != null) return existing;
      return UserProfile(
        id: user.id,
        fullName: fullName ?? 'User',
        email: email,
        role: UserRole.citizen,
        avatarUrl: avatarUrl,
      );
    }

    final updates = <String, dynamic>{};
    if (fullName != null && fullName.isNotEmpty && fullName != existing.fullName) {
      updates['full_name'] = fullName;
    }
    if (avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        avatarUrl != existing.avatarUrl) {
      updates['avatar_url'] = avatarUrl;
    }
    if (email.isNotEmpty && email != existing.email) {
      updates['email'] = email;
    }

    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', user.id);
      existing = await getProfile(user.id) ?? existing;
    }

    return existing;
  }

  /// True when the citizen has fully completed their profile: phone number
  /// filled in AND an app login password set. The first-run 'Complete
  /// Profile' dialog keeps reappearing until both are done.
  Future<bool> hasCompletedProfile(String userId) async {
    final profile = await getProfile(userId);
    return profile?.phone?.trim().isNotEmpty == true &&
        (profile?.passwordSet ?? false);
  }

  /// Saves citizen profile fields (phone) and/or marks that an app login
  /// password has been set via Supabase Auth. RLS lets citizens update their
  /// own row; the trigger still blocks role/worker_id/vehicle_number changes.
  Future<void> updateCitizenProfile({
    required String userId,
    String? phone,
    bool? passwordSet,
  }) async {
    final updates = <String, dynamic>{
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (passwordSet != null) 'password_set': passwordSet,
    };
    if (updates.isEmpty) return;
    await _client.from('profiles').update(updates).eq('id', userId);
  }

  Future<List<UserProfile>> listWorkers() async {
    final rows = await _client
        .from('profiles')
        .select()
        .eq('role', 'worker')
        .order('full_name');
    return rows
        .map((row) => UserProfile.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<UserProfile?> getProfileByEmail(String email) async {
    final row = await _client
        .from('profiles')
        .select()
        .ilike('email', email.trim())
        .maybeSingle();
    if (row == null) return null;
    return UserProfile.fromJson(Map<String, dynamic>.from(row));
  }

  /// Head promotes an existing user to worker by email.
  ///
  /// The worker account must already exist in Supabase Auth (created by the
  /// administrator with email/password). The `handle_new_user` trigger creates
  /// their profile row automatically, so it will be found here.
  Future<String?> promoteToWorker({
    required String email,
    required String name,
    required String phone,
    required String vehicleNumber,
  }) async {
    final profile = await getProfileByEmail(email);
    if (profile == null) {
      return 'No account found for $email. Create the worker account in Supabase Authentication first, then try again.';
    }

    final workerId = profile.workerId ?? _nextWorkerId(await listWorkers());

    await _client.from('profiles').update({
      'role': 'worker',
      'full_name': name,
      'phone': phone,
      'worker_id': workerId,
      'vehicle_number': vehicleNumber.toUpperCase(),
    }).eq('id', profile.id);

    return null;
  }

  Future<String?> updateWorkerProfile({
    required String id,
    required String name,
    required String phone,
    required String vehicleNumber,
  }) async {
    await _client.from('profiles').update({
      'full_name': name,
      'phone': phone,
      'vehicle_number': vehicleNumber.toUpperCase(),
    }).eq('id', id);
    return null;
  }

  Future<String?> deleteWorkerProfile(String id) async {
    await _client.from('profiles').update({
      'role': 'citizen',
      'worker_id': null,
      'vehicle_number': null,
    }).eq('id', id);
    return null;
  }

  String _nextWorkerId(List<UserProfile> workers) {
    var max = 1000;
    for (final worker in workers) {
      final id = worker.workerId;
      if (id == null) continue;
      final num = int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), ''));
      if (num != null && num > max) max = num;
    }
    return 'WK-${max + 1}';
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
