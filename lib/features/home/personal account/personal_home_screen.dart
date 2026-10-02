import 'package:bookify/features/home/Notifications%20screen/notifications_controller.dart';
import 'package:bookify/features/home/Notifications%20screen/notifications_screen.dart';
import 'package:bookify/features/home/personal%20account/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for rating fetch
import '../chat system/chat/chat_list_screen.dart';
import '../chat system/chat/chat_unread_controller.dart';
import 'business details page/business_detail_screen.dart';
import 'my appointment screen/my_appointments_screen.dart';
import 'search_and_filter_page.dart';
import 'personal_home_controller.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_icons.dart';

class PersonalHomeScreen extends StatelessWidget {
  const PersonalHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Ensure ChatUnreadController is registered (for badge)
    if (!Get.isRegistered<ChatUnreadController>()) {
      Get.put(ChatUnreadController());
    }
    final chatUnreadController = Get.find<ChatUnreadController>();

    final controller = Get.put(PersonalHomeController(), permanent: true);

    final notificationsController = Get.isRegistered<NotificationsController>()
        ? Get.find<NotificationsController>()
        : Get.put(NotificationsController(), permanent: true);

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final double scale = isTablet ? 1.05 : 1.0;
    final double cardWidth = isTablet ? 170 : 150;
    final double horizontalPadding = isTablet ? 24 : 16;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Bookify",
          style: TextStyle(
            fontSize: 24 * scale,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryPurple,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Obx(() {
            final hasUnread = notificationsController.unreadCountObs.value > 0;
            final unreadCount = notificationsController.unreadCountObs.value;
            return _buildAppBarIconButton(
              icon: AppIcons.notifications,
              onTap: () {
                Get.to(() => NotificationsScreen(
                  initialRole: UserRole.personal,
                ));
              },
              showBadge: hasUnread,
              badgeCount: unreadCount,
              scale: scale,
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          switch (controller.bottomNavIndex.value) {
            case 0:
              return _buildHomeBody(controller, scale, horizontalPadding);
            case 1:
              return SearchAndFilteredPageScreen(
                categoryId: 'all',
                categoryName: 'All Services',
                isSearchTab: true,
              );
            case 2:
              return const ChatListScreen();
            case 3:
              return const MyAppointmentsScreen(showAppBar: false);
            case 4:
              return const ProfileScreen();
            default:
              return _buildHomeBody(controller, scale, horizontalPadding);
          }
        }),
      ),
      bottomNavigationBar: Obx(() => _buildBottomNavBar(controller, chatUnreadController)),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // App Bar Icon Badge
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildAppBarIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool showBadge,
    required int? badgeCount,
    required double scale,
  }) {
    return Container(
      margin: EdgeInsets.only(right: 8 * scale),
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
                  color: const Color(0xFF2D2D3A),
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

  Widget _buildBottomNavBar(PersonalHomeController controller, ChatUnreadController chatUnreadController) {
    final double scale = 1.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4 * scale),
          child: SizedBox(
            height: 60 * scale,
            child: Row(
              children: [
                Expanded(child: _buildPersonalBottomNavItem(
                  icon: AppIcons.navHomeOutlined,
                  activeIcon: AppIcons.navHomeFilled,
                  label: 'Home',
                  isSelected: controller.bottomNavIndex.value == 0,
                  onTap: () { controller.clearFilters(); controller.onBottomNavTapped(0); },
                  badgeCount: null,
                  scale: scale,
                )),
                Expanded(child: _buildPersonalBottomNavItem(
                  icon: AppIcons.navSearchOutlined,
                  activeIcon: AppIcons.navSearchFilled,
                  label: 'Search',
                  isSelected: controller.bottomNavIndex.value == 1,
                  onTap: () => controller.onBottomNavTapped(1),
                  badgeCount: null,
                  scale: scale,
                )),
                Expanded(child: Obx(() => _buildPersonalBottomNavItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Chats',
                  isSelected: controller.bottomNavIndex.value == 2,
                  onTap: () => controller.onBottomNavTapped(2),
                  badgeCount: chatUnreadController.totalUnreadCount.value > 0 ? chatUnreadController.totalUnreadCount.value : null,
                  scale: scale,
                ))),
                Expanded(child: _buildPersonalBottomNavItem(
                  icon: AppIcons.navAppointmentOutlined,
                  activeIcon: AppIcons.navAppointmentFilled,
                  label: 'Appointments',
                  isSelected: controller.bottomNavIndex.value == 3,
                  onTap: () => controller.onBottomNavTapped(3),
                  badgeCount: null,
                  scale: scale,
                )),
                Expanded(child: _buildPersonalBottomNavItem(
                  icon: AppIcons.navProfileOutlined,
                  activeIcon: AppIcons.navProfileFilled,
                  label: 'Profile',
                  isSelected: controller.bottomNavIndex.value == 4,
                  onTap: () => controller.onBottomNavTapped(4),
                  badgeCount: null,
                  scale: scale,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalBottomNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required int? badgeCount,
    required double scale,
  }) {
    const double iconContainerSize = 28;
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
                color: isSelected ? const Color(0xFFF0EFFF) : Colors.transparent,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                                color: isSelected ? AppColors.primaryPurple : const Color(0xFFA0A0B0),
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
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFA0A0B0),
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

  // ──────────────────────────────────────────────────────────────────────────
  // 🎨 HELPER: Dynamic Category Colors (Based on your Controller list)
  // ──────────────────────────────────────────────────────────────────────────
  Color _getCategoryColor(String categoryName) {
    final String cat = categoryName.toLowerCase();
    if (cat.contains('auto')) return const Color(0xFF6C63FF); // Purple (Automotive)
    if (cat.contains('beauty')) return const Color(0xFFFF5C8D); // Pink (Beauty)
    if (cat.contains('health') || cat.contains('fitness')) return const Color(0xFF4CB8FF); // Blue (Healthcare)
    if (cat.contains('home') || cat.contains('service')) return const Color(0xFF46D891); // Green (Home Services)
    if (cat.contains('other') || cat.contains('more') || cat.contains('food')) return const Color(0xFFFFA94D); // Orange (More)
    return AppColors.primaryPurple; // Default purple
  }

  IconData _getCategoryIcon(String categoryName) {
    final String cat = categoryName.toLowerCase();
    if (cat.contains('auto')) return Icons.directions_car_outlined;
    if (cat.contains('beauty')) return Icons.spa_outlined;
    if (cat.contains('health') || cat.contains('fitness')) return Icons.local_hospital_outlined;
    if (cat.contains('home') || cat.contains('service')) return Icons.home_repair_service_outlined;
    return Icons.grid_view_rounded; // More/Other
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HOME BODY
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHomeBody(
      PersonalHomeController controller,
      double scale,
      double horizontalPadding,
      ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Find. Book. Enjoy.",
                  style: TextStyle(
                    fontSize: 26 * scale,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Explore top services near you and\nbook appointments with ease.",
                  style: TextStyle(
                    fontSize: 14 * scale,
                    color: const Color(0xFF8B8B9E),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ SEARCH BAR
                _buildEnhancedSearchBar(controller, scale),

                const SizedBox(height: 20),

                // ✅ CATEGORIES GRID (5 Columns with dynamic colors)
                _buildCategoryGrid(controller, scale, horizontalPadding),

                const SizedBox(height: 16),
              ],
            ),
          ),
          Obx(() {
            if (controller.isLoading.value && controller.allBusinesses.isEmpty) {
              return SizedBox(
                height: 300,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryPurple,
                  ),
                ),
              );
            }
            if (controller.isSearching.value) {
              return _buildSearchResults(controller, scale, horizontalPadding);
            }
            return _buildDashboard(controller, scale, horizontalPadding);
          }),
        ],
      ),
    );
  }

  // ✅ NEW CATEGORIES GRID UI (With distinct color backgrounds)
  Widget _buildCategoryGrid(PersonalHomeController controller, double scale, double horizontalPadding) {
    final categories = [
      {'id': 'Automotive', 'label': 'Automotive'},
      {'id': 'Beauty & Wellness', 'label': 'Beauty &\nWellness'},
      {'id': 'Health & Fitness', 'label': 'Healthcare'},
      {'id': 'Home Services', 'label': 'Home\nServices'},
      {'id': 'Other', 'label': 'More'},
    ];

    return SizedBox(
      height: 70 * scale,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: categories.map((cat) {
          final categoryName = cat['id'] as String;
          final Color categoryColor = _getCategoryColor(categoryName);
          final IconData categoryIcon = _getCategoryIcon(categoryName);

          return Expanded(
            child: GestureDetector(
              onTap: () => controller.onCategorySelected(categoryName),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ✅ Dynamic Colored Icon Background
                    Container(
                      padding: EdgeInsets.all(6 * scale),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.12), // Lighter background
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        categoryIcon,
                        size: 22 * scale,
                        color: categoryColor, // Actual color for icon
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      cat['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 7 * scale,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D2D3A),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnhancedSearchBar(PersonalHomeController controller, double scale) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50 * scale,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search services, businesses...",
                hintStyle: TextStyle(color: const Color(0xFFB0B0C0), fontSize: 13 * scale),
                prefixIcon: Icon(AppIcons.search, color: AppColors.primaryPurple, size: 22),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14 * scale),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            Get.to(
                  () => const SearchAndFilteredPageScreen(
                categoryId: 'all',
                categoryName: 'All Services',
              ),
              transition: Transition.rightToLeft,
              duration: const Duration(milliseconds: 300),
            );
          },
          child: Container(
            height: 50 * scale,
            width: 50 * scale,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(AppIcons.filter, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  // ✅ NEW DASHBOARD: Alternating Horizontal Scrolling (2 items then 3 items)
  Widget _buildDashboard(
      PersonalHomeController controller,
      double scale,
      double horizontalPadding,
      ) {
    final Map<String, List<Map<String, dynamic>>> categorizedBusinesses = {};
    for (final business in controller.allBusinesses) {
      final category = business['category'] ?? 'Other';
      if (!categorizedBusinesses.containsKey(category)) {
        categorizedBusinesses[category] = [];
      }
      categorizedBusinesses[category]!.add(business);
    }

    final categoryList = categorizedBusinesses.keys.toList();

    return ListView.builder(
      padding: EdgeInsets.only(top: 0, bottom: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categoryList.length + 1, // +1 for the bottom banner
      itemBuilder: (context, index) {
        if (index == categoryList.length) {
          return _buildPromoBanner(controller, scale, horizontalPadding);
        }

        final category = categoryList[index];
        final businesses = categorizedBusinesses[category]!;
        final Color categoryColor = _getCategoryColor(category);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getCategoryIcon(category),
                          size: 16,
                          color: categoryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Get.to(
                            () => SearchAndFilteredPageScreen(
                          categoryId: category,
                          categoryName: category,
                        ),
                        transition: Transition.rightToLeft,
                        duration: const Duration(milliseconds: 300),
                      );
                    },
                    child: Text(
                      "View All",
                      style: TextStyle(
                        color: categoryColor, // Dynamic color
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ ALTERNATING HORIZONTAL SCROLL:
            // Even Categories (0, 2, 4) = 2 items wide
            // Odd Categories (1, 3) = 3 items wide
            _buildAlternatingHorizontalList(
              businesses: businesses,
              categoryColor: categoryColor,
              scale: scale,
              horizontalPadding: horizontalPadding,
              categoryIndex: index,
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // ✅ NEW HELPER: Builds a horizontal list alternating between 2 and 3 items wide
  Widget _buildAlternatingHorizontalList({
    required List<Map<String, dynamic>> businesses,
    required Color categoryColor,
    required double scale,
    required double horizontalPadding,
    required int categoryIndex,
  }) {
    // Even index (0, 2, 4) = 2 items per row. Odd index (1, 3) = 3 items per row.
    final int itemsPerRow = (categoryIndex % 2 == 0) ? 2 : 3;

    // Width logic: 2 items = 50% each (0.48 with spacing), 3 items = 33% each (0.31 with spacing)
    final double widthFactor = (itemsPerRow == 2) ? 0.48 : 0.31;

    return SizedBox(
      height: 150 * scale, // Fixed height for horizontal scrolling
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        itemCount: businesses.length,
        itemBuilder: (context, index) {
          final business = businesses[index];
          return Container(
            width: MediaQuery.of(context).size.width * widthFactor,
            margin: EdgeInsets.only(right: 12, bottom: 4, top: 4),
            child: _buildCompactCard(
              business: business,
              categoryColor: categoryColor,
              scale: scale,
            ),
          );
        },
      ),
    );
  }

  // ✅ UPDATED COMPACT CARD (Dynamic Real-time Rating)
  Widget _buildCompactCard({
    required Map<String, dynamic> business,
    required Color categoryColor,
    required double scale,
  }) {
    final imageUrl = business['profileImage'] ?? '';
    final String businessId = business['id'] ?? '';

    return GestureDetector(
      onTap: () {
        Get.to(
              () => BusinessDetailScreen(businessId: business['id']),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 300),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Container(
                height: 70 * scale, // Adjusted height for grid
                width: double.infinity,
                color: categoryColor.withOpacity(0.08),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholderImage(categoryColor),
                )
                    : _buildPlaceholderImage(categoryColor),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          business['name'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12 * scale,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      // ✅ NEW: Dynamic Rating Fetched from Firebase
                      _buildDynamicRatingBadge(
                        businessId: businessId,
                        categoryColor: categoryColor,
                        scale: scale,
                      ),
                    ],
                  ),
                  SizedBox(height: 4 * scale),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 10 * scale, color: const Color(0xFF8B8B9E)),
                      SizedBox(width: 2 * scale),
                      Expanded(
                        child: Text(
                          " ${business['city'] ?? ''}",
                          maxLines: 1,
                          style: TextStyle(fontSize: 10 * scale, color: const Color(0xFF8B8B9E)),
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

  // ✅ NEW HELPER: Fetches and displays dynamic rating from Firebase
  Widget _buildDynamicRatingBadge({
    required String businessId,
    required Color categoryColor,
    required double scale,
  }) {
    if (businessId.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('businessId', isEqualTo: businessId)
          .snapshots(),
      builder: (context, snapshot) {
        double averageRating = 0.0;
        int totalReviews = 0;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final docs = snapshot.data!.docs;
          totalReviews = docs.length;
          double sumRatings = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            sumRatings += (data['rating'] as int? ?? 0).toDouble();
          }
          averageRating = sumRatings / totalReviews;
        }

        // IF NO RATINGS: Show outlined star only (No color, no number)
        if (totalReviews == 0) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 2 * scale),
            child: Icon(
              Icons.star_border_rounded,
              color: const Color(0xFFB0B0C0),
              size: 11 * scale,
            ),
          );
        }

        // IF HAS RATINGS: Show colored badge with number
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
          decoration: BoxDecoration(
            color: categoryColor,
            borderRadius: BorderRadius.circular(6 * scale),
          ),
          child: Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.white, size: 10 * scale),
              SizedBox(width: 2 * scale),
              Text(
                averageRating.toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage(Color categoryColor) {
    return Container(
      color: categoryColor.withOpacity(0.08),
      child: Center(
        child: Icon(
          AppIcons.business,
          color: categoryColor.withOpacity(0.5),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildPlaceholderImageLarge() {
    return Container(
      color: AppColors.primaryPurple.withOpacity(0.1),
      child: Center(
        child: Icon(
          AppIcons.businessCenter,
          color: AppColors.primaryPurple,
          size: 30,
        ),
      ),
    );
  }

  // ✅ PROMO BANNER
  Widget _buildPromoBanner(PersonalHomeController controller, double scale, double horizontalPadding){
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
      child: Container(
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryPurple, Color(0xFF7B6ADD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Manage Your Appointments",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14 * scale,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "View, reschedule or cancel your\nappointments anytime.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11 * scale,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                controller.onBottomNavTapped(3);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryPurple,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "My Appointments",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11 * scale,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ SEARCH RESULTS (Detailed View)
  Widget _buildSearchResults(
      PersonalHomeController controller,
      double scale,
      double horizontalPadding,
      ) {
    return Obx(() {
      if (controller.filteredBusinesses.isEmpty && !controller.isLoading.value) {
        return Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 40),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.searchOff,
                    size: 60,
                    color: const Color(0xFFB0B0C0),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No services found",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2D2D3A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Try adjusting your filters or search terms",
                    style: TextStyle(fontSize: 13, color: const Color(0xFF8B8B9E)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(horizontalPadding),
        itemCount: controller.filteredBusinesses.length,
        itemBuilder: (context, index) =>
            _buildDetailedCard(controller.filteredBusinesses[index], scale),
      );
    });
  }

  Widget _buildDetailedCard(Map<String, dynamic> business, double scale) {
    final imageUrl = business['profileImage'] ?? '';
    final Color categoryColor = _getCategoryColor(business['category'] ?? 'Other');

    return GestureDetector(
      onTap: () {
        Get.to(
              () => BusinessDetailScreen(businessId: business['id']),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 300),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 80,
                width: 80,
                color: categoryColor.withOpacity(0.1),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholderImageLarge(),
                )
                    : _buildPlaceholderImageLarge(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          business['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                          const SizedBox(width: 2),
                          Text(
                            business['rating'] ?? '4.5',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D2D3A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    business['description'] ?? '',
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF8B8B9E),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 13, color: categoryColor),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          business['city'] ?? business['address'] ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2D2D3A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "View Details",
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
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