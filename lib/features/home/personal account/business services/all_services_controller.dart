import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/custom_snackbar.dart';

class ServiceData {
  final String id;
  final String name;
  final String description;
  final String category;
  final String price;
  final String duration;
  final String imageUrl;
  final List<String> imageUrls;
  final String businessId;

  ServiceData({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.duration,
    required this.imageUrl,
    required this.imageUrls,
    required this.businessId,
  });

  factory ServiceData.fromMap(Map<String, dynamic> map, String docId) {
    List<String> imageUrls = [];
    if (map['imageUrls'] != null) {
      imageUrls = List<String>.from(map['imageUrls']);
    } else if (map['imageUrl'] != null && map['imageUrl'].toString().isNotEmpty) {
      imageUrls = [map['imageUrl']];
    }

    return ServiceData(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: map['price']?.toString() ?? '0',
      duration: map['duration']?.toString() ?? '0',
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
      imageUrls: imageUrls,
      businessId: map['businessId'] ?? '',
    );
  }
}

class AllServicesController extends GetxController {
  final businessId = ''.obs;
  final businessName = ''.obs;
  final services = <ServiceData>[].obs;
  final isLoading = false.obs;

  StreamSubscription<DocumentSnapshot>? _businessSubscription;

  @override
  void onClose() {
    _businessSubscription?.cancel();
    super.onClose();
  }

  void initBusiness(String id, {String? name}) {
    businessId.value = id;
    if (name != null) {
      businessName.value = name;
    }
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    if (businessId.value.isEmpty) return;

    isLoading.value = true;

    _businessSubscription?.cancel();
    _businessSubscription = FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId.value)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;

        // Update business name if not provided
        if (businessName.value.isEmpty) {
          businessName.value = data['businessName'] ?? '';
        }

        // Load services
        if (data['services'] != null) {
          final servicesList = data['services'] as List<dynamic>;
          final List<ServiceData> loadedServices = [];

          for (var service in servicesList) {
            loadedServices.add(ServiceData.fromMap(service, service['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()));
          }

          services.assignAll(loadedServices);
          print('[AllServicesController] Loaded ${services.length} services for business: ${businessId.value}');
        } else {
          services.clear();
        }
      } else {
        services.clear();
        AppSnackbar.error('Business not found');
      }
      isLoading.value = false;
    }, onError: (e) {
      print('[AllServicesController] Error: $e');
      isLoading.value = false;
      AppSnackbar.error('Failed to load services');
    });
  }

  Future<void> refreshServices() async {
    _setupRealtimeListener();
  }
}