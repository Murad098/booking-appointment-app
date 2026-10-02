import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/user_service.dart';
import '../payment method/payment_methods_screen.dart';
import 'add_edit_service_screen.dart';
import '../../../../app/app_colors.dart';

class BusinessServiceController extends GetxController {
  final services = <Service>[].obs;
  final isLoading = false.obs;
  final businessCategories = <String>[].obs;
  final hasPaymentMethods = false.obs;

  // Firestore stream subscription
  StreamSubscription<DocumentSnapshot>? _businessDocSubscription;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    if (userId != null) {
      _listenToBusinessData();
    } else {
      // If no user, we still want to stop loading and show empty state
      isLoading.value = false;
    }
    loadBusinessCategory(); // load suggestions (not real-time, but fine)
  }

  /// Listens to the business document for real‑time updates
  void _listenToBusinessData() {
    if (userId == null) return;

    isLoading.value = true;

    _businessDocSubscription = FirebaseFirestore.instance
        .collection('businesses')
        .doc(userId)
        .snapshots()
        .listen(
          (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data()!;

          // Update services
          final servicesList = data['services'] as List?;
          if (servicesList != null) {
            services.value = servicesList
                .map((s) => Service.fromMap(s as Map<String, dynamic>))
                .toList();
          } else {
            services.clear();
          }

          // Update payment methods status
          final methods = data['paymentMethods'] as List?;
          hasPaymentMethods.value = (methods != null && methods.isNotEmpty);
        } else {
          // Document doesn't exist yet – clear everything
          services.clear();
          hasPaymentMethods.value = false;
        }

        // First data received – hide loading
        if (isLoading.value) {
          isLoading.value = false;
        }
      },
      onError: (error) {
        print('❌ Error listening to business data: $error');
        isLoading.value = false; // stop loading on error
      },
    );
  }

  @override
  void onClose() {
    _businessDocSubscription?.cancel();
    super.onClose();
  }

  // ---------- Category suggestions (not real‑time) ----------
  Future<void> loadBusinessCategory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final businessProfile = await UserService.getBusinessProfile(user.uid);
        if (businessProfile != null && businessProfile['category'] != null) {
          businessCategories.value = _getSuggestionsForCategory(businessProfile['category']);
        }
      }
    } catch (e) {
      print('Error loading business category: $e');
    }
  }

  List<String> _getSuggestionsForCategory(String category) {
    final Map<String, List<String>> categorySuggestions = {
      'Beauty & Wellness': [
        'Haircut', 'Hair Coloring', 'Hair Styling', 'Manicure', 'Pedicure',
        'Facial', 'Makeup', 'Waxing', 'Threading', 'Bleaching', 'Massage',
        'Body Scrub', 'Nail Art', 'Bridal Makeup', 'Hair Treatment'
      ],
      'Health & Fitness': [
        'Personal Training', 'Yoga', 'Pilates', 'Zumba', 'Cardio', 'Weight Training',
        'Nutrition Counseling', 'Physical Therapy', 'CrossFit', 'Boxing'
      ],
      'Food & Dining': [
        'Food Delivery', 'Catering', 'Dine-in', 'Takeaway', 'Buffet', 'Fine Dining',
        'Fast Food', 'Bakery', 'Coffee Shop', 'Food Truck'
      ],
      'Automotive': [
        'Car Wash', 'Oil Change', 'Tire Rotation', 'Brake Service', 'Engine Repair',
        'AC Repair', 'Battery Replacement', 'Car Detailing', 'Paint Job'
      ],
      'Home Services': [
        'Plumbing', 'Electrical', 'Carpentry', 'Painting', 'Cleaning', 'Pest Control',
        'Gardening', 'AC Repair', 'Appliance Repair', 'Moving Services'
      ],
      'Professional Services': [
        'Legal Consultation', 'Accounting', 'Tax Preparation', 'Consulting',
        'Marketing', 'Web Design', 'Photography', 'Event Planning'
      ],
      'Retail': [
        'Clothing', 'Electronics', 'Groceries', 'Furniture', 'Books', 'Shoes',
        'Jewelry', 'Sports Equipment', 'Toys', 'Pet Supplies'
      ],
      'Education': [
        'Tutoring', 'Test Prep', 'Language Classes', 'Music Lessons', 'Art Classes',
        'Coding Classes', 'Online Courses', 'Workshops'
      ],
      'Entertainment': [
        'Concert Tickets', 'Movie Tickets', 'Event Booking', 'Party Planning',
        'DJ Services', 'Photography', 'Videography'
      ],
      'Other': [
        'Custom Service', 'Consultation', 'Maintenance', 'Repair', 'Installation'
      ]
    };

    return categorySuggestions[category] ?? categorySuggestions['Other']!;
  }

  // ---------- CRUD operations ----------
  Future<void> saveServicesToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final servicesData = services.map((s) => s.toMap()).toList();
        await UserService.updateBusinessServices(user.uid, servicesData);
      }
    } catch (e) {
      print('Error saving services: $e');
    }
  }

  Future<void> addService(Service service) async {
    services.add(service); // UI updates immediately via stream, but we still write
    await saveServicesToFirestore();
  }

  Future<void> updateService(String id, Service updatedService) async {
    final index = services.indexWhere((s) => s.id == id);
    if (index != -1) {
      services[index] = updatedService;
      await saveServicesToFirestore();
    }
  }

  Future<void> deleteService(String id) async {
    services.removeWhere((s) => s.id == id);
    await saveServicesToFirestore();
  }

  Service? getServiceById(String id) {
    try {
      return services.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  // ---------- Payment method check (now just reads the reactive value) ----------
  Future<void> checkPaymentMethods() async {
    // The stream already maintains hasPaymentMethods, so we can just return.
    // But we keep this method for compatibility (may be called from screen).
    // We'll optionally refresh by re-fetching once.
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final businessProfile = await UserService.getBusinessProfile(user.uid);
        if (businessProfile != null) {
          final methods = businessProfile['paymentMethods'] as List?;
          hasPaymentMethods.value = (methods != null && methods.isNotEmpty);
        } else {
          hasPaymentMethods.value = false;
        }
      }
    } catch (e) {
      print('Error checking payment methods: $e');
      hasPaymentMethods.value = false;
    }
  }

  // ---------- Dialogs and navigation ----------
  Future<void> showPaymentMethodRequiredDialog() async {
    await Get.dialog(
      AlertDialog(
        title: Text(
          'Payment Method Required',
          style: TextStyle(color: AppColors.textHeadline),
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: AppColors.textBody),
            children: [
              TextSpan(text: 'You need to add a '),
              TextSpan(
                text: 'payment method',
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    Get.back(); // close dialog
                    await Get.to(() => PaymentMethodsScreen());
                    // Stream will auto-update, but we can force a refresh if needed
                    await checkPaymentMethods();
                  },
              ),
              TextSpan(text: ' before you can add services.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: AppColors.textBody)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // close dialog
              await Get.to(() => PaymentMethodsScreen());
              await checkPaymentMethods();
            },
            child: Text('Add Payment Method', style: TextStyle(color: Colors.white),),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> showAddService() async {
    await checkPaymentMethods(); // ensure latest status
    if (!hasPaymentMethods.value) {
      await showPaymentMethodRequiredDialog();
      return;
    }
    await Get.to(() => const AddEditServiceScreen());
    // Stream will update, no need to call loadAllData
  }

  Future<void> showEditService(Service service) async {
    await Get.to(() => AddEditServiceScreen(service: service));
    // Stream updates automatically
  }
}

// Service class remains unchanged
class Service {
  final String id;
  final String name;
  final String description;
  final String category;
  final int price;
  final int duration;
  final List<String>? imageUrls;
  final String? imageUrl;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.duration,
    this.imageUrls,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'duration': duration,
      'imageUrls': imageUrls ?? (imageUrl != null ? [imageUrl!] : []),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: map['price'] ?? 0,
      duration: map['duration'] ?? 0,
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(map['imageUrls'])
          : (map['imageUrl'] != null ? [map['imageUrl']] : null),
      imageUrl: map['imageUrl'],
    );
  }
}