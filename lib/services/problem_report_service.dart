import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stores "Report a Problem" messages from Help & Support. Each user may
/// submit exactly one report — enforced by the `unique (user_id)` constraint
/// in the database and checked before the dialog opens.
class ProblemReportService {
  ProblemReportService._();
  static final ProblemReportService instance = ProblemReportService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// True when the signed-in user has already submitted a report.
  Future<bool> hasReported() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final row = await _client
          .from('problem_reports')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      return row != null;
    } on Object catch (e) {
      debugPrint('hasReported failed: $e');
      return false;
    }
  }

  /// Saves the user's problem report. Throws on failure (e.g. already
  /// reported — the database enforces one report per user).
  Future<void> submit(String message) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('You must be signed in to report a problem.');
    }
    await _client.from('problem_reports').insert({
      'user_id': userId,
      'message': message.trim(),
    });
  }
}
