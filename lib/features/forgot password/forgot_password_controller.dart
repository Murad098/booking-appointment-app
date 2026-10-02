import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/custom_snackbar.dart';
import '../../services/auth_provider_service.dart';

class ForgotPasswordController extends GetxController {
  final TextEditingController emailController = TextEditingController();

  // State variables
  final RxBool isLoading = false.obs;
  final RxMap<String, String?> fieldErrors = <String, String?>{}.obs;

  // Cooldown timer variables
  final RxBool isCooldown = false.obs;
  final RxInt cooldownSeconds = 60.obs;
  final RxBool isCheckingAccount = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Timer for cooldown
  Timer? _cooldownTimer;

  @override
  void onClose() {
    emailController.dispose();
    _cooldownTimer?.cancel();
    super.onClose();
  }

  // Clear specific field error
  void clearFieldError(String field) {
    if (fieldErrors.containsKey(field)) {
      fieldErrors[field] = null;
    }
  }

  // Start cooldown timer
  void _startCooldown() {
    isCooldown.value = true;
    cooldownSeconds.value = 60;

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (cooldownSeconds.value <= 1) {
        timer.cancel();
        isCooldown.value = false;
        cooldownSeconds.value = 60;
      } else {
        cooldownSeconds.value--;
      }
    });
  }

  // Validate Email
  bool _validateEmail() {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      fieldErrors['email'] = 'Email address is required';
      return false;
    }

    // email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      fieldErrors['email'] = 'Please enter a valid email address';
      return false;
    }

    fieldErrors['email'] = null;
    return true;
  }

  // Check if account exists in Firebase Auth using signInWithEmailAndPassword with a dummy password
  // This is a safe way to check without actually signing in
  Future<bool> _checkAccountExists(String email) async {
    try {
      // Try to sign in with a dummy password - this will throw user-not-found if account doesn't exist
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: 'dummy_password_for_check_123',
      );
      return true; // If successful, account exists (but this won't happen with dummy password)
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return false; // Account doesn't exist
      }
      // For other errors (wrong-password, etc.), account exists
      return true;
    } catch (e) {
      print('[ForgotPassword] Error checking account existence: $e');
      return false;
    }
  }

  // Handle Reset Password
  // DELETE the entire _checkAccountExists method — it is unreliable and unused after this fix.

  Future<void> resetPassword() async {
    if (!_validateEmail()) {
      print("Validation Failed");
      return;
    }

    if (isCooldown.value) {
      AppSnackbar.error(
        'Please wait ${cooldownSeconds.value} seconds before trying again.',
        position: SnackPosition.BOTTOM,
      );
      return;
    }

    print("Starting Reset Process...");
    isLoading.value = true;

    final email = emailController.text.trim().toLowerCase();

    try {
      // Step 1: Check provider from Firestore (source of truth)
      final provider = await AuthProviderService.getProvider(email);
      print('[ForgotPassword] Provider for $email: $provider');

      // Step 2: No Firestore record → account does not exist in our system
      if (provider == null) {
        fieldErrors['email'] = 'No account found for this email address';
        AppSnackbar.error(
          'No account found for this email address',
          position: SnackPosition.BOTTOM,
        );
        isLoading.value = false;
        return;
      }

      // Step 3: Google account → password reset not applicable
      if (provider == 'google') {
        fieldErrors['email'] =
        'This account is registered with Google. Password reset is not available.';
        AppSnackbar.error(
          'This account is registered with Google.',
          position: SnackPosition.BOTTOM,
        );
        isLoading.value = false;
        return;
      }

      // Step 4: Email/password account → attempt to send reset email
      if (provider == 'password') {
        // sendPasswordResetEmail will throw if Firebase itself rejects it
        // (e.g. user-not-found on older SDKs, malformed email, etc.)
        await _auth.sendPasswordResetEmail(email: email);

        // Only reaches here if Firebase confirmed the send
        AppSnackbar.success(
          'Password reset link sent! Please check your inbox/spam folder.',
          position: SnackPosition.BOTTOM,
        );

        _startCooldown();
        fieldErrors['email'] = null;

        await Future.delayed(const Duration(seconds: 2));
        if (Get.previousRoute.isNotEmpty) {
          Get.back();
        }
        return;
      }

      // Step 5: Unknown provider value stored in Firestore
      fieldErrors['email'] = 'Unable to process password reset for this account.';
      AppSnackbar.error(
        'Unable to process password reset. Please contact support.',
        position: SnackPosition.BOTTOM,
      );

    } on FirebaseAuthException catch (e) {
      print("[ForgotPassword] FirebaseAuthException: ${e.code}");

      switch (e.code) {
        case 'invalid-email':
          fieldErrors['email'] = 'Please enter a valid email address';
          AppSnackbar.error(
            'Invalid email address format',
            position: SnackPosition.BOTTOM,
          );
          break;
        case 'user-not-found':
        // Older Firebase SDK: throws this from sendPasswordResetEmail
          fieldErrors['email'] = 'No account found for this email address';
          AppSnackbar.error(
            'No account found with this email',
            position: SnackPosition.BOTTOM,
          );
          break;
        case 'too-many-requests':
          fieldErrors['email'] = 'Too many requests. Please try again later.';
          AppSnackbar.error(
            'Too many password reset attempts. Please wait a few minutes before trying again.',
            position: SnackPosition.BOTTOM,
          );
          break;
        case 'operation-not-allowed':
          fieldErrors['email'] =
          'Password reset is not enabled. Please contact support.';
          AppSnackbar.error(
            'Password reset is currently unavailable. Please contact support.',
            position: SnackPosition.BOTTOM,
          );
          break;
        default:
          fieldErrors['email'] = 'Failed to send reset link. Please try again.';
          AppSnackbar.error(
            e.message ?? 'Failed to send reset link. Please try again.',
            position: SnackPosition.BOTTOM,
          );
      }
    } catch (e) {
      print("Error occurred: $e");
      AppSnackbar.error(
        'Failed to send reset link. Please check your internet connection and try again.',
        position: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}