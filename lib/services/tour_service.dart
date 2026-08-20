import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the first-login app tour was shown for a user.
/// Keyed by user id, so each account on the same device gets its own tour.
class TourService {
  TourService._();
  static final TourService instance = TourService._();

  Future<bool> hasSeen(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tour_seen_$userId') ?? false;
  }

  Future<void> markSeen(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tour_seen_$userId', true);
  }
}
