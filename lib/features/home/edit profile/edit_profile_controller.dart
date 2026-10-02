import 'package:bookify/app/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../../services/supabase_storage_service.dart';
import '../../../../../services/user_service.dart';

class EditProfileController extends GetxController {
  final businessNameController = TextEditingController();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final businessDescriptionController = TextEditingController(); // New field

  final isLoading = false.obs;
  final isImageUploading = false.obs;
  final profileImageUrl = ''.obs;
  final userRole = ''.obs;

  File? selectedImageFile;
  String _existingRemoteImageUrl = '';

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> loadUserData() async {
    isLoading.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final role = await UserService.getUserRole(user.uid);
      userRole.value = role ?? 'personal';

      if (userRole.value == 'business') {
        final businessProfile = await UserService.getBusinessProfile(user.uid);
        if (businessProfile != null) {
          businessNameController.text = businessProfile['businessName'] ?? '';
          emailController.text = businessProfile['email'] ?? user.email ?? '';
          phoneController.text = businessProfile['phoneNumber'] ?? '';
          addressController.text = businessProfile['address'] ?? '';
          cityController.text = businessProfile['city'] ?? '';
          businessDescriptionController.text = businessProfile['description'] ?? ''; // Load business description
          final savedImage = businessProfile['profileImage'] ?? '';
          _existingRemoteImageUrl = savedImage;
          profileImageUrl.value = savedImage;
        }
      } else {
        final userData = await UserService.getUserData(user.uid);
        if (userData != null) {
          fullNameController.text = userData['name'] ?? '';
          emailController.text = userData['email'] ?? user.email ?? '';
          phoneController.text = userData['phoneNumber'] ?? '';
          addressController.text = userData['address'] ?? '';
          cityController.text = userData['city'] ?? '';
          final savedImage = userData['profileImage'] ?? '';
          _existingRemoteImageUrl = savedImage;
          profileImageUrl.value = savedImage;
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    businessNameController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    businessDescriptionController.dispose(); // Dispose new controller
    super.onClose();
  }

  Future<void> uploadProfilePicture() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        selectedImageFile = File(pickedFile.path);
        profileImageUrl.value = pickedFile.path;
      }
    } catch (e) {
      print('Error picking image: $e');
      AppSnackbar.error(
        'Failed to pick image',
        position: SnackPosition.BOTTOM,
      );
    }
  }

  String getDisplayName() {
    if (userRole.value == 'business') {
      return businessNameController.text.isNotEmpty
          ? businessNameController.text
          : 'Business Name';
    }
    return fullNameController.text.isNotEmpty
        ? fullNameController.text
        : 'User Name';
  }

  String getInitials() {
    final name = getDisplayName();
    if (name.isEmpty) return userRole.value == 'business' ? 'B' : 'U';
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return names[0].substring(0, 1).toUpperCase();
  }

  Future<void> saveProfile() async {
    isLoading.value = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String finalImageUrl = _existingRemoteImageUrl;

      if (selectedImageFile != null) {
        isImageUploading.value = true;

        final uploaded = await SupabaseStorageService().uploadProfileImage(selectedImageFile!);
        isImageUploading.value = false;

        if (uploaded != null) {
          if (_existingRemoteImageUrl.isNotEmpty &&
              _existingRemoteImageUrl.contains('supabase.co')) {
            await SupabaseStorageService().deleteOldProfileImage(_existingRemoteImageUrl);
          }
          finalImageUrl = uploaded;
          _existingRemoteImageUrl = uploaded;
          print('[EditProfileController] ✅ Image URL to save: $finalImageUrl');
        } else {
          AppSnackbar.error(
            'Image Upload Failed',
            position: SnackPosition.BOTTOM,
          );
        }
      }

      if (userRole.value == 'business') {
        final businessProfile = await UserService.getBusinessProfile(user.uid);
        final updatedProfile = {
          'basicInfo': {
            'businessName': businessNameController.text.trim(),
            'category': businessProfile?['category'] ?? '',
            'description': businessDescriptionController.text.trim(), // Save business description
            'email': emailController.text.trim(),
            'phoneNumber': phoneController.text.trim(),
            'address': addressController.text.trim(),
            'city': cityController.text.trim(),
          },
          'operatingHours': businessProfile?['operatingHours'] ?? {},
        };

        await UserService.saveBusinessProfile(user.uid, updatedProfile);

        if (finalImageUrl.isNotEmpty) {
          await UserService.updateBusinessProfileImage(user.uid, finalImageUrl);
        }
      } else {
        final updateData = {
          'name': fullNameController.text.trim(),
          'email': emailController.text.trim(),
          'phoneNumber': phoneController.text.trim(),
          'address': addressController.text.trim(),
          'city': cityController.text.trim(),
        };

        if (finalImageUrl.isNotEmpty) {
          updateData['profileImage'] = finalImageUrl;
        }

        await UserService.updateUserData(user.uid, updateData);
      }

      profileImageUrl.value = finalImageUrl;

      Get.back(result: true);
      AppSnackbar.success(
        'Profile updated successfully',
        position: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error saving profile: $e');
      AppSnackbar.error(
        'Failed to update profile: ${e.toString()}',
        position: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}