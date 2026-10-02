import 'package:bookify/features/home/Notifications%20screen/notifications_controller.dart';
import 'package:bookify/features/home/business%20account/branch%20management/branch_list_screen.dart';
import 'package:bookify/features/home/business%20account/business%20analytics/business_analytics_screen.dart';
import 'package:bookify/features/home/business%20account/business%20profile/profile_settings_screen.dart';
import 'package:bookify/features/home/business%20account/my%20services/my_services_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_icons.dart';
import '../../Auth/auth_controller.dart';
import '../Notifications screen/notifications_screen.dart';
import '../appointment_details/appointment_details_screen.dart';
import '../chat system/chat/chat_list_screen.dart';
import '../chat system/chat/chat_unread_controller.dart';
import 'business appointments/business_appointments_screen.dart';
import 'business services/business_service_screen.dart';
import 'business_home_controller.dart';

class BusinessHomeScreen extends StatelessWidget {
  const BusinessHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Ensure ChatUnreadController is registered (for badge)
    if (!Get.isRegistered<ChatUnreadController>()) {
      Get.put(ChatUnreadController());
    }
    final chatUnreadController = Get.find<ChatUnreadController>();

    // ✅ FIX: Get existing controller or create new one, then refresh data
    final controller = Get.isRegistered<BusinessHomeController>()
        ? (Get.find<BusinessHomeController>()..fetchBusinessData())
        : Get.put(BusinessHomeController());

    final notificationsController = Get.find<NotificationsController>();
    final screenWidth = MediaQuery.of(context).size.width;

    final isVerySmall = screenWidth < 320;
    final isSmall = screenWidth < 360;
    final isMobile = screenWidth < 600;

