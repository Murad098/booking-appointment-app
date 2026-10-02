import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import 'change_password_controller.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChangePasswordController());

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
          'Change Password',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isCheckingProvider.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryPurple,
            ),
          );
        }

        // If provider is Google, show restriction message
        if (controller.provider.value == 'google') {
          return _buildGoogleRestrictionMessage();
        }

        // Show password change form for email/password users
        return _buildChangePasswordForm(controller);
      }),
    );
  }

  Widget _buildGoogleRestrictionMessage() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.g_mobiledata,
                size: 40,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Account Type: Google Sign-In',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeadline,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This option is only available for Email & Password accounts.\n\nYour account is signed in with Google.\n\nTo change your password, please use Google Account Settings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textBody,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangePasswordForm(ChangePasswordController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryPurple.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryPurple,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Choose a strong password that you haven\'t used before.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textBody,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Current Password Field
          Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeadline,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.currentPasswordController,
                obscureText: controller.obscureCurrentPassword.value,
                decoration: InputDecoration(
                  hintText: 'Enter your current password',
                  hintStyle: TextStyle(
                    color: AppColors.textPlaceholder,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: AppColors.textPlaceholder,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscureCurrentPassword.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textPlaceholder,
                      size: 20,
                    ),
                    onPressed: () => controller.toggleCurrentPasswordVisibility(),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: controller.currentPasswordError.value.isNotEmpty
                          ? Colors.red
                          : AppColors.dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: controller.currentPasswordError.value.isNotEmpty
                          ? Colors.red
                          : AppColors.dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: controller.currentPasswordError.value.isNotEmpty
                          ? Colors.red
                          : AppColors.primaryPurple,
                      width: 2,
                    ),
                  ),
                  errorText: controller.currentPasswordError.value.isNotEmpty
                      ? controller.currentPasswordError.value
                      : null,
                  errorStyle: const TextStyle(fontSize: 12),
                ),
                onChanged: (value) {
                  if (controller.currentPasswordError.value.isNotEmpty) {
                    controller.currentPasswordError.value = '';
                  }
                },
              ),
            ],
          )),
          const SizedBox(height: 20),

          // New Password Field
          Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeadline,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.newPasswordController,
                obscureText: controller.obscureNewPassword.value,
                decoration: InputDecoration(
                  hintText: 'Enter new password',
                  hintStyle: TextStyle(
                    color: AppColors.textPlaceholder,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: AppColors.textPlaceholder,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscureNewPassword.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textPlaceholder,
                      size: 20,
                    ),
                    onPressed: () => controller.toggleNewPasswordVisibility(),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primaryPurple,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (controller.newPasswordError.value.isNotEmpty) {
                    controller.newPasswordError.value = '';
                  }
                  if (controller.confirmPasswordError.value.isNotEmpty) {
                    controller.confirmPasswordError.value = '';
                  }
                },
              ),
              if (controller.newPasswordError.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    controller.newPasswordError.value,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
            ],
          )),
          const SizedBox(height: 20),

          // Confirm New Password Field
          Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirm New Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeadline,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.confirmPasswordController,
                obscureText: controller.obscureConfirmPassword.value,
                decoration: InputDecoration(
                  hintText: 'Confirm your new password',
                  hintStyle: TextStyle(
                    color: AppColors.textPlaceholder,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: AppColors.textPlaceholder,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscureConfirmPassword.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textPlaceholder,
                      size: 20,
                    ),
                    onPressed: () => controller.toggleConfirmPasswordVisibility(),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primaryPurple,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (controller.confirmPasswordError.value.isNotEmpty) {
                    controller.confirmPasswordError.value = '';
                  }
                },
              ),
              if (controller.confirmPasswordError.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    controller.confirmPasswordError.value,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
            ],
          )),
          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Obx(() => ElevatedButton(
              onPressed: controller.isUpdating.value
                  ? null
                  : () => controller.changePassword(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: controller.isUpdating.value
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }
}