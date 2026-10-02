import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_icons.dart';
import '../../../services/user_service.dart';
import '../../change password/change_password_screen.dart';
import '../Notifications screen/notifications_controller.dart';
import '../Notifications screen/notifications_screen.dart';
import '../app settings/app_settings_screen.dart';
import '../edit profile/edit_profile_screen.dart';
import '../hep center/help_center_screen.dart';
import '../privacy policy/privacy_policy_screen.dart';
import 'my appointment screen/my_appointments_screen.dart';
import 'personal_home_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PersonalHomeController>();
    final profileController = Get.put(ProfileDataController());
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final double horizontalPadding = isTablet ? 24 : 16;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Obx(() {
          if (profileController.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryPurple,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => profileController.loadUserProfile(),
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              children: [
                const SizedBox(height: 16),

                _buildProfileHeader(profileController),

                const SizedBox(height: 24),

                _buildSectionTitle('Account'),
                const SizedBox(height: 12),
                _buildProfileItem(
                  icon: AppIcons.drawerProfile,
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  onTap: () async {
                    final result = await Get.to(() => const EditProfileScreen());
                    if (result == true) {
                      await profileController.loadUserProfile();
                    }
                  },
                ),
                _buildProfileItem(
                  icon: AppIcons.drawerAppointments,
                  title: 'My Appointments',
                  subtitle: 'View and manage your bookings',
                  onTap: () {
                    Get.to(() => const MyAppointmentsScreen(
                      showAppBar: true,
                    ));
                  },
                ),
                _buildProfileItem(
                  icon: AppIcons.drawerNotifications,
                  title: 'Notifications',
                  subtitle: 'Manage your alerts and preferences',
                  onTap: () {
                    Get.to(() => const NotificationsScreen(
                      initialRole: UserRole.personal,
                    ));
                  },
                ),
                _buildProfileItem(
                  icon: AppIcons.password,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: () {
                    Get.to(() =>const ChangePasswordScreen());
                  },
                ),
                _buildProfileItem(
                  icon: AppIcons.drawerSettings,
                  title: 'Settings',
                  subtitle: 'App preferences and configurations',
                  onTap: () {
                    Get.to(() => const AppSettingsScreen());
                  },
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('Support'),
                const SizedBox(height: 12),
                _buildProfileItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get assistance or contact us',
                  onTap: () {
                    Get.to(() => const HelpCenterScreen());
                  },
                ),
                _buildProfileItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy practices',
                  onTap: () {
                    Get.to(() => const PrivacyPolicyScreen());
                  },
                ),


                const SizedBox(height: 32),

                _buildLogoutButton(controller),

                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProfileHeader(ProfileDataController controller) {
    return Obx(() {
      final hasImage = controller.profileImageUrl.value.isNotEmpty &&
          controller.profileImageUrl.value.startsWith('http');

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primaryPurple,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              ),
              child: ClipOval(
                child: hasImage
                    ? Image.network(
                  controller.profileImageUrl.value,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        controller.initials,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                )
                    : Center(
                  child: Text(
                    controller.initials,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.email.value,
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
      );
    });
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textHeadline,
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryPurple, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textHeadline,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textBody.withOpacity(0.8),
          ),
        ),
        trailing: Icon(
          AppIcons.arrowRight,
          color: AppColors.textPlaceholder,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(PersonalHomeController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(AppIcons.drawerLogout, color: Colors.red[400], size: 22),
        title: const Text(
          "Logout",
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          "Sign out from your account",
          style: TextStyle(
            fontSize: 12,
            color: Colors.red[400]?.withOpacity(0.9),
          ),
        ),
        trailing: Icon(
          AppIcons.arrowRight,
          color: Colors.red[300],
          size: 18,
        ),
        onTap: () {
          Get.defaultDialog(
            title: "Logout",
            middleText: "Are you sure you want to logout?",
            confirm: Obx(() => SizedBox(
              width: 120,
              height: 44,
              child: OutlinedButton(
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
              ),
            )),
            cancel: TextButton(
              onPressed: () => Get.back(),
              child: const Text("Cancel"),
            ),
          );
        },
      ),
    );
  }
}

class ProfileDataController extends GetxController {
  final fullName = ''.obs;
  final email = ''.obs;
  final profileImageUrl = ''.obs;
  final isLoading = false.obs;

  String get initials {
    if (fullName.value.isEmpty) return 'U';
    final names = fullName.value.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return names[0].substring(0, 1).toUpperCase();
  }

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    isLoading.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final role = await UserService.getUserRole(user.uid);

      if (role == 'business') {
        final businessProfile = await UserService.getBusinessProfile(user.uid);
        if (businessProfile != null) {
          fullName.value = businessProfile['businessName'] ?? 'Business Name';
          email.value = businessProfile['email'] ?? user.email ?? '';
          profileImageUrl.value = businessProfile['profileImage'] ?? '';
        }
      } else {
        final userData = await UserService.getUserData(user.uid);
        if (userData != null) {
          fullName.value = userData['name'] ?? 'User';
          email.value = userData['email'] ?? user.email ?? '';
          profileImageUrl.value = userData['profileImage'] ?? '';
        } else {
          fullName.value = user.displayName ?? 'User';
          email.value = user.email ?? '';
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      isLoading.value = false;
    }
  }
}