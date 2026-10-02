// lib/features/chat/chat_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { sending, sent, delivered, read }
enum MessageType { text, image, video, voice, file }

class ChatUser {
  final String id;
  final String name;
  final String? profileImage;
  final String? email;
  final bool isOnline;
  final DateTime? lastSeen;

  ChatUser({
    required this.id,
    required this.name,
    this.profileImage,
    this.email,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatUser.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatUser(
      id: id,
      name: data['name'] ?? '',
      profileImage: data['profileImage'],
      email: data['email'],
      isOnline: data['isOnline'] ?? false,
      lastSeen: data['lastSeen'] != null
          ? (data['lastSeen'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'profileImage': profileImage,
      'email': email,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    };
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final int? duration;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderName;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.type,
    required this.status,
    required this.timestamp,
    this.mediaUrl,
    this.thumbnailUrl,
    this.duration,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderName,
  });

  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatMessage(
      id: id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      type: MessageType.values.firstWhere(
            (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
            (e) => e.toString() == 'MessageStatus.${data['status']}',
        orElse: () => MessageStatus.sent,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mediaUrl: data['mediaUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      duration: data['duration'],
      replyToMessageId: data['replyToMessageId'],
      replyToText: data['replyToText'],
      replyToSenderName: data['replyToSenderName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'replyToMessageId': replyToMessageId,
      'replyToText': replyToText,
      'replyToSenderName': replyToSenderName,
    };
  }
}

class ChatRoom {
  final String id;
  final List<String> participants;
  final Map<String, dynamic> participantDetails;
  final ChatMessage? lastMessage;
  final DateTime updatedAt;
  final int? unreadCount;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.participantDetails,
    this.lastMessage,
    required this.updatedAt,
    this.unreadCount,
  });

  factory ChatRoom.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatRoom(
      id: id,
      participants: List<String>.from(data['participants'] ?? []),
      participantDetails: Map<String, dynamic>.from(data['participantDetails'] ?? {}),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data['unreadCount'],
    );
  }
}