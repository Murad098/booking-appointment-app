import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import 'service_detail_controller.dart';
import 'all_reviews_screen.dart'; // Import the new all reviews screen

class ServiceDetailScreen extends StatelessWidget {
  final String serviceId;
  final String userType;

  const ServiceDetailScreen({
    super.key,
    required this.serviceId,
    this.userType = 'customer',
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ServiceDetailController());
    controller.initService(serviceId);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final padding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(AppIcons.arrowLeft, color: AppColors.textHeadline),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Service Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(AppIcons.threedots, color: AppColors.textHeadline),
            onPressed: () {
              // TODO: Show share options
            },
          ),
        ],
      ),
      body: Obx(() {
        final hasService = controller.serviceName.value.isNotEmpty;
        final hasBusiness = controller.businessName.value.isNotEmpty;

        // Show loading indicator until service, business, AND ratings are loaded
        if (!hasService || !hasBusiness || controller.isLoadingRatings.value) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
            ),
          );
        }

        return Column(
          children: [
            _buildImageCarousel(controller, screenWidth),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildServiceInfo(controller),
                    const SizedBox(height: 20),
                    _buildOverviewCard(controller),
                    const SizedBox(height: 20),
                    _buildDetailsCard(controller, screenWidth),
                    const SizedBox(height: 20),
                    _buildPaymentCard(controller),
                    const SizedBox(height: 20),
                    _buildBusinessCard(controller),
                    const SizedBox(height: 20),
                    // ✅ UPDATED: Reviews section - Show max 5 reviews
                    _buildReviewsSection(controller),
                  ],
                ),
              ),
            ),
            _buildBookNowButton(controller),
          ],
        );
      }),
    );
  }

  Widget _buildImageCarousel(ServiceDetailController controller, double screenWidth) {
    return Obx(() => Container(
      height: 250,
      width: double.infinity,
      color: AppColors.scaffoldBackground,
      child: Stack(
        children: [
          Center(
            child: controller.serviceImageUrls.isNotEmpty
                ? PageView.builder(
              onPageChanged: (index) => controller.currentImageIndex.value = index,
              itemCount: controller.serviceImageUrls.length,
              itemBuilder: (context, index) {
                return Image.network(
                  controller.serviceImageUrls[index],
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 250,
                      color: AppColors.primaryPurple.withOpacity(0.1),
                      child: const Icon(
                        Icons.image_outlined,
                        size: 60,
                        color: AppColors.primaryPurple,
                      ),
                    );
                  },
                );
              },
            )
                : Container(
              width: double.infinity,
              height: 250,
              color: AppColors.primaryPurple.withOpacity(0.1),
              child: const Icon(
                Icons.image_outlined,
                size: 60,
                color: AppColors.primaryPurple,
              ),
            ),
          ),

          if (controller.serviceImageUrls.length > 1)
            Positioned(
              bottom: 45,
              right: 12,
              child: GestureDetector(
                onTap: controller.nextImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Swap to next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

          if (controller.serviceImageUrls.length > 1)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Obx(() => Text(
                  '${controller.currentImageIndex.value + 1}/${controller.serviceImageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                )),
              ),
            ),
        ],
      ),
    ));
  }

  Widget _buildServiceInfo(ServiceDetailController controller) {
    // Get dynamic service rating
    final avgRating = controller.serviceAverageRating.value;
    final totalReviews = controller.serviceTotalReviews.value;
    final ratingText = controller.getServiceRatingText();
    final roundedRating = controller.getRoundedServiceRating();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.serviceName.value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                AppIcons.business,
                size: 16,
                color: AppColors.textPlaceholder,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  controller.businessName.value,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textBody,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Dynamic rating display for this service
          Row(
            children: [
              ..._buildStarRating(roundedRating),
              const SizedBox(width: 8),
              if (totalReviews > 0)
                Text(
                  avgRating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeadline,
                  ),
                ),
              const SizedBox(width: 4),
              Text(
                totalReviews > 0
                    ? '(${ratingText} • ${totalReviews} review${totalReviews != 1 ? 's' : ''})'
                    : '(${ratingText})',
                style: TextStyle(
                  fontSize: 13,
                  color: totalReviews > 0 ? AppColors.textBody : AppColors.textPlaceholder,
                  fontWeight: totalReviews == 0 ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build star rating display
  List<Widget> _buildStarRating(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.25 && (rating - fullStars) < 0.75;
    bool hasThreeQuarterStar = (rating - fullStars) >= 0.75;

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(Icon(Icons.star, size: 16, color: Colors.amber));
      } else if (i == fullStars && hasHalfStar) {
        stars.add(Icon(Icons.star_half, size: 16, color: Colors.amber));
      } else if (i == fullStars && hasThreeQuarterStar) {
        stars.add(Icon(Icons.star, size: 16, color: Colors.amber));
      } else {
        stars.add(Icon(Icons.star_border, size: 16, color: Colors.amber));
      }
    }

    return stars;
  }

  // ✅ UPDATED: Reviews section widget - Show max 5 reviews
  Widget _buildReviewsSection(ServiceDetailController controller) {
    final totalReviews = controller.serviceTotalReviews.value;
    final recentReviews = controller.recentReviews;

    // Show only first 5 reviews
    final displayReviews = recentReviews.length > 5 ? recentReviews.sublist(0, 5) : recentReviews;
    final hasMoreReviews = recentReviews.length > 5;

    if (totalReviews == 0) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.iconBgPurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.rate_review,
                    size: 18,
                    color: AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Reviews',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeadline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: AppColors.textPlaceholder,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textBody,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to review this service',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.iconBgPurple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.rate_review,
                      size: 18,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Reviews',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeadline,
                    ),
                  ),
                ],
              ),
              // Show View All button only if there are more than 5 reviews
              if (hasMoreReviews || totalReviews > 5)
                TextButton(
                  onPressed: () {
                    // Navigate to all reviews screen
                    Get.to(() => AllReviewsScreen(serviceId: controller.serviceId.value));
                  },
                  child: Text(
                    'View All Reviews',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Show rating summary
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        controller.serviceAverageRating.value.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _buildStarRating(controller.getRoundedServiceRating()),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${controller.serviceTotalReviews.value} review${controller.serviceTotalReviews.value != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
                // Rating distribution bars
                Expanded(
                  child: Column(
                    children: [
                      _buildRatingBar(5, controller.serviceRatingDistribution[5] ?? 0, controller.serviceTotalReviews.value),
                      const SizedBox(height: 4),
                      _buildRatingBar(4, controller.serviceRatingDistribution[4] ?? 0, controller.serviceTotalReviews.value),
                      const SizedBox(height: 4),
                      _buildRatingBar(3, controller.serviceRatingDistribution[3] ?? 0, controller.serviceTotalReviews.value),
                      const SizedBox(height: 4),
                      _buildRatingBar(2, controller.serviceRatingDistribution[2] ?? 0, controller.serviceTotalReviews.value),
                      const SizedBox(height: 4),
                      _buildRatingBar(1, controller.serviceRatingDistribution[1] ?? 0, controller.serviceTotalReviews.value),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Recent reviews - Only show first 5
          ...displayReviews.map((review) => FutureBuilder(
            future: _getCustomerDetails(review['customerId']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildReviewShimmer();
              }
              final customerData = snapshot.data;
              return _buildReviewItem(
                review: review,
                customerName: customerData?['name'] ?? 'User',
                customerImage: customerData?['profileImage'],
              );
            },
          )),
        ],
      ),
    );
  }

  // Helper method to fetch customer details
  Future<Map<String, dynamic>?> _getCustomerDetails(String? customerId) async {
    if (customerId == null || customerId.isEmpty) return null;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get();

      if (userDoc.exists) {
        return userDoc.data();
      }
    } catch (e) {
      print('Error fetching customer details: $e');
    }
    return null;
  }

  // Review shimmer loading effect
  Widget _buildReviewShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 14,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Rating bar widget
  Widget _buildRatingBar(int rating, int count, int total) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            '$rating ★',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textBody,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade200,
              color: Colors.amber,
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPlaceholder,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ✅ UPDATED: Review item widget with customer name and profile image
  Widget _buildReviewItem({
    required Map<String, dynamic> review,
    required String customerName,
    String? customerImage,
  }) {
    final rating = review['rating'] as int;
    final reviewText = review['review'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer profile image
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
            backgroundImage: customerImage != null && customerImage.isNotEmpty
                ? NetworkImage(customerImage)
                : null,
            child: customerImage == null || customerImage.isEmpty
                ? Text(
              customerName.isNotEmpty ? customerName[0].toUpperCase() : 'U',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPurple,
              ),
            )
                : null,
          ),
          const SizedBox(width: 12),
          // Review content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer name
                Text(
                  customerName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeadline,
                  ),
                ),
                const SizedBox(height: 4),
                // Star rating
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        size: 14,
                        color: Colors.amber,
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                // Review text
                Text(
                  reviewText,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textBody,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(ServiceDetailController controller) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.iconBgPurple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  AppIcons.info,
                  size: 18,
                  color: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Overview',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeadline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            controller.serviceDescription.value,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textBody,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.app,
                  size: 14,
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(width: 6),
                Text(
                  controller.serviceCategory.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(ServiceDetailController controller, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.iconBgGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  AppIcons.clock,
                  size: 18,
                  color: AppColors.statusSuccess,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Service Details',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeadline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: AppIcons.money,
                  iconColor: AppColors.primaryPurple,
                  iconBg: AppColors.iconBgPurple,
                  label: 'Price',
                  value: 'PKR ${controller.servicePrice.value}',
                  valueColor: AppColors.primaryPurple,
                  valueWeight: FontWeight.w700,
                  screenWidth: screenWidth,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem(
                  icon: AppIcons.clock,
                  iconColor: AppColors.statusSuccess,
                  iconBg: AppColors.iconBgGreen,
                  label: 'Duration',
                  value: '${controller.serviceDuration.value} min',
                  screenWidth: screenWidth,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    Color? valueColor,
    FontWeight? valueWeight,
    required double screenWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPlaceholder,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: screenWidth < 400 ? 14 : 16,
            fontWeight: valueWeight ?? FontWeight.w600,
            color: valueColor ?? AppColors.textHeadline,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPaymentCard(ServiceDetailController controller) {
    final priceStr = controller.servicePrice.value.replaceAll(RegExp(r'[^0-9]'), '');
    final totalPrice = int.tryParse(priceStr) ?? 0;
    final advancePayment = (totalPrice * 0.2).toInt();
    final remainingBalance = totalPrice - advancePayment;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.iconBgAmber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  AppIcons.money,
                  size: 18,
                  color: AppColors.statusWarning,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Payment',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeadline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPriceRow('Total Price', _formatPrice(totalPrice)),
          const SizedBox(height: 10),
          _buildPriceRow(
            'Advance Payment (20%)',
            _formatPrice(advancePayment),
            isHighlighted: true,
          ),
          const SizedBox(height: 10),
          _buildPriceRow('Remaining Balance', _formatPrice(remainingBalance)),
          const SizedBox(height: 20),
          Divider(color: AppColors.dividerColor, thickness: 1),
          const SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundLightPurple,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryPurple.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.info,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Advance payment secures your booking. Pay the remaining balance directly at the business.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textBody,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textBody,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isHighlighted ? AppColors.primaryPurple : AppColors.textHeadline,
          ),
        ),
      ],
    );
  }

  String _formatPrice(int price) {
    return 'PKR ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  Widget _buildBusinessCard(ServiceDetailController controller) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.iconBgPurple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  AppIcons.business,
                  size: 18,
                  color: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Business',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeadline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            controller.businessName.value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 12),
          _buildContactRow(AppIcons.phone, controller.businessPhone.value, 'Call'),
          const SizedBox(height: 10),
          _buildContactRow(AppIcons.location, controller.businessLocation.value, 'Location'),
          const SizedBox(height: 16),

          // Dynamic operating hours from Firestore
          _buildOperatingHoursSection(controller),
        ],
      ),
    );
  }

  // Dynamic hours widget — exact same logic as BusinessDetailScreen
  Widget _buildOperatingHoursSection(ServiceDetailController controller) {
    return Obx(() {
      if (controller.operatingHours.isEmpty) {
        // Fallback if no hours in Firestore
        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(AppIcons.clock, size: 16, color: AppColors.textBody),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hours not available',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textBody,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final List<Widget> hourWidgets = [];

      for (final day in days) {
        final schedule = controller.operatingHours[day];
        if (schedule != null) {
          final isOpen = schedule['isOpen'] ?? false;
          final dayLabel = _getShortDayName(day);

          hourWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHeadline,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      isOpen
                          ? '${controller.formatTimeString(schedule['openTime'] ?? '09:00')} - ${controller.formatTimeString(schedule['closeTime'] ?? '18:00')}'
                          : 'Closed',
                      style: TextStyle(
                        fontSize: 13,
                        color: isOpen ? AppColors.textBody : AppColors.textPlaceholder,
                        fontStyle: isOpen ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.clock, size: 16, color: AppColors.primaryPurple),
              const SizedBox(width: 8),
              Text(
                'Business Hours',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeadline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...hourWidgets,
        ],
      );
    });
  }

  String _getShortDayName(String fullDay) {
    const dayMap = {
      'Monday': 'Mon',
      'Tuesday': 'Tue',
      'Wednesday': 'Wed',
      'Thursday': 'Thu',
      'Friday': 'Fri',
      'Saturday': 'Sat',
      'Sunday': 'Sun',
    };
    return dayMap[fullDay] ?? fullDay.substring(0, 3);
  }

  Widget _buildContactRow(IconData icon, String text, String label) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.iconBgPurple,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: AppColors.primaryPurple),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textPlaceholder,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeadline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookNowButton(ServiceDetailController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Obx(() => ElevatedButton(
          onPressed: controller.isBooking.value ? null : () => controller.bookService(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: controller.isBooking.value
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.calendar, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Book Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        )),
      ),
    );
  }
}