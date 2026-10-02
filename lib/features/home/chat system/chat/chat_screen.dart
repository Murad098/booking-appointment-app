import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/custom_snackbar.dart';
import '../chat_models.dart';
import 'chat_screen_controller.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatScreenController());

    return Obx(() {
      if (controller.isLoading.value || !controller.isDataLoaded.value) {
        return const Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
            ),
          ),
        );
      }

      return WillPopScope(
        onWillPop: () async {
          controller.markMessagesAsReadOnLeave();
          return true;
        },
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                controller.markMessagesAsReadOnLeave();
                Get.back();
              },
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    image: controller.otherUserProfileImage.value.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(controller.otherUserProfileImage.value),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: controller.otherUserProfileImage.value.isEmpty
                      ? const Icon(Icons.person, size: 20, color: AppColors.primaryPurple)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.otherUserName.value,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.isUserOnline.value ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: controller.isUserOnline.value
                              ? AppColors.statusSuccess
                              : AppColors.textPlaceholder,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.black),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Obx(() {
                  final displayItems = controller.getDisplayItems();
                  return ListView.builder(
                    reverse: true,
                    controller: controller.scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: displayItems.length,
                    itemBuilder: (context, index) {
                      final item = displayItems[index];
                      if (item is String) {
                        if (item == '__unread_divider__') {
                          return _buildNewMessagesDivider(controller); // ✅ pass controller
                        }
                        return _buildDateLabel(item);
                      } else if (item is ChatMessage) {
                        final message = item;
                        final isMe = controller.isMyMessage(message);
                        final statusText = controller.getMessageStatusText(message, controller.messages.indexOf(message));
                        return _buildMessageBubble(
                          message: message,
                          isMe: isMe,
                          statusText: statusText,
                          controller: controller,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                }),
              ),
              Obx(() {
                if (controller.isRecording.value) {
                  return _buildRecordingPanel(controller);
                }
                return _buildMessageInput(controller);
              }),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDateLabel(String label) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  // ✅ NEW WhatsApp‑style unread divider (green pill, shows count)
  Widget _buildNewMessagesDivider(ChatScreenController controller) {
    final count = controller.totalUnreadMessages.value;
    if (count <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF25D366), // WhatsApp green
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '$count unread message${count > 1 ? 's' : ''}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required ChatMessage message,
    required bool isMe,
    required String statusText,
    required ChatScreenController controller,
  }) {
    return GestureDetector(
      onLongPress: () {
        _showMessageActionSheet(message, isMe, controller);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.replyToText != null && message.replyToText!.isNotEmpty)
                Container(
                  constraints: BoxConstraints(maxWidth: Get.width * 0.78),
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isMe ? Colors.white : AppColors.primaryPurple).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(
                        color: isMe ? AppColors.primaryPurple : Colors.grey,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.replyToSenderName ?? 'Replying to...',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isMe ? AppColors.primaryPurple : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message.replyToText!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe ? Colors.black87 : Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                constraints: BoxConstraints(maxWidth: Get.width * 0.78),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primaryPurple : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.type == MessageType.text)
                      _buildTextMessage(message, isMe),
                    if (message.type == MessageType.image)
                      _buildImageMessage(message, isMe, controller),
                    if (message.type == MessageType.video)
                      _buildVideoMessage(message, isMe, controller),
                    if (message.type == MessageType.voice)
                      _buildVoiceMessage(message, isMe, controller),
                    if (message.type == MessageType.file)
                      _buildFileMessage(message, isMe, controller),
                  ],
                ),
              ),
              if (statusText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 4),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textPlaceholder,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextMessage(ChatMessage message, bool isMe) {
    final text = message.text;
    final hasLink = text.contains(RegExp(r'https?://[^\s]+'));
    final isDeleted = text == "This message has been deleted";

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: isDeleted
              ? Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: isMe
                  ? Colors.white.withOpacity(0.5)
                  : Colors.grey.shade500,
            ),
          )
              : hasLink
              ? GestureDetector(
            onTap: () async {
              final uri = Uri.tryParse(text);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isMe ? Colors.white : AppColors.textHeadline,
                fontWeight: FontWeight.w400,
              ),
            ),
          )
              : Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: isMe ? Colors.white : AppColors.textHeadline,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _formatTime(message.timestamp),
          style: TextStyle(
            fontSize: 10,
            color: isMe ? Colors.white.withOpacity(0.7) : AppColors.textPlaceholder,
          ),
        ),
      ],
    );
  }

  Widget _buildImageMessage(ChatMessage message, bool isMe, ChatScreenController controller) {
    final isSending = message.status == MessageStatus.sending && isMe;
    final progress = controller.uploadProgress[message.id] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 180,
                width: 200,
                color: Colors.grey[800],
                child: isSending
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        value: progress / 100,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$progress%',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                )
                    : Image.network(
                  message.mediaUrl ?? '',
                  height: 180,
                  width: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      width: 200,
                      color: AppColors.grey200,
                      child: const Icon(Icons.broken_image, size: 40, color: AppColors.textPlaceholder),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _formatTime(message.timestamp),
          style: const TextStyle(fontSize: 10, color: AppColors.textPlaceholder),
        ),
      ],
    );
  }

  Widget _buildVideoMessage(ChatMessage message, bool isMe, ChatScreenController controller) {
    final isSending = message.status == MessageStatus.sending && isMe;
    final progress = controller.uploadProgress[message.id] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 180,
                width: 200,
                color: Colors.grey[800],
                child: isSending
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        value: progress / 100,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$progress%',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                )
                    : GestureDetector(
                  onTap: () {
                    if (message.mediaUrl != null) {
                      _showVideoPlayer(message.mediaUrl!);
                    }
                  },
                  child: FutureBuilder<Widget>(
                    future: _buildVideoThumbnail(message.mediaUrl),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return const Center(
                          child: Icon(Icons.play_circle_filled, size: 50, color: Colors.white),
                        );
                      }
                      return snapshot.data!;
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _formatTime(message.timestamp),
          style: const TextStyle(fontSize: 10, color: AppColors.textPlaceholder),
        ),
      ],
    );
  }

  Future<Widget> _buildVideoThumbnail(String? videoUrl) async {
    if (videoUrl == null || videoUrl.isEmpty) {
      return const Icon(Icons.play_circle_filled, size: 50, color: Colors.white);
    }
    try {
      final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: (await Directory.systemTemp.createTemp()).path,
        imageFormat: ImageFormat.JPEG,
        quality: 80,
      );
      if (thumbnailPath != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(thumbnailPath),
            height: 180,
            width: 200,
            fit: BoxFit.cover,
          ),
        );
      } else {
        return const Icon(Icons.play_circle_filled, size: 50, color: Colors.white);
      }
    } catch (e) {
      return const Icon(Icons.play_circle_filled, size: 50, color: Colors.white);
    }
  }

  Widget _buildFileMessage(ChatMessage message, bool isMe, ChatScreenController controller) {
    final isSending = message.status == MessageStatus.sending && isMe;
    final progress = controller.uploadProgress[message.id] ?? 0;

    return GestureDetector(
      onTap: () async {
        if (message.mediaUrl != null) {
          final uri = Uri.parse(message.mediaUrl!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            AppSnackbar.error('Cannot open file');
          }
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(
            Icons.insert_drive_file,
            color: isMe ? Colors.white.withOpacity(0.9) : AppColors.primaryPurple,
            size: 28,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: isMe ? Colors.white : AppColors.textHeadline,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (isSending)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 20,
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$progress%',
                          style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _formatTime(message.timestamp),
            style: TextStyle(
              fontSize: 10,
              color: isMe ? Colors.white.withOpacity(0.7) : AppColors.textPlaceholder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceMessage(ChatMessage message, bool isMe, ChatScreenController controller) {
    return Obx(() {
      final isPlaying = controller.playingVoiceMessageId.value == message.id &&
          controller.voicePlaying.value;
      final progress = controller.playingVoiceMessageId.value == message.id
          ? controller.voiceProgress.value
          : 0.0;
      final isSending = message.status == MessageStatus.sending && isMe;

      final dummyBars = _getDummyWaveformBars(message.id);

      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isSending)
            SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isMe ? Colors.white : AppColors.primaryPurple,
                    ),
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => controller.playVoiceMessage(message.id, message.mediaUrl!),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.primaryPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: isMe ? Colors.white : AppColors.primaryPurple,
                  size: 20,
                ),
              ),
            ),
          const SizedBox(width: 10),
          SizedBox(
            width: 140,
            height: 38,
            child: CustomPaint(
              painter: _VoiceWaveformPainter(
                bars: dummyBars,
                progress: progress,
                activeColor: isMe ? Colors.white : AppColors.primaryPurple,
                inactiveColor: isMe
                    ? Colors.white.withOpacity(0.4)
                    : AppColors.primaryPurple.withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            controller.formatDuration(message.duration ?? 0),
            style: TextStyle(
              fontSize: 11,
              color: isMe ? Colors.white.withOpacity(0.7) : AppColors.textPlaceholder,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _formatTime(message.timestamp),
            style: TextStyle(
              fontSize: 10,
              color: isMe ? Colors.white.withOpacity(0.7) : AppColors.textPlaceholder,
            ),
          ),
        ],
      );
    });
  }

  List<double> _getDummyWaveformBars(String messageId) {
    const int barCount = 30;
    final random = math.Random(messageId.hashCode);
    return List.generate(barCount, (index) => 0.3 + random.nextDouble() * 0.7);
  }

  void _showMessageActionSheet(ChatMessage message, bool isMe, ChatScreenController controller) {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply, color: AppColors.primaryPurple),
                title: const Text('Reply', style: TextStyle(color: AppColors.textHeadline)),
                onTap: () {
                  Get.back();
                  controller.setReplyingMessage(message);
                },
              ),
              if (isMe && message.text != "This message has been deleted")
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Get.back();
                    _confirmDelete(message, controller);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(ChatMessage message, ChatScreenController controller) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete message'),
        content: const Text('Do you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await controller.deleteMessage(message);
    }
  }

  Widget _buildMessageInput(ChatScreenController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Obx(() {
            final reply = controller.replyingMessage.value;
            if (reply == null) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to ${controller.isMyMessage(reply) ? "you" : controller.otherUserName.value}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reply.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.textHeadline),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: controller.clearReply,
                  ),
                ],
              ),
            );
          }),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.primaryPurple, width: 1),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file, color: AppColors.primaryPurple, size: 22),
                        onPressed: () => _showMediaOptions(controller),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller.messageController,
                          decoration: const InputDecoration(
                            hintText: 'Message...',
                            hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 15),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          style: const TextStyle(color: AppColors.textHeadline, fontSize: 15),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            if (controller.messageController.text.trim().isNotEmpty) {
                              controller.sendTextMessage();
                            }
                          },
                          onChanged: (value) => controller.messageText.value = value,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt, color: AppColors.primaryPurple, size: 22),
                        onPressed: () => controller.captureCamera(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(() {
                if (controller.messageText.value.isNotEmpty) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primaryPurple,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: () => controller.sendTextMessage(),
                      padding: const EdgeInsets.all(10),
                    ),
                  );
                } else {
                  return GestureDetector(
                    onTap: () => controller.startVoiceRecording(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        Icons.mic,
                        color: AppColors.primaryPurple,
                        size: 22,
                      ),
                    ),
                  );
                }
              }),
            ],
          ),
        ],
      ),
    );
  }

  void _showMediaOptions(ChatScreenController controller) {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryPurple),
                title: const Text('Camera', style: TextStyle(color: AppColors.textHeadline)),
                onTap: () {
                  Get.back();
                  controller.captureCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: AppColors.primaryPurple),
                title: const Text('Gallery', style: TextStyle(color: AppColors.textHeadline)),
                onTap: () {
                  Get.back();
                  controller.sendImageMessage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: AppColors.primaryPurple),
                title: const Text('Video', style: TextStyle(color: AppColors.textHeadline)),
                onTap: () {
                  Get.back();
                  controller.sendVideoMessage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file, color: AppColors.primaryPurple),
                title: const Text('Document', style: TextStyle(color: AppColors.textHeadline)),
                onTap: () {
                  Get.back();
                  controller.sendFileMessage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordingPanel(ChatScreenController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: Obx(() {
                    final bars = List<double>.from(controller.waveformBars);
                    return CustomPaint(
                      painter: _WaveformPainter(
                        bars: bars,
                        progress: 1.0,
                        activeColor: AppColors.primaryPurple,
                        inactiveColor: AppColors.primaryPurple.withOpacity(0.2),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Obx(() => Text(
                controller.formatDuration(controller.recordingDuration.value),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircleButton(
                onTap: () => controller.cancelRecording(),
                size: 42,
                bgColor: Colors.grey.shade100,
                child: Icon(Icons.delete_outline, color: Colors.red, size: 22),
              ),
              _buildCircleButton(
                onTap: () => controller.stopAndSendVoiceRecording(),
                size: 50,
                bgColor: const Color(0xFF00BFA5),
                child: const Icon(Icons.send, color: Colors.white, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required VoidCallback onTap,
    required double size,
    required Color bgColor,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.95),
            ),
            child: Center(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _showVideoPlayer(String videoUrl) {
    Get.to(() => VideoPlayerScreen(videoUrl: videoUrl));
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller.initialize().then((_) {
      setState(() {
        _isInitialized = true;
      });
      _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying ? _controller.pause() : _controller.play();
          });
        },
        child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
      )
          : null,
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> bars;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  const _WaveformPainter({
    required this.bars,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    const barWidth = 3.0;
    const barGap = 2.5;
    const minBarHeight = 4.0;
    const unitWidth = barWidth + barGap;

    final maxVisible = (size.width / unitWidth).floor();
    final displayBars = bars.length > maxVisible ? bars.sublist(bars.length - maxVisible) : bars;
    final centerY = size.height / 2;
    final progressIndex = (displayBars.length * progress).floor();

    for (int i = 0; i < displayBars.length; i++) {
      final barH = math.max(minBarHeight, displayBars[i] * size.height * 0.88);
      final x = i * unitWidth + barWidth / 2;
      final paint = Paint()
        ..color = i < progressIndex ? activeColor : inactiveColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth;
      canvas.drawLine(
        Offset(x, centerY - barH / 2),
        Offset(x, centerY + barH / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.bars.length != bars.length ||
          old.progress != progress ||
          old.activeColor != activeColor ||
          old.inactiveColor != inactiveColor;
}

class _VoiceWaveformPainter extends CustomPainter {
  final List<double> bars;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  const _VoiceWaveformPainter({
    required this.bars,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    const barWidth = 3.0;
    const barGap = 2.5;
    const minBarHeight = 4.0;
    const unitWidth = barWidth + barGap;

    final maxVisible = (size.width / unitWidth).floor();
    final displayBars = bars.length > maxVisible ? bars.sublist(bars.length - maxVisible) : bars;
    final centerY = size.height / 2;
    final progressIndex = (displayBars.length * progress).floor();

    for (int i = 0; i < displayBars.length; i++) {
      final barH = math.max(minBarHeight, displayBars[i] * size.height * 0.88);
      final x = i * unitWidth + barWidth / 2;
      final paint = Paint()
        ..color = i < progressIndex ? activeColor : inactiveColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth;
      canvas.drawLine(
        Offset(x, centerY - barH / 2),
        Offset(x, centerY + barH / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_VoiceWaveformPainter old) =>
      old.bars.length != bars.length ||
          old.progress != progress ||
          old.activeColor != activeColor ||
          old.inactiveColor != inactiveColor;
}