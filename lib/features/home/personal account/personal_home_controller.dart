import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/custom_snackbar.dart';
import '../../../services/shared_preferences_service.dart';
import '../../login/login_screen.dart';

class PersonalHomeController extends GetxController {
  // ════════════════════════════════════════════════════════════
  // SEARCH & FILTERS
  // ════════════════════════════════════════════════════════════
  final searchQuery = ''.obs;
  final isSearching = false.obs;
  final appliedCategoryId = 'all'.obs;
  final appliedCityQuery = ''.obs;
  final tempSelectedCategoryId = 'all'.obs;
  final tempCityQuery = ''.obs;
  final selectedCategoryId = 'all'.obs;
  final filteredBusinesses = <Map<String, dynamic>>[].obs;
  final allBusinesses = <Map<String, dynamic>>[].obs;
  final allCategories = <CategoryData>[].obs;

  // ════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION STATE (Persistent)
  // ════════════════════════════════════════════════════════════
  final bottomNavIndex = 0.obs;

  // ════════════════════════════════════════════════════════════
  // LOGOUT LOADING STATE
  // ════════════════════════════════════════════════════════════
  final isLoggingOut = false.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    initCategories();
    loadAllBusinesses();
  }

  void initCategories() {
    allCategories.assignAll([
      CategoryData(id: 'all', name: 'All', icon: Icons.apps),
      CategoryData(id: 'Beauty & Wellness', name: 'Beauty & Wellness', icon: Icons.spa),
      CategoryData(id: 'Health & Fitness', name: 'Health & Fitness', icon: Icons.fitness_center),
      CategoryData(id: 'Food & Dining', name: 'Food & Dining', icon: Icons.restaurant),
      CategoryData(id: 'Automotive', name: 'Automotive', icon: Icons.car_repair),
      CategoryData(id: 'Home Services', name: 'Home Services', icon: Icons.home_repair_service),
      CategoryData(id: 'Professional Services', name: 'Professional Services', icon: Icons.business_center),
      CategoryData(id: 'Retail', name: 'Retail', icon: Icons.shopping_bag),
      CategoryData(id: 'Education', name: 'Education', icon: Icons.school),
      CategoryData(id: 'Entertainment', name: 'Entertainment', icon: Icons.movie),
      CategoryData(id: 'Other', name: 'Other', icon: Icons.more_horiz),
    ]);
  }

  Future<void> loadAllBusinesses() async {
    isLoading.value = true;
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .where('isActive', isEqualTo: true)
          .get();

      final businesses = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['businessName'] ?? '',
          'category': data['category'] ?? '',
          'description': data['description'] ?? '',
          'city': data['city'] ?? '',
          'address': data['address'] ?? '',
          'phoneNumber': data['phoneNumber'] ?? '',
          'email': data['email'] ?? '',
          'profileImage': data['profileImage'] ?? '',
        };
      }).toList();

      allBusinesses.value = businesses;
      _applyFilters();
    } catch (e) {
      print('Error loading businesses: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION HANDLER
  // ════════════════════════════════════════════════════════════
  void onBottomNavTapped(int index) {
    bottomNavIndex.value = index;

    if (index != 1) {
      if (searchQuery.value.isEmpty) {
        isSearching.value = false;
      }
    } else {
      isSearching.value = searchQuery.value.isNotEmpty;
    }
  }

  // ════════════════════════════════════════════════════════════
  // SEARCH FUNCTIONALITY
  // ════════════════════════════════════════════════════════════
  void onSearchChanged(String query) {
    searchQuery.value = query.trim();
    isSearching.value = searchQuery.value.isNotEmpty;
    _applyFilters();
  }

  void applyFiltersDirect({
    required String categoryId,
    required String city,
  }) {
    appliedCategoryId.value = categoryId;
    appliedCityQuery.value = city.trim().toLowerCase();
    isSearching.value = true;
    _applyFilters();
  }

  void onCategorySelected(String id) {
    selectedCategoryId.value = id;
    appliedCategoryId.value = id;
    tempSelectedCategoryId.value = id;
    searchQuery.value = '';
    isSearching.value = false;
    _applyFilters();
  }

  // ════════════════════════════════════════════════════════════
  // FILTER SHEET METHODS
  // ════════════════════════════════════════════════════════════
  void updateTempCategory(String id) => tempSelectedCategoryId.value = id;
  void updateTempCity(String query) => tempCityQuery.value = query.trim();

  void applyFilters() {
    appliedCategoryId.value = tempSelectedCategoryId.value;
    appliedCityQuery.value = tempCityQuery.value;
    selectedCategoryId.value = appliedCategoryId.value;
    _applyFilters();
  }

  void clearFilters() {
    searchQuery.value = '';
    isSearching.value = false;
    selectedCategoryId.value = 'all';
    appliedCategoryId.value = 'all';
    appliedCityQuery.value = '';
    tempSelectedCategoryId.value = 'all';
    tempCityQuery.value = '';
    _applyFilters();
  }

  // ════════════════════════════════════════════════════════════
  // CORE FILTERING LOGIC
  // ════════════════════════════════════════════════════════════
  void _applyFilters() {
    var results = List<Map<String, dynamic>>.from(allBusinesses);

    if (appliedCategoryId.value != 'all') {
      results = results.where((b) => b['category'] == appliedCategoryId.value).toList();
    }

    if (appliedCityQuery.value.isNotEmpty) {
      final cityQuery = appliedCityQuery.value.toLowerCase();
      results = results.where((b) =>
      (b['city']?.toString().toLowerCase().contains(cityQuery) ?? false) ||
          (b['address']?.toString().toLowerCase().contains(cityQuery) ?? false)
      ).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      results = results.where((b) {
        final catName = b['category']?.toString().toLowerCase() ?? '';
        return b['name'].toString().toLowerCase().contains(q) ||
            (b['city']?.toString().toLowerCase().contains(q) ?? false) ||
            catName.contains(q);
      }).toList();
    }

    filteredBusinesses.assignAll(results);
  }

  bool get hasActiveFilters =>
      appliedCategoryId.value != 'all' || appliedCityQuery.value.isNotEmpty;

  // ════════════════════════════════════════════════════════════
  // LOGOUT FUNCTIONALITY
  // ════════════════════════════════════════════════════════════
  Future<void> logout() async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Remove FCM token from Firestore so this device stops receiving notifications
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': FieldValue.delete()});

        // Delete the token from FCM so a fresh one is generated on next login
        await FirebaseMessaging.instance.deleteToken();
      }

      await FirebaseAuth.instance.signOut();
      await SharedPreferencesService.clearLoginSession();
      resetForm();
      AppSnackbar.success("Account Logged out Successfully", position: SnackPosition.BOTTOM);
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      print('Logout error: $e');
      AppSnackbar.error("Account logout unsuccessful", position: SnackPosition.BOTTOM);
      await SharedPreferencesService.clearLoginSession();
      resetForm();
      Get.offAll(() => const LoginScreen());
    } finally {
      isLoggingOut.value = false;
    }
  }

  void resetForm() {
    searchQuery.value = '';
    isSearching.value = false;
    appliedCategoryId.value = 'all';
    appliedCityQuery.value = '';
    tempSelectedCategoryId.value = 'all';
    tempCityQuery.value = '';
    selectedCategoryId.value = 'all';
    bottomNavIndex.value = 0;
    filteredBusinesses.clear();
  }
}

class CategoryData {
  final String id;
  final String name;
  final IconData icon;
  CategoryData({required this.id, required this.name, required this.icon});
}