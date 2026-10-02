import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../services/user_service.dart';
import '../../../../app/custom_snackbar.dart';
import '../../book appointment/booking_controller.dart';
import '../../book appointment/booking_step1_date_time.dart';

class ServiceDetailController extends GetxController {
  final serviceId = ''.obs;

  final serviceName = ''.obs;
  final serviceDescription = ''.obs;
  final serviceCategory = ''.obs;
  final servicePrice = ''.obs;
  final serviceDuration = ''.obs;
  final serviceImageUrls = <String>[].obs;
  final businessId = ''.obs;
  final businessName = ''.obs;
  final businessRating = ''.obs;
  final businessPhone = ''.obs;
  final businessLocation = ''.obs;
  final currentImageIndex = 0.obs;
  final isBooking = false.obs;
  final advancePayment = 0.0.obs;

  // ✅ NEW: Rating-related observables for service
  final serviceAverageRating = 0.0.obs;
  final serviceTotalReviews = 0.obs;
  final isLoadingRatings = false.obs;
  final serviceRatingDistribution = <int, int>{}.obs;
  final recentReviews = <Map<String, dynamic>>[].obs;

  // ✅ NEW: Operating hours — same structure as BusinessDetailController
  final operatingHours = <String, Map<String, dynamic>>{}.obs;

  double get totalPrice {
    final priceStr = servicePrice.value.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(priceStr) ?? 0.0;
  }

  double get calculatedAdvance => totalPrice * 0.2;

  void nextImage() {
    if (serviceImageUrls.isNotEmpty && currentImageIndex.value < serviceImageUrls.length - 1) {
      currentImageIndex.value++;
    }
  }

  void previousImage() {
    if (serviceImageUrls.isNotEmpty && currentImageIndex.value > 0) {
      currentImageIndex.value--;
    }
  }

  Future<void> initService(String id) async {
    serviceId.value = id;
    currentImageIndex.value = 0;

    try {
      final QuerySnapshot allBusinesses = await FirebaseFirestore.instance
          .collection('businesses')
          .get();

      Map<String, dynamic>? foundBusiness;
      Map<String, dynamic>? foundService;

      for (var doc in allBusinesses.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final servicesList = data['services'] as List<dynamic>?;

        if (servicesList != null) {
          final service = servicesList.firstWhere(
                (s) => s['id'] == id,
            orElse: () => null,
          );

          if (service != null) {
            foundBusiness = {
              'id': doc.id,
              ...data,
            };
            foundService = service;
            break;
          }
        }
      }

      if (foundBusiness != null && foundService != null) {
        serviceName.value = foundService['name'] ?? '';
        serviceDescription.value = foundService['description'] ?? '';
        serviceCategory.value = foundService['category'] ?? '';
        servicePrice.value = foundService['price']?.toString() ?? '0';
        serviceDuration.value = foundService['duration']?.toString() ?? '0';

        if (foundService['imageUrls'] != null && foundService['imageUrls'] is List) {
          serviceImageUrls.value = List<String>.from(foundService['imageUrls']);
        } else if (foundService['imageUrl'] != null && foundService['imageUrl'].toString().isNotEmpty) {
          serviceImageUrls.value = [foundService['imageUrl']];
        } else {
          serviceImageUrls.clear();
        }

        businessId.value = foundBusiness['id'];
        businessName.value = foundBusiness['businessName'] ?? '';
        businessPhone.value = foundBusiness['phoneNumber'] ?? '';
        businessLocation.value = foundBusiness['city'] ?? '';
        advancePayment.value = calculatedAdvance;

        // ✅ NEW: Fetch operating hours from Firestore data
        if (foundBusiness['operatingHours'] != null) {
          final hours = foundBusiness['operatingHours'] as Map<String, dynamic>;
          operatingHours.value = {};
          hours.forEach((day, schedule) {
            operatingHours[day] = Map<String, dynamic>.from(schedule);
          });
        } else {
          operatingHours.clear();
        }

        // ✅ NEW: Fetch service ratings after service is loaded
        await fetchServiceRatings();

        print('[ServiceDetailController] ✅ Service found: ${businessName.value}');
      } else {
        print('[ServiceDetailController] ❌ Service not found');
        AppSnackbar.error('Service not found');
      }
    } catch (e) {
      print('Error loading service details: $e');
      AppSnackbar.error('Failed to load service details');
    }
  }

