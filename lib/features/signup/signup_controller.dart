import 'package:bookify/app/custom_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/auth_provider_service.dart';
import '../../services/email_service.dart';
import '../../services/notification_service.dart';
import '../../services/user_service.dart';
import '../../services/shared_preferences_service.dart';
import '../account type/account_type_screen.dart';
import '../home/business account/business profile setup/business_profile_screen1.dart';
import '../home/business account/business_home_screen.dart';
import '../home/personal account/personal_home_screen.dart';
import '../home/Notifications screen/notifications_controller.dart';

class SignupController extends GetxController {
  // Form controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();

  // Observable variables
  final RxBool obscurePassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;
  final RxBool isSigningUp = false.obs;
  final RxBool isSigningUpWithGoogle = false.obs;

  // to store errors for each field
  final RxMap<String, String> fieldErrors = <String, String>{}.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void resetForm() {
    fullNameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    fieldErrors.clear();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  // Validate ALL fields
  bool validateForm() {
    fieldErrors.clear();
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (fullName.isEmpty) {
      fieldErrors['fullName'] = 'Full name is required';
    } else if (fullName.length < 2) {
      fieldErrors['fullName'] = 'Please enter your full name';
    }

    if (email.isEmpty) {
      fieldErrors['email'] = 'Email is required';
    } else if (!email.contains('@')) {
      fieldErrors['email'] = 'Please enter a valid email';
    }

    if (password.isEmpty) {
      fieldErrors['password'] = 'Password is required';
    } else if (password.length < 6) {
      fieldErrors['password'] = 'Password must be at least 6 characters';
    }

    if (confirmPassword.isEmpty) {
      fieldErrors['confirmPassword'] = 'Please confirm your password';
    } else if (password != confirmPassword) {
      fieldErrors['confirmPassword'] = 'Passwords do not match';
    }

    return fieldErrors.isEmpty;
  }

  void clearFieldError(String field) {
    if (fieldErrors.containsKey(field)) {
      fieldErrors.remove(field);
    }
  }

  // Helper method to redirect based on user role and business profile completion
  Future<void> _redirectBasedOnRole() async {
    final user = _auth.currentUser;
    if (user == null) return;

    print('[LoginController] Checking role for user: ${user.uid}');

    final role = await UserService.getUserRole(user.uid);
    print('[LoginController] Retrieved role: $role');

    // If role exists (not null and not empty), redirect based on role
    if (role != null && role.isNotEmpty) {
      if (role == 'business') {
        // Check if business profile is completed
        final isProfileCompleted = await UserService.isBusinessProfileCompleted(user.uid);
        print('[LoginController] Business profile completed: $isProfileCompleted');
        if (isProfileCompleted) {
          // Business profile exists - go to Business Home
          Get.offAll(
                () => BusinessHomeScreen(),
            binding: BindingsBuilder(() {
              Get.put(NotificationsController());
            }),
          );
        } else {
          // Business profile missing - show setup flow
          Get.offAll(
                () => BusinessProfileStep1(),
            binding: BindingsBuilder(() {
              Get.put(NotificationsController());
            }),
          );
        }
      } else if (role == 'personal') {
        Get.offAll(
              () => const PersonalHomeScreen(),
          binding: BindingsBuilder(() {
            Get.put(NotificationsController(), permanent: true);
          }),
        );
      } else {
        // Invalid role - show account type selection
        Get.offAll(() => AccountTypeScreen());
      }
    } else {
      // NO ROLE FOUND - first time user or role not set
      print('[LoginController] No role found, showing AccountTypeScreen');
      Get.offAll(() => AccountTypeScreen());
    }
  }

  // ====================== Email/Password Sign Up ======================
  Future<void> signUp() async {
    if (!validateForm()) {
      if (fieldErrors.isNotEmpty) {
        AppSnackbar.error('Please fix the errors below');
      }
      return;
    }

    isSigningUp.value = true;
    final email = emailController.text.trim();
    final fullName = fullNameController.text.trim();

    try {
      // 1. Create Auth User First
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: passwordController.text,
      );

      // 2. Update Display Name
      await _auth.currentUser?.updateDisplayName(fullName);

      // 3. ONLY AFTER SUCCESSFUL AUTH, save provider to Firestore
      await AuthProviderService.saveProvider(email, 'password');

      // 4. SAVE USER DATA TO FIRESTORE
      final String uid = userCredential.user?.uid ?? _auth.currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        await UserService.saveUserData(uid, fullName, email);
      }

      // Set user as logged in
      await SharedPreferencesService.setLoggedIn(true);

      await EmailService.queueWelcomeEmail(email, fullName);

      AppSnackbar.success('Account created successfully!',
          position: SnackPosition.BOTTOM);
      resetForm();
      await NotificationService().refreshTokenForCurrentUser();

      // Redirect based on role (new user has no role, so goes to AccountTypeScreen)
      await _redirectBasedOnRole();

    } on FirebaseAuthException catch (e) {
      String message = 'Sign up failed';
      if (e.code == 'email-already-in-use') {
        message = 'An account already exists with this email. Please log in.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else {
        message = e.message ?? 'Sign up failed';
      }
      AppSnackbar.error(message, position: SnackPosition.BOTTOM);
    } catch (e) {
      AppSnackbar.error('Something went wrong: $e',
          position: SnackPosition.BOTTOM);
    } finally {
      isSigningUp.value = false;
    }
  }

  // ====================== Google Sign Up ======================
  Future<void> signUpWithGoogle() async {
    isSigningUpWithGoogle.value = true;

    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();

      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) {
        return;
      }

      final String email = googleUser.email.toLowerCase().trim();
      final String fullName = googleUser.displayName ?? 'User';

      // ── STEP 1: Check stored provider BEFORE touching Firebase Auth ──
      final String? storedProvider =
      await AuthProviderService.getProvider(email);

      // Block if this email was registered with email/password
      if (storedProvider == 'password') {
        AppSnackbar.error(
          'An account already exists with this email using Email/Password. Please log in with your email and password.',
          position: SnackPosition.BOTTOM,
        );
        return;
      }

      // If it's already a known Google user, just log them in
      if (storedProvider == 'google') {
        // We can optionally redirect to login or handle here,
        // but usually SignUp screen should allow logging in existing users too.
        // Let's proceed to auth to get the session, then handle navigation.
      }

      // ── STEP 2: Sign in with Google credential ──
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      // ── STEP 3: Determine new vs returning Google user ──
      final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? true;

      // Logic:
      // 1. If storedProvider == 'google', it's existing.
      // 2. If storedProvider is null, check isNewUser.
      //    - If isNewUser is true -> Brand New.
      //    - If isNewUser is false -> Existing Auth user (maybe orphaned from Firestore). Treat as Existing/Login.

      final bool isExistingUser = (storedProvider == 'google') || !isNewUser;

      if (isExistingUser) {
        // ── Returning Google user ──
        // Account already exists → login successful

        // Heal Firestore if it was missing (isNewUser was false but storedProvider was null)
        if (storedProvider == null) {
          await AuthProviderService.saveProvider(email, 'google');
          // ALSO SAVE USER DATA IF MISSING
          final String uid = userCredential.user?.uid ?? _auth.currentUser?.uid ?? '';
          if (uid.isNotEmpty) {
            await UserService.saveUserData(uid, fullName, email);
          }
        }

        // Set user as logged in
        await SharedPreferencesService.setLoggedIn(true);

        AppSnackbar.success(
          'Login successful!',
          position: SnackPosition.BOTTOM,
        );
        resetForm();
        await NotificationService().refreshTokenForCurrentUser();

        // Redirect based on role
        await _redirectBasedOnRole();
        return;
      }

      // ── Brand-new Google account ──
      // ONLY NOW, after confirming it's a new user in Auth, we save to Firestore
      await AuthProviderService.saveProvider(email, 'google');

      // SAVE USER DATA TO FIRESTORE FOR NEW GOOGLE ACCOUNT
      final String uid = userCredential.user?.uid ?? _auth.currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        await UserService.saveUserData(uid, fullName, email);
      }

      // Set user as logged in
      await SharedPreferencesService.setLoggedIn(true);

      await EmailService.queueWelcomeEmail(email, fullName);

      // Show success and redirect based on role (new user has no role)
      AppSnackbar.success(
        'Account created successfully!',
        position: SnackPosition.BOTTOM,
      );
      resetForm();
      await NotificationService().refreshTokenForCurrentUser();

      // Redirect based on role
      await _redirectBasedOnRole();

    } on FirebaseAuthException catch (e) {
      String message = 'Google sign up failed';
      if (e.code == 'account-exists-with-different-credential') {
        message =
        'An account already exists with this email using Email/Password. Please log in with your email and password.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid credentials';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Google Sign-In is not enabled.';
      } else {
        message = e.message ?? 'Google sign up failed';
      }
      AppSnackbar.error(message, position: SnackPosition.BOTTOM);
    } catch (e) {
      AppSnackbar.error('Google sign up was cancelled or failed',
          position: SnackPosition.BOTTOM);
    } finally {
      isSigningUpWithGoogle.value = false;
    }
  }

  void navigateToSignIn() {
    fieldErrors.clear();
    Get.toNamed('/login');
  }

  void navigateBack() {
    fieldErrors.clear();
    Get.back();
  }

  @override
  void onInit() {
    super.onInit();
    fieldErrors.clear();
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}