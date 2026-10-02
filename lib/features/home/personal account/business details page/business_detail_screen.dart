import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import '../business services/all_services_screen.dart';
import '../service details/service_detail_screen.dart';
import 'business_detail_controller.dart';

class BusinessDetailScreen extends StatelessWidget {
  final String businessId;

  const BusinessDetailScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BusinessDetailController());
    controller.initBusiness(businessId);

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
        title: Obx(() => Text(
          controller.business.value?['name'] ?? 'Business',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        )),
      ),
      body: Obx(() {
        // Show loading indicator while fetching business data OR ratings
        if (controller.isLoading.value || controller.isLoadingRatings.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
            ),
          );
        }

        final business = controller.business.value;
        if (business == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business, size: 64, color: AppColors.textPlaceholder),
                const SizedBox(height: 16),
                Text(
                  'Business not found',
                  style: TextStyle(color: AppColors.textBody),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfessionalHeader(business, controller, padding),
              const SizedBox(height: 24),
              _buildServicesSection(controller, padding, business),
              const SizedBox(height: 24),
              _buildBusinessInfoSection(business, controller),
              const SizedBox(height: 80),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.openChatWithBusiness(),
        backgroundColor: AppColors.primaryPurple,
        shape: const CircleBorder(),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

  Widget _buildProfessionalHeader(Map<String, dynamic> business, BusinessDetailController controller, double padding) {
    final imageUrl = business['profileImage'] ?? '';

    // Get dynamic rating and review count
    final avgRating = controller.averageRating.value;
    final totalReviewsCount = controller.totalReviews.value;
    final ratingText = controller.getRatingText();
    final roundedRating = controller.getRoundedRating();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryPurple.withOpacity(0.1),
              image: imageUrl.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: imageUrl.isEmpty
                ? Icon(
              AppIcons.business,
              size: 32,
              color: AppColors.primaryPurple,
            )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business['name'] ?? '',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeadline,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  business['category'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPlaceholder,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Dynamic star rating display
                    ..._buildStarRating(roundedRating),
                    const SizedBox(width: 8),
                    // Dynamic rating number
                    if (totalReviewsCount > 0)
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textBody,
                        ),
                      ),
                    // Dynamic review count text
                    Text(
                      totalReviewsCount > 0
                          ? ' • ${totalReviewsCount} review${totalReviewsCount != 1 ? 's' : ''}'
                          : ' • ${ratingText}',
                      style: TextStyle(
                        fontSize: 12,
                        color: totalReviewsCount > 0 ? AppColors.textPlaceholder : AppColors.primaryPurple,
                        fontWeight: totalReviewsCount == 0 ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        // Full star
        stars.add(Icon(AppIcons.star, size: 14, color: Colors.amber));
      } else if (i == fullStars && hasHalfStar) {
        // Half star
        stars.add(Icon(Icons.star_half, size: 14, color: Colors.amber));
      } else if (i == fullStars && hasThreeQuarterStar) {
        // For 3/4 star, we can use a full star as approximation
        stars.add(Icon(AppIcons.star, size: 14, color: Colors.amber));
      } else {
        // Empty star
        stars.add(Icon(Icons.star_border, size: 14, color: Colors.amber));
      }
    }

    return stars;
  }

  Widget _buildServicesSection(BusinessDetailController controller, double padding, Map<String, dynamic> business) {
    final allServices = controller.services;
    final services = allServices.length > 4 ? allServices.take(4).toList() : allServices;

    if (services.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              AppIcons.searchOff,
              size: 48,
              color: AppColors.textPlaceholder,
            ),
            const SizedBox(height: 12),
            Text(
              'No services available',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textBody,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Our Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeadline,
              ),
            ),
            if (allServices.length > 4)
              TextButton(
                onPressed: () {
                  Get.to(() => AllServicesScreen(
                    businessId: businessId,
                    businessName: business['name'],
                  ));
                },
                child: Text(
                  'View All',
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
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final cardWidth = (availableWidth - 12) / 1.8;
            final cardHeight = 280.0;

            return SizedBox(
              height: cardHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: services.length,
                padding: EdgeInsets.only(right: padding),
                itemBuilder: (context, index) {
                  final service = services[index];
                  return Container(
                    width: cardWidth,
                    margin: EdgeInsets.only(right: 12),
                    child: ClipRect(
                      child: _buildServiceCard(service, controller, cardWidth, cardHeight),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(
      Map<String, dynamic> service,
      BusinessDetailController controller,
      double cardWidth,
      double cardHeight,
      ) {
    final imageUrl = service['imageUrl'] ?? '';
    final imageUrls = service['imageUrls'] ?? [];
    final displayImage = imageUrls.isNotEmpty ? imageUrls.first : imageUrl;

    return GestureDetector(
      onTap: () {
        Get.to(
              () => ServiceDetailScreen(serviceId: service['id']),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 300),
        );
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: cardHeight * 0.5,
                width: double.infinity,
                color: AppColors.primaryPurple.withOpacity(0.1),
                child: displayImage.isNotEmpty
                    ? Image.network(
                  displayImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildServicePlaceholder(),
                )
                    : _buildServicePlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    service['name'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeadline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service['description'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textBody,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PKR ${service['price'] ?? '0'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      Text(
                        '${service['duration'] ?? '0'} min',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPlaceholder,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicePlaceholder() {
    return Container(
      color: AppColors.primaryPurple.withOpacity(0.1),
      child: Center(
        child: Icon(
          AppIcons.business,
          color: AppColors.primaryPurple.withOpacity(0.5),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildBusinessInfoSection(Map<String, dynamic> business, BusinessDetailController controller) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            business['description'] ?? '',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textBody,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: AppColors.dividerColor),
          const SizedBox(height: 20),
          Text(
            'Contact',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 12),
          _buildContactRow(AppIcons.phone, business['phoneNumber'] ?? '', 'Call'),
          const SizedBox(height: 12),
          _buildContactRow(AppIcons.location, business['address'] ?? business['city'] ?? '', 'Location'),
          const SizedBox(height: 20),
          Divider(color: AppColors.dividerColor),
          const SizedBox(height: 20),
          Text(
            'Hours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 12),
          _buildOperatingHoursSection(controller),
        ],
      ),
    );
  }

  Widget _buildOperatingHoursSection(BusinessDetailController controller) {
    return Obx(() {
      if (controller.operatingHours.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.clock, size: 18, color: AppColors.textBody),
                const SizedBox(width: 8),
                Text(
                  'Mon-Sat: 9:00 AM - 8:00 PM',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(AppIcons.clock, size: 18, color: AppColors.textBody),
                const SizedBox(width: 8),
                Text(
                  'Sun: Closed',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPlaceholder,
                  ),
                ),
              ],
            ),
          ],
        );
      }

      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final List<Widget> hourWidgets = [];

      for (final day in days) {
        final schedule = controller.operatingHours[day];
        if (schedule != null) {
          final isOpen = schedule['isOpen'] ?? false;
          if (isOpen) {
            final openTime = _formatTimeString(schedule['openTime'] ?? '09:00');
            final closeTime = _formatTimeString(schedule['closeTime'] ?? '18:00');
            hourWidgets.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        _getShortDayName(day),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHeadline,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '$openTime - $closeTime',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textBody,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            hourWidgets.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        _getShortDayName(day),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHeadline,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Closed',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPlaceholder,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: hourWidgets,
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

  String _formatTimeString(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      return '$displayHour:$minute $period';
    } catch (e) {
      return time24;
    }
  }

  Widget _buildContactRow(IconData icon, String text, String label) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.iconBgPurple,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryPurple),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textPlaceholder,
              ),
            ),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textHeadline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}