import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/notification_service.dart';

class AppSettingsController extends GetxController {
  // --- Communication Methods ---
  var isChatEnabled = true.obs;
  var isEmailEnabled = true.obs;
  var isPushEnabled = true.obs;

  // Loading state
  var isLoading = true.obs;  // Changed from false to true - start loading immediately

  // Current user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // --- Language ---
  var currentLanguage = 'English'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPushNotificationPreference();
  }

  /// Load user's push notification preference from Firestore
  Future<void> _loadPushNotificationPreference() async {
    if (currentUserId == null) {
      // If no user, stop loading (though this shouldn't happen on settings screen)
      isLoading.value = false;
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final pushEnabled = userDoc.data()?['pushNotificationsEnabled'] as bool?;
        if (pushEnabled != null) {
          isPushEnabled.value = pushEnabled;
          print('[AppSettings] Loaded push preference: $pushEnabled for user: $currentUserId');
        }
      }
    } catch (e) {
      print('[AppSettings] Error loading push preference: $e');
    } finally {
      // Data loading complete - hide loading indicator
      isLoading.value = false;
    }
  }

  /// Save push notification preference to Firestore and handle token accordingly
  Future<void> _savePushNotificationPreference(bool value) async {
    if (currentUserId == null) return;

    try {
      // Save the preference first
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .set({
        'pushNotificationsEnabled': value,
        'pushNotificationsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('[AppSettings] Saved push preference: $value for user: $currentUserId');

      // Handle token based on the new preference
      if (value) {
        // Enable: refresh and save token
        await NotificationService().enablePushNotifications(currentUserId!);
      } else {
        // Disable: remove token from Firestore
        await NotificationService().disablePushNotifications(currentUserId!);
      }
    } catch (e) {
      print('[AppSettings] Error saving push preference: $e');
    }
  }

  // Toggle Handlers
  void toggleSms(bool value) => isChatEnabled.value = value;
  void toggleEmail(bool value) => isEmailEnabled.value = value;

  void togglePush(bool value) async {
    isPushEnabled.value = value;
    await _savePushNotificationPreference(value);
  }

  void changeLanguage(String lang) {
    currentLanguage.value = lang;
  }
}