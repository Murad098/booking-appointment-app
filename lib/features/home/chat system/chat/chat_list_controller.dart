import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat_models.dart';

class ChatListController extends GetxController {
  final chatRooms = <ChatRoom>[].obs;
  final isLoading = true.obs;
  final isDataLoaded = false.obs;
  final onlineStatus = <String, bool>{}.obs;

  // Per-room unread counts keyed by chatId
  final unreadCounts = <String, int>{}.obs;

  // Cache for user/business details (same logic as ChatScreen)
  final Map<String, ChatUser> _userDetailsCache = {};

  // Cache for pending futures to avoid duplicate async calls
  final Map<String, Future<ChatUser>> _futureCache = {};

  // Per-room message stream subscriptions for unread counts
  final Map<String, StreamSubscription<QuerySnapshot>> _unreadSubscriptions = {};

  StreamSubscription<QuerySnapshot>? _chatRoomsSubscription;
  StreamSubscription<QuerySnapshot>? _usersStatusSubscription;
  late final String currentUserId;

  @override
  void onInit() {
    super.onInit();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      _loadAllData();
    }
  }

  @override
  void onClose() {
    _chatRoomsSubscription?.cancel();
    _usersStatusSubscription?.cancel();
    for (final sub in _unreadSubscriptions.values) {
      sub.cancel();
    }
    _unreadSubscriptions.clear();
    super.onClose();
  }

  Future<void> _loadAllData() async {
    isLoading.value = true;
    isDataLoaded.value = false;

    try {
      // Setup listeners first
      await _setupUsersStatusListener();
      await _setupChatRoomsListener();

      // Wait for the first snapshot to arrive (handled inside _setupChatRoomsListener)
    } catch (e) {
      print('Error loading chat list data: $e');
      isLoading.value = false;
      isDataLoaded.value = true; // Show empty state if error
    }
  }

  Future<void> _setupChatRoomsListener() {
    return Future(() {
      _chatRoomsSubscription = FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .listen((snapshot) async {
        final List<ChatRoom> rooms = [];

        // Track active room IDs to clean up stale subscriptions
        final activeRoomIds = snapshot.docs.map((d) => d.id).toSet();
        final staleIds = _unreadSubscriptions.keys.toSet().difference(activeRoomIds);
        for (final staleId in staleIds) {
          _unreadSubscriptions[staleId]?.cancel();
          _unreadSubscriptions.remove(staleId);
          unreadCounts.remove(staleId);
        }

        // Process each room while preserving Firestore order (updatedAt descending)
        if (snapshot.docs.isEmpty) {
          chatRooms.value = [];
          _userDetailsCache.clear();
          _futureCache.clear();
          if (!isDataLoaded.value) {
            isDataLoaded.value = true;
            isLoading.value = false;
          }
          return;
        }

        // First pass: create basic room objects with lastMessage
        final List<ChatRoom?> tempRooms = List.filled(snapshot.docs.length, null);
        final List<String> otherUserIds = [];

        for (int i = 0; i < snapshot.docs.length; i++) {
          final doc = snapshot.docs[i];
          final data = doc.data();
          final room = ChatRoom.fromFirestore(data, doc.id);

          // Setup unread count listener for this room
          _setupUnreadCountListener(doc.id);

          // Get other participant id
          final otherId = room.participants.firstWhere((p) => p != currentUserId);
          otherUserIds.add(otherId);

          final lastMessage = await _getLastMessage(doc.id);
          tempRooms[i] = ChatRoom(
            id: room.id,
            participants: room.participants,
            participantDetails: room.participantDetails,
            lastMessage: lastMessage,
            updatedAt: room.updatedAt,
            unreadCount: room.unreadCount,
          );
        }

        // Second pass: preload ALL other participant details (exactly like ChatScreen)
        // This ensures the loading indicator stays until every user/business is fully fetched.
        final uniqueOtherIds = otherUserIds.toSet();
        await Future.wait(uniqueOtherIds.map((id) => _fetchUserDetails(id)));

        // Now all details are cached – build final room list
        final validRooms = tempRooms.whereType<ChatRoom>().toList();
        chatRooms.value = validRooms;

        // Mark data as fully loaded only after all user details are cached
        if (!isDataLoaded.value) {
          isDataLoaded.value = true;
          isLoading.value = false;
        }
      });
    });
  }

  // Real-time listener for unread message count per chat room
  void _setupUnreadCountListener(String chatId) {
    if (_unreadSubscriptions.containsKey(chatId)) return;

    final sub = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', whereNotIn: ['read'])
        .snapshots()
        .listen((snapshot) {
      unreadCounts[chatId] = snapshot.docs.length;
    });

    _unreadSubscriptions[chatId] = sub;
  }

  Future<ChatMessage?> _getLastMessage(String chatId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ChatMessage.fromFirestore(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
    } catch (e) {
      print('Error getting last message: $e');
    }
    return null;
  }

  Future<void> _setupUsersStatusListener() {
    return Future(() {
      _usersStatusSubscription = FirebaseFirestore.instance
          .collection('users')
          .snapshots()
          .listen((snapshot) {
        for (var doc in snapshot.docs) {
          final isOnline = doc.data()['isOnline'] ?? false;
          onlineStatus[doc.id] = isOnline;
        }
      });
    });
  }

  String getOtherParticipantId(ChatRoom room) {
    return room.participants.firstWhere((p) => p != currentUserId);
  }

  // Role-based user data fetching (same logic as ChatScreen)
  Future<ChatUser> _fetchUserDetails(String userId) async {
    // Return from future cache if already fetching
    if (_futureCache.containsKey(userId)) {
      return _futureCache[userId]!;
    }

    final future = (() async {
      if (_userDetailsCache.containsKey(userId)) {
        return _userDetailsCache[userId]!;
      }

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (!userDoc.exists) {
          final user = ChatUser(
            id: userId,
            name: 'User',
            profileImage: null,
            email: null,
            isOnline: onlineStatus[userId] ?? false,
          );
          _userDetailsCache[userId] = user;
          return user;
        }

        final userRole = userDoc.data()?['role'] as String? ?? '';
        final isOnline = userDoc.data()?['isOnline'] ?? false;

        if (userRole == 'business') {
          final businessDoc = await FirebaseFirestore.instance
              .collection('businesses')
              .doc(userId)
              .get();

          if (businessDoc.exists) {
            final businessData = businessDoc.data();
            if (businessData != null) {
              final chatUser = ChatUser(
                id: userId,
                name: businessData['businessName'] ?? 'Business',
                profileImage: businessData['profileImage'],
                email: businessData['email'],
                isOnline: isOnline,
              );
              _userDetailsCache[userId] = chatUser;
              return chatUser;
            }
          }
        }

        final data = userDoc.data();
        final chatUser = ChatUser(
          id: userId,
          name: data?['name'] ?? 'User',
          profileImage: data?['profileImage'],
          email: data?['email'],
          isOnline: isOnline,
        );
        _userDetailsCache[userId] = chatUser;
        return chatUser;
      } catch (e) {
        print('Error fetching user details for $userId: $e');
        final fallback = ChatUser(
          id: userId,
          name: 'User',
          profileImage: null,
          email: null,
          isOnline: onlineStatus[userId] ?? false,
        );
        _userDetailsCache[userId] = fallback;
        return fallback;
      }
    })();

    _futureCache[userId] = future;
    return future;
  }

  // Synchronous version (now safe because we preload everything before isLoading becomes false)
  ChatUser getOtherParticipant(ChatRoom room) {
    final otherId = getOtherParticipantId(room);
    // This should never be null because we preloaded all users.
    if (_userDetailsCache.containsKey(otherId)) {
      return _userDetailsCache[otherId]!;
    }
    // Fallback (in case something went wrong, but UI will show loading until preload completes)
    return ChatUser(
      id: otherId,
      name: 'Loading...',
      profileImage: null,
      email: null,
      isOnline: onlineStatus[otherId] ?? false,
    );
  }

  // Async version (kept for compatibility, but synchronous version is preferred after preload)
  Future<ChatUser> getOtherParticipantAsync(ChatRoom room) async {
    final otherId = getOtherParticipantId(room);
    return _fetchUserDetails(otherId);
  }

  String formatTimestamp(DateTime timestamp) {
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

  void openChat(ChatRoom room) async {
    final otherUser = await getOtherParticipantAsync(room);
    Get.toNamed('/chat', arguments: {
      'chatId': room.id,
      'userId': otherUser.id,
      'userName': otherUser.name,
      'userProfileImage': otherUser.profileImage,
    });
  }

  void refreshChats() {
    _userDetailsCache.clear();
    _futureCache.clear();
    for (final sub in _unreadSubscriptions.values) {
      sub.cancel();
    }
    _unreadSubscriptions.clear();
    unreadCounts.clear();
    _loadAllData();
  }
}