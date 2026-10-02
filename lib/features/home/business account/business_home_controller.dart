import 'package:bookify/app/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../../Auth/auth_controller.dart';

class BusinessHomeController extends GetxController {
  // Observable for UI
  final isLoading = false.obs;
  final tabIndex = 0.obs;
  final bottomNavIndex = 0.obs;
  final overviewFilter = 'All'.obs;

  // Data observables
  final appointments = <Map<String, dynamic>>[].obs;
  final todayAppointments = 0.obs;
  final pendingCount = 0.obs;
  final confirmedCount = 0.obs;
  final completedCount = 0.obs;
  final autoCancelledCount = 0.obs;
  final totalRevenue = 0.0.obs;
  final totalCustomers = 0.obs;
  final todaysEarnings = 0.0.obs;

  // Stream subscription for real-time updates
  StreamSubscription<QuerySnapshot>? _bookingsSubscription;

  // FIX: Add a manual refresh trigger
  final _refreshTrigger = 0.obs;

  // Timer for periodic auto-cancel check
  Timer? _autoCancelTimer;

  // Helper to limit to 5 items
  List<Map<String, dynamic>> _limitToFive(List<Map<String, dynamic>> list) {
    return list.length > 5 ? list.take(5).toList() : list;
  }

  List<Map<String, dynamic>> get filteredAppointments {
    final now = DateTime.now();
    final today = now.toString().split(' ')[0];
    final yesterday = now.subtract(const Duration(days: 1)).toString().split(' ')[0];
    final tomorrow = now.add(const Duration(days: 1)).toString().split(' ')[0];

    List<Map<String, dynamic>> result;
    switch (overviewFilter.value) {
      case 'Today':
        result = appointments.where((a) => a['date'] == today).toList();
        break;
      case 'Tomorrow':
        result = appointments.where((a) => a['date'] == tomorrow).toList();
        break;
      case 'Yesterday':
        result = appointments.where((a) => a['date'] == yesterday).toList();
        break;
      case 'Previous':
        result = appointments.where((a) {
          final date = a['date'] as String;
          return date.compareTo(yesterday) < 0;
        }).toList();
        break;
      case 'Upcoming':
        result = appointments.where((a) {
          final date = a['date'] as String;
          return date.compareTo(today) >= 0;
        }).toList();
        break;
      default:
        result = List.from(appointments);
    }
    result.sort((a, b) => _parseAppointmentDateTime(b).compareTo(_parseAppointmentDateTime(a)));
    return _limitToFive(result);
  }

  List<Map<String, dynamic>> get pendingAppointments {
    final result = appointments.where((a) => a['status'] == 'pending' && a['autoCancelled'] != true).toList();
    result.sort((a, b) => _parseAppointmentDateTime(b).compareTo(_parseAppointmentDateTime(a)));
    return _limitToFive(result);
  }

  List<Map<String, dynamic>> get confirmedAppointments {
    final result = appointments.where((a) => a['status'] == 'confirmed').toList();
    result.sort((a, b) => _parseAppointmentDateTime(b).compareTo(_parseAppointmentDateTime(a)));
    return _limitToFive(result);
  }

  List<Map<String, dynamic>> get autoCancelledAppointments {
    final result = appointments.where((a) => a['autoCancelled'] == true).toList();
    result.sort((a, b) => _parseAppointmentDateTime(b).compareTo(_parseAppointmentDateTime(a)));
    return _limitToFive(result);
  }


  // Revenue calculation based on status with refund handling
  double get calculatedTotalRevenue {
    double revenue = 0.0;
    for (var appointment in appointments) {
      final status = appointment['status'] as String;
      final price = appointment['price'] as double;
      final advancePaid = appointment['advancePaid'] as double? ?? 0;
      final autoCancelled = appointment['autoCancelled'] as bool? ?? false;
      final refunded = appointment['refunded'] as bool? ?? false;

      if (autoCancelled) continue;

      if (status == 'confirmed') {
        revenue += advancePaid;
      } else if (status == 'completed') {
        revenue += price;
      } else if (status == 'cancelled' && refunded) {
        revenue -= advancePaid;
      }
    }
    return revenue;
  }

