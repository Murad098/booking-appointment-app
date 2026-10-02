import 'package:bookify/app/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../app/app_colors.dart';
import '../../chat system/chat/chat_screen.dart';

class BusinessDetailController extends GetxController {
  final businessId = ''.obs;
  final selectedService = Rxn<Map<String, dynamic>>();

  final business = Rxn<Map<String, dynamic>>();
  final services = <Map<String, dynamic>>[].obs;
  final operatingHours = <String, Map<String, dynamic>>{}.obs;
  final isLoading = false.obs;

  // New: Rating-related observables
  final averageRating = 0.0.obs;
  final totalReviews = 0.obs;
  final isLoadingRatings = false.obs;
  final ratingDistribution = <int, int>{}.obs; // Track how many 1-star, 2-star, etc.

  List<Map<String, dynamic>> get featuredServices => services.take(3).toList();

  Future<void> initBusiness(String id) async {
    businessId.value = id;
    isLoading.value = true;

    try {
      final businessDoc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(id)
          .get();

      if (businessDoc.exists) {
        final data = businessDoc.data() as Map<String, dynamic>;
        business.value = {
          'id': businessDoc.id,
          'name': data['businessName'] ?? '',
          'category': data['category'] ?? '',
          'description': data['description'] ?? '',
          'city': data['city'] ?? '',
          'address': data['address'] ?? '',
          'phoneNumber': data['phoneNumber'] ?? '',
          'email': data['email'] ?? '',
          'profileImage': data['profileImage'] ?? '',
        };

        if (data['operatingHours'] != null) {
          final hours = data['operatingHours'] as Map<String, dynamic>;
          operatingHours.value = {};
          hours.forEach((day, schedule) {
            operatingHours[day] = Map<String, dynamic>.from(schedule);
          });
        }

        if (data['services'] != null) {
          final servicesList = data['services'] as List<dynamic>;
          services.value = servicesList.map((s) {
            return {
              'id': s['id'] ?? '',
              'name': s['name'] ?? '',
              'description': s['description'] ?? '',
              'category': s['category'] ?? '',
              'price': s['price']?.toString() ?? '0',
              'duration': s['duration']?.toString() ?? '0',
              'imageUrl': s['imageUrl'] ?? '',
              'imageUrls': s['imageUrls'] ?? [],
            };
          }).toList();
        }

        // Fetch ratings after services are loaded
        await fetchBusinessRatings();
      }
    } catch (e) {
      print('Error loading business details: $e');
      AppSnackbar.error('Failed to load business details');
    } finally {
      isLoading.value = false;
    }
  }

