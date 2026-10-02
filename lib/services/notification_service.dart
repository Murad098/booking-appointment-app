// lib/services/notification_service.dart

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

// ════════════════════════════════════════════════════════════════════════════
// HOW TO FIND YOUR FIREBASE PROJECT ID (not the number):
//   Firebase Console → Project Settings → General
//   → "Project ID" field (looks like: bookify-12345, NOT a number)
//   Replace _fcmProjectId below with that value.
//
// BUG THAT WAS HERE: _fcmProjectId was set to '505681813229'
// That is your PROJECT NUMBER. The FCM HTTP v1 URL needs the PROJECT ID.
// Using the number gives a 404 from FCM and no notification is sent.
// ════════════════════════════════════════════════════════════════════════════
const String _fcmProjectId = 'bookify-12c57'; // e.g. 'bookify-abc123'

// ════════════════════════════════════════════════════════════════════════════
// BACKGROUND HANDLER — must be top-level (outside any class).
// Registered in main.dart BEFORE Firebase.initializeApp().
// ════════════════════════════════════════════════════════════════════════════
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // NOTE: Do NOT call Firebase.initializeApp() here if you're using
  // firebase_core 2.x+ — it's already initialised by the plugin.
  print('[FCM Background] ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const String _channelId   = 'bookify_channel';
  static const String _channelName  = 'Bookify Notifications';
  static const String _channelDesc  = 'Appointment updates for Bookify';

  // Cache for current token to avoid unnecessary operations
  String? _cachedToken;

  // ── Call once in main(), after Firebase.initializeApp() ─────────────────
  Future<void> initialize() async {
    // 1. Create Android channel first — must exist before ANY notification fires
    await _createAndroidChannel();

    // 2. Local notifications plugin init
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        _handleLocalTap(r.payload);
      },
    );

    // 3. Request OS permission (required Android 13+ / iOS always)
    final settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
    print('[FCM] Permission: ${settings.authorizationStatus}');

    // 4. iOS foreground banners
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    // 5. ── CRITICAL FIX: Check for existing user immediately ──
    // This ensures the token is saved for users already logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print('[FCM] Existing user found on app start: ${currentUser.uid}');
      // Check if push is enabled before saving token
      final isPushEnabled = await _isPushEnabledForUser(currentUser.uid);
      if (isPushEnabled) {
        await _refreshAndSaveToken(currentUser.uid);
      } else {
        print('[FCM] Push notifications disabled for user, not saving token on start');
      }
    }

    // 6. Listen to auth state changes for FUTURE logins/logouts
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        print('[FCM] Auth state change - user logged in: ${user.uid}');
        // Check if push is enabled before saving token
        final isPushEnabled = await _isPushEnabledForUser(user.uid);
        if (isPushEnabled) {
          await _refreshAndSaveToken(user.uid);
        } else {
          print('[FCM] Push notifications disabled for user, not saving token on login');
        }
      } else {
        print('[FCM] Auth state change - user logged out');
        _cachedToken = null;
      }
    });

    // 7. Refresh token whenever FCM rotates it
    _fcm.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('[FCM] Token refreshed for user: ${user.uid}');
        // Check if push is enabled before saving new token
        final isPushEnabled = await _isPushEnabledForUser(user.uid);
        if (isPushEnabled) {
          await _saveToken(user.uid, newToken);
        } else {
          print('[FCM] Push notifications disabled, not saving refreshed token');
        }
      }
    });

    // 8. Foreground message → show local banner
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // 9. App brought to foreground by tapping notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);

    // 10. App cold-started by tapping notification
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      Future.delayed(const Duration(seconds: 1),
              () => _handleRemoteMessage(initial));
    }
  }

  /// Check if push notifications are enabled for a user
  Future<bool> _isPushEnabledForUser(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final enabled = userDoc.data()?['pushNotificationsEnabled'] as bool?;
        return enabled ?? true; // Default to true if not set
      }
      return true; // Default to enabled if user doc doesn't exist
    } catch (e) {
      print('[FCM] Error checking push enabled for $userId: $e');
      return true; // Default to enabled on error
    }
  }

  // ── Public method to manually refresh token (call after login/signup) ──
  Future<void> refreshTokenForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('[FCM] Manual token refresh requested for: ${user.uid}');
      final isPushEnabled = await _isPushEnabledForUser(user.uid);
      if (isPushEnabled) {
        await _refreshAndSaveToken(user.uid);
      } else {
        print('[FCM] Push notifications disabled, not refreshing token');
      }
    } else {
      print('[FCM] Manual token refresh called but no user logged in');
    }
  }

  /// Enable push notifications for the current user
  /// This will refresh and save the FCM token
  Future<void> enablePushNotifications(String userId) async {
    try {
      print('[FCM] Enabling push notifications for user: $userId');
      await _refreshAndSaveToken(userId);
      print('[FCM] Push notifications enabled and token saved for user: $userId');
    } catch (e) {
      print('[FCM] Error enabling push notifications: $e');
    }
  }

  /// Disable push notifications for the current user
  /// This will remove the FCM token from Firestore
  Future<void> disablePushNotifications(String userId) async {
    try {
      print('[FCM] Disabling push notifications for user: $userId');

      // Remove the token from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Clear cached token
      _cachedToken = null;

      print('[FCM] Push notifications disabled and token removed for user: $userId');
    } catch (e) {
      print('[FCM] Error disabling push notifications: $e');
    }
  }

  /// Update push notification preference and handle token accordingly
  Future<void> updatePushPreference(String userId, bool enabled) async {
    // First save the preference
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'pushNotificationsEnabled': enabled,
      'pushNotificationsUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('[FCM] Push preference updated to: $enabled for user: $userId');

    // Then handle token based on preference
    if (enabled) {
      await enablePushNotifications(userId);
    } else {
      await disablePushNotifications(userId);
    }
  }

  // ── Fetch a fresh token and write it to Firestore ────────────────────────
  Future<void> _refreshAndSaveToken(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) {
        print('[FCM] getToken() returned null — check google-services.json');
        return;
      }
      print('[FCM] Token for uid $uid: $token');
      _cachedToken = token;
      await _saveToken(uid, token);
    } catch (e) {
      print('[FCM] _refreshAndSaveToken error: $e');
    }
  }

  // ── Write token to Firestore ─────────────────────────────────────────────
  Future<void> _saveToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print('[FCM] Token saved for uid: $uid');
    } catch (e) {
      print('[FCM] _saveToken error: $e');
    }
  }

  // ── Android 8+ notification channel ─────────────────────────────────────
  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId, _channelName,
      description: _channelDesc,
      importance: Importance.max,  // MAX = heads-up banners
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    print('[FCM] Android channel ready: $_channelId');
  }

  // ── Foreground banner ────────────────────────────────────────────────────
  // FIXED: Show different icons for chat vs appointment notifications
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;

    final type = message.data['type'] ?? '';

    // Choose icon based on notification type
    final String notificationIcon =
    type == 'chat_message'
        ? '@drawable/ic_chat_notification'   // ← chat icon
        : '@drawable/ic_appointment_notification'; // ← appointment icon

    print('[FCM] Foreground message: ${n.title}, type: $type, icon: $notificationIcon');

    final details = NotificationDetails( // ← removed const
      android: AndroidNotificationDetails( // ← implicitly non-const now
        _channelId, _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        icon: notificationIcon,  // ← dynamic icon (works because no const)
        playSound: true,
        enableVibration: true,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true, presentBadge: true, presentSound: true,
      ),
    );

    await _localNotifications.show(
      id: n.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: details,
      payload: message.data['bookingId'],
    );
  }

  // FIX: Updated to open Notifications Screen when notification is tapped
  void _handleLocalTap(String? payload) {
    print('[FCM] Local notification tapped, payload: $payload');
    // Add a small delay to ensure the app is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      _navigateToNotificationsScreen();
    });
  }

  // FIX: Updated to open Notifications Screen when notification is tapped from background/killed state
  void _handleRemoteMessage(RemoteMessage message) {
    final bookingId = message.data['bookingId'] ?? '';
    final type = message.data['type'] ?? '';
    print('[FCM] Remote message opened: type=$type, bookingId=$bookingId');

    // Add a small delay to ensure the app is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      _navigateToNotificationsScreen();
    });
  }

  // Helper method to navigate to Notifications Screen based on user role
  void _navigateToNotificationsScreen() {
    try {
      // Check if we have a current user to determine role
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print('[FCM] No user logged in, cannot navigate to notifications');
        return;
      }

      // Get user role from Firestore
      FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get().then((doc) {
        if (doc.exists) {
          final role = doc.data()?['role'] as String?;
          print('[FCM] User role for navigation: $role');

          if (role == 'business') {
            // Navigate to Notifications Screen for Business user
            Get.toNamed('/notifications', arguments: {'initialRole': 'business'});
          } else {
            // Navigate to Notifications Screen for Personal/Customer user
            Get.toNamed('/notifications', arguments: {'initialRole': 'customer'});
          }
        } else {
          // Default to customer view if role not found
          Get.toNamed('/notifications', arguments: {'initialRole': 'customer'});
        }
      }).catchError((e) {
        print('[FCM] Error fetching user role: $e');
        // Fallback - try to navigate anyway
        Get.toNamed('/notifications');
      });
    } catch (e) {
      print('[FCM] Navigation error: $e');
    }
  }

  /// Check if user has push notifications enabled
  Future<bool> _arePushNotificationsEnabled(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final enabled = userDoc.data()?['pushNotificationsEnabled'] as bool?;
        // Default to true if not set (backwards compatibility)
        return enabled ?? true;
      }
      return true; // Default to enabled if user doc doesn't exist
    } catch (e) {
      print('[FCM] Error checking push preference for $userId: $e');
      return true; // Default to enabled on error
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // sendPushNotification
  //
  // BUGS THAT WERE HERE:
  //  1. The old version only did Firestore.add() — FCM API was never called.
  //  2. _fcmProjectId was the project NUMBER not the project ID, causing 404.
  //
  // This version calls FCM HTTP v1 API with a proper OAuth2 service-account
  // token, so the push is actually delivered to the device.
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (userId.trim().isEmpty) {
      print('[FCM] sendPushNotification: empty userId');
      return;
    }

    // Always store in Firestore (powers in-app notification feed)
    await _storeInFirestore(userId, title, body, data);

    // ── NEW: Check if user has push notifications enabled ──
    final arePushEnabled = await _arePushNotificationsEnabled(userId);
    if (!arePushEnabled) {
      print('[FCM] Push notifications disabled for user: $userId — skipping push delivery');
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('[FCM] No user doc for: $userId');
        return;
      }

      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.trim().isEmpty) {
        print('[FCM] No token stored for $userId '
            '— user may not have opened the app after login or push is disabled');
        return;
      }

      print('[FCM] Sending to userId: $userId (push enabled: $arePushEnabled)');

      final accessToken = await _getOAuthToken();
      if (accessToken == null) {
        print('[FCM] OAuth token null — push not sent');
        return;
      }

      // FCM requires all data values to be strings
      final stringData = (data ?? {})
          .map((k, v) => MapEntry(k, v?.toString() ?? ''));

      // Determine icon for FCM payload (only affects Android)
      final String androidIcon =
      (data?['type'] == 'chat_message')
          ? 'ic_chat_notification'
          : 'ic_appointment_notification';

      final payload = jsonEncode({
        'message': {
          'token': fcmToken,
          'notification': {'title': title, 'body': body},
          'data': stringData,
          'android': {
            'priority': 'HIGH',
            'notification': {
              'channel_id': _channelId,
              'sound': 'default',
              'icon': androidIcon,  // ← dynamic icon for FCM
              'default_vibrate_timings': true,
              'notification_priority': 'PRIORITY_MAX',
              'visibility': 'PUBLIC',
            },
          },
          'apns': {
            'headers': {'apns-priority': '10'},
            'payload': {
              'aps': {
                'alert': {'title': title, 'body': body},
                'sound': 'default',
                'badge': 1,
                'content-available': 1,
              },
            },
          },
        },
      });

      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$_fcmProjectId/messages:send',
        ),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
        body: payload,
      );

      if (response.statusCode == 200) {
        print('[FCM] ✓ Push delivered to $userId');
      } else {
        print('[FCM] ✗ Push failed ${response.statusCode}: ${response.body}');
        if (response.statusCode == 404 || response.statusCode == 410) {
          // Token is stale — remove it so we don't keep trying
          await FirebaseFirestore.instance
              .collection('users').doc(userId)
              .update({'fcmToken': FieldValue.delete()});
          print('[FCM] Stale token removed for $userId');
        }
      }
    } catch (e, st) {
      print('[FCM] sendPushNotification error: $e\n$st');
    }
  }

  // ── OAuth2 token from service account ───────────────────────────────────
  Future<String?> _getOAuthToken() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/service_account.json');
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final credentials = auth.ServiceAccountCredentials.fromJson(json);
      const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await auth.clientViaServiceAccount(credentials, scopes);
      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      print('[FCM] _getOAuthToken error: $e');
      print('[FCM] → Is assets/service_account.json in pubspec.yaml assets?');
      return null;
    }
  }

  // ── Firestore notification feed entry ───────────────────────────────────
  Future<void> _storeInFirestore(
      String userId, String title, String body,
      Map<String, dynamic>? data,
      ) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': data?['type'] ?? 'general',
        'bookingId': data?['bookingId'] ?? '',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('[FCM] _storeInFirestore error: $e');
    }
  }
}