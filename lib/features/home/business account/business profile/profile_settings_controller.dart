// lib/features/home/business account/profile settings/profile_settings_controller.dart

import 'package:bookify/app/custom_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../app/app_colors.dart';
import '../../../../services/shared_preferences_service.dart';
import '../../../../services/user_service.dart';
import '../../../login/login_screen.dart';

class ProfileSettingsController extends GetxController {
  final fullName = ''.obs;
  final email = ''.obs;
  final phoneNumber = ''.obs;
  final address = ''.obs;
  final city = ''.obs;
  final accountType = 'Business Account'.obs;
  final profileImageUrl = ''.obs;
  final appVersion = '1.0.0'.obs;
  final isLoggingOut = false.obs;
  final isLoading = false.obs;
  final isDeletingAccount = false.obs;

  String get initials {
    if (fullName.value.isEmpty) return 'B';
    final names = fullName.value.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return names[0].substring(0, 1).toUpperCase();
  }

  @override
  void onInit() {
    super.onInit();
    loadBusinessProfile();
  }

  Future<void> loadBusinessProfile() async {
    isLoading.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final businessProfile = await UserService.getBusinessProfile(user.uid);

        if (businessProfile != null) {
          fullName.value = businessProfile['businessName'] ?? 'Business Name';
          email.value = businessProfile['email'] ?? user.email ?? '';
          phoneNumber.value = businessProfile['phoneNumber'] ?? 'Not provided';
          address.value = businessProfile['address'] ?? 'Not provided';
          city.value = businessProfile['city'] ?? 'Not provided';
          profileImageUrl.value = businessProfile['profileImage'] ?? '';
        } else {
          final userData = await UserService.getUserData(user.uid);
          fullName.value = userData?['name'] ?? 'Business User';
          email.value = user.email ?? '';
          profileImageUrl.value = userData?['profileImage'] ?? '';
        }
      }
    } catch (e) {
      print('Error loading business profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? imageUrl,
  }) {
    if (name != null) fullName.value = name;
    if (email != null) this.email.value = email;
    if (phone != null) phoneNumber.value = phone;
    if (address != null) this.address.value = address;
    if (city != null) this.city.value = city;
    if (imageUrl != null) profileImageUrl.value = imageUrl;
  }

  Future<void> logout() async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': FieldValue.delete()});
        await FirebaseMessaging.instance.deleteToken();
      }

      await FirebaseAuth.instance.signOut();
      await SharedPreferencesService.clearLoginSession();
      AppSnackbar.success("Account Logged out Successfully", position: SnackPosition.BOTTOM);
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      print('Logout error: $e');
      AppSnackbar.error("Account logout unsuccessful", position: SnackPosition.BOTTOM);
      await SharedPreferencesService.clearLoginSession();
      Get.offAll(() => const LoginScreen());
    } finally {
      isLoggingOut.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // DELETE ACCOUNT – detects provider and uses correct flow
  // ─────────────────────────────────────────────────────────
  void deleteAccount() {
    Get.defaultDialog(
      title: 'Delete Account',
      middleText: 'Do you really want to delete your business account?',
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
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: BorderSide(color: Colors.red[400]!, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.zero,
          ),
          onPressed: () {
            Get.back(); // close confirmation
            _startDeletionBasedOnProvider();
          },
          child: Text(
            'Yes, Delete',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red[400]),
          ),
        ),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        style: TextButton.styleFrom(foregroundColor: AppColors.textBody),
        child: Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _startDeletionBasedOnProvider() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');

    if (isGoogle) {
      _performGoogleReauthAndDelete();
    } else {
      _showPasswordDialog();
    }
  }

  // ──────────────────────────────
  // GOOGLE RE-AUTH & DELETE (matches login_controller pattern)
  // ──────────────────────────────
  Future<void> _performGoogleReauthAndDelete() async {
    if (isDeletingAccount.value) return;
    isDeletingAccount.value = true;

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();                         // ✅ required for this version

      // authenticate() shows the Google sign‑in UI – the only way to get fresh tokens
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();

      if (googleUser == null) {
        AppSnackbar.error('Google sign‑in cancelled. Account not deleted.');
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
        barrierDismissible: false,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppSnackbar.error('No user signed in.');
        return;
      }

      // Re‑authenticate
      await user.reauthenticateWithCredential(credential);

      // Delete account and clean up Firestore
      await _deleteAccountAndCleanup(user);
    } on FirebaseAuthException catch (e) {
      print('Google re‑auth failed: ${e.message}');
      AppSnackbar.error('Re‑authentication failed. Please try again.');
    } catch (e) {
      print('Google deletion error: $e');
      AppSnackbar.error('An unexpected error occurred.');
    } finally {
      if (Get.isDialogOpen ?? false) Get.close(1);
      isDeletingAccount.value = false;
    }
  }

  // ──────────────────────────────
  // PASSWORD PROMPT (email/password)
  // ──────────────────────────────
  void _showPasswordDialog() {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: Text('Verify Your Identity'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Enter your password',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Get.back();
                _performPasswordBasedDeletion(passwordController.text.trim());
              }
            },
            child: Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  Future<void> _performPasswordBasedDeletion(String password) async {
    if (isDeletingAccount.value) return;
    isDeletingAccount.value = true;

    Get.dialog(
      const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
      barrierDismissible: false,
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppSnackbar.error('No user signed in.');
        return;
      }

      final String email = user.email ?? '';
      if (email.isEmpty) {
        AppSnackbar.error('No email associated with this account.');
        return;
      }

      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);

      await _deleteAccountAndCleanup(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        AppSnackbar.error('Incorrect password. Please try again.');
      } else {
        AppSnackbar.error('Re‑authentication failed: ${e.message}');
      }
    } catch (e) {
      print('Password deletion error: $e');
      AppSnackbar.error('An unexpected error occurred.');
    } finally {
      if (Get.isDialogOpen ?? false) Get.close(1);
      isDeletingAccount.value = false;
    }
  }

  // ──────────────────────────────
  // SHARED DELETE + CLEANUP
  // ──────────────────────────────
  Future<void> _deleteAccountAndCleanup(User user) async {
    final String uid = user.uid;
    final String? email = user.email;

    await user.delete();

    final futures = <Future<void>>[
      FirebaseFirestore.instance.collection('users').doc(uid).delete(),
      FirebaseFirestore.instance.collection('businesses').doc(uid).delete(),
    ];
    if (email != null && email.isNotEmpty) {
      futures.add(FirebaseFirestore.instance.collection('user_providers').doc(email).delete());
    }
    await Future.wait(futures);

    print('Account and Firestore data deleted for $uid');

    await SharedPreferencesService.clearLoginSession();
    AppSnackbar.success('Account deleted successfully');
    Get.offAll(() => const LoginScreen());
  }
}