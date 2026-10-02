import 'dart:async';

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusinessAnalyticsController extends GetxController {
  final selectedPeriod = 'Last 7 Days'.obs;

  final revenueTrend = <RevenueData>[].obs;
  final topServices = <TopService>[].obs;
  final bookingStatus = <BookingStatus>[].obs;
  final peakHours = <PeakHour>[].obs;

  final repeatCustomers = 0.obs;
  final avgSpend = 0.obs;
  final retentionRate = 0.obs;
  final averageRating = 0.0.obs;
  final totalReviews = 0.obs;
  final totalRevenue = 0.obs;
  final totalBookings = 0.obs;
  final newCustomers = 0.obs;

  final isLoading = false.obs;

  // Stream subscriptions for real-time updates
  StreamSubscription<QuerySnapshot>? _bookingsSubscription;
  StreamSubscription<QuerySnapshot>? _servicesSubscription;
  StreamSubscription<QuerySnapshot>? _reviewsSubscription;

  // Cache for all bookings
  List<Map<String, dynamic>> _allBookings = [];
  Set<String> _uniqueCustomers = {};
  Map<String, List<String>> _customerBookings = {};

  // Cache for services and reviews
  List<Map<String, dynamic>> _allServices = [];
  List<Map<String, dynamic>> _allReviews = [];

  @override
  void onInit() {
    super.onInit();
    _setupRealTimeListeners();
  }

  @override
  void onClose() {
    _bookingsSubscription?.cancel();
    _servicesSubscription?.cancel();
    _reviewsSubscription?.cancel();
    super.onClose();
  }

  void _setupRealTimeListeners() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    isLoading.value = true;

    _bookingsSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('businessId', isEqualTo: user.uid)
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) {
      _processBookingsSnapshot(snapshot);
      _calculateAllAnalytics();
      isLoading.value = false;
    }, onError: (e) {
      print('[Analytics] Error loading bookings: $e');
      isLoading.value = false;
    });

    _servicesSubscription = FirebaseFirestore.instance
        .collection('services')
        .where('businessId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      _processServicesSnapshot(snapshot);
      _calculateAverageRating();
    });

    _reviewsSubscription = FirebaseFirestore.instance
        .collection('reviews')
        .snapshots()
        .listen((snapshot) {
      _processReviewsSnapshot(snapshot);
      _calculateAverageRating();
    });
  }

  void _processBookingsSnapshot(QuerySnapshot snapshot) {
    _allBookings = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = data['createdAt'] as Timestamp?;
      final completedAt = data['completedAt'] as Timestamp?;

      return {
        'id': doc.id,
        'status': data['status'] ?? 'pending',
        'price': _extractNumericPrice(data['servicePrice']?.toString() ?? '0'),
        'advancePaid': (data['advanceAmount'] ?? 0).toDouble(),
        'selectedDate': data['selectedDate']?.toString() ?? '',
        'selectedTime': data['selectedTime']?.toString() ?? '',
        'customerId': data['customerId']?.toString() ?? '',
        'customerEmail': data['customerEmail']?.toString() ?? '',
        'customerName': data['customerName']?.toString() ?? '',
        'serviceName': data['serviceName']?.toString() ?? '',
        'serviceId': data['serviceId']?.toString() ?? '',
        'createdAt': createdAt,
        'createdAtDate': createdAt != null ? createdAt.toDate() : null,
        'completedAt': completedAt,
        'completedAtDate': completedAt != null ? completedAt.toDate() : null,
        'autoCancelled': data['autoCancelled'] ?? false,
        'refunded': data['refunded'] ?? false,
        'cancelledAt': data['cancelledAt'],
      };
    }).toList();

    _customerBookings.clear();
    _uniqueCustomers.clear();

    for (var booking in _allBookings) {
      final customerId = booking['customerId'] as String;
      final customerEmail = booking['customerEmail'] as String;
      final identifier = customerId.isNotEmpty ? customerId : customerEmail;

      if (identifier.isNotEmpty && identifier != '') {
        _uniqueCustomers.add(identifier);
        if (!_customerBookings.containsKey(identifier)) {
          _customerBookings[identifier] = [];
        }
        _customerBookings[identifier]!.add(booking['id'] as String);
      }
    }
  }

  void _processServicesSnapshot(QuerySnapshot snapshot) {
    _allServices = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'name': data['name']?.toString() ?? data['serviceName']?.toString() ?? '',
        'price': data['price'] ?? data['servicePrice'] ?? 0,
      };
    }).toList();
  }

  void _processReviewsSnapshot(QuerySnapshot snapshot) {
    _allReviews = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'serviceId': data['serviceId']?.toString() ?? '',
        'rating': (data['rating'] as num?)?.toDouble() ?? 0,
        'customerId': data['customerId']?.toString() ?? '',
        'createdAt': data['createdAt'],
      };
    }).toList();
  }

  double _extractNumericPrice(String priceStr) {
    try {
      final numeric = priceStr.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(numeric) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Get date range based on selected period
  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (selectedPeriod.value) {
      case 'Last 7 Days':
        return DateTime(now.year, now.month, now.day - 6);
      case 'Last 30 Days':
        return DateTime(now.year, now.month, now.day - 29);
      case 'Last 365 Days':
        return DateTime(now.year, now.month, now.day - 364);
      default:
        return DateTime(now.year, now.month, now.day - 6);
    }
  }

  DateTime _getEndDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  // Calculate revenue for a specific date
  // Advance payments count on booking creation date
  // Remaining payments (80%) count on completion date
  double _calculateRevenueForDate(DateTime date) {
    double revenue = 0.0;
    final targetDate = DateTime(date.year, date.month, date.day);

    for (var booking in _allBookings) {
      final autoCancelled = booking['autoCancelled'] as bool? ?? false;
      if (autoCancelled) continue;

      // ADVANCE PAYMENT (20%): Count on booking creation date
      final createdAtDate = booking['createdAtDate'] as DateTime?;
      if (createdAtDate != null) {
        final createdDate = DateTime(createdAtDate.year, createdAtDate.month, createdAtDate.day);
        if (createdDate.year == targetDate.year &&
            createdDate.month == targetDate.month &&
            createdDate.day == targetDate.day) {
          final advancePaid = booking['advancePaid'] as double;
          revenue += advancePaid;
        }
      }

      // REMAINING PAYMENT (80%): Count on completion date (only for completed appointments)
      final status = booking['status'] as String;
      if (status == 'completed') {
        final completedAtDate = booking['completedAtDate'] as DateTime?;
        if (completedAtDate != null) {
          final completedDate = DateTime(completedAtDate.year, completedAtDate.month, completedAtDate.day);
          if (completedDate.year == targetDate.year &&
              completedDate.month == targetDate.month &&
              completedDate.day == targetDate.day) {
            final price = booking['price'] as double;
            final advancePaid = booking['advancePaid'] as double;
            final remainingAmount = price - advancePaid;
            revenue += remainingAmount;
          }
        }
      }
    }

    return revenue;
  }

  // Calculate booking count for a specific date (based on booking creation date)
  int _calculateBookingCountForDate(DateTime date) {
    int count = 0;
    final targetDate = DateTime(date.year, date.month, date.day);

    for (var booking in _allBookings) {
      final createdAtDate = booking['createdAtDate'] as DateTime?;
      if (createdAtDate == null) continue;

      final createdDate = DateTime(createdAtDate.year, createdAtDate.month, createdAtDate.day);
      if (createdDate.year == targetDate.year &&
          createdDate.month == targetDate.month &&
          createdDate.day == targetDate.day) {
        final autoCancelled = booking['autoCancelled'] as bool? ?? false;
        if (!autoCancelled) {
          count++;
        }
      }
    }

    return count;
  }

  Future<void> _calculateAllAnalytics() async {
    await _calculateRevenueAndBookings();
    await _calculateRevenueTrend();
    await _calculateTopServices();
    await _calculateBookingStatus();
    await _calculatePeakHours();
    await _calculateCustomerInsights();
    await _calculateAverageRating();
  }

  Future<void> _calculateRevenueAndBookings() async {
    final startDate = _getStartDate();
    final endDate = _getEndDate();

    double revenue = 0;
    int bookings = 0;
    Set<String> uniqueCustomers = {};

    for (var booking in _allBookings) {
      final createdAtDate = booking['createdAtDate'] as DateTime?;
      if (createdAtDate == null) continue;

      final bookingDate = DateTime(createdAtDate.year, createdAtDate.month, createdAtDate.day);
      if (bookingDate.isBefore(startDate) || bookingDate.isAfter(endDate)) continue;

      final autoCancelled = booking['autoCancelled'] as bool? ?? false;
      if (autoCancelled) continue;

      // Count bookings (based on creation date)
      bookings++;

      // Calculate revenue from this booking
      final status = booking['status'] as String;
      final price = booking['price'] as double;
      final advancePaid = booking['advancePaid'] as double;

      // Add advance payment (always added on booking creation date)
      revenue += advancePaid;

      // Add remaining payment if completed within period
      if (status == 'completed') {
        final completedAtDate = booking['completedAtDate'] as DateTime?;
        if (completedAtDate != null) {
          final completedDate = DateTime(completedAtDate.year, completedAtDate.month, completedAtDate.day);
          if (!completedDate.isBefore(startDate) && !completedDate.isAfter(endDate)) {
            final remainingAmount = price - advancePaid;
            revenue += remainingAmount;
          }
        }
      }

      // Track unique customers
      final customerId = booking['customerId'] as String;
      final customerEmail = booking['customerEmail'] as String;
      final identifier = customerId.isNotEmpty ? customerId : customerEmail;
      if (identifier.isNotEmpty && identifier != '') {
        uniqueCustomers.add(identifier);
      }
    }

    totalRevenue.value = revenue.toInt();
    totalBookings.value = bookings;
    newCustomers.value = uniqueCustomers.length;
  }

  Future<void> _calculateRevenueTrend() async {
    final now = DateTime.now();

    switch (selectedPeriod.value) {
      case 'Last 7 Days':
        await _calculateWeeklyTrend(now);
        break;
      case 'Last 30 Days':
        await _calculateMonthlyTrend(now);
        break;
      case 'Last 365 Days':
        await _calculateYearlyTrend(now);
        break;
    }
  }

  // Last 7 Days - Order: Previous 6 days first, then today last
  Future<void> _calculateWeeklyTrend(DateTime now) async {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Get weekday names in order: today's weekday name should be last
    // We need to get the actual dates for the last 7 days
    final List<DateTime> last7Days = [];
    for (int i = 6; i >= 0; i--) {
      last7Days.add(DateTime(now.year, now.month, now.day - i));
    }

    // Create ordered list of day names based on actual dates
    final List<String> orderedDays = [];
    final List<int> revenues = [];
    final List<int> bookings = [];

    for (var date in last7Days) {
      final weekdayIndex = date.weekday - 1; // 0 = Monday
      orderedDays.add(weekdays[weekdayIndex]);
      revenues.add(_calculateRevenueForDate(date).toInt());
      bookings.add(_calculateBookingCountForDate(date));
    }

    final revenueData = <RevenueData>[];
    for (int i = 0; i < orderedDays.length; i++) {
      revenueData.add(RevenueData(
        orderedDays[i],
        revenues[i],
        bookings[i],
      ));
    }

    revenueTrend.value = revenueData;
  }

  // Last 30 Days - Group revenue by weekday across all 30 days
  Future<void> _calculateMonthlyTrend(DateTime now) async {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final revenueData = <RevenueData>[];
    final startDate = DateTime(now.year, now.month, now.day - 29);

    // Group by weekday over the last 30 days
    for (int i = 0; i < 7; i++) {
      final targetWeekday = i + 1; // Monday = 1
      double totalRevenue = 0;
      int totalBookings = 0;

      for (int day = 0; day < 30; day++) {
        final date = startDate.add(Duration(days: day));
        if (date.weekday == targetWeekday) {
          totalRevenue += _calculateRevenueForDate(date);
          totalBookings += _calculateBookingCountForDate(date);
        }
      }

      revenueData.add(RevenueData(
        weekdays[i],
        totalRevenue.toInt(),
        totalBookings,
      ));
    }

    revenueTrend.value = revenueData;
  }

  // Last 365 Days - Show total revenue per month
  Future<void> _calculateYearlyTrend(DateTime now) async {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final revenueData = <RevenueData>[];
    final startDate = DateTime(now.year, now.month, now.day - 364);

    for (int month = 0; month < 12; month++) {
      double monthlyRevenue = 0;
      int monthlyBookings = 0;

      for (int day = 0; day < 365; day++) {
        final date = startDate.add(Duration(days: day));
        if (date.month == month + 1) {
          monthlyRevenue += _calculateRevenueForDate(date);
          monthlyBookings += _calculateBookingCountForDate(date);
        }
      }

      revenueData.add(RevenueData(months[month], monthlyRevenue.toInt(), monthlyBookings));
    }

    revenueTrend.value = revenueData;
  }

  Future<void> _calculateTopServices() async {
    final startDate = _getStartDate();
    final endDate = _getEndDate();

    final Map<String, Map<String, dynamic>> serviceBookings = {};

    for (var booking in _allBookings) {
      final createdAtDate = booking['createdAtDate'] as DateTime?;
      if (createdAtDate == null) continue;

      final bookingDate = DateTime(createdAtDate.year, createdAtDate.month, createdAtDate.day);
      if (bookingDate.isBefore(startDate) || bookingDate.isAfter(endDate)) continue;

      final serviceName = booking['serviceName'].toString();
      if (serviceName.isEmpty) continue;

      final autoCancelled = booking['autoCancelled'] as bool? ?? false;
      if (autoCancelled) continue;

      if (!serviceBookings.containsKey(serviceName)) {
        serviceBookings[serviceName] = {
          'bookings': 0,
          'revenue': 0.0,
        };
      }

      final status = booking['status'] as String;
      if (status == 'confirmed' || status == 'completed') {
        double amount = 0;
        if (status == 'completed') {
          amount = booking['price'] as double;
        } else if (status == 'confirmed') {
          amount = booking['advancePaid'] as double;
        }
        serviceBookings[serviceName]!['revenue'] = (serviceBookings[serviceName]!['revenue'] as double) + amount;
        serviceBookings[serviceName]!['bookings'] = (serviceBookings[serviceName]!['bookings'] as int) + 1;
      }
    }

    final sortedServices = serviceBookings.entries
        .map((e) => TopService(
      e.key,
      (e.value['revenue'] as double).toInt(),
      e.value['bookings'] as int,
    ))
        .toList()
      ..sort((a, b) => b.bookings.compareTo(a.bookings));

    topServices.value = sortedServices.take(4).toList();
  }

  Future<void> _calculateBookingStatus() async {
    final startDate = _getStartDate();
    final endDate = _getEndDate();

    int completed = 0;
    int cancelled = 0;
    int confirmed = 0;

    for (var booking in _allBookings) {
      final createdAtDate = booking['createdAtDate'] as DateTime?;
      if (createdAtDate == null) continue;

      final bookingDate = DateTime(createdAtDate.year, createdAtDate.month, createdAtDate.day);
      if (bookingDate.isBefore(startDate) || bookingDate.isAfter(endDate)) continue;

      final status = booking['status'] as String;
      final autoCancelled = booking['autoCancelled'] as bool? ?? false;

      if (status == 'completed') {
        completed++;
      } else if (status == 'cancelled' || autoCancelled) {
        cancelled++;
      } else if (status == 'confirmed') {
        confirmed++;
      }
    }

    final total = completed + cancelled + confirmed;
    if (total > 0) {
      bookingStatus.value = [
        BookingStatus('Completed', completed, ((completed / total) * 100).toInt()),
        BookingStatus('Confirmed', confirmed, ((confirmed / total) * 100).toInt()),
        BookingStatus('Cancelled', cancelled, ((cancelled / total) * 100).toInt()),
      ];
    } else {
      bookingStatus.clear();
    }
  }

  Future<void> _calculatePeakHours() async {
    final startDate = _getStartDate();
    final endDate = _getEndDate();

    final Map<int, int> hourCounts = {};

    for (var booking in _allBookings) {
      final createdAtDate = booking['createdAtDate'] as DateTime?;
      if (createdAtDate == null) continue;

      final bookingDate = DateTime(createdAtDate.year, createdAtDate.month, createdAtDate.day);
      if (bookingDate.isBefore(startDate) || bookingDate.isAfter(endDate)) continue;

      final status = booking['status'] as String;
      final autoCancelled = booking['autoCancelled'] as bool? ?? false;
      if (status == 'cancelled' || autoCancelled) continue;

      final timeStr = booking['selectedTime'].toString();
      final hour = _extractHourFromTime(timeStr);
      if (hour != null) {
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }
    }

    final sortedHours = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final peakData = <PeakHour>[];
    for (var entry in sortedHours.take(8)) {
      final nextHour = entry.key + 1;
      final timeSlot = '${entry.key.toString().padLeft(2, '0')}:00 - ${nextHour.toString().padLeft(2, '0')}:00';
      peakData.add(PeakHour(timeSlot, entry.value));
    }

    peakHours.value = peakData;
  }

  Future<void> _calculateCustomerInsights() async {
    final startDate = _getStartDate();
    final endDate = _getEndDate();

    // Calculate repeat customers in period
    int repeatCount = 0;
    int totalCustomersInPeriod = 0;
    Map<String, int> customerBookingCountInPeriod = {};

    for (var booking in _allBookings) {
      final createdAtDate = booking['createdAtDate'] as DateTime?;
      if (createdAtDate == null) continue;

      final bookingDate = DateTime(createdAtDate.year, createdAtDate.month, createdAtDate.day);
      if (bookingDate.isBefore(startDate) || bookingDate.isAfter(endDate)) continue;

      final autoCancelled = booking['autoCancelled'] as bool? ?? false;
      if (autoCancelled) continue;

      final customerId = booking['customerId'] as String;
      final customerEmail = booking['customerEmail'] as String;
      final identifier = customerId.isNotEmpty ? customerId : customerEmail;

      if (identifier.isNotEmpty && identifier != '') {
        customerBookingCountInPeriod[identifier] = (customerBookingCountInPeriod[identifier] ?? 0) + 1;
      }
    }

    for (var count in customerBookingCountInPeriod.values) {
      totalCustomersInPeriod++;
      if (count > 1) {
        repeatCount++;
      }
    }

    if (totalCustomersInPeriod > 0) {
      repeatCustomers.value = ((repeatCount / totalCustomersInPeriod) * 100).toInt();
    } else {
      repeatCustomers.value = 0;
    }

    // Calculate average spend
    double totalSpend = 0;
    int paidCount = 0;

    for (var booking in _allBookings) {
      final createdAtDate = booking['createdAtDate'] as DateTime?;
      if (createdAtDate == null) continue;

      final bookingDate = DateTime(createdAtDate.year, createdAtDate.month, createdAtDate.day);
      if (bookingDate.isBefore(startDate) || bookingDate.isAfter(endDate)) continue;

      final status = booking['status'] as String;
      final autoCancelled = booking['autoCancelled'] as bool? ?? false;
      if (autoCancelled) continue;

      if (status == 'completed' || status == 'confirmed') {
        if (status == 'completed') {
          totalSpend += booking['price'] as double;
        } else {
          totalSpend += booking['advancePaid'] as double;
        }
        paidCount++;
      }
    }

    if (paidCount > 0) {
      avgSpend.value = (totalSpend / paidCount).toInt();
    } else {
      avgSpend.value = 0;
    }

    // Calculate retention rate (customers who booked more than once in last 90 days)
    final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
    int retainedCustomers = 0;
    int totalUniqueCustomers = 0;
    Map<String, int> customerBookingsLast90Days = {};

    for (var booking in _allBookings) {
      final createdAtDate = booking['createdAtDate'] as DateTime?;
      if (createdAtDate == null) continue;

      if (createdAtDate.isAfter(ninetyDaysAgo)) {
        final autoCancelled = booking['autoCancelled'] as bool? ?? false;
        if (autoCancelled) continue;

        final customerId = booking['customerId'] as String;
        final customerEmail = booking['customerEmail'] as String;
        final identifier = customerId.isNotEmpty ? customerId : customerEmail;

        if (identifier.isNotEmpty && identifier != '') {
          customerBookingsLast90Days[identifier] = (customerBookingsLast90Days[identifier] ?? 0) + 1;
        }
      }
    }

    for (var count in customerBookingsLast90Days.values) {
      totalUniqueCustomers++;
      if (count > 1) {
        retainedCustomers++;
      }
    }

    if (totalUniqueCustomers > 0) {
      retentionRate.value = ((retainedCustomers / totalUniqueCustomers) * 100).toInt();
    } else {
      retentionRate.value = 0;
    }
  }

  Future<void> _calculateAverageRating() async {
    try {
      final startDate = _getStartDate();
      final endDate = _getEndDate();

      if (_allServices.isEmpty) {
        averageRating.value = 0.0;
        totalReviews.value = 0;
        return;
      }

      final List<String> serviceIds = _allServices.map((service) => service['id'] as String).toList();

      if (serviceIds.isEmpty) {
        averageRating.value = 0.0;
        totalReviews.value = 0;
        return;
      }

      // Filter reviews by service ID AND by creation date within period
      final List<Map<String, dynamic>> businessReviews = [];

      for (final review in _allReviews) {
        final reviewServiceId = review['serviceId'] as String;
        if (!serviceIds.contains(reviewServiceId)) continue;

        final createdAt = review['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final reviewDate = createdAt.toDate();
          if (reviewDate.isBefore(startDate) || reviewDate.isAfter(endDate)) continue;
        }

        businessReviews.add(review);
      }

      totalReviews.value = businessReviews.length;

      if (businessReviews.isEmpty) {
        averageRating.value = 0.0;
        return;
      }

      int sumRatings = 0;
      for (final review in businessReviews) {
        final rating = (review['rating'] as double).toInt();
        sumRatings += rating;
      }

      averageRating.value = sumRatings / totalReviews.value;

    } catch (e) {
      print('[Analytics] Error calculating average rating: $e');
      averageRating.value = 0.0;
      totalReviews.value = 0;
    }
  }

  void changePeriod(String period) {
    selectedPeriod.value = period;
    _calculateAllAnalytics();
  }

  String formatRevenue(int amount) {
    if (amount < 1000) {
      return 'PKR $amount';
    } else if (amount < 100000) {
      final kValue = (amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1);
      return 'PKR ${kValue}K';
    } else {
      final kValue = (amount / 1000).toStringAsFixed(0);
      return 'PKR ${kValue}K';
    }
  }

  String getRevenuePercentage() {
    if (revenueTrend.length < 2) return '+0%';
    final current = revenueTrend.last;
    final previous = revenueTrend.length > 1 ? revenueTrend[revenueTrend.length - 2] : null;
    if (previous == null || previous.amount == 0) return '+0%';
    final percentage = ((current.amount - previous.amount) / previous.amount * 100);
    return percentage >= 0 ? '+${percentage.toStringAsFixed(1)}%' : '${percentage.toStringAsFixed(1)}%';
  }

  String getBookingsPercentage() {
    if (revenueTrend.length < 2) return '+0%';
    final current = revenueTrend.last;
    final previous = revenueTrend.length > 1 ? revenueTrend[revenueTrend.length - 2] : null;
    if (previous == null || previous.percentage == 0) return '+0%';
    final percentage = ((current.percentage - previous.percentage) / previous.percentage * 100);
    return percentage >= 0 ? '+${percentage.toStringAsFixed(1)}%' : '${percentage.toStringAsFixed(1)}%';
  }

  String getCustomersPercentage() {
    return repeatCustomers.value > 0 ? '+${repeatCustomers.value}%' : '+0%';
  }

  String getRatingChange() {
    if (averageRating.value > 0) {
      return '+${averageRating.value.toStringAsFixed(1)}';
    }
    return '+0.0';
  }

  String getRatingText() {
    final rating = averageRating.value;
    if (rating == 0) return 'Not Rated Yet';
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.5) return 'Good';
    if (rating >= 3.0) return 'Fair';
    return 'Poor';
  }

  double getRoundedRating() {
    if (averageRating.value == 0) return 0;
    return (averageRating.value * 2).round() / 2;
  }

  int? _extractHourFromTime(String timeStr) {
    if (timeStr.isEmpty) return null;
    try {
      String cleanTime = timeStr;
      if (timeStr.contains(' - ')) {
        cleanTime = timeStr.split(' - ')[0].trim();
      }
      final parts = cleanTime.split(':');
      if (parts.isNotEmpty) {
        return int.parse(parts[0]);
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}

class RevenueData {
  final String day;
  final int amount;
  final int percentage;

  RevenueData(this.day, this.amount, this.percentage);
}

class TopService {
  final String name;
  final int revenue;
  final int bookings;

  TopService(this.name, this.revenue, this.bookings);
}

class BookingStatus {
  final String label;
  final int count;
  final int percentage;
  BookingStatus(this.label, this.count, this.percentage);
}

class PeakHour {
  final String timeSlot;
  final int bookings;

  PeakHour(this.timeSlot, this.bookings);
}