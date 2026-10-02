// lib/features/chat/chat_list_screen.dart (unchanged - kept 100% intact as requested)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import '../chat_models.dart';
import 'chat_list_controller.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatListController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Obx(() {
        if (controller.isLoading.value || !controller.isDataLoaded.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
            ),
          );
        }

        if (controller.chatRooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: AppColors.textPlaceholder,
                ),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textBody,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation by booking a service',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPlaceholder,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: controller.chatRooms.length,
          separatorBuilder: (context, index) => Divider(
            color: AppColors.dividerColor,
            height: 1,
            thickness: 0.5,
            indent: 70,
          ),
          itemBuilder: (context, index) {
            final room = controller.chatRooms[index];
            final lastMessage = room.lastMessage;

            return FutureBuilder<ChatUser>(
              future: controller.getOtherParticipantAsync(room),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildChatItemPlaceholder();
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return _buildChatItemPlaceholder();
                }

                final otherUser = snapshot.data!;

                return Obx(() {
                  final unreadCount = controller.unreadCounts[room.id] ?? 0;
                  return _buildChatItem(
                    room: room,
                    otherUser: otherUser,
                    lastMessage: lastMessage,
                    lastMessageTime: room.updatedAt,
                    unreadCount: unreadCount,
                    onTap: () => controller.openChat(room),
                    controller: controller,
                  );
                });
              },
            );
          },
        );
      }),
    );
  }

  Widget _buildChatItemPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.grey200,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  color: AppColors.grey200,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 180,
                  height: 12,
                  color: AppColors.grey200,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem({
    required ChatRoom room,
    required ChatUser otherUser,
    required ChatMessage? lastMessage,
    required DateTime lastMessageTime,
    required int unreadCount,
    required VoidCallback onTap,
    required ChatListController controller,
  }) {
    final hasUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    image: otherUser.profileImage != null && otherUser.profileImage!.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(otherUser.profileImage!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: otherUser.profileImage == null || otherUser.profileImage!.isEmpty
                      ? Icon(
                    Icons.person,
                    size: 28,
                    color: AppColors.primaryPurple,
                  )
                      : null,
                ),
                if (otherUser.isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          otherUser.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                            color: AppColors.textHeadline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        controller.formatTimestamp(lastMessageTime),
                        style: TextStyle(
                          fontSize: 11,
                          color: hasUnread ? AppColors.primaryPurple : AppColors.textPlaceholder,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage?.text ?? 'No messages yet',
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread
                                ? AppColors.textHeadline
                                : AppColors.textBody,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hasUnread)
                        Container(
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryPurple,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}