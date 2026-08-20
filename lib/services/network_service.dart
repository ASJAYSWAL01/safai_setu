import 'dart:io';

/// Lightweight connectivity helper. Actual Supabase/network errors are still
/// handled at call sites because connectivity != reachable internet.
class NetworkService {
  NetworkService._();
  static final NetworkService instance = NetworkService._();

  Future<bool> hasInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('supabase.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on Object {
      return false;
    }
  }

  String offlineMessage() =>
      'No internet connection. Please connect to the internet and try again.';
}
