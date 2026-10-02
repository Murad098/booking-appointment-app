// lib/features/home/business account/branch management/branch_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:bookify/firebase_options.dart';
import '../../../../app/custom_snackbar.dart';
import '../../../../services/user_service.dart';
import '../../../../services/auth_provider_service.dart';
import 'branch_model.dart';

class BranchController extends GetxController {
  // State
  final RxList<Branch> branches = <Branch>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isDeleting = false.obs;

  // Form Inputs for Creation (Step 1)
  final branchName = ''.obs;
  final branchLocation = ''.obs;
  final RxList<String> selectedServices = <String>[].obs;

  // Available Services Options (optional)
  final List<String> availableServices = [
    'Haircut', 'Beard Trim', 'Facial', 'Massage', 'Manicure', 'Pedicure'
  ];

  // Registration Inputs (Step 2)
  final regEmail = ''.obs;
  final regPassword = ''.obs;
  final regConfirmPassword = ''.obs;

  // Error States
  final RxBool showRegErrors = false.obs;
  final RxString regError = ''.obs;

  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _branchesSubscription;

  @override
  void onInit() {
    super.onInit();
    _resetForm();
    _fetchBranches();
  }

  @override
  void onClose() {
    _branchesSubscription?.cancel();
    super.onClose();
  }

  void _resetForm() {
    branchName.value = '';
    branchLocation.value = '';
    selectedServices.clear();
    regEmail.value = '';
    regPassword.value = '';
    regConfirmPassword.value = '';
    showRegErrors.value = false;
    regError.value = '';
  }

