// notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends StatelessWidget {
  final UserRole? initialRole;

  const NotificationsScreen({super.key, this.initialRole});

  @override
  Widget build(BuildContext context) {
    // Get or create the controller
    final controller = Get.isRegistered<NotificationsController>()
        ? Get.find<NotificationsController>()
        : Get.put(NotificationsController(), permanent: true);

    // ── FIX: Resolve the role synchronously, before any build happens ──
    // The old code used addPostFrameCallback, which fires AFTER the first
    // Obx build — so filteredNotifications ran with the wrong role and
    // returned an empty list. Setting role here (synchronously in build())
    // ensures the correct role is in place before filteredNotifications
    // is ever evaluated.
    final args = Get.arguments;
    UserRole roleToSet;

    if (args is Map<String, dynamic> && args.containsKey('initialRole')) {
      final roleArg = args['initialRole'];
      roleToSet = roleArg == 'business'
          ? UserRole.business
          : UserRole.personal;
    } else {
      roleToSet = initialRole ?? UserRole.personal;
    }

    // Set role immediately — no callback delay
    if (controller.userRole.value != roleToSet) {
      controller.setUserRole(roleToSet);
    }

    // ── FIX: Ensure Firestore listener is active ──
    // On the personal side the controller may have been created before
    // Firebase Auth finished loading. refreshNotifications() is a no-op
    // if the listener is already running, so this is safe to call always.
    controller.refreshNotifications();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final padding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(AppIcons.arrowLeft, color: AppColors.textHeadline),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => controller.markAllAsRead(),
            child: Text(
              'Mark all read',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(controller, padding),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(
                  () => _buildNotificationsList(controller, context, padding),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTabs(NotificationsController controller, double padding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.dividerColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Obx(() => _buildTabItem(
                'All (${controller.totalCount})',
                controller.selectedTab.value == 0,
                    () => controller.changeTab(0),
              )),
            ),
            Expanded(
              child: Obx(() => _buildTabItem(
                'Unread (${controller.unreadCount})',
                controller.selectedTab.value == 1,
                    () => controller.changeTab(1),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primaryPurple : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.primaryPurple : AppColors.textBody,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(
      NotificationsController controller,
      BuildContext context,
      double padding,
      ) {
    final notifications = controller.filteredNotifications;

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.notifications,
              size: 48,
              color: AppColors.textPlaceholder,
            ),
            SizedBox(height: 12),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textBody,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(
        left: padding,
        right: padding,
        bottom: 20,
      ),
      itemCount: notifications.length,
      separatorBuilder: (context, index) => SizedBox(height: 10),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationItem(notification, controller, context);
      },
    );
  }

  Widget _buildNotificationItem(
      AppNotification notification,
      NotificationsController controller,
      BuildContext context,
      ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.deleteColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          AppIcons.delete,
          color: Colors.white,
          size: 20,
        ),
      ),
      confirmDismiss: (direction) async {
        controller.deleteNotification(notification.id);
        return true;
      },
      child: GestureDetector(
        onTap: () {
          controller.markAsReadAndNavigate(notification.id, context);
        },
        child: Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead
                ? AppColors.cardBackground
                : AppColors.primaryPurple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.transparent
                  : AppColors.primaryPurple.withOpacity(0.3),
              width: notification.isRead ? 0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification.type),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeadline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textBody,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    Text(
                      notification.formattedTimestamp,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textPlaceholder,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 10,
                  height: 10,
                  margin: EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color bgColor;
    Color iconColor;

    switch (type) {
      case NotificationType.chatMessage:
        icon = Icons.chat_bubble_rounded;
        bgColor = const Color(0xFFE8F5E9);
        iconColor = const Color(0xFF4CAF50);
        break;

      case NotificationType.bookingConfirmed:
      case NotificationType.appointmentReminder:
        icon = AppIcons.navAppointmentFilled;
        bgColor = AppColors.iconBgPurple;
        iconColor = AppColors.primaryPurple;
        break;

      case NotificationType.paymentSuccessful:
        icon = AppIcons.money;
        bgColor = AppColors.iconBgGreen;
        iconColor = AppColors.statusSuccess;
        break;

      case NotificationType.newBookingRequest:
      case NotificationType.pendingApproval:
        icon = AppIcons.calendar;
        bgColor = AppColors.iconBgPurple;
        iconColor = Colors.blue;
        break;

      case NotificationType.appointmentCancelled:
      case NotificationType.autoCancelled:
        icon = AppIcons.close;
        bgColor = const Color(0xFFFFEBEE);
        iconColor = AppColors.deleteColor;
        break;

      case NotificationType.rescheduleRequest:
      case NotificationType.rescheduleConfirmed:
        icon = AppIcons.clock;
        bgColor = AppColors.iconBgAmber;
        iconColor = AppColors.statusWarning;
        break;

      case NotificationType.ratingRequest:
        icon = Icons.star_rate_rounded;
        bgColor = AppColors.iconBgAmber;
        iconColor = Colors.amber;
        break;

      case NotificationType.refundProcessed:
        icon = Icons.receipt;
        bgColor = AppColors.iconBgGreen;
        iconColor = Colors.green;
        break;

      default:
        icon = AppIcons.info;
        bgColor = AppColors.grey200;
        iconColor = AppColors.textBody;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 20,
        color: iconColor,
      ),
    );
  }
}