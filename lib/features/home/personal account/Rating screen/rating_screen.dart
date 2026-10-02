import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/custom_snackbar.dart';
import 'rating_success_screen.dart'; // Import the new success screen

class RatingScreen extends StatelessWidget {
  const RatingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String bookingId = Get.arguments['bookingId'];

    final controller = Get.put(
      RatingController(bookingId: bookingId),
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textHeadline,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Rate Your Experience',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        // ─────────────────────────────────────────────
        // PROFESSIONAL LOADING STATE
        // ─────────────────────────────────────────────
        if (controller.isLoading.value) {
          return const _RatingLoadingView();
        }

        // Check if review already submitted
        if (controller.reviewAlreadySubmitted.value) {
          return _buildAlreadyReviewedView(controller);
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.06,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // ─────────────────────────────────────────────
              // SERVICE IMAGE
              // ─────────────────────────────────────────────
              _buildServiceImage(controller),

              const SizedBox(height: 24),

              // ─────────────────────────────────────────────
              // SERVICE NAME
              // ─────────────────────────────────────────────
              Text(
                controller.serviceName.value,
                style: TextStyle(
                  fontSize:
                  MediaQuery.of(context).size.width < 380 ? 20 : 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeadline,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // ─────────────────────────────────────────────
              // BUSINESS NAME
              // ─────────────────────────────────────────────
              Text(
                controller.businessName.value,
                style: TextStyle(
                  fontSize:
                  MediaQuery.of(context).size.width < 380 ? 13 : 14,
                  color: AppColors.textBody,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // ─────────────────────────────────────────────
              // RATING CARD
              // ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'How was your experience?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHeadline,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildStarRating(controller, context),

                    const SizedBox(height: 12),

                    Text(
                      controller.rating.value > 0
                          ? _getRatingText(controller.rating.value)
                          : 'Tap to rate',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: controller.rating.value > 0
                            ? AppColors.primaryPurple
                            : AppColors.textPlaceholder,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─────────────────────────────────────────────
              // REVIEW BOX
              // ─────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.dividerColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        'Write your review',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHeadline,
                        ),
                      ),
                    ),

                    TextField(
                      controller: controller.reviewController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText:
                        'Share your experience with this service...',
                        hintStyle: TextStyle(
                          color: AppColors.textPlaceholder,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                        counterText: '',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ─────────────────────────────────────────────
              // SUBMIT BUTTON
              // ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : () => controller.submitRating(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                      : const Text(
                    'Submit Rating',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPlaceholder,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAlreadyReviewedView(RatingController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 50,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Already Reviewed',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeadline,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You have already submitted a review for this service.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textBody,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SERVICE IMAGE
  // ─────────────────────────────────────────────
  Widget _buildServiceImage(RatingController controller) {
    return Obx(() {
      final imageUrl = controller.serviceImageUrl.value;

      if (imageUrl.isEmpty) {
        return _buildDefaultIcon();
      }

      return Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,

            // IMPORTANT FIX
            // Prevent flickering while loading image
            frameBuilder: (
                context,
                child,
                frame,
                wasSynchronouslyLoaded,
                ) {
              if (wasSynchronouslyLoaded) {
                return child;
              }

              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: child,
              );
            },

            loadingBuilder: (
                context,
                child,
                loadingProgress,
                ) {
              if (loadingProgress == null) {
                return child;
              }

              return Container(
                color:
                AppColors.primaryPurple.withOpacity(0.06),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(
                      AppColors.primaryPurple,
                    ),
                  ),
                ),
              );
            },

            errorBuilder: (
                context,
                error,
                stackTrace,
                ) {
              return _buildDefaultIcon();
            },
          ),
        ),
      );
    });
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withOpacity(0.18),
            AppColors.primaryPurple.withOpacity(0.08),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.star_rate_rounded,
        size: 54,
        color: AppColors.primaryPurple.withOpacity(0.7),
      ),
    );
  }

  Widget _buildStarRating(
      RatingController controller,
      BuildContext context,
      ) {
    final screenWidth = MediaQuery.of(context).size.width;

    final starSize = screenWidth < 360
        ? 40.0
        : (screenWidth < 480 ? 44.0 : 48.0);

    final starSpacing = screenWidth < 360 ? 4.0 : 8.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => controller.setRating(index + 1),
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: starSpacing / 2,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                index < controller.rating.value
                    ? Icons.star
                    : Icons.star_border,
                key: ValueKey(controller.rating.value),
                size: starSize,
                color: Colors.amber,
              ),
            ),
          ),
        );
      }),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}

// ─────────────────────────────────────────────
// LOADING VIEW
// ─────────────────────────────────────────────
class _RatingLoadingView extends StatelessWidget {
  const _RatingLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          AppColors.primaryPurple,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────
class RatingController extends GetxController {
  final String bookingId;

  final rating = 0.obs;

  final reviewController = TextEditingController();

  final isSubmitting = false.obs;

  // IMPORTANT
  final isLoading = true.obs;

