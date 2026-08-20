import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_models.dart';
import '../models/user.dart';
import '../screens/complaints/complaint_details_page.dart';
import '../screens/head/head_citizen_complaints_page.dart';
import '../screens/head/head_proofs_page.dart';
import '../screens/head/head_tasks_page.dart';
import '../screens/worker/worker_task_detail_page.dart';
import 'auth_service.dart';

/// Top-level handler for messages received while the app is terminated or in
/// the background. Must be a static/global function — Flutter runs it in a
/// separate isolate where the main UI is unavailable. FCM already displays
/// notification messages in background/terminated state on its own, so there
/// is nothing to render here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

/// Firebase Cloud Messaging push notifications.
///
/// - Requests notification permission (Android 13+).
/// - Saves this device's FCM token to Supabase (`device_tokens`) linked to the
///   signed-in user, so the app or a future Edge Function can send targeted
///   pushes (e.g. "new task assigned to worker").
/// - Shows notifications while the app is in the FOREGROUND (FCM only shows
///   them automatically in background/terminated state).
/// - Routes notification taps to the correct screen based on the user's role
///   and the message's `route` data (format: `screen|id`).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String channelId = 'safai_setu_notifications';
  static const String channelName = 'Safai Setu Notifications';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;

  /// Re-registers the FCM token whenever the app returns to the foreground.
  /// FCM tokens rotate, and this also fixes accounts whose token was never
  /// saved (e.g. signed in before token registration existed) — so a Head who
  /// never re-signed-in still gets pushes after updating the app.
  AppLifecycleListener? _lifecycleListener;

  /// When a worker taps a "tasks" notification, this is set to the Tasks tab
  /// index (1) so the WorkerShell switches to it instead of pushing a page.
  final ValueNotifier<int?> workerTabRequest = ValueNotifier<int?>(null);

  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_initialized) return;
    _initialized = true;
    _navigatorKey = navigatorKey;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Local notifications render FCM messages while the app is open.
    const androidInit = AndroidInitializationSettings('ic_notification');
    await _local.initialize(
      settings: const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) _handleRoute(payload);
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          channelId,
          channelName,
          importance: Importance.high,
        ));

    // Permission (iOS always prompts; Android 13+ asks via this call).
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // Ask for location permission right after notifications, so a fresh
    // install grants both at once (location is used by the complaint map,
    // worker live sharing, tracking, etc.). No-op if already granted or
    // permanently denied — never re-prompts.
    try {
      var loc = await Geolocator.checkPermission();
      if (loc == LocationPermission.denied) {
        loc = await Geolocator.requestPermission();
      }
      debugPrint('Location permission: $loc');
    } on Object catch (e) {
      debugPrint('Location permission request failed: $e');
    }

    // Register this device's token with the signed-in user. initialize() runs
    // BEFORE sign-in (main() calls it before Supabase auth is ready), so the
    // initial save would always see "no user" and skip — re-save the token
    // every time a user signs in (or an existing session is restored), and
    // again whenever the app resumes (tokens rotate / were never saved).
    AuthService.instance.currentUser.addListener(_onAuthUserChanged);
    _lifecycleListener = AppLifecycleListener(
      onResume: () => unawaited(_saveTokenForCurrentUser()),
    );
    await _saveTokenForCurrentUser();
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _saveToken(token);
    });

    // Foreground messages -> show via local notifications.
    FirebaseMessaging.onMessage.listen((message) {
      _showForeground(message);
    });

    // Tap on a notification that opened the app from background/terminated.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleMessage(initial);
  }

  void _onAuthUserChanged() {
    unawaited(_saveTokenForCurrentUser());
  }

  /// Fetches the current device token and saves it (only when signed in).
  Future<void> _saveTokenForCurrentUser() async {
    if (AuthService.instance.user == null) return;
    try {
      await _saveToken(await FirebaseMessaging.instance.getToken());
    } on Object catch (e) {
      debugPrint('FCM token refresh failed: $e');
    }
  }

  /// Saves the FCM token for the currently signed-in user (upsert per token,
  /// so the same user on multiple devices keeps one row per token).
  Future<void> _saveToken(String? token) async {
    if (token == null || token.isEmpty) return;
    final user = AuthService.instance.user;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('device_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');
      debugPrint('FCM token saved for ${user.email}');
    } on Object catch (e) {
      debugPrint('FCM token save failed: $e');
    }
  }

  /// Best-effort push to one user. Uses the `send-notification` Supabase Edge
  /// Function (must be deployed + have the FIREBASE_SERVICE_ACCOUNT secret).
  /// Silent no-op when unavailable, so the app never breaks on notifications.
  Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    String? route,
  }) {
    return _invoke({
      'userId': userId,
      'title': title,
      'body': body,
      if (route != null) 'route': route,
    });
  }

  /// Best-effort push to every user with the given role
  /// (e.g. all heads when a complaint arrives, all citizens for a broadcast).
  Future<void> sendToRole({
    required String role,
    required String title,
    required String body,
    String? route,
  }) {
    return _invoke({
      'role': role,
      'title': title,
      'body': body,
      if (route != null) 'route': route,
    });
  }

  /// Best-effort push to a worker by their Worker ID (WK-xxxx).
  Future<void> sendToWorkerId({
    required String workerId,
    required String title,
    required String body,
    String? route,
  }) {
    return _invoke({
      'workerId': workerId,
      'title': title,
      'body': body,
      if (route != null) 'route': route,
    });
  }

  Future<void> _invoke(Map<String, dynamic> body) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'send-notification',
        body: body,
      );
    } on Object catch (e) {
      debugPrint('send-notification failed (edge function not deployed?): $e');
    }
  }

  /// Fetches this user's notification history (newest first) from Supabase.
  /// Every push sent through the send-notification Edge Function is stored in
  /// the `notifications` table, so the list works even after reinstall.
  Future<List<AppNotificationItem>> fetchHistory() async {
    final user = AuthService.instance.user;
    if (user == null) return const [];
    try {
      final res = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      final rows = res as List;
      return rows.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return AppNotificationItem(
          title: (map['title'] as String?) ?? '',
          message: (map['body'] as String?) ?? '',
          createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '')
                  ?.toUtc() ??
              DateTime.now().toUtc(),
          isRead: (map['is_read'] as bool?) ?? false,
          route: map['route'] as String?,
        );
      }).toList();
    } on Object catch (e) {
      debugPrint('fetch notification history failed: $e');
      return const [];
    }
  }

  /// Deletes this user's entire notification history.
  Future<void> clearHistory() async {
    final user = AuthService.instance.user;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('user_id', user.id);
    } on Object catch (e) {
      debugPrint('clear notification history failed: $e');
    }
  }

  /// Opens the screen a notification route points to. Used when the user taps
  /// a history entry (same routing as a fresh push tap).
  void openRoute(String? payload) {
    if (payload == null || payload.isEmpty) return;
    _handleRoute(payload);
  }

  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _local.show(
      id: message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch,
      title: notification.title ?? 'Safai Setu',
      body: notification.body ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['route'] as String?,
    );
  }

  void _handleMessage(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty) _handleRoute(route);
  }

  /// Pushes the screen the notification points to, gated by the user's role.
  /// Route payload format: `screen|id`, e.g. `task|abc-123`,
  /// `complaint|abc-123`, `proofs`, `tasks`.
  void _handleRoute(String payload) {
    final navigator = _navigatorKey?.currentState;
    final user = AuthService.instance.user;
    if (navigator == null || user == null) return;
    try {
      final parts = payload.split('|');
      final screen = parts.isNotEmpty ? parts[0] : '';
      final id = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
      switch (user.role) {
        case UserRole.worker:
          if (screen == 'tasks') {
            // Switch the Worker shell to the Tasks tab (index 1).
            workerTabRequest.value = 1;
          } else if (screen == 'task' && id != null) {
            navigator.push(MaterialPageRoute(
              builder: (_) => WorkerTaskDetailPage(taskId: id),
            ));
          }
          break;
        case UserRole.head:
          if (screen == 'proofs') {
            navigator.push(
                MaterialPageRoute(builder: (_) => const HeadProofsPage()));
          } else if (screen == 'complaints') {
            navigator.push(MaterialPageRoute(
                builder: (_) => const HeadCitizenComplaintsPage()));
          } else if (screen == 'tasks') {
            navigator.push(
                MaterialPageRoute(builder: (_) => const HeadTasksPage()));
          }
          break;
        case UserRole.citizen:
          if (screen == 'complaint' && id != null) {
            navigator.push(MaterialPageRoute(
              builder: (_) => ComplaintDetailsPage(complaintId: id),
            ));
          }
          break;
      }
    } on Object catch (e) {
      debugPrint('Notification route failed: $e');
    }
  }
}
