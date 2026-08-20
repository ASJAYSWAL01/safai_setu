import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart';
import '../utils/config.dart';
import 'profile_service.dart';

/// Supabase + Google Sign-In authentication.
///
/// One sign-in for every role — the user's `profiles.role` (assigned in the
/// database) decides which dashboard they see, never a separate login flow.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final ValueNotifier<AppUser?> currentUser = ValueNotifier<AppUser?>(null);
  final ValueNotifier<bool> isInitializing = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isSigningIn = ValueNotifier<bool>(false);

  /// True when a valid Supabase session exists but the account has no usable
  /// profile row (email/password accounts that an admin has not configured).
  /// AuthGate shows an error screen instead of any dashboard or the login page.
  final ValueNotifier<bool> isAccountNotConfigured = ValueNotifier<bool>(false);

  StreamSubscription<AuthState>? _authSubscription;
  bool _googleInitialized = false;

  AppUser? get user => currentUser.value;
  bool get isAuthenticated => currentUser.value != null;

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> initialize() async {
    // GoogleSignIn (7.2.0) is a singleton that must be initialized exactly once.
    if (AppConfig.isGoogleSignInConfigured) {
      try {
        await GoogleSignIn.instance.initialize(
          serverClientId: AppConfig.googleWebClientId,
          clientId: Platform.isIOS && AppConfig.googleIosClientId.isNotEmpty
              ? AppConfig.googleIosClientId
              : (Platform.isAndroid &&
                      AppConfig.googleAndroidClientId.isNotEmpty &&
                      !AppConfig.googleAndroidClientId
                          .startsWith('GOOGLE_ANDROID_')
                  ? AppConfig.googleAndroidClientId
                  : null),
        );
        _googleInitialized = true;
      } on Object catch (e, st) {
        debugPrint('GoogleSignIn initialize error: $e\n$st');
      }
    }

    _authSubscription?.cancel();
    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      unawaited(_handleAuthSession(data.session));
    });

    await _handleAuthSession(_client.auth.currentSession);
    isInitializing.value = false;
  }

  Future<String?> _handleAuthSession(Session? session) async {
    if (session == null) {
      currentUser.value = null;
      isAccountNotConfigured.value = false;
      return null;
    }

    try {
      // New Google accounts get a citizen profile automatically. Email/password
      // accounts (workers/heads) are created by an admin and must already have
      // a profile row — never auto-create one for them (Phase 24 / Test F).
      final provider = session.user.appMetadata['provider'] as String?;
      if (provider == 'google') {
        final profile = await ProfileService.instance.syncProfile(session.user);
        isAccountNotConfigured.value = false;
        currentUser.value = profile.toAppUser();
      } else {
        final profile =
            await ProfileService.instance.getProfile(session.user.id);
        if (profile == null) {
          debugPrint(
            'AuthService: no profile row for ${session.user.email} '
            '(provider: ${session.user.appMetadata['provider']}) — showing '
            '"Account not configured".',
          );
          isAccountNotConfigured.value = true;
          currentUser.value = null;
        } else {
          debugPrint(
            'AuthService: ${session.user.email} → profile role '
            '"${profile.role.name}" → ${profile.role == UserRole.head ? 'HeadShell' : profile.role == UserRole.worker ? 'WorkerShell' : 'MainShell (citizen!)'}.',
          );
          isAccountNotConfigured.value = false;
          currentUser.value = profile.toAppUser();
        }
      }
      return null;
    } on Object catch (e, st) {
      debugPrint('AuthService profile sync failed: $e\n$st');
      final provider = session.user.appMetadata['provider'] as String?;
      if (provider == 'google') {
        // Google metadata is safe to fall back to; role default is citizen.
        currentUser.value = _fallbackUserFromSession(session);
        isAccountNotConfigured.value = false;
        return null;
      }
      // Never guess a role for an email/password account — refuse access
      // rather than misroute a worker/head to the citizen dashboard. Return
      // the real error so the login screen can show WHY it failed.
      currentUser.value = null;
      isAccountNotConfigured.value = false;
      return 'Account verification failed. Please contact the administrator. ($e)';
    }
  }

  AppUser _fallbackUserFromSession(Session session) {
    final user = session.user;
    final metadata = user.userMetadata ?? {};
    return AppUser(
      id: user.id,
      name: (metadata['full_name'] as String?) ??
          (metadata['name'] as String?) ??
          user.email?.split('@').first ??
          'User',
      email: user.email ?? '',
      role: UserRole.citizen,
      photoUrl: (metadata['avatar_url'] as String?) ??
          (metadata['picture'] as String?),
    );
  }

  /// Email + password sign-in (workers and heads).
  ///
  /// Supabase Auth handles the credentials — this method never sees the
  /// password beyond passing it to `signInWithPassword`. The user's
  /// `profiles.role` (assigned in the database) decides their dashboard,
  /// NOT the login method.
  Future<String?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (isSigningIn.value) return 'Sign-in already in progress.';
    if (!AppConfig.isSupabaseConfigured) {
      return 'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY.';
    }

    isSigningIn.value = true;
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final session = _client.auth.currentSession;
      if (session == null) {
        return 'Authentication failed. Please try again.';
      }

      final sessionError = await _handleAuthSession(session);
      if (sessionError != null) return sessionError;
      return null;
    } on AuthException catch (e) {
      debugPrint('Supabase password auth error: ${e.message}');
      return _friendlyPasswordError(e.message);
    } on SocketException {
      return 'No internet connection. Please connect to the internet and try again.';
    } on Object catch (e, st) {
      debugPrint('signInWithEmailAndPassword unexpected error: $e\n$st');
      return 'Sign-in failed: $e';
    } finally {
      isSigningIn.value = false;
    }
  }

  String _friendlyPasswordError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid email or password') ||
        lower.contains('wrong password')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (lower.contains('email not confirmed')) {
      return 'This email is not confirmed yet. Check your inbox for the confirmation link.';
    }
    if (lower.contains('user not found') ||
        lower.contains('no user found')) {
      return 'No account found with this email. Please contact your administrator.';
    }
    return message;
  }

  /// Google Sign-In — native flow using google_sign_in package.
  ///
  /// Uses [GoogleSignIn.instance.signIn()] to get a Google ID token, then
  /// exchanges it with Supabase via [signInWithIdToken]. This is the same
  /// native flow used in the previously working APK — no WebView, no
  /// Supabase server-side client secret required.
  Future<String?> signInWithGoogle(BuildContext context) async {
    if (isSigningIn.value) return 'Sign-in already in progress.';
    if (!AppConfig.isSupabaseConfigured) {
      return 'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY.';
    }

    isSigningIn.value = true;
    try {
      // Initialize GoogleSignIn if not already done.
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize(
          serverClientId: AppConfig.googleWebClientId,
        );
        _googleInitialized = true;
      }

      // Sign out first to force account picker to show every time.
      await GoogleSignIn.instance.signOut();

      // Trigger the native Google account picker (v7.x API).
      late final GoogleSignInAccount googleUser;
      try {
        googleUser = await GoogleSignIn.instance.authenticate();
      } catch (_) {
        return 'Google sign-in was cancelled.';
      }

      // Get fresh auth tokens.
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        return 'Google sign-in failed: could not get ID token.';
      }

      // Exchange the Google ID token for a Supabase session.
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final session = _client.auth.currentSession;
      if (session == null) {
        return 'Google authentication failed. Please try again.';
      }

      await _handleAuthSession(session);
      return null;
    } on AuthException catch (e) {
      debugPrint('Supabase Google signInWithIdToken error: ${e.message}');
      return 'Google sign-in failed: ${e.message}';
    } on SocketException {
      return 'No internet connection. Please connect to the internet and try again.';
    } on Object catch (e, st) {
      debugPrint('signInWithGoogle unexpected error: $e\n$st');
      return 'Sign-in failed: $e';
    } finally {
      isSigningIn.value = false;
    }
  }

  /// Saves the citizen's phone number and (optionally) sets their Supabase
  /// Auth password so they can later sign out and back in with the same email
  /// + password instead of Google. The password is stored hashed by Supabase
  /// Auth — never as plaintext in `profiles`.
  ///
  /// Returns null on success, or a user-facing error message.
  Future<String?> completeCitizenProfile({
    required String phone,
    String? password,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      return 'You must be signed in to complete your profile.';
    }
    final userId = session.user.id;

    try {
      await ProfileService.instance.updateCitizenProfile(
        userId: userId,
        phone: phone,
      );
    } on Object catch (e) {
      debugPrint('completeCitizenProfile phone update failed: $e');
      return 'Could not save your profile. Please try again.';
    }

    if (password != null && password.isNotEmpty) {
      try {
        // Adds email + password login to an account created via Google.
        await _client.auth.updateUser(UserAttributes(password: password));
      } on AuthException catch (e) {
        debugPrint('updateUser password error: ${e.message}');
        return 'Could not set your login password: ${e.message}';
      } on Object catch (e) {
        debugPrint('updateUser password unexpected error: $e');
        return 'Could not set your login password. Please try again.';
      }
      try {
        await ProfileService.instance.updateCitizenProfile(
          userId: userId,
          passwordSet: true,
        );
      } on Object catch (e) {
        debugPrint('mark password_set failed: $e');
      }
    }

    await refreshCurrentUser();
    return null;
  }

  /// Re-reads the profile row and refreshes [currentUser] (e.g. after the
  /// citizen edits their profile details).
  Future<void> refreshCurrentUser() async {
    await _handleAuthSession(_client.auth.currentSession);
  }

  Future<void> logout() async {
    if (_googleInitialized) {
      try {
        // signOut() only ends the local session. We deliberately do NOT call
        // disconnect() — it revokes the app's authorization on the Google
        // account, which forces a full re-authorization on the next sign-in
        // and can surface as "[16] Account reauth failed" for some accounts.
        await GoogleSignIn.instance.signOut();
      } on Object catch (e) {
        debugPrint('Google sign-out error: $e');
      }
    }

    try {
      await _client.auth.signOut();
    } on Object catch (e) {
      debugPrint('Supabase sign-out error: $e');
    }

    currentUser.value = null;
    isAccountNotConfigured.value = false;
  }

  void dispose() {
    _authSubscription?.cancel();
  }

  // ---------------------------------------------------------------------------
  // Head worker management (backed by Supabase profiles)
  // ---------------------------------------------------------------------------

  Future<List<AppUser>> get workers async {
    final profiles = await ProfileService.instance.listWorkers();
    return profiles.map((p) => p.toAppUser()).toList();
  }

  Future<AppUser?> getWorkerById(String id) async {
    final profile = await ProfileService.instance.getProfile(id);
    if (profile == null || profile.role != UserRole.worker) return null;
    return profile.toAppUser();
  }

  Future<AppUser?> getWorkerByWorkerId(String workerId) async {
    final workers = await ProfileService.instance.listWorkers();
    for (final profile in workers) {
      if (profile.workerId == workerId.trim().toUpperCase()) {
        return profile.toAppUser();
      }
    }
    return null;
  }

  Future<({AppUser? worker, String? error})> registerWorker({
    required String email,
    required String name,
    required String phone,
    required String vehicleNumber,
  }) async {
    if (user == null || !user!.isHead) {
      return (worker: null, error: 'Only the Head can generate Worker IDs.');
    }
    final error = await ProfileService.instance.promoteToWorker(
      email: email,
      name: name,
      phone: phone,
      vehicleNumber: vehicleNumber,
    );
    if (error != null) return (worker: null, error: error);
    final profile = await ProfileService.instance.getProfileByEmail(email);
    return (worker: profile?.toAppUser(), error: null);
  }

  Future<String?> updateWorker({
    required String id,
    required String name,
    required String phone,
    required String vehicleNumber,
  }) =>
      ProfileService.instance.updateWorkerProfile(
        id: id,
        name: name,
        phone: phone,
        vehicleNumber: vehicleNumber,
      );

  Future<String?> deleteWorker(String id) =>
      ProfileService.instance.deleteWorkerProfile(id);
}
