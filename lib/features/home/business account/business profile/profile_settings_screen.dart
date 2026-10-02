import 'package:bookify/features/change%20password/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import '../../Notifications screen/notifications_controller.dart';
import '../../Notifications screen/notifications_screen.dart';
import '../../app settings/app_settings_screen.dart';
import '../../edit profile/edit_profile_screen.dart';
import '../../hep center/help_center_screen.dart';
import '../payment method/payment_methods_screen.dart';
import 'profile_settings_controller.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileSettingsController());
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
        title: Text(
          'Profile & Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryPurple,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadBusinessProfile(),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Combined Profile Header & Business Details Section (New Design)
                _buildProfileAndBusinessCard(controller),
                SizedBox(height: 24),

                // 🔹 Edit Profile Button
                _buildEditButton(controller),
                SizedBox(height: 24),

                // 🔹 Account Section
                _buildSectionTitle('Account'),
                SizedBox(height: 12),
                _buildAccountSection(controller),
                SizedBox(height: 24),

                // 🔹 Support Section
                _buildSectionTitle('Support'),
                SizedBox(height: 12),
                _buildSupportSection(),
                SizedBox(height: 24),

                // 🔹 App Info & Legal
                _buildAppInfoSection(controller),
                SizedBox(height: 24),

                // 🔹 Logout Button (Updated)
                _buildLogoutButton(controller),
                SizedBox(height: 16),

                // 🔹 Delete Account
                _buildDeleteAccount(controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ════════════════════════════════════════════════════════════
  // COMBINED PROFILE & BUSINESS DETAILS CARD (New Design)
  // Matches the uploaded UI reference image
  // ════════════════════════════════════════════════════════════
  Widget _buildProfileAndBusinessCard(ProfileSettingsController controller) {
    return Obx(() {
      final imageUrl = controller.profileImageUrl.value;
      final hasImage = imageUrl.isNotEmpty && imageUrl.startsWith('http');

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Section: Profile Image, Name, and Role
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Profile Image / Avatar
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: hasImage
                          ? Image.network(
                        imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            controller.initials,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      )
                          : Center(
                        child: Text(
                          controller.initials,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name and Role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.fullName.value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.accountType.value,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Section: Business Details (Email, Phone, Location)
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Email Row
                  _buildBusinessDetailRow(
                    icon: AppIcons.email,
                    label: 'Email',
                    value: controller.email.value,
                  ),
                  const SizedBox(height: 16),
                  // Phone Row
                  _buildBusinessDetailRow(
                    icon: AppIcons.phone,
                    label: 'Phone',
                    value: controller.phoneNumber.value,
                  ),
                  const SizedBox(height: 16),
                  // Location Row (Address, City)
                  _buildBusinessDetailRow(
                    icon: AppIcons.location,
                    label: 'Location',
                    value: _formatLocation(controller.address.value, controller.city.value),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // Helper method to format location from address and city
  String _formatLocation(String address, String city) {
    if (address.isEmpty && city.isEmpty) return 'Not provided';
    if (address.isEmpty) return city;
    if (city.isEmpty) return address;
    return '$address, $city';
  }

  // Individual business detail row
  Widget _buildBusinessDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon Container
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.iconBgPurple,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primaryPurple,
          ),
        ),
        const SizedBox(width: 12),
        // Label and Value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? 'Not provided' : value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeadline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // EDIT BUTTON (Updated with navigation result handling)
  // ════════════════════════════════════════════════════════════
  Widget _buildEditButton(ProfileSettingsController controller) {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: () async {
          final result = await Get.to(() => const EditProfileScreen());
          if (result == true) {
            await controller.loadBusinessProfile();
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.edit,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ACCOUNT SECTION (Updated Notifications)
  // ════════════════════════════════════════════════════════════
  Widget _buildAccountSection(ProfileSettingsController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 🔹 UPDATED: Notifications now navigates to BusinessNotificationsScreen
          _buildSettingItem(
            icon: AppIcons.notifications,
            title: 'Notifications',
            onTap: () {
              Get.to(() => const NotificationsScreen(
                initialRole: UserRole.business,
              ));
            },
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: AppIcons.payment,
            title: 'Payment Methods',
            onTap: () {
              Get.to(() => const PaymentMethodsScreen());
            },
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: AppIcons.privacy,
            title: 'Change Password',
            onTap: () {
              Get.to(ChangePasswordScreen());
            },
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: AppIcons.drawerSettings,
            title: 'Settings',
            onTap: () {
              Get.to(() => const AppSettingsScreen());
            },
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // SUPPORT SECTION
  // ════════════════════════════════════════════════════════════
  Widget _buildSupportSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: AppIcons.help,
            title: 'Help Center',
            onTap: () {
              Get.to(() => const HelpCenterScreen());
            },
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: AppIcons.contactSupport,
            title: 'Contact Support',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // APP INFO SECTION (FIXED - removed unnecessary Obx)
  // ════════════════════════════════════════════════════════════
  Widget _buildAppInfoSection(ProfileSettingsController controller) {
    // No Obx needed here since no observable variables are being used
    return Column(
      children: [
        _buildSimpleTextItem(
          title: 'Terms of Service',
          onTap: () {},
        ),
        SizedBox(height: 16),
        _buildSimpleTextItem(
          title: 'Privacy Policy',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSimpleTextItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textBody,
              ),
            ),
            Icon(
              AppIcons.arrowRight,
              size: 20,
              color: AppColors.textPlaceholder,
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // LOGOUT BUTTON (Updated with dialog and loading - FIXED Obx)
  // ════════════════════════════════════════════════════════════
  Widget _buildLogoutButton(ProfileSettingsController controller) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: TextButton.icon(
        onPressed: () {
          Get.defaultDialog(
            title: 'Logout',
            middleText: 'Are you sure you want to logout?',
            backgroundColor: Colors.white,
            radius: 14,
            titleStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeadline,
            ),
            middleTextStyle: TextStyle(
              fontSize: 14,
              color: AppColors.textBody,
            ),
            confirm: SizedBox(
              width: 120,
              height: 44,
              child: Obx(() => OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  side: BorderSide(color: Colors.red[400]!, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.zero,
                ),
                onPressed: controller.isLoggingOut.value
                    ? null
                    : () async {
                  await controller.logout();
                },
                child: controller.isLoggingOut.value
                    ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red[400]!),
                  ),
                )
                    : Text(
                  'Yes, Logout',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[400],
                  ),
                ),
              )),
            ),
            cancel: TextButton(
              onPressed: () => Get.back(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textBody,
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
        icon: Icon(
          AppIcons.logout,
          color: AppColors.deleteColor,
          size: 20,
        ),
        label: Text(
          'Log Out',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.deleteColor,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // DELETE ACCOUNT
  // ════════════════════════════════════════════════════════════
  Widget _buildDeleteAccount(ProfileSettingsController controller) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.deleteColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.deleteColor.withOpacity(0.2)),
      ),
      child: TextButton(
        onPressed: () => controller.deleteAccount(),   // ← triggers the full deletion flow
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.delete, color: AppColors.deleteColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Delete Account',
              style: TextStyle(fontSize: 15, color: AppColors.deleteColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ════════════════════════════════════════════════════════════
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textBody,
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.iconBgPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.primaryPurple,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHeadline,
                  ),
                ),
              ),
              SizedBox(width: 8),
              trailing ??
                  Icon(
                    AppIcons.arrowRight,
                    size: 20,
                    color: AppColors.textPlaceholder,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.dividerColor,
      indent: 68,
      endIndent: 20,
    );
  }
}
