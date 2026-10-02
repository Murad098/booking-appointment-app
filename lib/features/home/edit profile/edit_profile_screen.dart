import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../app/app_colors.dart';
import '../../../../../app/app_icons.dart';
import 'edit_profile_controller.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditProfileController());
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final padding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(AppIcons.arrowLeft, color: AppColors.textHeadline),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => Text(
          controller.userRole.value == 'business' ? 'Edit Business Profile' : 'Edit Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        )),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.profileImageUrl.value.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryPurple,
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Profile Picture Section with Professional Camera Icon
              _buildProfilePicture(controller),
              SizedBox(height: 24),

              // 🔹 Edit Form
              _buildSectionTitle(controller.userRole.value == 'business' ? 'Business Details' : 'Personal Details'),
              SizedBox(height: 16),
              _buildEditForm(controller),
              SizedBox(height: 32),

              // 🔹 Save Button (Mobile)
              if (isMobile) _buildSaveButton(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfilePicture(EditProfileController controller) {
    return Obx(() {
      final imageVal = controller.profileImageUrl.value;
      final bool isNetwork = imageVal.startsWith('http');
      final bool isLocal = imageVal.isNotEmpty && !isNetwork;

      return Center(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: imageVal.isEmpty
                        ? Icon(
                      controller.userRole.value == 'business'
                          ? AppIcons.business
                          : AppIcons.drawerProfile,
                      size: 50,
                      color: Colors.white,
                    )
                        : isNetwork
                        ? Image.network(
                      imageVal,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        controller.userRole.value == 'business'
                            ? AppIcons.business
                            : AppIcons.drawerProfile,
                        size: 50,
                        color: Colors.white,
                      ),
                    )
                        : Image.file(
                      File(imageVal),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // ✅ Camera icon — white background, black icon
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => controller.uploadProfilePicture(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white, // ✅ White background
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: controller.isImageUploading.value
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black87,
                        ),
                      )
                          : const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.black87, // ✅ Black icon
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              controller.userRole.value == 'business'
                  ? 'Business Logo'
                  : 'Profile Photo',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textHeadline,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap camera to upload',
              style: TextStyle(fontSize: 13, color: AppColors.textBody),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textBody,
      ),
    );
  }

  Widget _buildEditForm(EditProfileController controller) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
        children: [
          if (controller.userRole.value == 'business') ...[
            _buildTextField(
              controller: controller.businessNameController,
              label: 'Business Name',
              hint: 'Enter your business name',
              icon: AppIcons.business,
            ),
            SizedBox(height: 20),
            // 🔹 NEW: Business Description Field for Business Users
            _buildTextField(
              controller: controller.businessDescriptionController,
              label: 'Business Description',
              hint: 'Tell customers about your business...',
              icon: Icons.description,
              maxLines: 3,
            ),
            SizedBox(height: 20),
          ] else ...[
            _buildTextField(
              controller: controller.fullNameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: AppIcons.drawerProfile,
            ),
            SizedBox(height: 20),
          ],
          _buildTextField(
            controller: controller.emailController,
            label: 'Email Address',
            hint: 'Enter your email',
            icon: AppIcons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: controller.phoneController,
            label: 'Phone Number',
            hint: 'Enter your phone number',
            icon: AppIcons.phone,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: controller.addressController,
            label: 'Address',
            hint: 'Enter your address',
            icon: AppIcons.location,
            maxLines: 2,
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: controller.cityController,
            label: 'City',
            hint: 'Enter your city',
            icon: Icons.location_city,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textHeadline,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textPlaceholder),
              prefixIcon: Container(
                margin: EdgeInsets.only(right: 8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.iconBgPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryPurple,
                  size: 18,
                ),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(EditProfileController controller) {
    return Obx(() => Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.primaryPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: controller.isLoading.value
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : TextButton(
        onPressed: () => controller.saveProfile(),
        child: Text(
          'Save Changes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    ));
  }
}