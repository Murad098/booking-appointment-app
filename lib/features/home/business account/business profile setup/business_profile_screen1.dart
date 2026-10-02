import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import 'business_profile_controller.dart';
import 'business_profile_screen2.dart';

class BusinessProfileStep1 extends StatelessWidget {
  const BusinessProfileStep1({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BusinessProfileController());
    final isMobile = MediaQuery.of(context).size.width < 600;
    final padding = isMobile ? 16.0 : 24.0;
    final maxWidth = isMobile ? double.infinity : 600.0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'Business Profile Setup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeadline,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Step 1 of 2',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textBody.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: 0.5,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHeadline,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Business Name *'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: controller.businessName,
                          hint: 'Elite Hair Salon',
                          prefixIcon: AppIcons.business,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Business Category *'),
                        const SizedBox(height: 8),
                        Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: controller.businessCategory.value,
                              isExpanded: true,
                              icon: Icon(AppIcons.arrowDown, color: AppColors.primaryPurple),
                              items: controller.categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    category,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                controller.businessCategory.value = value!;
                              },
                            ),
                          ),
                        )),
                        const SizedBox(height: 20),
                        _buildLabel('Business Description *'),
                        const SizedBox(height: 8),
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: TextField(
                            controller: controller.businessDescription,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              hintText: 'Tell customers about your business...',
                              hintStyle: TextStyle(color: AppColors.textPlaceholder),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Business Email *'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: controller.businessEmail,
                          hint: 'contact@business.com',
                          prefixIcon: AppIcons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Phone Number *'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: controller.phoneNumber,
                          hint: '+92 300 1234567 or 03XXXXXXXXX',
                          prefixIcon: AppIcons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Business Address *'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: controller.businessAddress,
                          hint: '123 Main Street, Area Name',
                          prefixIcon: AppIcons.location,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('City *'),
                        const SizedBox(height: 8),
                        Obx(() => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: TextField(
                                controller: controller.city,
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                  hintText: 'e.g., Karachi, Lahore, Islamabad',
                                  hintStyle: TextStyle(color: AppColors.textPlaceholder),
                                  prefixIcon: Icon(Icons.location_city, color: AppColors.primaryPurple),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                onChanged: (value) {
                                  // The controller's listener handles suggestions
                                },
                              ),
                            ),
                            // City Suggestions Dropdown
                            if (controller.showCitySuggestions.value && controller.citySuggestions.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: controller.citySuggestions.map((cityName) {
                                    return InkWell(
                                      onTap: () => controller.selectCitySuggestion(cityName),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_city,
                                              size: 16,
                                              color: AppColors.primaryPurple,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              cityName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textHeadline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        )),
                        const SizedBox(height: 32),
                        Obx(() => SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value ? null : () {
                              if (controller.validateStep1()) {
                                controller.onContinue();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: controller.isLoading.value
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textHeadline,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlignVertical: TextAlignVertical.center,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textPlaceholder),
          prefixIcon: Icon(prefixIcon, color: AppColors.primaryPurple),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}