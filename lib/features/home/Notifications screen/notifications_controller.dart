import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// User Role Enum
enum UserRole { personal, business }

// Notification Model
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final UserRole targetRole;
  bool isRead;
  final String? bookingId;
  final String? relatedId;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.targetRole,
    this.isRead = false,
    this.bookingId,
    this.relatedId,
  });

  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

enum NotificationType {
  bookingConfirmed,
  appointmentReminder,
  paymentSuccessful,
  newBookingRequest,
  appointmentCancelled,
  pendingApproval,
  rescheduleRequest,
  rescheduleConfirmed,
  ratingRequest,
  autoCancelled,
  refundProcessed,
  chatMessage, // ← ADDED for chat notifications
}

class NotificationsController extends GetxController {
  final notifications = <AppNotification>[].obs;
  final selectedTab = 0.obs;
  final notificationsEnabled = true.obs;
  final userRole = UserRole.personal.obs;
  final unreadCountObs = 0.obs;

  StreamSubscription<QuerySnapshot>? _notificationsSubscription;
  late CollectionReference _notificationsCollection;

  // Track if listener is already set up for current user
  String? _currentUserId;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes to set up/tear down listener
    _setupAuthStateListener();
  }

  @override
  void onClose() {
    _notificationsSubscription?.cancel();
    super.onClose();
  }

  void _setupAuthStateListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && _currentUserId != user.uid) {
        // User is logged in and it's a different user than before
        _currentUserId = user.uid;
        _setupRealtimeListenerForUser(user.uid);
      } else if (user == null) {
        // User logged out - clear notifications and cancel listener
        _notificationsSubscription?.cancel();
        _notificationsSubscription = null;
        _currentUserId = null;
        notifications.clear();
        unreadCountObs.value = 0;
      }
    });
  }

  // New method to set up listener for a specific user
  void _setupRealtimeListenerForUser(String uid) {
    // Cancel existing subscription if any
    _notificationsSubscription?.cancel();

    _notificationsCollection = FirebaseFirestore.instance.collection('notifications');

    // FIX: Removed .orderBy('createdAt') from the query to avoid needing a
    // composite Firestore index and to prevent silent failures when createdAt
    // is null on some documents. Sorting is handled in _processNotifications.
    _notificationsSubscription = _notificationsCollection
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      _processNotifications(snapshot.docs);
    }, onError: (error) {
      print('[NotificationsController] Firestore listener error: $error');
    });
  }

  void _processNotifications(List<QueryDocumentSnapshot> docs) {
    final List<AppNotification> loadedNotifications = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final userRoleValue = _getUserRoleFromData(data);
      NotificationType type = _parseNotificationType(data['type'] ?? 'general');

      loadedNotifications.add(AppNotification(
        id: doc.id,
        title: data['title'] ?? '',
        message: data['body'] ?? '',
        // FIX: Safe null handling — if createdAt is missing, use DateTime.now()
        // so the notification still appears instead of crashing or being skipped.
        timestamp: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        type: type,
        targetRole: userRoleValue,
        isRead: data['isRead'] ?? false,
        bookingId: data['bookingId'],
        relatedId: data['relatedId'],
      ));
    }

    // FIX: Corrected sort order to match the requirements:
    //   1. Unread notifications first (isRead == false → sort to top)
    //   2. Within each group, newest first (descending timestamp)
    //   This satisfies: "If all read, sort newest at top, older at bottom."
    loadedNotifications.sort((a, b) {
      if (a.isRead != b.isRead) {
        return a.isRead ? 1 : -1; // unread (false) floats to top
      }
      return b.timestamp.compareTo(a.timestamp); // newest first within group
    });

    notifications.value = loadedNotifications;
    _updateUnreadCount();
  }

  UserRole _getUserRoleFromData(Map<String, dynamic> data) {
    if (data['targetRole'] != null) {
      return data['targetRole'] == 'business' ? UserRole.business : UserRole.personal;
    }

    final type = data['type'] ?? '';
    if (type == 'new_booking_request' || type == 'pendingApproval') {
      return UserRole.business;
    }

    return userRole.value;
  }

  NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'booking_confirmed':
      case 'appointment_approved':
        return NotificationType.bookingConfirmed;
      case 'appointment_reminder':
        return NotificationType.appointmentReminder;
      case 'payment_successful':
        return NotificationType.paymentSuccessful;
      case 'new_booking_request':
        return NotificationType.newBookingRequest;
      case 'appointment_cancelled':
        return NotificationType.appointmentCancelled;
      case 'pending_approval':
        return NotificationType.pendingApproval;
      case 'reschedule_request':
        return NotificationType.rescheduleRequest;
      case 'reschedule_confirmed':
        return NotificationType.rescheduleConfirmed;
      case 'rating_request':
        return NotificationType.ratingRequest;
      case 'auto_cancelled':
        return NotificationType.autoCancelled;
      case 'refund_processed':
        return NotificationType.refundProcessed;
      case 'chat_message': // ← ADDED
        return NotificationType.chatMessage;
      default:
        return NotificationType.bookingConfirmed;
    }
  }

  void setUserRole(UserRole role) {
    if (userRole.value == role) return;
    userRole.value = role;
    _updateUnreadCount();
  }

  void _updateUnreadCount() {
    // FIX: Count ALL unread notifications for the current user,
    // regardless of targetRole, so the badge always reflects reality.
    final count = notifications.where((n) => !n.isRead).length;
    unreadCountObs.value = count;
  }

  // FIX: The core fix — removed the `n.targetRole == userRole.value` filter.
  // The Firestore query already scopes results to the current user's UID,
  // so every notification in the list belongs to this user and must be shown.
  // The old role filter was silently hiding notifications whenever targetRole
  // didn't match the controller's current userRole (e.g. before setUserRole
  // was called, or when the role assignment logic chose the wrong fallback).
  List<AppNotification> get filteredNotifications {
    if (selectedTab.value == 0) {
      // "All" tab: every notification, already sorted unread-first then newest-first
      return List<AppNotification>.from(notifications);
    } else {
      // "Unread" tab: only unread, sorted newest first
      final unreadOnly = notifications.where((n) => !n.isRead).toList();
      unreadOnly.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return unreadOnly;
    }
  }

  int get totalCount => filteredNotifications.length;
  int get unreadCount => unreadCountObs.value;

  Future<void> markAsReadAndNavigate(String id, BuildContext context) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !notifications[index].isRead) {
      notifications[index].isRead = true;

      // Re-sort after marking as read: read items sink below unread ones
      final currentList = List<AppNotification>.from(notifications);
      currentList.sort((a, b) {
        if (a.isRead != b.isRead) {
          return a.isRead ? 1 : -1;
        }
        return b.timestamp.compareTo(a.timestamp);
      });
      notifications.value = currentList;

      await _notificationsCollection.doc(id).update({'isRead': true});
      _updateUnreadCount();
    }

    final notification = notifications.firstWhere((n) => n.id == id);
    _navigateBasedOnType(notification, context);
  }

  void _navigateBasedOnType(AppNotification notification, BuildContext context) {
    final bookingId = notification.bookingId;

    switch (notification.type) {
      case NotificationType.ratingRequest:
        if (bookingId != null && bookingId.isNotEmpty) {
          Get.toNamed('/rating', arguments: {'bookingId': bookingId});
        }
        break;

      case NotificationType.rescheduleRequest:
      case NotificationType.rescheduleConfirmed:
      case NotificationType.bookingConfirmed:
      case NotificationType.appointmentCancelled:
      case NotificationType.autoCancelled:
      case NotificationType.refundProcessed:
        if (bookingId != null && bookingId.isNotEmpty) {
          final isBusinessView = userRole.value == UserRole.business;
          Get.toNamed('/appointment-details', arguments: {
            'id': bookingId,
            'isBusinessView': isBusinessView,
          });
        }
        break;

      case NotificationType.newBookingRequest:
      case NotificationType.pendingApproval:
        if (bookingId != null && bookingId.isNotEmpty) {
          Get.toNamed('/appointment-details', arguments: {
            'id': bookingId,
            'isBusinessView': true,
          });
        }
        break;

      case NotificationType.chatMessage:
      // Navigate to chat screen using chatId from relatedId or bookingId
        final chatId = notification.relatedId ?? notification.bookingId;
        if (chatId != null && chatId.isNotEmpty) {
          Get.toNamed('/chat-details', arguments: {'chatId': chatId});
        }
        break;

      default:
        break;
    }
  }

  void markAllAsRead() async {
    var changed = false;
    final batch = FirebaseFirestore.instance.batch();

    for (var notification in notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
        batch.update(_notificationsCollection.doc(notification.id), {'isRead': true});
        changed = true;
      }
    }

    if (changed) {
      await batch.commit();
      final currentList = List<AppNotification>.from(notifications);
      currentList.sort((a, b) {
        if (a.isRead != b.isRead) {
          return a.isRead ? 1 : -1;
        }
        return b.timestamp.compareTo(a.timestamp);
      });
      notifications.value = currentList;
      _updateUnreadCount();
    }
  }

  void deleteNotification(String id) async {
    await _notificationsCollection.doc(id).delete();
    notifications.removeWhere((n) => n.id == id);
    _updateUnreadCount();
  }

  void changeTab(int index) {
    selectedTab.value = index;
  }

  void toggleNotifications() {
    notificationsEnabled.value = !notificationsEnabled.value;
  }

  void refreshNotifications() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && _currentUserId == currentUser.uid) {
      // Re-fetch by canceling and re-setting up
      _setupRealtimeListenerForUser(currentUser.uid);
    } else if (currentUser != null) {
      _setupRealtimeListenerForUser(currentUser.uid);
    }
  }
}