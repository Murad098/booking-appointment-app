// lib/features/home/chat system/chat/chat_unread_controller.dart
import 'dart:async';

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatUnreadController extends GetxController {
  // Number of distinct chats with unread messages (per user)
  final totalUnreadCount = 0.obs;

  final Map<String, StreamSubscription<QuerySnapshot>> _messageSubscriptions = {};
  StreamSubscription<QuerySnapshot>? _chatsSubscription;

  // Stores the current unread count per room (for real‑time updates)
  final Map<String, int> _roomUnreadCounts = {};

  String? _currentUserId;

  @override
  void onInit() {
    super.onInit();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (_currentUserId != null) {
      _listenToChatRooms();
    }
  }

  @override
  void onClose() {
    _chatsSubscription?.cancel();
    for (final sub in _messageSubscriptions.values) {
      sub.cancel();
    }
    _messageSubscriptions.clear();
    _roomUnreadCounts.clear();
    super.onClose();
  }

  void _listenToChatRooms() {
    if (_currentUserId == null) return;

    _chatsSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: _currentUserId)
        .snapshots()
        .listen((snapshot) {
      // Remove subscriptions for rooms that no longer exist
      final activeRoomIds = snapshot.docs.map((doc) => doc.id).toSet();
      final staleIds = _messageSubscriptions.keys.toSet().difference(activeRoomIds);
      for (final id in staleIds) {
        _messageSubscriptions[id]?.cancel();
        _messageSubscriptions.remove(id);
        _roomUnreadCounts.remove(id); // clean up per‑room count
      }

      // Add or update subscriptions for each room
      for (final doc in snapshot.docs) {
        final chatId = doc.id;
        if (!_messageSubscriptions.containsKey(chatId)) {
          _listenToUnreadMessages(chatId);
        }
      }
      _recalculateTotal();
    });
  }

  void _listenToUnreadMessages(String chatId) {
    if (_currentUserId == null) return;

    final sub = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: _currentUserId)
        .where('status', whereNotIn: ['read'])
        .snapshots()
        .listen((snapshot) {
      // Update the per‑room unread count
      final count = snapshot.docs.length;
      _roomUnreadCounts[chatId] = count;
      _recalculateTotal();
    });

    _messageSubscriptions[chatId] = sub;
  }

  /// Recalculates the badge number as the count of rooms that have at least one unread message.
  Future<void> _recalculateTotal() async {
    if (_currentUserId == null) {
      totalUnreadCount.value = 0;
      return;
    }

    // Count how many rooms have unread messages > 0
    final roomsWithUnread = _roomUnreadCounts.values.where((c) => c > 0).length;
    totalUnreadCount.value = roomsWithUnread;
  }
}