  // New: Fetch all reviews for business services
  Future<void> fetchBusinessRatings() async {
    try {
      isLoadingRatings.value = true;

      if (services.isEmpty) {
        averageRating.value = 0.0;
        totalReviews.value = 0;
        ratingDistribution.clear();
        return;
      }

      // Collect all service IDs
      final List<String> serviceIds = services.map((service) => service['id'] as String).toList();

      if (serviceIds.isEmpty) {
        averageRating.value = 0.0;
        totalReviews.value = 0;
        ratingDistribution.clear();
        return;
      }

      // Query reviews for all services
      // Note: Firestore doesn't support 'in' queries with more than 10 items
      // We'll query in batches if needed
      List<QueryDocumentSnapshot> allReviews = [];

      // Process in batches of 10
      for (int i = 0; i < serviceIds.length; i += 10) {
        final end = (i + 10) < serviceIds.length ? i + 10 : serviceIds.length;
        final batchIds = serviceIds.sublist(i, end);

        final querySnapshot = await FirebaseFirestore.instance
            .collection('reviews')
            .where('serviceId', whereIn: batchIds)
            .get();

        allReviews.addAll(querySnapshot.docs);
      }

      totalReviews.value = allReviews.length;

      if (allReviews.isEmpty) {
        averageRating.value = 0.0;
        ratingDistribution.clear();
        return;
      }

      // Calculate average rating and distribution
      int sumRatings = 0;
      final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final doc in allReviews) {
        final rating = doc['rating'] as int? ?? 0;
        if (rating >= 1 && rating <= 5) {
          sumRatings += rating;
          distribution[rating] = (distribution[rating] ?? 0) + 1;
        }
      }

      averageRating.value = sumRatings / totalReviews.value;
      ratingDistribution.value = distribution;

    } catch (e) {
      print('Error fetching business ratings: $e');
      averageRating.value = 0.0;
      totalReviews.value = 0;
      ratingDistribution.clear();
    } finally {
      isLoadingRatings.value = false;
    }
  }

  // Helper method to refresh ratings (useful after new review is submitted)
  Future<void> refreshRatings() async {
    await fetchBusinessRatings();
  }

  // Get rating text based on average rating
  String getRatingText() {
    final rating = averageRating.value;
    if (rating == 0) return 'Not Rated Yet';
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.5) return 'Good';
    if (rating >= 3.0) return 'Fair';
    return 'Poor';
  }

  // Get star display (rounded to nearest half-star)
  double getRoundedRating() {
    if (averageRating.value == 0) return 0;
    return (averageRating.value * 2).round() / 2;
  }

  // Open chat with business
  // Open chat with business - FIXED to use UID only
  // Open chat with business - FIXED to use UID only
  Future<void> openChatWithBusiness() async {
    if (business.value == null) {
      AppSnackbar.error('Unable to start chat');
      return;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      AppSnackbar.error('Please login to chat');
      return;
    }

    final businessUserId = businessId.value;

    if (businessUserId.isEmpty) {
      AppSnackbar.error('Unable to identify business');
      return;
    }

    // Show loading indicator
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      String businessName = 'Business';
      String businessEmail = '';
      String? businessProfileImage;

      // First, get the business role to confirm it's a business
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(businessUserId)
          .get();

      String userRole = userDoc.exists ? (userDoc.data()?['role'] as String? ?? '') : '';

      // If it's a business, fetch from businesses collection for the name
      if (userRole == 'business') {
        final businessDoc = await FirebaseFirestore.instance
            .collection('businesses')
            .doc(businessUserId)
            .get();

        if (businessDoc.exists) {
          final businessData = businessDoc.data();
          if (businessData != null) {
            businessName = businessData['businessName'] ?? 'Business';
            businessEmail = businessData['email'] ?? '';
            businessProfileImage = businessData['profileImage'];
          }
        } else {
          // Fallback to businesses collection with businessId from controller
          final businessDocFromId = await FirebaseFirestore.instance
              .collection('businesses')
              .doc(businessUserId)
              .get();

          if (businessDocFromId.exists) {
            final businessData = businessDocFromId.data();
            if (businessData != null) {
              businessName = businessData['businessName'] ?? 'Business';
              businessEmail = businessData['email'] ?? '';
              businessProfileImage = businessData['profileImage'];
            }
          } else {
            // Last fallback - use the business data from the controller
            businessName = business.value!['name'] ?? 'Business';
            businessEmail = business.value!['email'] ?? '';
            businessProfileImage = business.value!['profileImage'];
          }
        }
      } else {
        // Not a business? Use the business data from the controller
        businessName = business.value!['name'] ?? 'Business';
        businessEmail = business.value!['email'] ?? '';
        businessProfileImage = business.value!['profileImage'];
      }

      // Close loading dialog before navigation
      Get.back();

      // Navigate to chat or create new chat room
      await _navigateToChat(businessUserId, businessName, businessEmail, businessProfileImage);
    } catch (e) {
      Get.back(); // Close loading dialog
      print('[BusinessDetail] Error opening chat: $e');
      AppSnackbar.error('Failed to start chat: $e');
    }
  }

  Future<void> _navigateToChat(String otherUserId, String otherUserName, String otherUserEmail, String? profileImage) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Check if chat room already exists between these two users
      final existingChatSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      String? existingChatId;

      for (var doc in existingChatSnapshot.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(otherUserId) && participants.length == 2) {
          existingChatId = doc.id;
          break;
        }
      }

      if (existingChatId != null) {
        // Open existing chat - use Get.to() instead of Get.toNamed() for reliability
        Get.to(
              () => ChatScreen(),
          arguments: {
            'chatId': existingChatId,
            'userId': otherUserId,
            'userName': otherUserName,
            'userProfileImage': profileImage,
          },
          transition: Transition.rightToLeft,
        );
      } else {
        // Create new chat room
        final chatId = DateTime.now().millisecondsSinceEpoch.toString();

        // Fetch current user details
        final currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();
        final currentUserData = currentUserDoc.data() ?? {};
        final currentUserName = currentUserData['name'] ?? 'User';
        final currentUserEmail = currentUserData['email'] ?? '';
        final currentUserProfileImage = currentUserData['profileImage'] ?? '';

        final chatData = {
          'id': chatId,
          'participants': [currentUserId, otherUserId],
          'participantDetails': {
            currentUserId: {
              'name': currentUserName,
              'email': currentUserEmail,
              'profileImage': currentUserProfileImage,
            },
            otherUserId: {
              'name': otherUserName,
              'email': otherUserEmail,
              'profileImage': profileImage,
            },
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .set(chatData);

        // Open new chat - use Get.to() instead of Get.toNamed() for reliability
        Get.to(
              () => ChatScreen(),
          arguments: {
            'chatId': chatId,
            'userId': otherUserId,
            'userName': otherUserName,
            'userProfileImage': profileImage,
          },
          transition: Transition.rightToLeft,
        );
      }
    } catch (e) {
      print('[BusinessDetail] Error opening chat: $e');
      throw e;
    }
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

  void selectService(Map<String, dynamic> service) {
    selectedService.value = service;
  }

  void clearSelection() {
    selectedService.value = null;
  }

  void bookService(Map<String, dynamic> service) {
    AppSnackbar.success('Booking ${service['name']} at ${business.value?['name']}',
      position: SnackPosition.BOTTOM,
    );
  }

  void chatWithBusiness() {
    AppSnackbar.success('Starting chat with ${business.value?['name']}',
      position: SnackPosition.BOTTOM,
    );
  }
}