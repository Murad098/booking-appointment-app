import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_settings_controller.dart';
import '../../../../app/app_colors.dart'; // Adjust path as needed

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppSettingsController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textHeadline,
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        // Show loading indicator while fetching data
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading settings...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ),
          );
        }

        // Show actual content only after data is loaded
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Section 1: Communication Methods ---
              _buildSectionTitle('Communication Methods'),
              _buildCard(
                children: [
                  Obx(() => _buildSwitchTile(
                    icon: Icons.email_outlined,
                    iconColor: Colors.purple,
                    title: 'Email Notifications',
                    subtitle: 'Get updates in your inbox',
                    value: controller.isEmailEnabled.value,
                    onChanged: controller.toggleEmail,
                  )),
                  const Divider(height: 1),
                  Obx(() => _buildSwitchTile(
                    icon: Icons.notifications_none_outlined,
                    iconColor: AppColors.primaryPurple,
                    title: 'Push Notifications',
                    subtitle: 'Receive push alerts on your device',
                    value: controller.isPushEnabled.value,
                    onChanged: controller.togglePush,
                  )),
                ],
              ),

              const SizedBox(height: 24),

              // --- Section 2: Language & Region ---
              _buildSectionTitle('Language & Region'),
              _buildCard(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.language, size: 20, color: Colors.green),
                    ),
                    title: Text(
                      'Language',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHeadline,
                      ),
                    ),
                    subtitle: Obx(() => Text(
                      controller.currentLanguage.value,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textBody,
                      ),
                    )),
                    trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    onTap: () {
                      // Implement language selection logic here
                      Get.snackbar('Info', 'Language selection coming soon');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- Footer Info ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E7FF)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: AppColors.primaryPurple),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Your Experience',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textHeadline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your preferences are saved automatically. You can change them anytime.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textBody,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textBody.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textHeadline,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textBody,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryPurple,
      ),
    );
  }
}