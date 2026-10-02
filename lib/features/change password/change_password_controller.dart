import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/custom_snackbar.dart';
import '../../../../services/auth_provider_service.dart';
import '../../../../services/email_service.dart';   // 🔥 ADDED: import EmailService

class ChangePasswordController extends GetxController {
  // Text controllers
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Observable states
  final obscureCurrentPassword = true.obs;
  final obscureNewPassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final isUpdating = false.obs;
  final isCheckingProvider = true.obs;
  final provider = ''.obs;

  // Error messages
  final currentPasswordError = ''.obs;
  final newPasswordError = ''.obs;
  final confirmPasswordError = ''.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    _checkAuthProvider();
  }

  Future<void> _checkAuthProvider() async {
    isCheckingProvider.value = true;
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        final authProvider = await AuthProviderService.getProvider(user.email!);
        provider.value = authProvider ?? 'unknown';
        print('[ChangePassword] Auth provider: ${provider.value}');
      } else {
        provider.value = 'unknown';
      }
    } catch (e) {
      print('[ChangePassword] Error checking provider: $e');
      provider.value = 'unknown';
    } finally {
      isCheckingProvider.value = false;
    }
  }

  void toggleCurrentPasswordVisibility() {
    obscureCurrentPassword.value = !obscureCurrentPassword.value;
  }

  void toggleNewPasswordVisibility() {
    obscureNewPassword.value = !obscureNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  bool _validateForm() {
    bool isValid = true;

    // Reset errors
    currentPasswordError.value = '';
    newPasswordError.value = '';
    confirmPasswordError.value = '';

    // Validate current password
    if (currentPasswordController.text.trim().isEmpty) {
      currentPasswordError.value = 'Current password is required';
      isValid = false;
    }

    // Validate new password
    final newPassword = newPasswordController.text;
    if (newPassword.isEmpty) {
      newPasswordError.value = 'New password is required';
      isValid = false;
    } else if (newPassword.length < 6) {
      newPasswordError.value = 'Password must be at least 6 characters';
      isValid = false;
    }

    // Validate confirm password
    final confirmPassword = confirmPasswordController.text;
    if (confirmPassword.isEmpty) {
      confirmPasswordError.value = 'Please confirm your new password';
      isValid = false;
    } else if (newPassword != confirmPassword) {
      confirmPasswordError.value = 'Passwords do not match';
      isValid = false;
    }

    return isValid;
  }

  Future<void> changePassword() async {
    if (!_validateForm()) {
      return;
    }

    isUpdating.value = true;

    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppSnackbar.error('User not logged in');
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text.trim(),
      );

      // Re-authenticate user to verify current password
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPasswordController.text.trim());

      // 🔥 ADDED: Send password‑changed confirmation email (non‑blocking)
      final String userEmail = user.email!;
      final String userName = user.displayName ?? userEmail.split('@')[0];
      EmailService.queuePasswordChangedEmail(userEmail, userName);

      // Clear form
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      currentPasswordError.value = '';
      newPasswordError.value = '';
      confirmPasswordError.value = '';

      AppSnackbar.success(
        'Password changed successfully!',
        position: SnackPosition.BOTTOM,
      );

      // Go back after successful change
      Future.delayed(const Duration(milliseconds: 1500), () {
        Get.back();
      });

    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        currentPasswordError.value = 'Incorrect password';
        AppSnackbar.error('Incorrect current password');
      } else if (e.code == 'weak-password') {
        newPasswordError.value = 'Password is too weak. Please choose a stronger password.';
        AppSnackbar.error('Password is too weak');
      } else if (e.code == 'requires-recent-login') {
        AppSnackbar.error(
          'For security reasons, please log out and log in again to change your password.',
          position: SnackPosition.BOTTOM,
        );
      } else {
        AppSnackbar.error(e.message ?? 'Failed to change password');
      }
    } catch (e) {
      AppSnackbar.error('Failed to change password: $e');
    } finally {
      isUpdating.value = false;
    }
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}