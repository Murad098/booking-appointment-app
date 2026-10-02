import 'dart:async';

import 'package:bookify/app/custom_snackbar.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../services/user_service.dart';
import '../../personal account/service details/service_detail_screen.dart';

class MyServicesController extends GetxController {
  final RxList<ServiceData> myServices = <ServiceData>[].obs;
  final RxBool isLoading = false.obs;

  // Stream subscription for real-time updates
  StreamSubscription<DocumentSnapshot>? _businessProfileSubscription;

  @override
  void onInit() {
    super.onInit();
    _setupRealtimeListener();
  }

  @override
  void onClose() {
    _businessProfileSubscription?.cancel();
    super.onClose();
  }

  void _setupRealtimeListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Listen to real-time changes to the business document
    _businessProfileSubscription = FirebaseFirestore.instance
        .collection('businesses')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _processBusinessData(snapshot.data()!);
      } else {
        myServices.clear();
      }
    }, onError: (e) {
      print('[MyServicesController] Realtime error: $e');
    });
  }

  void _processBusinessData(Map<String, dynamic> businessProfile) async {
    isLoading.value = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        myServices.clear();
        isLoading.value = false;
        return;
      }

      if (businessProfile['services'] != null) {
        final servicesList = businessProfile['services'] as List<dynamic>;

        final List<ServiceData> services = servicesList.map((service) {
          List<String>? imageUrls;
          if (service['imageUrls'] != null) {
            imageUrls = List<String>.from(service['imageUrls']);
          } else if (service['imageUrl'] != null && service['imageUrl'].toString().isNotEmpty) {
            imageUrls = [service['imageUrl']];
          }

          String displayImageUrl = '';
          if (imageUrls != null && imageUrls.isNotEmpty) {
            displayImageUrl = imageUrls.first;
          } else if (service['imageUrl'] != null) {
            displayImageUrl = service['imageUrl'];
          }

          return ServiceData(
            id: service['id'] ?? '',
            name: service['name'] ?? '',
            description: service['description'] ?? '',
            category: service['category'] ?? '',
            price: service['price']?.toString() ?? '0',
            duration: service['duration']?.toString() ?? '0',
            imageUrl: displayImageUrl,
            imageUrls: imageUrls,
            businessId: user.uid,
            businessName: businessProfile['businessName'] ?? '',
          );
        }).toList();

        myServices.assignAll(services);
        print('[MyServicesController] Realtime update - Loaded ${myServices.length} services');
      } else {
        myServices.clear();
      }
    } catch (e) {
      print('[MyServicesController] Error processing services: $e');
      AppSnackbar.error('Failed to load services');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchServices() async {
    // This method is kept for manual refresh compatibility
    isLoading.value = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        myServices.clear();
        isLoading.value = false;
        return;
      }

      final businessProfile = await UserService.getBusinessProfile(user.uid);

      if (businessProfile != null && businessProfile['services'] != null) {
        final servicesList = businessProfile['services'] as List<dynamic>;

        final List<ServiceData> services = servicesList.map((service) {
          List<String>? imageUrls;
          if (service['imageUrls'] != null) {
            imageUrls = List<String>.from(service['imageUrls']);
          } else if (service['imageUrl'] != null && service['imageUrl'].toString().isNotEmpty) {
            imageUrls = [service['imageUrl']];
          }

          String displayImageUrl = '';
          if (imageUrls != null && imageUrls.isNotEmpty) {
            displayImageUrl = imageUrls.first;
          } else if (service['imageUrl'] != null) {
            displayImageUrl = service['imageUrl'];
          }

          return ServiceData(
            id: service['id'] ?? '',
            name: service['name'] ?? '',
            description: service['description'] ?? '',
            category: service['category'] ?? '',
            price: service['price']?.toString() ?? '0',
            duration: service['duration']?.toString() ?? '0',
            imageUrl: displayImageUrl,
            imageUrls: imageUrls,
            businessId: user.uid,
            businessName: businessProfile['businessName'] ?? '',
          );
        }).toList();

        myServices.assignAll(services);
        print('[MyServicesController] Loaded ${myServices.length} services');
      } else {
        myServices.clear();
      }
    } catch (e) {
      print('[MyServicesController] Error loading services: $e');
      AppSnackbar.error('Failed to load services');
      myServices.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void onServiceTap(ServiceData service) {
    Get.to(
          () => ServiceDetailScreen(serviceId: service.id),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    )?.then((_) => refreshServices());
  }

  Future<void> refreshServices() async {
    await fetchServices();
  }
}

class ServiceData {
  final String id;
  final String name;
  final String description;
  final String category;
  final String price;
  final String duration;
  final String imageUrl;
  final List<String>? imageUrls;
  final String businessId;
  final String businessName;

  ServiceData({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.duration,
    required this.imageUrl,
    this.imageUrls,
    required this.businessId,
    required this.businessName,
  });
}