  // Today's earnings calculation - FIXED
  // Rule:
  // 1. Advance payments (20%) from bookings created today
  // 2. Remaining payments (80%) from appointments completed today
  double get calculatedTodaysEarnings {
    final todayDate = DateTime.now().toString().split(' ')[0];
    double earnings = 0.0;

    for (var appointment in appointments) {
      final autoCancelled = appointment['autoCancelled'] as bool? ?? false;
      if (autoCancelled) continue;

      final status = appointment['status'] as String;
      final price = appointment['price'] as double;
      final advancePaid = appointment['advancePaid'] as double? ?? 0;
      final remainingAmount = price - advancePaid;

      // Get booking creation date
      final bookingCreatedDate = appointment['bookingCreatedDate'] as String? ?? '';

      // Get completion date if completed
      final completedAt = appointment['completedAt'] as Timestamp?;
      final completionDate = completedAt != null
          ? completedAt.toDate().toString().split(' ')[0]
          : '';

      // Case 1: Advance payment from booking created today
      if (bookingCreatedDate == todayDate) {
        earnings += advancePaid;
      }

      // Case 2: Remaining payment from appointment completed today
      if (status == 'completed' && completionDate == todayDate) {
        earnings += remainingAmount;
      }
    }

    return earnings;
  }



  String get revenue => 'PKR ${calculatedTotalRevenue.toStringAsFixed(0)}';
  String get todayEarnings => 'PKR ${calculatedTodaysEarnings.toStringAsFixed(0)}';

  @override
  void onInit() {
    super.onInit();
    fetchBusinessData();
    _startAutoCancelTimer();
    _refreshBranchStatus();
  }

  @override
  void onClose() {
    _bookingsSubscription?.cancel();
    _autoCancelTimer?.cancel();
    super.onClose();
  }