  // ------------------------------------------------------------------
  // Fetch branches from Firestore for the current business user
  // ------------------------------------------------------------------
  void _fetchBranches() {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading.value = true;

    _branchesSubscription?.cancel();
    _branchesSubscription = _firestore
        .collection('branches')
        .where('businessId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      final List<Branch> fetched = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        fetched.add(Branch.fromMap(data, doc.id));
      }
      branches.assignAll(fetched);
      isLoading.value = false;
    }, onError: (e) {
      print('Error fetching branches: $e');
      isLoading.value = false;
      AppSnackbar.error('Failed to load branches');
    });
  }

  // ------------------------------------------------------------------
  // Toggle service selection (optional)
  // ------------------------------------------------------------------
  void toggleService(String service) {
    if (selectedServices.contains(service)) {
      selectedServices.remove(service);
    } else {
      selectedServices.add(service);
    }
  }

  // ------------------------------------------------------------------
  // Validate Step 1
  // ------------------------------------------------------------------
  bool validateBranchForm() {
    return branchName.value.isNotEmpty && branchLocation.value.isNotEmpty;
  }

  // ------------------------------------------------------------------
  // CREATE BRANCH (new user via REST API + branch document)
  // ------------------------------------------------------------------
  Future<void> createBranch() async {
    showRegErrors.value = true;
    regError.value = '';

    // --- Validate email ---
    final email = regEmail.value.trim();
    if (email.isEmpty) {
      regError.value = 'Email is required.';
      _showErrorSnackbar(regError.value);
      return;
    }
    if (!GetUtils.isEmail(email)) {
      regError.value = 'Please enter a valid email address.';
      _showErrorSnackbar(regError.value);
      return;
    }

    // --- Validate password ---
    if (regPassword.value.length < 6) {
      regError.value = 'Password must be at least 6 characters.';
      _showErrorSnackbar(regError.value);
      return;
    }

    if (regPassword.value != regConfirmPassword.value) {
      regError.value = 'Passwords do not match.';
      _showErrorSnackbar(regError.value);
      return;
    }

    // --- Validate branch name and location ---
    if (!validateBranchForm()) {
      AppSnackbar.error('Please fill in Branch Name and Location.');
      return;
    }

    try {
      isLoading.value = true;

      // 1. Create Firebase Auth user via REST API (no auto-sign-in)
      final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
      final url = Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey');
      final response = await http.post(
        url,
        body: jsonEncode({
          'email': email,
          'password': regPassword.value,
          'returnSecureToken': true,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'Unknown error';
        String userFriendlyMessage;
        switch (errorMessage) {
          case 'EMAIL_EXISTS':
            userFriendlyMessage =
            'This email is already registered. Please use a different email.';
            break;
          case 'WEAK_PASSWORD : Password should be at least 6 characters':
            userFriendlyMessage = 'Password is too weak.';
            break;
          default:
            userFriendlyMessage = errorMessage;
        }
        regError.value = userFriendlyMessage;
        _showErrorSnackbar(userFriendlyMessage);
        return;
      }

      final data = jsonDecode(response.body);
      final branchManagerUid = data['localId'] as String;

      // 2. Save user data for branch manager (like a normal sign-up)
      await AuthProviderService.saveProvider(email, 'password');
      await UserService.saveUserData(branchManagerUid, 'Branch Manager', email);
      await UserService.saveUserRole(branchManagerUid, 'business');
      await UserService.setBranchStatus(branchManagerUid, true);

      // 3. Create branch document in Firestore (for the business user)
      //    NOTE: branchManagerPassword is stored here so we can delete
      //    the Firebase Auth account via REST API later (no Cloud Function needed).
      //    Lock this document with Firestore Security Rules so only the
      //    business owner (businessId == request.auth.uid) can read it.
      final currentUser = _auth.currentUser!;
      final branchData = {
        'businessId': currentUser.uid,
        'branchManagerId': branchManagerUid,
        'branchManagerEmail': email,
        'branchManagerPassword': regPassword.value, // ← required for REST-based Auth deletion
        'name': branchName.value.trim(),
        'location': branchLocation.value.trim(),
        'services': List.from(selectedServices),
        'imageUrl':
        'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=200&q=80',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('branches').add(branchData);

      // 4. Reset form and show success
      _resetForm();
      AppSnackbar.success('Branch created successfully!');
      Get.offNamed('/branch-list');

    } catch (e) {
      regError.value = 'An unexpected error occurred.';
      _showErrorSnackbar(regError.value);
      print('Branch creation error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _showErrorSnackbar(String message) {
    AppSnackbar.error(message, position: SnackPosition.BOTTOM);
  }

  // ------------------------------------------------------------------
  // DELETE FIREBASE AUTH USER via REST API
  // Steps:
  //   1. Sign in as the branch manager via REST API to obtain their idToken.
  //   2. Use that idToken to call the deleteAccount REST endpoint.
  //   3. The current business user session is NEVER touched — all HTTP only.
  // This requires the branch manager's plain-text password to be stored
  // at branch creation time (see 'branchManagerPassword' field in Firestore).
  // ------------------------------------------------------------------
  Future<bool> _deleteAuthUserViaRestApi({
    required String email,
    required String password,
  }) async {
    final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;

    try {
      // Step A: Sign in to get the idToken for this branch manager account
      final signInUrl = Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey');

      final signInResponse = await http.post(
        signInUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      if (signInResponse.statusCode != 200) {
        final err = jsonDecode(signInResponse.body);
        print('REST sign-in failed: ${err['error']['message']}');
        return false;
      }

      final signInData = jsonDecode(signInResponse.body);
      final idToken = signInData['idToken'] as String;

      // Step B: Delete the account using the idToken
      final deleteUrl = Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$apiKey');

      final deleteResponse = await http.post(
        deleteUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (deleteResponse.statusCode != 200) {
        final err = jsonDecode(deleteResponse.body);
        print('REST delete failed: ${err['error']['message']}');
        return false;
      }

      print('Firebase Auth user ($email) deleted via REST API successfully.');
      return true;

    } catch (e) {
      print('_deleteAuthUserViaRestApi error: $e');
      return false;
    }
  }

  // ------------------------------------------------------------------
  // DELETE BRANCH – complete cleanup including Firebase Auth user
  // ------------------------------------------------------------------
  Future<void> deleteBranch(String branchId) async {
    final branch = branches.firstWhereOrNull((b) => b.id == branchId);
    if (branch == null) {
      AppSnackbar.error('Branch not found');
      return;
    }

    isDeleting.value = true;
    try {
      final managerId = branch.branchManagerId;
      final managerEmail = branch.branchManagerEmail;

      // ----------------------------------------------------------------
      // 1. Fetch the stored branch manager password from Firestore.
      //    Saved as 'branchManagerPassword' at creation time.
      //    Legacy branches created before this fix won't have this field.
      // ----------------------------------------------------------------
      String managerPassword = '';
      final branchDoc =
      await _firestore.collection('branches').doc(branchId).get();
      managerPassword =
          (branchDoc.data()?['branchManagerPassword'] as String?) ?? '';

      // ----------------------------------------------------------------
      // 2. Delete the Firebase Auth user via REST API (no session impact)
      // ----------------------------------------------------------------
      if (managerEmail.isNotEmpty && managerPassword.isNotEmpty) {
        final authDeleted = await _deleteAuthUserViaRestApi(
          email: managerEmail,
          password: managerPassword,
        );
        if (authDeleted) {
          print('Auth user ($managerEmail) deleted from Firebase Authentication.');
        } else {
          // Auth deletion failed but we still clean up Firestore.
          // This can happen if the password was changed after creation.
          print(
              'Warning: Auth user could not be deleted via REST. '
                  'Firestore cleanup will still proceed. '
                  'You may need to manually remove the Auth user from the Firebase console.');
        }
      } else {
        // Legacy branch — no password stored. Firestore cleanup still runs.
        // The orphaned Auth account will need manual removal from Firebase console.
        print(
            'Warning: No stored password for this branch manager '
                '(branchId: $branchId, email: $managerEmail). '
                'Skipping Auth deletion — remove the Auth user manually in the Firebase console. '
                'New branches created after this update will delete Auth automatically.');
      }

      // ----------------------------------------------------------------
      // 3. Delete the user document from 'users' collection
      // ----------------------------------------------------------------
      if (managerId.isNotEmpty) {
        await _firestore.collection('users').doc(managerId).delete();
        print('Deleted users document for $managerId');
      }

      // ----------------------------------------------------------------
      // 4. Delete the business document from 'businesses' collection
      // ----------------------------------------------------------------
      if (managerId.isNotEmpty) {
        await _firestore.collection('businesses').doc(managerId).delete();
        print('Deleted business document for $managerId');
      }

      // ----------------------------------------------------------------
      // 5. Delete the user provider record from 'user_providers'
      // ----------------------------------------------------------------
      if (managerEmail.isNotEmpty) {
        await _firestore.collection('user_providers').doc(managerEmail).delete();
        print('Deleted user_providers record for $managerEmail');
      }

      // ----------------------------------------------------------------
      // 6. Delete the branch document itself
      // ----------------------------------------------------------------
      await _firestore.collection('branches').doc(branchId).delete();
      print('Deleted branch document $branchId');

      AppSnackbar.success('Branch deleted successfully');

      // Force a refresh just in case the stream doesn't update instantly
      _fetchBranches();

    } catch (e) {
      print('Error during branch deletion: $e');
      AppSnackbar.error('Failed to delete branch: $e');
    } finally {
      isDeleting.value = false;
    }
  }

  // ------------------------------------------------------------------
  // (Optional) refresh branches manually
  // ------------------------------------------------------------------
  void refreshBranches() {
    _fetchBranches();
  }
}