  // ✅ NEW: Fetch ratings and reviews specifically for this service
  Future<void> fetchServiceRatings() async {
    try {
      isLoadingRatings.value = true;

      // Query reviews specifically for this service ID
      final querySnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('serviceId', isEqualTo: serviceId.value)
          .get();

      final reviews = querySnapshot.docs;
      serviceTotalReviews.value = reviews.length;

      if (reviews.isEmpty) {
        serviceAverageRating.value = 0.0;
        serviceRatingDistribution.clear();
        recentReviews.clear();
        businessRating.value = 'Not Rated Yet';
        return;
      }

      // Calculate average rating and distribution
      int sumRatings = 0;
      final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      final List<Map<String, dynamic>> reviewsList = [];

      for (final doc in reviews) {
        final data = doc.data();
        final rating = data['rating'] as int? ?? 0;

        if (rating >= 1 && rating <= 5) {
          sumRatings += rating;
          distribution[rating] = (distribution[rating] ?? 0) + 1;

          // Collect recent reviews (last 3)
          reviewsList.add({
            'id': doc.id,
            'rating': rating,
            'review': data['review'] ?? '',
            'customerId': data['customerId'] ?? '',
            'createdAt': data['createdAt'],
          });
        }
      }

      serviceAverageRating.value = sumRatings / serviceTotalReviews.value;
      serviceRatingDistribution.value = distribution;

      // Sort reviews by createdAt (newest first) and take last 3
      reviewsList.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      recentReviews.value = reviewsList.take(3).toList();

      // Update business rating display
      final avgRating = serviceAverageRating.value;
      if (avgRating == 0) {
        businessRating.value = 'Not Rated Yet';
      } else {
        businessRating.value = avgRating.toStringAsFixed(1);
      }

    } catch (e) {
      print('Error fetching service ratings: $e');
      serviceAverageRating.value = 0.0;
      serviceTotalReviews.value = 0;
      serviceRatingDistribution.clear();
      businessRating.value = 'Not Rated Yet';
    } finally {
      isLoadingRatings.value = false;
    }
  }

  // ✅ NEW: Helper method to get rating text
  String getServiceRatingText() {
    final rating = serviceAverageRating.value;
    if (rating == 0) return 'Not Rated Yet';
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.5) return 'Good';
    if (rating >= 3.0) return 'Fair';
    return 'Poor';
  }

  // ✅ NEW: Helper method to get rounded rating for star display
  double getRoundedServiceRating() {
    if (serviceAverageRating.value == 0) return 0;
    return (serviceAverageRating.value * 2).round() / 2;
  }

  // ✅ NEW: Refresh ratings (useful after new review is submitted)
  Future<void> refreshServiceRatings() async {
    await fetchServiceRatings();
  }

  Future<void> bookService() async {
    isBooking.value = true;

    final bookingController = Get.put(BookingController(), permanent: true);
    bookingController.initBooking(
      serviceId: serviceId.value,
      businessId: businessId.value,
      businessName: businessName.value,
      serviceName: serviceName.value,
      serviceDescription: serviceDescription.value,
      serviceCategory: serviceCategory.value,
      servicePrice: servicePrice.value,
      serviceDuration: serviceDuration.value,
      serviceImageUrl: serviceImageUrls.isNotEmpty ? serviceImageUrls.first : '',
      userType: 'personal',
    );

    await Get.to(() => const BookingStep1DateTime());

    isBooking.value = false;
  }

  String formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<String> get availableTimeSlots => [
    '9:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
    '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM',
  ];

  // ✅ NEW: 24h → 12h formatter
  String formatTimeString(String time24) {
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
}