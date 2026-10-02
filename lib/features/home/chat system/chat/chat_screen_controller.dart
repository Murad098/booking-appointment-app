import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/custom_snackbar.dart';
import '../../../../services/chat_supabase_storage_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/chat_notification_service.dart';
import '../chat_models.dart';

class ChatScreenController extends GetxController {
  final messages = <ChatMessage>[].obs;
  final isLoading = true.obs;
  final isDataLoaded = false.obs;
  final isRecording = false.obs;

  final recordingDuration = 0.obs;
  final waveformBars = RxList<double>([]);

  String? _currentRecordingPath;

  final otherUserName = ''.obs;
  final isUserOnline = false.obs;
  final otherUserProfileImage = ''.obs;
  final messageText = ''.obs;

  final replyingMessage = Rx<ChatMessage?>(null);

  final playingVoiceMessageId = ''.obs;
  final voicePlaying = false.obs;
  final voiceProgress = 0.0.obs;
  final voiceDuration = 0.obs;

  final uploadProgress = <String, int>{}.obs;

  final firstUnreadIndex = Rx<int?>(-1);
  final totalUnreadMessages = 0.obs;

  // For reverse ListView we still need to know where the unread divider goes.
  // This will be the reversed index of the first unread message.
  final firstUnreadReversedIndex = Rx<int?>(-1);

  final dateHeaders = <String>[].obs;
  // For reverse, we need a list of dates in reverse order as well.
  final reversedDateHeaders = <String>[].obs;

  bool _initialDataReceived = false;
  Completer<void>? _firstSnapshotCompleter;

  late String chatId;
  late String otherUserId;
  late String currentUserId;
  late String currentUserName;

  Timer? _recordingTimer;
  Timer? _waveformTimer;
  AudioRecorder? _audioRecorder;
  AudioPlayer? _audioPlayer;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController(); // Simple ScrollController
  final TextEditingController captionController = TextEditingController();

  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  StreamSubscription<DocumentSnapshot>? _userStatusSubscription;
  StreamSubscription<QuerySnapshot>? _deliveryStatusSubscription;