  void _startAutoCancelTimer() {
    _autoCancelTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndAutoCancelExpiredAppointments();
    });
  }
  // NEW method: ensures AuthController exists and refreshes branch status
  Future<void> _refreshBranchStatus() async {
    // Ensure AuthController is registered (it may not be if user goes directly to home)
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }
    final authController = Get.find<AuthController>();
    await authController.refreshBranchStatus();
  }

  Future<void> _checkAndAutoCancelExpiredAppointments() async {
    final now = DateTime.now();
    bool hasUpdates = false;

    for (var appointment in appointments) {
      final status = appointment['status'] as String? ?? 'pending';
      final autoCancelled = appointment['autoCancelled'] as bool? ?? false;

      if (status == 'pending' && !autoCancelled) {
        if (_isAppointmentPast(appointment, now)) {
          await _autoCancelAppointment(appointment['id']);
          hasUpdates = true;
        }
      }
    }

    if (hasUpdates) {
      fetchBusinessData();
    }
  }

  Future<void> _autoCancelAppointment(String id) async {
    try {
      print('[BusinessHomeController] Auto-cancelling appointment: $id');

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(id)
          .update({
        'status': 'cancelled',
        'autoCancelled': true,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'refunded': false,
      });

      print('[BusinessHomeController] Auto-cancelled appointment: $id');
    } catch (e) {
      print('[BusinessHomeController] Error auto-cancelling appointment $id: $e');
    }
  }

  void fetchBusinessData() {
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
        .snapshots(includeMetadataChanges: true)
        .listen((bookingsSnapshot) {
      print('[BusinessHomeController] Real-time update received. Docs count: ${bookingsSnapshot.docs.length}');
      _processBookings(bookingsSnapshot.docs);
      isLoading.value = false;
      _refreshTrigger.value++;
    }, onError: (e) {
      print('Error fetching business data: $e');
      AppSnackbar.error('Failed to load dashboard data');
      isLoading.value = false;
    });
  }

  void _processBookings(List<QueryDocumentSnapshot> docs) {
    print('[BusinessHomeController] Processing ${docs.length} bookings');
    final bookings = <Map<String, dynamic>>[];
    double totalRevenueCalc = 0;
    int confirmed = 0;
    int pending = 0;
    int completed = 0;
    int autoCancelledTotal = 0;
    int todayCount = 0;
    final customersSet = <String>{};
    final todayDate = DateTime.now().toString().split(' ')[0];
    final now = DateTime.now();

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      String status = data['status'] ?? 'pending';
      bool isAutoCancelled = data['autoCancelled'] ?? false;
      final refunded = data['refunded'] ?? false;

      // Get booking creation date
      final createdAt = data['createdAt'] as Timestamp?;
      final bookingCreatedDate = createdAt != null
          ? createdAt.toDate().toString().split(' ')[0]
          : '';

      if (status == 'confirmed') {
        if (_isAppointmentPastData(data, now)) {
          status = 'completed';
          _updateAppointmentStatusToCompleted(doc.id);
        }
      }

      if (status == 'pending' && !isAutoCancelled) {
        if (_isAppointmentPastData(data, now)) {
          status = 'cancelled';
          isAutoCancelled = true;
          _updateAppointmentToAutoCancelled(doc.id);
        }
      }

      final priceStr = data['servicePrice']?.toString() ?? '0';
      final priceValue = double.tryParse(priceStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      final advanceValue = (data['advanceAmount'] ?? 0).toDouble();
      final remainingValue = priceValue - advanceValue;

      final appointment = {
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
        'remainingAmount': remainingValue,
        'paymentMethod': data['paymentMethod'] ?? '',
        'paymentScreenshotUrl': data['paymentScreenshotUrl'] ?? '',
        'status': status,
        'createdAt': createdAt,
        'bookingCreatedDate': bookingCreatedDate,
        'customerId': data['customerId'] ?? '',
        'refunded': refunded,
        'autoCancelled': isAutoCancelled,
        'completedAt': data['completedAt'],
      };

      bookings.add(appointment);
      print('[BusinessHomeController] Appointment ${doc.id} status: $status, autoCancelled: $isAutoCancelled, created: $bookingCreatedDate');

      // Calculate total revenue (advance always, remaining only if completed)
      if (!isAutoCancelled) {
        // Add advance payment to total revenue (always)
        totalRevenueCalc += advanceValue;

        if (status == 'completed') {
          // Add remaining payment when completed
          totalRevenueCalc += remainingValue;
          completed++;
        } else if (status == 'confirmed') {
          confirmed++;
        } else if (status == 'cancelled' && refunded) {
          // Subtract advance if refunded
          totalRevenueCalc -= advanceValue;
        }
      }

      if (status == 'pending' && !isAutoCancelled) {
        pending++;
      }

      if (isAutoCancelled) {
        autoCancelledTotal++;
      }

      // Count today's appointments (all statuses except auto-cancelled)
      final appointmentDate = data['selectedDate']?.toString().split('T')[0] ?? '';
      if (appointmentDate == todayDate && !isAutoCancelled && status != 'cancelled') {
        todayCount++;
      }

      if (data['customerId'] != null && data['customerId'].toString().isNotEmpty) {
        customersSet.add(data['customerId']);
      }
    }

    appointments.assignAll(bookings);
    totalRevenue.value = totalRevenueCalc;

    // Today's earnings will be calculated by the getter, but we also update the observable
    // to trigger UI refresh
    todaysEarnings.value = calculatedTodaysEarnings;

    confirmedCount.value = confirmed;
    completedCount.value = completed;
    pendingCount.value = pending;
    autoCancelledCount.value = autoCancelledTotal;
    todayAppointments.value = todayCount;
    totalCustomers.value = customersSet.length;

    print('[BusinessHomeController] Stats - Pending: $pending, Confirmed: $confirmed, Completed: $completed, AutoCancelled: $autoCancelledTotal');
    print('[BusinessHomeController] Today\'s Earnings: ${todaysEarnings.value}');
  }

  Future<void> _updateAppointmentStatusToCompleted(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(id)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[BusinessHomeController] Updated appointment to completed: $id');
    } catch (e) {
      print('[BusinessHomeController] Error updating to completed: $e');
    }
  }

  Future<void> _updateAppointmentToAutoCancelled(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(id)
          .update({
        'status': 'cancelled',
        'autoCancelled': true,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[BusinessHomeController] Updated appointment to auto-cancelled: $id');
    } catch (e) {
      print('[BusinessHomeController] Error updating to auto-cancelled: $e');
    }
  }

  void _autoUpdateCompletedStatus() {
    final now = DateTime.now();
    bool updated = false;

    for (var appointment in appointments) {
      if (appointment['status'] == 'confirmed') {
        if (_isAppointmentPast(appointment, now)) {
          appointment['status'] = 'completed';
          updated = true;
          _updateAppointmentStatusToCompleted(appointment['id']);
        }
      }
    }

    if (updated) {
      _recalculateStats();
    }
  }

  void _recalculateStats() {
    double revenue = 0;
    int confirmed = 0;
    int completed = 0;
    int pending = 0;
    int autoCancelled = 0;
    int todayCount = 0;
    final todayDate = DateTime.now().toString().split(' ')[0];

    for (var appointment in appointments) {
      final autoCancelledFlag = appointment['autoCancelled'] == true;
      final refunded = appointment['refunded'] == true;

      if (!autoCancelledFlag) {
        if (appointment['status'] == 'confirmed') {
          revenue += appointment['advancePaid'] as double;
          confirmed++;
        } else if (appointment['status'] == 'completed') {
          revenue += appointment['price'] as double;
          completed++;
        } else if (appointment['status'] == 'cancelled' && refunded) {
          revenue -= appointment['advancePaid'] as double;
        }
      }

      if (appointment['status'] == 'pending' && !autoCancelledFlag) {
        pending++;
      }
      if (autoCancelledFlag) {
        autoCancelled++;
      }

      final appointmentDate = appointment['date'] ?? '';
      if (appointmentDate == todayDate && appointment['status'] != 'cancelled' && !autoCancelledFlag) {
        todayCount++;
      }
    }

    totalRevenue.value = revenue;
    confirmedCount.value = confirmed;
    completedCount.value = completed;
    pendingCount.value = pending;
    autoCancelledCount.value = autoCancelled;
    todayAppointments.value = todayCount;

    // Update today's earnings
    todaysEarnings.value = calculatedTodaysEarnings;

    appointments.refresh();
  }

  bool _isAppointmentPast(Map<String, dynamic> appointment, DateTime now) {
    try {
      final dateStr = appointment['date'] as String? ?? '';
      final timeStr = appointment['time'] as String? ?? '';
      return _isDateTimePast(dateStr, timeStr, now);
    } catch (e) {
      return false;
    }
  }

  bool _isAppointmentPastData(Map<String, dynamic> data, DateTime now) {
    try {
      final dateStr = data['selectedDate']?.toString() ?? data['date']?.toString() ?? '';
      final timeStr = data['selectedTime']?.toString() ?? data['time']?.toString() ?? '';
      return _isDateTimePast(dateStr, timeStr, now);
    } catch (e) {
      return false;
    }
  }

  bool _isDateTimePast(String dateStr, String timeStr, DateTime now) {
    if (dateStr.isEmpty || timeStr.isEmpty) return false;

    try {
      String cleanDateStr = dateStr;
      if (dateStr.contains('T')) {
        cleanDateStr = dateStr.split('T')[0];
      }

      final dateParts = cleanDateStr.split('-');
      if (dateParts.length != 3) return false;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      String cleanTimeStr = timeStr;
      if (timeStr.contains(' - ')) {
        cleanTimeStr = timeStr.split(' - ')[0].trim();
      }

      final timeParts = cleanTimeStr.split(':');
      if (timeParts.length < 2) return false;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final appointmentDateTime = DateTime(year, month, day, hour, minute);
      return appointmentDateTime.isBefore(now);
    } catch (e) {
      return false;
    }
  }

  DateTime _parseAppointmentDateTime(Map<String, dynamic> appointment) {
    try {
      final dateStr = appointment['date'] as String? ?? '';
      final timeStr = appointment['time'] as String? ?? '';
      if (dateStr.isEmpty || timeStr.isEmpty) return DateTime(0);

      String cleanDateStr = dateStr;
      if (dateStr.contains('T')) {
        cleanDateStr = dateStr.split('T')[0];
      }

      final dateParts = cleanDateStr.split('-');
      String cleanTimeStr = timeStr;
      if (timeStr.contains(' - ')) {
        cleanTimeStr = timeStr.split(' - ')[0].trim();
      }
      final timeParts = cleanTimeStr.split(':');

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

  void changeTab(int index) {
    tabIndex.value = index;
    if (index == 0) _autoUpdateCompletedStatus();
  }

  void changeBottomNav(int index) {
    bottomNavIndex.value = index;
  }

  void changeOverviewFilter(String filter) {
    overviewFilter.value = filter;
  }

  void approveAppointment(String id) async {
    try {
      final index = appointments.indexWhere((a) => a['id'] == id);
      if (index != -1) {
        if (appointments[index]['autoCancelled'] == true) {
          AppSnackbar.error('Cannot approve an auto-cancelled appointment');
          return;
        }

        if (_isAppointmentPast(appointments[index], DateTime.now())) {
          AppSnackbar.error('Cannot approve an expired appointment');
          return;
        }

        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(id)
            .update({
          'status': 'confirmed',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        AppSnackbar.success('Appointment approved successfully');
      }
    } catch (e) {
      print('Error approving appointment: $e');
      AppSnackbar.error('Failed to approve appointment');
    }
  }

  void rejectAppointment(String id) async {
    try {
      final index = appointments.indexWhere((a) => a['id'] == id);
      if (index != -1) {
        if (appointments[index]['autoCancelled'] == true) {
          AppSnackbar.error('Cannot reject an auto-cancelled appointment');
          return;
        }

        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(id)
            .update({
          'status': 'cancelled',
          'autoCancelled': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        AppSnackbar.error('Appointment has been rejected');
      }
    } catch (e) {
      print('Error rejecting appointment: $e');
      AppSnackbar.error('Failed to reject appointment');
    }
  }

  String formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      String cleanDateStr = dateStr;
      if (dateStr.contains('T')) {
        cleanDateStr = dateStr.split('T')[0];
      }
      final date = DateTime.parse(cleanDateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}