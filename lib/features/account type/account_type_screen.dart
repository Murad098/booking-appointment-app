import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'account_type_controller.dart';
import '../../app/app_colors.dart';

class AccountTypeScreen extends StatelessWidget {
  const AccountTypeScreen({super.key});

  static const List<String> _businessFeatures = [
    'Create and manage services',
    'Accept online payments',
    'View booking dashboard',
    'Manual booking on behalf of clients',
  ];

  static const List<String> _personalFeatures = [
    'Browse services and businesses',
    'Book appointments instantly',
    'Secure payment options',
    'Manage and reschedule bookings',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AccountTypeController());

    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    // responsive scale
    final double scale = (size.height / 800).clamp(0.75, 1.0);
    final double landscapeScale = isLandscape ? 0.85 : 1.0;
    final double finalScale = scale * landscapeScale;

    final double headerFontSize = 22 * finalScale;
    final double subtitleFontSize = 13 * finalScale;
    final double cardPadding = 14 * finalScale;
    final double featureFontSize = 11 * finalScale;
    final double nextButtonHeight = 50 * finalScale;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      // Fixed button at the bottom
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Obx(() => SizedBox(
          width: double.infinity,
          height: nextButtonHeight,
          child: ElevatedButton(
            onPressed: controller.isNextEnabled && !controller.isLoading.value
                ? controller.onNext
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.isNextEnabled
                  ? AppColors.primaryPurple
                  : Colors.grey.shade300,
              disabledBackgroundColor: Colors.grey.shade300,
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
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(
              'Next',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: controller.isNextEnabled
                    ? Colors.white
                    : Colors.grey.shade500,
              ),
            ),
          ),
        )),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Text(
                  'Choose Your Account Type',
                  style: TextStyle(
                    fontSize: headerFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeadline,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6 * finalScale),
                Text(
                  'Select how you want to use our platform',
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    color: AppColors.textBody,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20 * finalScale),

                // CARDS SECTION
                if (isLandscape)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildCard(
                          controller: controller,
                          type: 'business',
                          features: _businessFeatures,
                          icon: Icons.business,
                          title: 'Business Account',
                          description:
                          'Manage your business, accept bookings, and grow your customer base',
                          scale: finalScale,
                          cardPadding: cardPadding,
                          featureFontSize: featureFontSize,
                        ),
                      ),
                      SizedBox(width: 16 * finalScale),
                      Expanded(
                        child: _buildCard(
                          controller: controller,
                          type: 'Personal',
                          features: _personalFeatures,
                          icon: Icons.person_outline,
                          title: 'Personal Account',
                          description:
                          'Discover services, book appointments, and manage your schedule',
                          scale: finalScale,
                          cardPadding: cardPadding,
                          featureFontSize: featureFontSize,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildCard(
                        controller: controller,
                        type: 'business',
                        features: _businessFeatures,
                        icon: Icons.business,
                        title: 'Business Account',
                        description:
                        'Manage your business, accept bookings, and grow your customer base',
                        scale: finalScale,
                        cardPadding: cardPadding,
                        featureFontSize: featureFontSize,
                      ),
                      SizedBox(height: 20 * finalScale),
                      _buildCard(
                        controller: controller,
                        type: 'Personal',
                        features: _personalFeatures,
                        icon: Icons.person_outline,
                        title: 'Personal Account',
                        description:
                        'Discover services, book appointments, and manage your schedule',
                        scale: finalScale,
                        cardPadding: cardPadding,
                        featureFontSize: featureFontSize,
                      ),
                    ],
                  ),
                // Padding to ensure cards don't get hidden behind the floating button on small screens
                SizedBox(height: 10 * finalScale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required AccountTypeController controller,
    required String type,
    required List<String> features,
    required IconData icon,
    required String title,
    required String description,
    required double scale,
    required double cardPadding,
    required double featureFontSize,
  }) {
    return Obx(() {
      final isSelected = controller.selectedAccountType.value == type;

      return GestureDetector(
        onTap: () => controller.selectAccountType(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primaryPurple : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38 * scale,
                    height: 38 * scale,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon,
                        color: AppColors.primaryPurple, size: 18 * scale),
                  ),
                  SizedBox(width: 12 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textHeadline,
                          ),
                        ),
                        SizedBox(height: 3 * scale),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 11 * scale,
                            color: AppColors.textBody,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12 * scale),
              ...features
                  .map((feature) => _buildFeature(feature, featureFontSize))
                  .toList(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFeature(String text, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF10B981),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                color: AppColors.textBody,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}