  final Set<String> _processedIncomingIds = {};

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      chatId = args['chatId'] ?? '';
      otherUserId = args['userId'] ?? '';
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      _loadAllData();
    }

    _initAudioRecorder();
    _initAudioPlayer();
  }

  @override
  void onClose() {
    _markNewlyArrivedMessagesAsRead();

    _messagesSubscription?.cancel();
    _userStatusSubscription?.cancel();
    _deliveryStatusSubscription?.cancel();
    _recordingTimer?.cancel();
    _waveformTimer?.cancel();
    _audioRecorder?.dispose();
    _audioPlayer?.dispose();
    messageController.dispose();
    scrollController.dispose();
    captionController.dispose();
    super.onClose();
  }

  bool _isStatusForward(MessageStatus? oldStatus, MessageStatus newStatus) {
    if (oldStatus == null) return true;
    const order = {
      MessageStatus.sending: 0,
      MessageStatus.sent: 1,
      MessageStatus.delivered: 2,
      MessageStatus.read: 3,
    };
    return (order[newStatus] ?? 0) >= (order[oldStatus] ?? 0);
  }

  Future<bool> _checkAndRequestPermission(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted) return true;

    final requestStatus = await permission.request();
    if (requestStatus.isGranted) {
      return true;
    } else if (requestStatus.isPermanentlyDenied) {
      AppSnackbar.error('Permission permanently denied. Please grant it in app settings.');
      await openAppSettings();
      return false;
    } else {
      AppSnackbar.error('Permission required to proceed.');
      return false;
    }
  }

  // ==================== VOICE RECORDING ====================
  Future<void> startVoiceRecording() async {
    final hasMic = await _checkAndRequestPermission(Permission.microphone);
    if (!hasMic) return;

    try {
      final hasPermission = await _audioRecorder?.hasPermission() ?? false;
      if (!hasPermission) {
        print('No permission to record audio');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final recordingPath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = recordingPath;

      waveformBars.clear();
      recordingDuration.value = 0;

      await _audioRecorder?.start(const RecordConfig(), path: recordingPath);
      isRecording.value = true;

      _startDurationTimer();
      _startWaveformCapture();
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> stopAndSendVoiceRecording() async {
    if (!isRecording.value) return;

    isRecording.value = false;
    _stopTimers();

    String? recordedPath;
    try {
      recordedPath = await _audioRecorder?.stop();
    } catch (e) {
      print('Error stopping recording: $e');
    }

    if (recordedPath == null || recordedPath.isEmpty) {
      _cleanupTempFile(_currentRecordingPath);
      _currentRecordingPath = null;
      return;
    }

    final file = File(recordedPath);
    if (!await file.exists()) {
      _cleanupTempFile(_currentRecordingPath);
      _currentRecordingPath = null;
      return;
    }

    final totalDuration = recordingDuration.value;
    await _sendVoiceMessageWithFile(file, totalDuration);

    _cleanupTempFile(_currentRecordingPath);
    _currentRecordingPath = null;
    waveformBars.clear();
    recordingDuration.value = 0;
  }

  void cancelRecording() {
    _stopTimers();
    _audioRecorder?.cancel();
    _cleanupTempFile(_currentRecordingPath);
    _currentRecordingPath = null;
    isRecording.value = false;
    waveformBars.clear();
    recordingDuration.value = 0;
  }

  Future<void> _sendVoiceMessageWithFile(File file, int duration) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    final sendingMessage = ChatMessage(
      id: messageId,
      chatId: chatId,
      senderId: currentUserId,
      receiverId: otherUserId,
      text: '🎤 Voice message',
      type: MessageType.voice,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
      mediaUrl: null,
      duration: duration,
    );

    await _saveMessageToFirestore(sendingMessage);

    String? voiceUrl;
    try {
      voiceUrl = await ChatSupabaseStorageService().uploadVoiceMessage(file);
    } catch (e) {
      print('Upload error: $e');
    }

    if (voiceUrl == null) {
      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);
      await messageRef.delete();
      AppSnackbar.error('Failed to send voice message');
      return;
    }

    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await messageRef.update({'mediaUrl': voiceUrl});
  }

  void _cleanupTempFile(String? path) {
    if (path != null) {
      final f = File(path);
      f.exists().then((exists) {
        if (exists) f.delete();
      });
    }
  }

  Future<void> playVoiceMessage(String messageId, String voiceUrl) async {
    if (playingVoiceMessageId.value == messageId && voicePlaying.value) {
      await _audioPlayer?.pause();
      voicePlaying.value = false;
    } else if (playingVoiceMessageId.value == messageId && !voicePlaying.value) {
      await _audioPlayer?.resume();
      voicePlaying.value = true;
    } else {
      playingVoiceMessageId.value = messageId;
      voiceProgress.value = 0.0;
      voiceDuration.value = 0;
      await _audioPlayer?.play(UrlSource(voiceUrl));
      voicePlaying.value = true;
    }
  }

  Future<void> deleteMessage(ChatMessage message) async {
    if (message.text == "This message has been deleted") return;

    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id);

    await messageRef.update({
      'text': 'This message has been deleted',
      'type': MessageType.text.index,
      'mediaUrl': null,
      'duration': null,
      'thumbnailUrl': null,
      'deleted': true,
    });
  }

  void setReplyingMessage(ChatMessage message) {
    replyingMessage.value = message;
  }

  void clearReply() {
    replyingMessage.value = null;
  }

  void _startDurationTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isRecording.value) {
        recordingDuration.value++;
      } else {
        timer.cancel();
      }
    });
  }

  void _stopTimers() {
    _recordingTimer?.cancel();
    _waveformTimer?.cancel();
  }

  void _startWaveformCapture() {
    _waveformTimer?.cancel();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!isRecording.value) {
        timer.cancel();
        return;
      }

      final ms = DateTime.now().millisecondsSinceEpoch;
      final a = (ms % 317) / 317.0;
      final b = (ms % 193) / 193.0;
      final c = (ms % 97) / 97.0;
      final amplitude = (a * 0.5 + b * 0.3 + c * 0.2);
      final bar = (0.15 + 0.85 * amplitude).clamp(0.05, 1.0);

      waveformBars.add(bar);
      if (waveformBars.length > 80) {
        waveformBars.removeAt(0);
      }
    });
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();

    _audioPlayer?.onPositionChanged.listen((position) {
      if (voiceDuration.value > 0) {
        voiceProgress.value = position.inMilliseconds / voiceDuration.value;
      }
    });

    _audioPlayer?.onDurationChanged.listen((duration) {
      voiceDuration.value = duration.inMilliseconds;
    });

    _audioPlayer?.onPlayerComplete.listen((_) {
      playingVoiceMessageId.value = '';
      voicePlaying.value = false;
      voiceProgress.value = 0.0;
      voiceDuration.value = 0;
    });
  }

  Future<void> _initAudioRecorder() async {
    _audioRecorder = AudioRecorder();
    try {
      final hasPermission = await _audioRecorder?.hasPermission() ?? false;
      if (!hasPermission) print('No permission to record audio');
    } catch (e) {
      print('Error initializing audio recorder: $e');
    }
  }

  // ==================== DATA LOADING ====================
  Future<void> _loadAllData() async {
    isLoading.value = true;
    isDataLoaded.value = false;
    _firstSnapshotCompleter = Completer<void>();

    try {
      await Future.wait([
        _fetchCurrentUserData(),
        _fetchOtherUserData(),
        _setupMessagesListener(),
      ]);

      await Future.any([
        _firstSnapshotCompleter!.future,
        Future.delayed(const Duration(seconds: 5)),
      ]);

      _firstSnapshotCompleter = null;
    } catch (e) {
      print('Error loading chat data: $e');
    } finally {
      isLoading.value = false;
      isDataLoaded.value = true;
    }
  }

  Future<void> _fetchCurrentUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          currentUserName = data['name'] ?? 'User';
        }
      }
    } catch (e) {
      print('Error fetching current user data: $e');
    }
  }

  Future<void> _fetchOtherUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();
      if (!userDoc.exists) return;

      final userRole = userDoc.data()?['role'] as String? ?? '';
      final isOnline = userDoc.data()?['isOnline'] ?? false;
      isUserOnline.value = isOnline;

      if (userRole == 'business') {
        final businessDoc = await FirebaseFirestore.instance
            .collection('businesses')
            .doc(otherUserId)
            .get();
        if (businessDoc.exists) {
          final businessData = businessDoc.data();
          if (businessData != null) {
            otherUserName.value = businessData['businessName'] ?? 'Business';
            otherUserProfileImage.value = businessData['profileImage'] ?? '';
          }
        }
      } else {
        final data = userDoc.data();
        if (data != null) {
          otherUserName.value = data['name'] ?? 'User';
          otherUserProfileImage.value = data['profileImage'] ?? '';
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void _setupUserStatusListener() {
    _userStatusSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(otherUserId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          isUserOnline.value = data['isOnline'] ?? false;
          if (isUserOnline.value) {
            _updateDeliveryStatusForSentMessages();
          }
        }
      }
    });
  }

  Future<void> _updateDeliveryStatusForSentMessages() async {
    final batch = FirebaseFirestore.instance.batch();
    final sentMessages = messages
        .where((m) => m.receiverId == otherUserId && m.status == MessageStatus.sent)
        .toList();
    for (var message in sentMessages) {
      if (message.status == MessageStatus.sent) {
        final messageRef = FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(message.id);
        batch.update(messageRef, {'status': 'delivered'});

        final index = messages.indexWhere((m) => m.id == message.id);
        if (index != -1 && messages[index].status == MessageStatus.sent) {
          final updatedMessage = messages[index];
          messages[index] = ChatMessage(
            id: updatedMessage.id,
            chatId: updatedMessage.chatId,
            senderId: updatedMessage.senderId,
            receiverId: updatedMessage.receiverId,
            text: updatedMessage.text,
            type: updatedMessage.type,
            status: MessageStatus.delivered,
            timestamp: updatedMessage.timestamp,
            mediaUrl: updatedMessage.mediaUrl,
            duration: updatedMessage.duration,
          );
        }
      }
    }
    if (sentMessages.isNotEmpty) {
      await batch.commit();
      messages.refresh();
    }
  }

  void _setupDeliveryStatusListener() {
    _deliveryStatusSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'sent')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final messageId = doc.id;
        final messageRef = FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId);
        messageRef.update({'status': 'delivered'});
      }
    });
  }

  String _getDateLabel(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      final difference = now.difference(timestamp).inDays;
      if (difference < 7) {
        const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        return weekdays[timestamp.weekday - 1];
      } else {
        return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
      }
    }
  }

  // ==================== REVERSE LISTVIEW SUPPORT ====================
  // Builds a list of display items (date headers + messages + unread divider) in REVERSE order.
  List<dynamic> getDisplayItems() {
    List<dynamic> items = [];

    // Build forward list first (from oldest to newest)
    List<dynamic> forwardItems = [];
    String lastDate = '';
    bool dividerAdded = false;

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final dateLabel = _getDateLabel(msg.timestamp);

      // Date header
      if (dateLabel != lastDate) {
        forwardItems.add(dateLabel);
        lastDate = dateLabel;
      }

      // Unread divider (only before the first unread message)
      if (!dividerAdded && totalUnreadMessages.value > 0 && i == firstUnreadIndex.value) {
        forwardItems.add('__unread_divider__');
        dividerAdded = true;
      }

      // Message
      forwardItems.add(msg);
    }

    // Reverse the list (newest first, which is what we want for reverse ListView)
    items = forwardItems.reversed.toList();

    // Also store reversed date headers for potential use (optional)
    reversedDateHeaders.assignAll(
      forwardItems.whereType<String>().where((e) => e != '__unread_divider__').toList().reversed,
    );

    // Compute reversed index of unread divider
    int reversedIdx = items.indexWhere((e) => e == '__unread_divider__');
    firstUnreadReversedIndex.value = reversedIdx;

    return items;
  }

  Future<void> _setupMessagesListener() {
    // Safety timeout
    Future.delayed(const Duration(seconds: 5), () {
      if (!_initialDataReceived) {
        print("⚠️ No Firestore snapshot after 5s – forcing data load");
        if (_firstSnapshotCompleter != null && !_firstSnapshotCompleter!.isCompleted) {
          _firstSnapshotCompleter!.complete();
        }
        isDataLoaded.value = true;
        isLoading.value = false;
      }
    });

    return Future(() {
      _messagesSubscription = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen((snapshot) {
        final msgs = snapshot.docs.map((doc) {
          return ChatMessage.fromFirestore(doc.data(), doc.id);
        }).toList();

        for (final msg in msgs) {
          if (msg.receiverId == currentUserId && !_processedIncomingIds.contains(msg.id)) {
            _processedIncomingIds.add(msg.id);
            ChatNotificationService().recordIncomingMessage(
              chatId: chatId,
              receiverId: currentUserId,
              senderId: msg.senderId,
              timestamp: msg.timestamp,
            );
          }
        }

        int firstUnread = -1;
        int totalUnread = 0;
        for (int i = 0; i < msgs.length; i++) {
          if (msgs[i].receiverId == currentUserId && msgs[i].status != MessageStatus.read) {
            if (firstUnread == -1) firstUnread = i;
            totalUnread++;
          }
        }

        messages.value = msgs;
        firstUnreadIndex.value = firstUnread;
        totalUnreadMessages.value = totalUnread;

        // Force UI rebuild (list will be built via getDisplayItems)
        // No scroll logic needed because reverse ListView keeps bottom visible.

        if (!_initialDataReceived) {
          _initialDataReceived = true;

          // ✅ REMOVED: auto-mark-unread on open – now messages stay unread until user leaves the screen.

          if (_firstSnapshotCompleter != null && !_firstSnapshotCompleter!.isCompleted) {
            _firstSnapshotCompleter!.complete();
          }
        }
      });
    });
  }

  Future<void> _markNewlyArrivedMessagesAsRead() async {
    final batch = FirebaseFirestore.instance.batch();
    final unreadMessages = messages
        .where((m) => m.receiverId == currentUserId && m.status != MessageStatus.read)
        .toList();
    for (var message in unreadMessages) {
      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(message.id);
      batch.update(messageRef, {'status': 'read'});
    }
    if (unreadMessages.isNotEmpty) {
      await batch.commit();
      for (var msg in unreadMessages) {
        final idx = messages.indexWhere((m) => m.id == msg.id);
        if (idx != -1 && _isStatusForward(messages[idx].status, MessageStatus.read)) {
          messages[idx] = ChatMessage(
            id: msg.id,
            chatId: msg.chatId,
            senderId: msg.senderId,
            receiverId: msg.receiverId,
            text: msg.text,
            type: msg.type,
            status: MessageStatus.read,
            timestamp: msg.timestamp,
            mediaUrl: msg.mediaUrl,
            duration: msg.duration,
            replyToMessageId: msg.replyToMessageId,
            replyToText: msg.replyToText,
            replyToSenderName: msg.replyToSenderName,
          );
        }
      }
      messages.refresh();
    }
  }

  Future<void> _markAllUnreadAsRead(List<ChatMessage> msgs) async {
    final batch = FirebaseFirestore.instance.batch();
    final unreadMessages = msgs
        .where((m) => m.receiverId == currentUserId && m.status != MessageStatus.read)
        .toList();
    for (var message in unreadMessages) {
      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(message.id);
      batch.update(messageRef, {'status': 'read'});
    }
    if (unreadMessages.isNotEmpty) {
      await batch.commit();
    }
  }

  Future<void> markMessagesAsReadOnLeave() async {
    await _markNewlyArrivedMessagesAsRead();
  }

  // ==================== SENDING MESSAGES ====================
  Future<void> sendTextMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    messageController.clear();
    messageText.value = '';

    String? replyToId;
    String? replyToText;
    String? replyToSenderName;
    if (replyingMessage.value != null) {
      replyToId = replyingMessage.value!.id;
      replyToText = replyingMessage.value!.text;
      replyToSenderName = replyingMessage.value!.senderId == currentUserId
          ? 'You'
          : otherUserName.value;
    }
    clearReply();

    await _sendMessage(
      text,
      MessageType.text,
      replyToId: replyToId,
      replyToText: replyToText,
      replyToSenderName: replyToSenderName,
    );
  }

  Future<void> captureCamera() async {
    final hasCamera = await _checkAndRequestPermission(Permission.camera);
    if (!hasCamera) return;

    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      await _sendMediaFile(File(photo.path), MessageType.image);
    }
  }

  Future<void> sendImageMessage() async {
    final hasStorage = await _checkAndRequestPermission(Permission.storage);
    if (!hasStorage) return;

    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      for (final xfile in pickedFiles) {
        await _sendMediaFile(File(xfile.path), MessageType.image);
      }
    }
  }

  Future<void> sendVideoMessage() async {
    final hasStorage = await _checkAndRequestPermission(Permission.storage);
    if (!hasStorage) return;

    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultipleMedia();
    if (pickedFiles.isNotEmpty) {
      final videoFiles = pickedFiles
          .where((xfile) =>
      xfile.path.toLowerCase().endsWith('.mp4') ||
          xfile.path.toLowerCase().endsWith('.mov') ||
          xfile.path.toLowerCase().endsWith('.avi'))
          .toList();
      for (final xfile in videoFiles) {
        await _sendMediaFile(File(xfile.path), MessageType.video);
      }
    }
  }

  Future<void> sendFileMessage() async {
    final hasStorage = await _checkAndRequestPermission(Permission.storage);
    if (!hasStorage) return;

    FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'],
    );
    if (result != null && result.files.isNotEmpty) {
      for (final picked in result.files) {
        if (picked.path != null) {
          await _sendMediaFile(File(picked.path!), MessageType.file);
        }
      }
    }
  }

  Future<void> _sendMediaFile(File file, MessageType type) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName = file.path.split('/').last;

    String displayText = '';
    switch (type) {
      case MessageType.image:
        displayText = '📷 Image';
        break;
      case MessageType.video:
        displayText = '🎥 Video';
        break;
      case MessageType.file:
        displayText = fileName;
        break;
      default:
        displayText = 'Media';
    }

    final sendingMessage = ChatMessage(
      id: messageId,
      chatId: chatId,
      senderId: currentUserId,
      receiverId: otherUserId,
      text: displayText,
      type: type,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
      mediaUrl: null,
      duration: null,
    );

    await _saveMessageToFirestore(sendingMessage);

    for (int i = 0; i <= 100; i += 10) {
      uploadProgress[messageId] = i;
      await Future.delayed(const Duration(milliseconds: 50));
    }

    String? mediaUrl;
    try {
      if (type == MessageType.image) {
        mediaUrl = await ChatSupabaseStorageService().uploadChatImage(file);
      } else if (type == MessageType.video) {
        mediaUrl = await ChatSupabaseStorageService().uploadChatVideo(file);
      } else {
        mediaUrl = await ChatSupabaseStorageService().uploadChatFile(file);
      }
    } catch (e) {
      print('Upload error: $e');
    }

    if (mediaUrl == null) {
      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);
      await messageRef.delete();
      uploadProgress.remove(messageId);
      AppSnackbar.error('Failed to send $type');
      return;
    }

    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await messageRef.update({'mediaUrl': mediaUrl});
    uploadProgress.remove(messageId);
  }

  Future<void> _sendMessage(
      String text,
      MessageType type, {
        String? mediaUrl,
        int? duration,
        String? replyToId,
        String? replyToText,
        String? replyToSenderName,
      }) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final message = ChatMessage(
      id: messageId,
      chatId: chatId,
      senderId: currentUserId,
      receiverId: otherUserId,
      text: text,
      type: type,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
      mediaUrl: mediaUrl,
      duration: duration,
      replyToMessageId: replyToId,
      replyToText: replyToText,
      replyToSenderName: replyToSenderName,
    );
    messages.add(message);
    // With reverse ListView, the list automatically shows the new message at bottom.
    await _saveMessageToFirestore(message);

    await ChatNotificationService().processOutgoingMessage(
      chatId: chatId,
      senderId: currentUserId,
      receiverId: otherUserId,
      messageText: text,
      senderName: currentUserName,
      messageTimestamp: message.timestamp,
    );
  }

  Future<void> _saveMessageToFirestore(ChatMessage message) async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final messagesRef = chatRef.collection('messages').doc(message.id);
    final batch = FirebaseFirestore.instance.batch();
    batch.set(messagesRef, message.toMap());
    batch.set(chatRef, {
      'lastMessage': message.text,
      'lastMessageTimestamp': Timestamp.fromDate(message.timestamp),
      'updatedAt': Timestamp.fromDate(message.timestamp),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  String getMessageStatusText(ChatMessage message, int index) {
    // With reverse list, we need to know if this is the latest outgoing message.
    // The latest outgoing is the first message in the reversed list that belongs to me.
    // Simpler: find the newest message in the original order and compare.
    final latestOutgoing = messages.lastWhere(
          (m) => m.senderId == currentUserId,
      orElse: () => ChatMessage(
        id: '',
        chatId: '',
        senderId: '',
        receiverId: '',
        text: '',
        type: MessageType.text,
        status: MessageStatus.sent,
        timestamp: DateTime.now(),
      ),
    );
    if (message.id == latestOutgoing.id && message.senderId == currentUserId) {
      switch (message.status) {
        case MessageStatus.sending:
          return 'Sending';
        case MessageStatus.sent:
          return 'Sent';
        case MessageStatus.delivered:
          return 'Delivered';
        case MessageStatus.read:
          return 'Read';
        default:
          return '';
      }
    }
    return '';
  }

  void updateMessageStatus(String messageId, MessageStatus status) {
    final message = messages.firstWhereOrNull((m) => m.id == messageId);
    if (message != null && _isStatusForward(message.status, status)) {
      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);
      messageRef.update({'status': status.toString().split('.').last});
    }
  }

  String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  bool isMyMessage(ChatMessage message) {
    return message.senderId == currentUserId;
  }
}