  // New: Check if review already submitted
  final reviewAlreadySubmitted = false.obs;

  final businessName = ''.obs;
  final serviceName = ''.obs;
  final serviceImageUrl = ''.obs;

  // Added: Store service ID for the review
  final serviceId = ''.obs;

  RatingController({
    required this.bookingId,
  });

  @override
  void onInit() {
    super.onInit();
    fetchBookingDetails();
    checkIfReviewAlreadyExists();
  }

  void setRating(int value) {
    rating.value = value;
  }

  // ─────────────────────────────────────────────
  // CHECK IF REVIEW ALREADY EXISTS (FIXED)
  // Now checks by serviceId + customerId, not bookingId
  // This ensures a user can only review a specific service ONCE
  // ─────────────────────────────────────────────
  Future<void> checkIfReviewAlreadyExists() async {
    try {
      final customerId = FirebaseAuth.instance.currentUser?.uid;

      if (customerId == null) return;

      // Wait for serviceId to be fetched first
      await Future.delayed(const Duration(milliseconds: 500));

      if (serviceId.value.isEmpty) {
        print('Service ID is empty, cannot check existing review');
        return;
      }

      // FIXED: Check by serviceId + customerId (not bookingId)
      // This allows: Ali can review Service A once, Bilal can review Service A once
      // Each user can review the same service only once
      final existingReview = await FirebaseFirestore.instance
          .collection('reviews')
          .where('serviceId', isEqualTo: serviceId.value)  // ← FIXED: Check by serviceId
          .where('customerId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (existingReview.docs.isNotEmpty) {
        reviewAlreadySubmitted.value = true;
        print('User has already reviewed this service (Service ID: ${serviceId.value})');
        return;
      }

      // Also check if booking has ratingGiven flag (backup check)
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (bookingDoc.exists && bookingDoc.data()?['ratingGiven'] == true) {
        reviewAlreadySubmitted.value = true;
        print('Booking has ratingGiven flag set to true');
      }

    } catch (e) {
      print('Error checking existing review: $e');
    }
  }

  // ─────────────────────────────────────────────
  // FETCH DATA
  // ─────────────────────────────────────────────
  Future<void> fetchBookingDetails() async {
    try {
      isLoading.value = true;

      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        AppSnackbar.error('Booking not found');
        Get.back();
        return;
      }

      final bookingData = bookingDoc.data() ?? {};

      businessName.value = (bookingData['businessName'] ?? '').toString();
      serviceName.value = (bookingData['serviceName'] ?? '').toString();
      serviceImageUrl.value = (bookingData['serviceImageUrl'] ?? '').toString();

      // Store the service ID from booking data
      serviceId.value = (bookingData['serviceId'] ?? '').toString();

      print('Fetched Service ID: ${serviceId.value}');

    } catch (e) {
      AppSnackbar.error('Failed to load rating details');
      print('Rating fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────
  // SUBMIT
  // ─────────────────────────────────────────────
  Future<void> submitRating() async {
    // Check if review already exists before submitting
    if (reviewAlreadySubmitted.value) {
      AppSnackbar.error('You have already reviewed this service');
      return;
    }

    if (rating.value == 0) {
      AppSnackbar.error('Please select a rating');
      return;
    }

    if (reviewController.text.trim().isEmpty) {
      AppSnackbar.error('Please write a review');
      return;
    }

    if (reviewController.text.trim().length < 10) {
      AppSnackbar.error(
        'Please write at least 10 characters',
      );
      return;
    }

    isSubmitting.value = true;

    try {
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      final businessId = bookingDoc.data()?['businessId'];
      final customerId = FirebaseAuth.instance.currentUser?.uid;

      // FIXED: Double check by serviceId + customerId (not bookingId)
      final existingReview = await FirebaseFirestore.instance
          .collection('reviews')
          .where('serviceId', isEqualTo: serviceId.value)  // ← FIXED: Check by serviceId
          .where('customerId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (existingReview.docs.isNotEmpty) {
        reviewAlreadySubmitted.value = true;
        isSubmitting.value = false;
        AppSnackbar.error('You have already reviewed this service');
        return;
      }

      // Add review to Firestore with serviceId
      await FirebaseFirestore.instance
          .collection('reviews')
          .add({
        'bookingId': bookingId,
        'serviceId': serviceId.value, // Store service ID for fetching reviews later
        'rating': rating.value,
        'review': reviewController.text.trim(),
        'businessId': businessId,
        'customerId': customerId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'ratingGiven': true,
        'ratedAt': FieldValue.serverTimestamp(),
      });

      isSubmitting.value = false;

      // Navigate to success screen instead of showing snackbar
      Get.offNamed('/rating-success', arguments: {
        'serviceName': serviceName.value,
        'businessName': businessName.value,
      });

    } catch (e) {
      isSubmitting.value = false;
      AppSnackbar.error('Failed to submit rating: $e');
      print('Submit rating error: $e');
    }
  }

  @override
  void onClose() {
    reviewController.dispose();
    super.onClose();
  }
}