import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../app/app_colors.dart';
import '../Notifications screen/notifications_controller.dart';
import '../personal account/personal_home_screen.dart';
import '../business account/business_home_screen.dart';
import 'booking_controller.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Animation Container
                Container(
                  width: isSmallScreen ? 100 : 120,
                  height: isSmallScreen ? 100 : 120,
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccess.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: isSmallScreen ? 60 : 80,
                    color: AppColors.statusSuccess,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 24 : 32),

                // Title
                Text(
                  'Appointment Submitted!',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHeadline,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),

                // Description
                Text(
                  'Your appointment request has been successfully submitted and is pending approval.',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 15,
                    color: AppColors.textBody,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),

                // Status Card
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Status Indicator
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.statusWarning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pending Approval',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.statusWarning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Reference ID
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reference ID',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              color: AppColors.textBody,
                            ),
                          ),
                          Text(
                            '#BK${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: AppColors.dividerColor),
                      const SizedBox(height: 12),

                      // Waiting Message
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: AppColors.textPlaceholder,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please wait for admin approval. You will be notified once confirmed.',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: AppColors.textBody,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Info Card
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLightPurple,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryPurple.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryPurple,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You can track your booking status in the "My Appointments" section.',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: AppColors.textBody,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),

                // Back to Home Button (Only button, removed View Booking Details)
                _buildBackToHomeButton(isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackToHomeButton(bool isSmallScreen) {
    final isLoading = false.obs;

    return Obx(() => SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading.value ? null : () async {
          isLoading.value = true;

          try {
            final user = FirebaseAuth.instance.currentUser;
            String? role = 'personal';

            if (user != null) {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();

              if (userDoc.exists && userDoc.data() != null) {
                role = userDoc.data()?['role'] as String? ?? 'personal';
              }
            }

            isLoading.value = false;

            if (role == 'business') {
              Get.offAll(
                    () => BusinessHomeScreen(),
                binding: BindingsBuilder(() {
                  Get.put(NotificationsController());
                }),
              );
            } else {
              Get.offAll(
                    () => const PersonalHomeScreen(),
                binding: BindingsBuilder(() {
                  Get.put(NotificationsController(), permanent: true);
                }),
              );
            }
          } catch (e) {
            isLoading.value = false;
            // On error, navigate to personal home as fallback
            Get.offAll(
                  () => const PersonalHomeScreen(),
              binding: BindingsBuilder(() {
                Get.put(NotificationsController(), permanent: true);
              }),
            );
          } finally {
            isLoading.value = false;
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading.value
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          'Back to Home',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ));
  }
}