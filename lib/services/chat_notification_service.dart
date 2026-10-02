import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class ChatNotificationService {
  static final ChatNotificationService _instance = ChatNotificationService._internal();
  factory ChatNotificationService() => _instance;
  ChatNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Deduplication cache: key = messageId (based on chatId + timestamp + text), value = timestamp when processed
  final Map<String, DateTime> _processedMessages = {};

  /// Generates a unique key for a message to detect duplicates.
  String _getMessageKey(String chatId, String senderId, String messageText, DateTime timestamp) {
    return '${chatId}_${senderId}_${timestamp.millisecondsSinceEpoch}_${messageText.hashCode}';
  }

  /// Call when a new outgoing message is sent.
  /// Always sends a fresh, individual notification (no duplicates).
  Future<void> processOutgoingMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String messageText,
    required String senderName,
    required DateTime messageTimestamp, // Pass the exact message timestamp to avoid race conditions
  }) async {
    try {
      final messageKey = _getMessageKey(chatId, senderId, messageText, messageTimestamp);

      // Clean up old entries (older than 5 seconds)
      final now = DateTime.now();
      _processedMessages.removeWhere((_, timestamp) => now.difference(timestamp) > const Duration(seconds: 5));

      // If we've already processed this exact message, skip
      if (_processedMessages.containsKey(messageKey)) {
        print('[ChatNotificationService] Duplicate message detected, skipping notification.');
        return;
      }

      // Mark as processed
      _processedMessages[messageKey] = now;

      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) return;

      // Send a new individual notification every time
      await _sendNewNotification(chatId, receiverId, senderName, messageText, now);

      // Optionally update the last notification timestamp
      await chatDoc.reference.update({
        'lastNotificationSentAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      print('[ChatNotificationService] processOutgoingMessage error: $e');
    }
  }

  /// Call when a new incoming message is received (reply from other user).
  /// Only updates the last incoming timestamp – no impact on notifications.
  Future<void> recordIncomingMessage({
    required String chatId,
    required String receiverId,
    required String senderId,
    required DateTime timestamp,
  }) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      await chatRef.update({
        'lastIncomingMessageTimestamp': Timestamp.fromDate(timestamp),
      });
    } catch (e) {
      print('[ChatNotificationService] recordIncomingMessage error: $e');
    }
  }

  Future<void> _sendNewNotification(String chatId, String receiverId, String senderName, String messageText, DateTime now) async {

    // Send push notification
    await _notificationService.sendPushNotification(
      userId: receiverId,
      title: 'New message from $senderName',
      body: messageText,
      data: {
        'type': 'chat_message',
        'chatId': chatId,
      },
    );
  }
}