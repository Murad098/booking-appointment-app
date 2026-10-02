import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../../../services/user_service.dart';

class MyAppointmentsController extends GetxController {
  final tabIndex = 0.obs; // 0 = Upcoming, 1 = Past (kept for backward compatibility)
  final isExpanded = false.obs;

  // ✅ NEW: Filter dropdown value
  final selectedFilter = 'All'.obs;

  // Loading states
  final isLoading = false.obs;
  final userRole = ''.obs;

  // Firestore data
  final allAppointments = <Map<String, dynamic>>[].obs;

  // Stream subscription for real-time updates
  StreamSubscription<QuerySnapshot>? _bookingsSubscription;

  @override
  void onInit() {
    super.onInit();
    fetchUserAndAppointments();
  }

  @override
  void onClose() {
    _bookingsSubscription?.cancel();
    super.onClose();
  }

  // Fetch user role and then load appointments
  Future<void> fetchUserAndAppointments() async {
    try {
      isLoading.value = true;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('[MyAppointments] No user logged in');
        isLoading.value = false;
        return;
      }

      // Get user role from UserService
      final role = await UserService.getUserRole(user.uid);
      userRole.value = role ?? 'personal';
      print('[MyAppointments] User role: ${userRole.value}');

      // Load appointments based on role
      await loadAppointmentsForUser(user.uid, userRole.value);

    } catch (e) {
      print('[MyAppointments] Error fetching user: $e');
      isLoading.value = false;
    }
  }

  Future<void> loadAppointmentsForUser(String userId, String role) async {
    isLoading.value = true;

    // Cancel any existing subscription
    _bookingsSubscription?.cancel();

    try {
      Query query;

      if (role == 'business') {
        // Business user: match by businessId
        query = FirebaseFirestore.instance
            .collection('bookings')
            .where('businessId', isEqualTo: userId);
        print('[MyAppointments] Fetching business appointments for: $userId');
      } else {
        // Personal user: match by customerId
        query = FirebaseFirestore.instance
            .collection('bookings')
            .where('customerId', isEqualTo: userId);
        print('[MyAppointments] Fetching customer appointments for: $userId');
      }

      // Listen to real-time updates
      _bookingsSubscription = query.snapshots().listen((snapshot) {
        _processBookings(snapshot.docs);
        isLoading.value = false;
      }, onError: (error) {
        print('[MyAppointments] Error loading appointments: $error');
        isLoading.value = false;
      });

    } catch (e) {
      print('[MyAppointments] Error setting up appointments stream: $e');
      isLoading.value = false;
    }
  }

  void _processBookings(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final bookings = <Map<String, dynamic>>[];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Get status, handle auto-completion for confirmed past appointments
      String status = data['status'] ?? 'pending';
      if (status == 'confirmed') {
        if (_isAppointmentPast(data, now)) {
          status = 'completed';
        }
      }

      // Parse price values
      final priceValue = double.tryParse(
          data['servicePrice']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 0;
      final advanceValue = (data['advanceAmount'] ?? 0).toDouble();

      // Get date and time
      final selectedDate = data['selectedDate']?.toString() ?? '';
      final selectedTime = data['selectedTime']?.toString() ?? '';
      final dateStr = selectedDate.split('T')[0];

      final appointment = {
        'id': doc.id,
        'services': data['serviceName'] ?? data['services'] ?? 'Service',
        'customerName': data['customerName'] ?? 'Customer',
        'customerEmail': data['customerEmail'] ?? '',
        'customerPhone': data['customerPhone'] ?? '',
        'businessId': data['businessId'] ?? '',
        'businessName': data['businessName'] ?? 'Business',
        'serviceId': data['serviceId'] ?? '',
        'serviceName': data['serviceName'] ?? '',
        'servicePrice': data['servicePrice'] ?? '0',
        'serviceDuration': data['serviceDuration'] ?? '0',
        'selectedDate': selectedDate,
        'selectedTime': selectedTime,
        'date': dateStr,
        'time': selectedTime,
        'duration': data['serviceDuration']?.toString() ?? '0',
        'price': priceValue,
        'advancePaid': advanceValue,
        'paymentMethod': data['paymentMethod'] ?? '',
        'paymentScreenshotUrl': data['paymentScreenshotUrl'] ?? '',
        'status': status,
        'createdAt': data['createdAt'],
        'customerId': data['customerId'] ?? '',
        'refunded': data['refunded'] ?? false,
        'autoCancelled': data['autoCancelled'] ?? false,
        'dateTime': _getDateTimeFromAppointment(data), // For sorting
      };

      bookings.add(appointment);
    }

    // Sort all appointments by date and time (nearest/latest first)
    bookings.sort((a, b) {
      final dateTimeA = a['dateTime'] as DateTime?;
      final dateTimeB = b['dateTime'] as DateTime?;
      if (dateTimeA == null && dateTimeB == null) return 0;
      if (dateTimeA == null) return 1;
      if (dateTimeB == null) return -1;
      return dateTimeA.compareTo(dateTimeB);
    });

    allAppointments.value = bookings;
    print('[MyAppointments] Loaded ${bookings.length} appointments');
  }

  // Helper method to get DateTime from appointment data
  DateTime? _getDateTimeFromAppointment(Map<String, dynamic> data) {
    try {
      final dateStr = data['selectedDate']?.toString().split('T')[0] ?? '';
      final timeStr = data['selectedTime']?.toString() ?? '';

      if (dateStr.isEmpty) return null;

      final dateParts = dateStr.split('-');
      if (dateParts.length != 3) return null;

      final timeParts = timeStr.split(':');
      int hour = 0, minute = 0;
      if (timeParts.length >= 2) {
        hour = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);
      }

      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        hour,
        minute,
      );
    } catch (e) {
      return null;
    }
  }

  bool _isAppointmentPast(Map<String, dynamic> data, DateTime now) {
    try {
      final dateStr = data['selectedDate']?.toString().split('T')[0] ?? '';
      final timeStr = data['selectedTime']?.toString() ?? '';

      if (dateStr.isEmpty || timeStr.isEmpty) return false;

      final dateParts = dateStr.split('-');
      if (dateParts.length != 3) return false;

      final timeParts = timeStr.split(':');
      if (timeParts.length < 2) return false;

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

  // ✅ NEW: Filtered appointments based on dropdown selection
  List<Map<String, dynamic>> get filteredAppointments {
    final today = DateTime.now();

    switch (selectedFilter.value) {
      case 'Upcoming':
        return allAppointments.where((apt) {
          final dateTime = apt['dateTime'] as DateTime?;
          if (dateTime == null) return false;
          final isActiveStatus = apt['status'] == 'pending' ||
              apt['status'] == 'confirmed';
          return dateTime.isAfter(today) && isActiveStatus;
        }).toList();

      case 'Pending':
        return allAppointments.where((apt) => apt['status'] == 'pending').toList();

      case 'Confirmed':
        return allAppointments.where((apt) => apt['status'] == 'confirmed').toList();

      case 'Completed':
        return allAppointments.where((apt) => apt['status'] == 'completed').toList();

      case 'Cancelled':
        return allAppointments.where((apt) => apt['status'] == 'cancelled').toList();

      case 'Past':
        return allAppointments.where((apt) {
          final dateTime = apt['dateTime'] as DateTime?;
          if (dateTime == null) return false;
          return dateTime.isBefore(today);
        }).toList();

      case 'All':
      default:
        return allAppointments.toList();
    }
  }

  // Get current user's appointments (filtered by customer/business ID)
  List<Map<String, dynamic>> get allFilteredAppointments => allAppointments;

  // Filter appointments by status for Upcoming tab (kept for backward compatibility)
  List<Map<String, dynamic>> get upcomingAppointments {
    final today = DateTime.now();
    return allAppointments.where((apt) {
      final dateStr = apt['date'] as String;
      try {
        final date = DateTime.parse(dateStr);
        final isTodayOrFuture = date.isAtSameMomentAs(today) || date.isAfter(today);
        final isActiveStatus = apt['status'] == 'pending' ||
            apt['status'] == 'confirmed';
        return isTodayOrFuture && isActiveStatus;
      } catch (e) {
        return false;
      }
    }).toList()
      ..sort((a, b) {
        try {
          final dateA = DateTime.parse(a['date'] as String);
          final dateB = DateTime.parse(b['date'] as String);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });
  }

  List<Map<String, dynamic>> get pendingAppointments {
    return allAppointments.where((apt) => apt['status'] == 'pending').toList();
  }

  List<Map<String, dynamic>> get confirmedAppointments {
    return allAppointments.where((apt) => apt['status'] == 'confirmed').toList();
  }

  List<Map<String, dynamic>> get completedAppointments {
    return allAppointments.where((apt) => apt['status'] == 'completed').toList();
  }

  List<Map<String, dynamic>> get cancelledAppointments {
    return allAppointments.where((apt) => apt['status'] == 'cancelled').toList();
  }

  // Get counts (kept for backward compatibility)
  int get upcomingCount => upcomingAppointments.length;
  int get pendingCount => pendingAppointments.length;
  int get confirmedCount => confirmedAppointments.length;
  int get completedCount => completedAppointments.length;
  int get cancelledCount => cancelledAppointments.length;

  // Past appointments (for Past tab) - kept for backward compatibility
  List<Map<String, dynamic>> get pastAppointments {
    final today = DateTime.now();
    return allAppointments.where((apt) {
      try {
        final dateStr = apt['date'] as String;
        final date = DateTime.parse(dateStr);
        return date.isBefore(today);
      } catch (e) {
        return false;
      }
    }).toList()
      ..sort((a, b) {
        try {
          final dateA = DateTime.parse(a['date'] as String);
          final dateB = DateTime.parse(b['date'] as String);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });
  }

  void changeTab(int index) {
    tabIndex.value = index;
  }

  // ✅ NEW: Method to update filter
  void updateFilter(String filter) {
    selectedFilter.value = filter;
  }

  String formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    } catch (e) {
      return dateStr;
    }
  }

  String formatFullDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void refreshAppointments() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      loadAppointmentsForUser(user.uid, userRole.value);
    }
  }
}