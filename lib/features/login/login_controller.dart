// lib/features/login/login_controller.dart
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
import '../Auth/auth_controller.dart';
import '../account type/account_type_screen.dart';
import '../home/business account/business profile setup/business_profile_screen1.dart';
import '../home/business account/business_home_screen.dart';
import '../home/personal account/personal_home_screen.dart';
import '../home/Notifications screen/notifications_controller.dart';

class LoginController extends GetxController {
  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Observable state variables
  final RxBool obscurePassword = true.obs;
  final RxBool isSigningIn = false.obs;
  final RxBool isSigningInWithGoogle = false.obs;

  // to store errors for each field
  final RxMap<String, String> fieldErrors = <String, String>{}.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void resetForm() {
    emailController.clear();
    passwordController.clear();
    fieldErrors.clear();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  // Validate ALL fields
  bool validateForm() {
    fieldErrors.clear();

    final email = emailController.text.trim();
    final password = passwordController.text;

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

    // 1. Check if the user is a branch manager and store in AuthController
    final bool isBranch = await UserService.isBranchUser(user.uid);
    final authController = Get.find<AuthController>();
    authController.setBranchUser(isBranch);
    print('[LoginController] isBranchUser: $isBranch');

    // 2. Get the user's role (this will fallback to 'business' if they are in branches collection)
    final role = await UserService.getUserRole(user.uid);
    print('[LoginController] Retrieved role: $role');

    // 3. Redirect based on role (all 'business' users, including branch managers, go through profile check)
    if (role != null && role.isNotEmpty) {
      if (role == 'business') {
        // Check if business profile is completed
        final isProfileCompleted = await UserService.isBusinessProfileCompleted(user.uid);
        print('[LoginController] Business profile completed: $isProfileCompleted');
        if (isProfileCompleted) {
          Get.offAll(
                () => BusinessHomeScreen(),
            binding: BindingsBuilder(() {
              Get.put(NotificationsController());
            }),
          );
        } else {
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
        Get.offAll(() => AccountTypeScreen());
      }
    } else {
      Get.offAll(() => AccountTypeScreen());
    }
  }

  // Handle Email/Password Sign In
  Future<void> signIn() async {
    if (!validateForm()) {
      if (fieldErrors.isNotEmpty) {
        AppSnackbar.error('Please fix the errors below');
      }
      return;
    }

    isSigningIn.value = true;
    final email = emailController.text.trim();

    try {
      // PRE-CHECK: block Google accounts from using email/password login
      final String? storedProvider =
      await AuthProviderService.getProvider(email);

      if (storedProvider == 'google') {
        AppSnackbar.error(
          'This account was created with Google. Please log in using the "Continue with Google" button.',
          position: SnackPosition.BOTTOM,
        );
        return;
      }

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: passwordController.text,
      );

      // Set user as logged in
      await SharedPreferencesService.setLoggedIn(true);

      AppSnackbar.success('Login Successful', position: SnackPosition.BOTTOM);
      resetForm();

      await NotificationService().refreshTokenForCurrentUser();

      // Redirect based on role
      await _redirectBasedOnRole();

    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No account found with this email. Please sign up.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled';
      } else {
        message = e.message ?? 'Login failed';
      }
      AppSnackbar.error(message, position: SnackPosition.BOTTOM);
    } catch (e) {
      AppSnackbar.error('Login failed: $e', position: SnackPosition.BOTTOM);
    } finally {
      isSigningIn.value = false;
    }
  }

  // Handle Google Sign In
  Future<void> signInWithGoogle() async {
    isSigningInWithGoogle.value = true;

    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();

      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) {
        return;
      }

      final String email = googleUser.email.toLowerCase().trim();
      final String fullName = googleUser.displayName ?? 'User';

      // PRE-CHECK: read stored provider BEFORE touching Firebase Auth
      final String? storedProvider =
      await AuthProviderService.getProvider(email);

      // Block email/password accounts from using Google login
      if (storedProvider == 'password') {
        AppSnackbar.error(
          'This account was created with Email/Password. Please log in with your email and password.',
          position: SnackPosition.BOTTOM,
        );
        return;
      }

      // Proceed with Google credential
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      // ── Determine new vs returning Google user ──
      final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? true;

      // If we have a stored provider 'google', it's definitely existing.
      // If storedProvider is null, we rely on isNewUser.
      final bool isExistingUser = (storedProvider == 'google') || !isNewUser;

      if (isExistingUser) {
        // ── Returning Google user: genuine login ──
        // Heal Firestore record if it was missing (edge case)
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

        AppSnackbar.success('Login Successful', position: SnackPosition.BOTTOM);
        resetForm();

        await NotificationService().refreshTokenForCurrentUser();

        // Redirect based on role
        await _redirectBasedOnRole();
        return;
      }

      // ── Brand-new Google account used on the LOGIN page ──
      // Firebase Auth created the account automatically via signInWithCredential.
      await AuthProviderService.saveProvider(email, 'google');

      // SAVE USER DATA TO FIRESTORE FOR NEW GOOGLE ACCOUNT
      final String uid = userCredential.user?.uid ?? _auth.currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        await UserService.saveUserData(uid, fullName, email);
      }

      // Set user as logged in for new account too
      await SharedPreferencesService.setLoggedIn(true);

      await EmailService.queueWelcomeEmail(email, fullName);

      AppSnackbar.success(
        'Account created successfully!',
        position: SnackPosition.BOTTOM,
      );
      resetForm();
      await NotificationService().refreshTokenForCurrentUser();

      // Redirect based on role (new user has no role)
      await _redirectBasedOnRole();

    } on FirebaseAuthException catch (e) {
      String message = 'Google sign in failed';
      if (e.code == 'account-exists-with-different-credential') {
        message =
        'An account already exists with this email using Email/Password. Please log in with your email and password.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid credentials';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled';
      } else {
        message = e.message ?? 'Google sign in failed';
      }
      AppSnackbar.error(message, position: SnackPosition.BOTTOM);
    } catch (e) {
      AppSnackbar.error(
          'Google sign in failed: $e', position: SnackPosition.BOTTOM);
    } finally {
      isSigningInWithGoogle.value = false;
    }
  }

  void navigateToSignUp() {
    fieldErrors.clear();
    Get.toNamed('/signup');
  }

  void navigateBack() {
    fieldErrors.clear();
    Get.back();
  }

  @override
  void onInit() {
    super.onInit();
    // Do NOT clear fieldErrors here – it’s already empty and triggers build errors.
    // Ensure AuthController is registered permanently
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}