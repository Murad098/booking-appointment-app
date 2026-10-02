// business_appointments_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../../app/app_colors.dart';

class BusinessAppointmentsController extends GetxController {
  final statusTabIndex = 0.obs;
  final dateRangeFilter = 'all'.obs;
  final dateRangeLabel = 'All Time'.obs;
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();

  // ── Firestore data ──
  final isLoading = false.obs;
  final appointments = <Map<String, dynamic>>[].obs;

  StreamSubscription<QuerySnapshot>? _bookingsSubscription;

  @override
  void onInit() {
    super.onInit();
    _fetchAppointments();
  }

  @override
  void onClose() {
    _bookingsSubscription?.cancel();
    super.onClose();
  }

  // ─────────────────────────────────────────────
  //  FIRESTORE FETCH  (mirrors BusinessHomeController logic)
  // ─────────────────────────────────────────────
  void _fetchAppointments() {
    isLoading.value = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      isLoading.value = false;
      return;
    }

    _bookingsSubscription?.cancel();

    _bookingsSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('businessId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      _processBookings(snapshot.docs);
      isLoading.value = false;
    }, onError: (e) {
      print('[BusinessAppointmentsController] ❌ Error: $e');
      isLoading.value = false;
    });
  }

  void _processBookings(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final bookings = <Map<String, dynamic>>[];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Auto-resolve confirmed → completed if time has passed
      String status = data['status'] ?? 'pending';
      if (status == 'confirmed') {
        if (_isAppointmentPast(data, now)) {
          status = 'completed';
        }
      }

      final priceValue = double.tryParse(
          data['servicePrice']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ??
          0;
      final advanceValue = (data['advanceAmount'] ?? 0).toDouble();

      bookings.add({
        'id': doc.id,
        'services': data['serviceName'] ?? '',
        'customerName': data['customerName'] ?? '',
        'customerEmail': data['customerEmail'] ?? '',
        'customerPhone': data['customerPhone'] ?? '',
        'businessId': data['businessId'] ?? '',
        'businessName': data['businessName'] ?? '',
        'serviceId': data['serviceId'] ?? '',
        'serviceName': data['serviceName'] ?? '',
        'servicePrice': data['servicePrice'] ?? '0',
        'serviceDuration': data['serviceDuration'] ?? '0',
        'selectedDate': data['selectedDate'] ?? '',
        'selectedTime': data['selectedTime'] ?? '',
        'date': data['selectedDate']?.toString().split('T')[0] ?? '',
        'time': data['selectedTime'] ?? '',
        'duration': data['serviceDuration'] ?? '0',
        'price': priceValue,
        'advancePaid': advanceValue,
        'paymentMethod': data['paymentMethod'] ?? '',
        'paymentScreenshotUrl': data['paymentScreenshotUrl'] ?? '',
        'status': status,
        'createdAt': data['createdAt'],
        'customerId': data['customerId'] ?? '',
        'refunded': data['refunded'] ?? false,
        'autoCancelled': data['autoCancelled'] ?? false,
      });
    }

    appointments.value = bookings;
    update();
  }

  bool _isAppointmentPast(Map<String, dynamic> data, DateTime now) {
    try {
      final dateStr =
      (data['selectedDate']?.toString().split('T')[0] ?? data['date'] ?? '') as String;
      final timeStr = (data['selectedTime'] ?? data['time'] ?? '') as String;

      if (dateStr.isEmpty || timeStr.isEmpty) return false;

      final dateParts = dateStr.split('-');
      final timeParts = timeStr.split(':');

      final appointmentDateTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      return appointmentDateTime.isBefore(now);
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  //  DATE RANGE HELPERS  (unchanged from original)
  // ─────────────────────────────────────────────
  void changeStatusTab(int index) {
    statusTabIndex.value = index;
  }

  void setDateRange(String filter, DateTime? start, DateTime? end) {
    dateRangeFilter.value = filter;
    startDate.value = start;
    endDate.value = end;

    switch (filter) {
      case 'all':
        dateRangeLabel.value = 'All Time';
        break;
      case 'today':
        dateRangeLabel.value = 'Today';
        break;
      case 'week':
        dateRangeLabel.value = 'This Week';
        break;
      case 'month':
        dateRangeLabel.value = 'This Month';
        break;
      default:
        dateRangeLabel.value = 'Custom Range';
    }
    update();
  }

  void setStartDate(DateTime date) {
    startDate.value = date;
    if (endDate.value != null && date.isAfter(endDate.value!)) {
      endDate.value = date;
    }
    dateRangeLabel.value = 'Custom Range';
    dateRangeFilter.value = 'custom';
    update();
  }

  void setEndDate(DateTime date) {
    endDate.value = date;
    if (startDate.value != null && date.isBefore(startDate.value!)) {
      startDate.value = date;
    }
    dateRangeLabel.value = 'Custom Range';
    dateRangeFilter.value = 'custom';
    update();
  }

  void applyCustomDateRange() {
    if (startDate.value != null && endDate.value != null) {
      dateRangeLabel.value =
      '${_formatDate(startDate.value!)} - ${_formatDate(endDate.value!)}';
      dateRangeFilter.value = 'custom';
      update();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // ─────────────────────────────────────────────
  //  FILTERED LIST  (same logic, now from Firestore)
  // ─────────────────────────────────────────────
  List<Map<String, dynamic>> get filteredAppointments {
    final statusMap = {
      0: 'completed',
      1: 'pending',
      2: 'confirmed',
      3: 'cancelled',
    };
    final targetStatus = statusMap[statusTabIndex.value];

    var result = appointments.where((a) => a['status'] == targetStatus).toList();

    // Apply date range filter
    if (dateRangeFilter.value != 'all' &&
        startDate.value != null &&
        endDate.value != null) {
      result = result.where((a) {
        try {
          final dateStr = a['date'] as String;
          final appointmentDate = DateTime.parse(dateStr);
          final apptDateOnly = DateTime(
              appointmentDate.year, appointmentDate.month, appointmentDate.day);
          final startOnly = DateTime(
              startDate.value!.year, startDate.value!.month, startDate.value!.day);
          final endOnly = DateTime(
              endDate.value!.year, endDate.value!.month, endDate.value!.day);
          return apptDateOnly.isAtSameMomentAs(startOnly) ||
              (apptDateOnly.isAfter(startOnly) && apptDateOnly.isBefore(endOnly)) ||
              apptDateOnly.isAtSameMomentAs(endOnly);
        } catch (e) {
          return false;
        }
      }).toList();
    }

    // Sort: latest first
    result.sort((a, b) =>
        _parseAppointmentDateTime(b).compareTo(_parseAppointmentDateTime(a)));
    return result;
  }

  DateTime _parseAppointmentDateTime(Map<String, dynamic> appointment) {
    try {
      final dateStr = appointment['date'] as String;
      final timeStr = appointment['time'] as String;
      if (dateStr.isEmpty || timeStr.isEmpty) return DateTime(0);

      final dateParts = dateStr.split('-');
      final timeParts = timeStr.split(':');
      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (e) {
      return DateTime(0);
    }
  }

  // ─────────────────────────────────────────────
  //  DISPLAY HELPERS  (unchanged from original)
  // ─────────────────────────────────────────────
  String formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Color getStatusBadgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFF5EB);
      case 'confirmed':
        return const Color(0xFFE8F9F0);
      case 'completed':
        return const Color(0xFFE3F2FD);
      case 'cancelled':
        return const Color(0xFFFFEBEE);
      default:
        return Colors.grey[100]!;
    }
  }

  Color getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.statusWarning;
      case 'confirmed':
        return AppColors.statusSuccess;
      case 'completed':
        return AppColors.statusInfo;
      case 'cancelled':
        return AppColors.statusError;
      default:
        return Colors.grey;
    }
  }

  Color getStatusBorderColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.withOpacity(0.3);
      case 'confirmed':
        return Colors.blue.withOpacity(0.3);
      case 'completed':
        return Colors.green.withOpacity(0.3);
      case 'cancelled':
        return Colors.red.withOpacity(0.3);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }
}