    final scale = isVerySmall ? 0.85 : isSmall ? 0.92 : 1.0;
    final padding = isMobile ? 12.0 : 24.0;
    final maxWidth = isMobile ? double.infinity : 600.0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        centerTitle: false,
        title: Obx(() => Text(
          _getAppBarTitle(controller.bottomNavIndex.value),
          style: TextStyle(
            fontSize: 22 * scale,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        )),
        actions: [
          Obx(() {
            final unreadCount = notificationsController.unreadCountObs.value;
            return _buildAppBarIconButton(
              icon: AppIcons.notifications,
              onTap: () {
                Get.to(() => NotificationsScreen(
                  initialRole: UserRole.business,
                ));
              },
              showBadge: unreadCount > 0,
              badgeCount: unreadCount,
              scale: scale,
            );
          }),
          _buildAppBarIconButton(
            icon: AppIcons.drawerProfile,
            onTap: () {
              Get.to(() => const ProfileSettingsScreen());
            },
            showBadge: false,
            badgeCount: null,
            scale: scale,
          ),
          // Conditionally show the branch management icon
          Obx(() {
            final authController = Get.find<AuthController>();
            if (authController.isBranchUser.value) {
              return const SizedBox.shrink(); // hide for branch managers
            }
            return _buildAppBarIconButton(
              icon: Icons.add_business_outlined,
              onTap: () {
                Get.to(() => const BranchListScreen());
              },
              showBadge: false,
              badgeCount: null,
              scale: scale,
            );
          }),
        ],
      ),
      body: Obx(() {
        switch (controller.bottomNavIndex.value) {
          case 0:
            return _buildHomeContent(controller, padding, maxWidth, scale);
          case 1:
            return const BusinessServicesScreen();
          case 2:
            return const ChatListScreen();
          case 3:
            return const BusinessAppointmentsScreen();
          case 4:
            return const BusinessAnalyticsScreen();
          default:
            return _buildHomeContent(controller, padding, maxWidth, scale);
        }
      }),
      bottomNavigationBar: Obx(() => _buildBottomNavigationBar(controller, chatUnreadController, scale)),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Business Dashboard';
      case 1:
        return 'Business Services';
      case 2:
        return 'Chats';
      case 3:
        return 'Business Appointments';
      case 4:
        return 'Business Analytics';
      default:
        return 'Business Dashboard';
    }
  }

  Widget _buildHomeContent(
      BusinessHomeController controller,
      double padding,
      double maxWidth,
      double scale,
      ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCards(controller, scale),
              SizedBox(height: 20 * scale),
              _buildActionButtons(scale),
              SizedBox(height: 24 * scale),
              _buildTabs(controller, scale),
              SizedBox(height: 16 * scale),
              Obx(() =>
              controller.tabIndex.value == 0
                  ? _buildOverviewFilter(controller, scale)
                  : const SizedBox.shrink()),
              SizedBox(height: 16 * scale),
              Obx(() => _buildTabContent(controller, scale)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BusinessHomeController controller, ChatUnreadController chatUnreadController, double scale) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20 * scale),
          topRight: Radius.circular(20 * scale),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4 * scale),
          child: SizedBox(
            height: 56 * scale,
            child: Row(
              children: [
                Expanded(
                  child: _buildBottomNavItem(
                    icon: AppIcons.navHomeOutlined,
                    activeIcon: AppIcons.navHomeFilled,
                    label: 'Home',
                    isSelected: controller.bottomNavIndex.value == 0,
                    onTap: () => controller.changeBottomNav(0),
                    badgeCount: null,
                    scale: scale,
                  ),
                ),
                Expanded(
                  child: _buildBottomNavItem(
                    icon: AppIcons.app,
                    activeIcon: AppIcons.app,
                    label: 'Services',
                    isSelected: controller.bottomNavIndex.value == 1,
                    onTap: () => controller.changeBottomNav(1),
                    badgeCount: null,
                    scale: scale,
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    final unread = chatUnreadController.totalUnreadCount.value;
                    return _buildBottomNavItem(
                      icon: Icons.chat_bubble_outline,
                      activeIcon: Icons.chat_bubble,
                      label: 'Chats',
                      isSelected: controller.bottomNavIndex.value == 2,
                      onTap: () => controller.changeBottomNav(2),
                      badgeCount: unread > 0 ? unread : null,
                      scale: scale,
                    );
                  }),
                ),
                Expanded(
                  child: _buildBottomNavItem(
                    icon: AppIcons.navAppointmentOutlined,
                    activeIcon: AppIcons.navAppointmentFilled,
                    label: 'Appointments',
                    isSelected: controller.bottomNavIndex.value == 3,
                    onTap: () => controller.changeBottomNav(3),
                    badgeCount: null,
                    scale: scale,
                  ),
                ),
                Expanded(
                  child: _buildBottomNavItem(
                    icon: Icons.analytics_outlined,
                    activeIcon: Icons.analytics,
                    label: 'Analytics',
                    isSelected: controller.bottomNavIndex.value == 4,
                    onTap: () => controller.changeBottomNav(4),
                    badgeCount: null,
                    scale: scale,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required int? badgeCount,
    required double scale,
  }) {
    // Fixed container size for the icon to keep badge attached to its top-right corner
    const double iconContainerSize = 28; // slightly larger than max icon size (22 * 1.15 ≈ 25.3)
    final double containerSize = iconContainerSize * scale;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 4 * scale),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: isSelected ? 44 * scale : 0,
              height: isSelected ? 44 * scale : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primaryPurple.withOpacity(0.12) : Colors.transparent,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: isSelected ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  // Fixed-size container for the icon – keeps badge attached to icon's top-right corner
                  SizedBox(
                    width: containerSize,
                    height: containerSize,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            alignment: Alignment.center,
                            child: AnimatedScale(
                              scale: isSelected ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 150),
                              child: Icon(
                                isSelected ? activeIcon : icon,
                                color: isSelected ? AppColors.primaryPurple : AppColors.textBody,
                                size: 22 * scale,
                              ),
                            ),
                          ),
                        ),
                        if (badgeCount != null && badgeCount > 0)
                          Positioned(
                            right: -4 * scale,
                            top: -4 * scale,
                            child: Container(
                              constraints: BoxConstraints(
                                minWidth: 16 * scale,
                                minHeight: 16 * scale,
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 2 * scale),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20 * scale),
                              ),
                              child: Text(
                                badgeCount > 9 ? '9+' : '$badgeCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9 * scale,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: isSelected ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: isSelected ? 0 : null,
                      child: isSelected ? null : SizedBox(height: 3 * scale),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: isSelected ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: isSelected
                        ? const SizedBox.shrink()
                        : AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: TextStyle(
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textBody,
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Updated UI components to match the image exactly
  // ------------------------------------------------------------------

  Widget _buildOverviewFilter(BusinessHomeController controller, double scale) {
    final filters = ['All', 'Today', 'Tomorrow', 'Yesterday', 'Previous', 'Upcoming'];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.overviewFilter.value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 20 * scale,
            color: AppColors.primaryPurple,
          ),
          items: filters.map((String filter) {
            return DropdownMenuItem<String>(
              value: filter,
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: AppColors.textHeadline,
                  fontWeight: controller.overviewFilter.value == filter
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              controller.changeOverviewFilter(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatsCards(BusinessHomeController controller, double scale) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: AppIcons.calendar,
                iconColor: AppColors.primaryPurple,
                iconBgColor: AppColors.iconBgLightPurple,
                borderColor: AppColors.primaryPurple,
                label: 'Today',
                value: controller.todayAppointments.value.toString(),
                subtitle: 'Appointments',
                scale: scale,
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: _buildStatCard(
                icon: Icons.attach_money,
                iconColor: const Color(0xFF22C55E), // Bright Green
                iconBgColor: const Color(0xFFDCFCE7), // Very Light Green
                borderColor: const Color(0xFF22C55E), // Bright Green
                label: 'Revenue',
                value: controller.todayEarnings,
                subtitle: "Today's earnings",
                showDollarBg: true,
                scale: scale,
              ),
            ),
          ],
        ),
        SizedBox(height: 12 * scale),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: AppIcons.clock,
                iconColor: AppColors.statusWarning, // Orange
                iconBgColor: const Color(0xFFFFF7ED), // Very Light Orange
                borderColor: AppColors.statusWarning, // Orange
                label: 'Pending',
                value: controller.pendingCount.value.toString(),
                subtitle: 'Needs approval',
                scale: scale,
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: _buildStatCard(
                icon: AppIcons.drawerProfile,
                iconColor: AppColors.primaryPurple,
                iconBgColor: AppColors.iconBgLightPurple,
                borderColor: AppColors.primaryPurple,
                label: 'Customers',
                value: controller.totalCustomers.value.toString(),
                subtitle: 'Total clients',
                scale: scale,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color borderColor,
    required String label,
    required String value,
    required String subtitle,
    bool showDollarBg = false,
    required double scale,
  }) {
    return Container(
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: borderColor,
            width: 4 * scale,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background watermarks
          if (showDollarBg)
            Positioned(
              right: -10 * scale,
              bottom: -10 * scale,
              child: Container(
                width: 60 * scale,
                height: 60 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7).withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.attach_money,
                  size: 40 * scale,
                  color: const Color(0xFF22C55E).withOpacity(0.15),
                ),
              ),
            ),
          if (label == 'Pending')
            Positioned(
              right: -10 * scale,
              bottom: -10 * scale,
              child: Container(
                width: 60 * scale,
                height: 60 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED).withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.clock,
                  size: 40 * scale,
                  color: AppColors.statusWarning.withOpacity(0.15),
                ),
              ),
            ),
          if (label == 'Customers')
            Positioned(
              right: -10 * scale,
              bottom: -10 * scale,
              child: Container(
                width: 60 * scale,
                height: 60 * scale,
                decoration: BoxDecoration(
                  color: AppColors.iconBgLightPurple.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people,
                  size: 40 * scale,
                  color: AppColors.primaryPurple.withOpacity(0.15),
                ),
              ),
            ),

          Column(
            mainAxisSize: MainAxisSize.min, // CRITICAL: Makes it responsive!
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(6 * scale),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                    child: Icon(icon, color: iconColor, size: 16 * scale),
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: AppColors.grey700,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8 * scale), // Replaced Spacer() to avoid overflow
              Padding(
                padding: EdgeInsets.only(left: 2 * scale),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 24 * scale,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeadline,
                  ),
                ),
              ),
              SizedBox(height: 2 * scale),
              Padding(
                padding: EdgeInsets.only(left: 2 * scale),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: AppColors.grey600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double scale) {
    final buttonHeight = scale < 0.9 ? 44.0 : 40.0;
    final iconSize = 16.0;
    final fontSize = scale < 0.9 ? 12.0 : 13.0;

    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Services',
            Icons.grid_view,
            AppColors.primaryPurple,
            Colors.white,
            true,
            buttonHeight,
            iconSize,
            fontSize,
          ),
        ),
        SizedBox(width: 10 * scale),
        Expanded(
          child: _buildActionButton(
            'Analytics',
            Icons.trending_up,
            Colors.transparent,
            AppColors.primaryPurple,
            false,
            buttonHeight,
            iconSize,
            fontSize,
          ),
        ),
        SizedBox(width: 10 * scale),
        Expanded(
          child: _buildActionButton(
            'New Booking',
            Icons.add,
            Colors.transparent,
            AppColors.textHeadline,
            false,
            buttonHeight,
            iconSize,
            fontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String label,
      IconData icon,
      Color bgColor,
      Color textColor,
      bool isFilled,
      double height,
      double iconSize,
      double fontSize,
      ) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isFilled ? bgColor : null,
        border: isFilled
            ? null
            : Border.all(
          color: textColor == AppColors.primaryPurple
              ? AppColors.primaryPurple.withOpacity(0.3)
              : Colors.grey[300]!,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton.icon(
        onPressed: () {
          if (label == 'Services') {
            Get.to(() => const BusinessServicesScreen(showAppBar: true));
          } else if (label == 'Analytics') {
            Get.to(() => const BusinessAnalyticsScreen(showAppBar: true));
          } else if (label == 'New Booking') {
            Get.to(() => const MyServicesScreen());
          }
        },
        icon: Icon(
          icon,
          color: textColor,
          size: iconSize,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 4),
          minimumSize: Size(0, height),
        ),
      ),
    );
  }

  Widget _buildTabs(BusinessHomeController controller, double scale) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => _buildTabItem(
              'Overview',
              controller.tabIndex.value == 0,
                  () => controller.changeTab(0),
              null,
              scale,
            )),
          ),
          Expanded(
            child: Obx(() => _buildTabItem(
              'Pending',
              controller.tabIndex.value == 1,
                  () => controller.changeTab(1),
              controller.pendingCount.value,
              scale,
            )),
          ),
          Expanded(
            child: Obx(() => _buildTabItem(
              'Confirmed',
              controller.tabIndex.value == 2,
                  () => controller.changeTab(2),
              controller.confirmedCount.value,
              scale,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, bool isSelected, VoidCallback onTap, int? badge, double scale) {
    Color getBadgeColor() {
      if (label == 'Pending') {
        return Colors.orange;
      } else if (label == 'Confirmed') {
        return Colors.green;
      }
      return Colors.orange;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12 * scale),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primaryPurple : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryPurple : AppColors.textBody,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (badge != null && badge > 0) ...[
              SizedBox(width: 6 * scale),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
                decoration: BoxDecoration(
                  color: getBadgeColor(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(BusinessHomeController controller, double scale){
    switch (controller.tabIndex.value) {
      case 0:
        return _buildOverviewTab(controller, scale);
      case 1:
        return _buildPendingTab(controller, scale);
      case 2:
        return _buildConfirmedTab(controller, scale);
      default:
        return const SizedBox();
    }
  }

  Widget _buildOverviewTab(BusinessHomeController controller, double scale) {
    return Obx((){
      final appointments = controller.filteredAppointments;
      if (appointments.isEmpty) {
        return _buildEmptyState(
            'No appointments found.',
            'Try changing the filters or check back later.',
            scale
        );
      }
      return Column(
        children: appointments.map((appointment) =>
            _buildAppointmentCard(appointment, controller, isDetailed: false, scale: scale)
        ).toList(),
      );
    });
  }

  Widget _buildPendingTab(BusinessHomeController controller, double scale) {
    return Obx((){
      final pending = controller.pendingAppointments;
      if (pending.isEmpty) {
        return _buildEmptyState(
            'No appointments found.',
            'Try changing the filters or check back later.',
            scale
        );
      }
      return Column(
        children: pending.map((appointment) =>
            _buildAppointmentCard(appointment, controller, isDetailed: false, scale: scale)
        ).toList(),
      );
    });
  }

  Widget _buildConfirmedTab(BusinessHomeController controller, double scale) {
    return Obx(() {
      final confirmed = controller.confirmedAppointments;
      if (confirmed.isEmpty) {
        return _buildEmptyState(
            'No appointments found.',
            'Try changing the filters or check back later.',
            scale
        );
      }
      return Column(
        children: confirmed.map((appointment) =>
            _buildAppointmentCard(
                appointment, controller, isDetailed: false, scale: scale)
        ).toList(),
      );
    });
  }

  Widget _buildEmptyState(String message, String subMessage, double scale) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40 * scale),
        child: Column(
          children: [
            Icon(
              AppIcons.searchOff,
              size: 64 * scale,
              color: Colors.grey[300],
            ),
            SizedBox(height: 20 * scale),
            Text(
              message,
              style: TextStyle(
                fontSize: 16 * scale,
                color: AppColors.textBody,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8 * scale),
            Text(
              subMessage,
              style: TextStyle(
                fontSize: 13 * scale,
                color: AppColors.textPlaceholder,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, BusinessHomeController controller, {required bool isDetailed, required double scale}) {
    final status = appointment['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final isCompleted = status == 'completed';
    final isCancelled = status == 'cancelled';

    final services = appointment['services']?.toString() ?? appointment['serviceName']?.toString() ?? 'Service';
    final customerName = appointment['customerName']?.toString() ?? 'Customer';
    final email = appointment['customerEmail']?.toString() ?? appointment['email']?.toString() ?? '';
    final date = appointment['date']?.toString() ?? '';
    final time = appointment['time']?.toString() ?? '';
    final duration = appointment['duration']?.toString() ?? appointment['serviceDuration']?.toString() ?? '0';
    final price = appointment['price'] ?? 0;
    final advancePaid = appointment['advancePaid'] ?? 0;

    final displayTime = time.contains(' - ') ? time.split(' - ')[0].trim() : time;
    final timeLabel = isDetailed ? '$displayTime ($duration min)' : displayTime;

    return GestureDetector(
      onTap: () {
        final Map<String, dynamic> args = Map.from(appointment);
        args['isBusinessView'] = true;
        Get.to(() => const AppointmentDetailsScreen(), arguments: args);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12 * scale),
        padding: EdgeInsets.all(14 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isPending
              ? Border.all(color: Colors.orange.withOpacity(0.3))
              : isCompleted
              ? Border.all(color: Colors.blue.withOpacity(0.3))
              : isCancelled
              ? Border.all(color: Colors.red.withOpacity(0.3))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        services,
                        style: TextStyle(
                          fontSize: 15 * scale,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHeadline,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 3 * scale),
                      Text(
                        customerName,
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: AppColors.textBody,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (isDetailed && email.isNotEmpty) ...[
                        SizedBox(height: 2 * scale),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 11 * scale,
                            color: AppColors.textBody.withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8 * scale),
                if (!isDetailed)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
                    decoration: BoxDecoration(
                      color: controller.getStatusBadgeColor(status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.capitalize!,
                      style: TextStyle(
                        fontSize: 11 * scale,
                        fontWeight: FontWeight.w600,
                        color: controller.getStatusTextColor(status),
                      ),
                    ),
                  ),
                if (isDetailed && isPending)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Action Required',
                        style: TextStyle(
                          fontSize: 11 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        'for approval',
                        style: TextStyle(
                          fontSize: 10 * scale,
                          color: AppColors.textBody.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            SizedBox(height: 10 * scale),

            Wrap(
              spacing: 12 * scale,
              runSpacing: 6 * scale,
              children: [
                _buildInfoChip(AppIcons.calendar, controller.formatDate(date), scale),
                _buildInfoChip(AppIcons.clock, timeLabel, scale),
                if (!isDetailed)
                  _buildInfoChip(Icons.attach_money, 'PKR $price', scale),
              ],
            ),

            if (isDetailed) ...[
              SizedBox(height: 10 * scale),
              Container(
                padding: EdgeInsets.all(12 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Payment Status:',
                            style: TextStyle(
                              fontSize: 12 * scale,
                              color: AppColors.textBody,
                            ),
                          ),
                        ),
                        Text(
                          price > 0
                              ? '${((advancePaid / price) * 100).toInt()}% Paid'
                              : '0% Paid',
                          style: TextStyle(
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6 * scale),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Amount:',
                            style: TextStyle(
                              fontSize: 12 * scale,
                              color: AppColors.textBody,
                            ),
                          ),
                        ),
                        Text(
                          'PKR $advancePaid / $price',
                          style: TextStyle(
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHeadline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12 * scale),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: () => controller.rejectAppointment(appointment['id']),
                        icon: Icon(AppIcons.close, color: Colors.red, size: 16 * scale),
                        label: Text(
                          'Reject',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 13 * scale,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10 * scale),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: () => controller.approveAppointment(appointment['id']),
                        icon: Icon(Icons.check, color: Colors.white, size: 16 * scale),
                        label: Text(
                          'Approve',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13 * scale,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, double scale) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14 * scale, color: AppColors.textBody),
        SizedBox(width: 4 * scale),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(
            text.isEmpty ? 'Not specified' : text,
            style: TextStyle(
              fontSize: 12 * scale,
              color: AppColors.textBody,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // App Bar Icon Button (Kept 100% unchanged)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildAppBarIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool showBadge,
    required int? badgeCount,
    required double scale,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 4 * scale),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10 * scale),
                child: Icon(
                  icon,
                  color: AppColors.textHeadline,
                  size: 24 * scale,
                ),
              ),
              if (showBadge)
                Positioned(
                  right: 10 * scale,
                  top: 10 * scale,
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: 12 * scale,
                      minHeight: 12 * scale,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 3 * scale, vertical: 1 * scale),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20 * scale),
                    ),
                    child: Text(
                      badgeCount != null && badgeCount > 9 ? '9+' : (badgeCount?.toString() ?? ''),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}