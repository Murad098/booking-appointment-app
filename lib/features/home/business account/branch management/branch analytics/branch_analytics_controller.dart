// lib/features/home/business account/branch management/branch_analytics_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../business analytics/business_analytics_controller.dart';

class BranchAnalyticsController extends GetxController {
  final String branchId;
  BranchAnalyticsController(this.branchId);

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

  StreamSubscription<QuerySnapshot>? _bookingsSubscription;
  StreamSubscription<QuerySnapshot>? _servicesSubscription;
  StreamSubscription<QuerySnapshot>? _reviewsSubscription;

  List<Map<String, dynamic>> _allBookings = [];
  Set<String> _uniqueCustomers = {};
  Map<String, List<String>> _customerBookings = {};
  List<Map<String, dynamic>> _allServices = [];
  List<Map<String, dynamic>> _allReviews = [];

  String? _businessId; // holds the branchManagerId (which is the business ID)

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _bookingsSubscription?.cancel();
    _servicesSubscription?.cancel();
    _reviewsSubscription?.cancel();
    super.onClose();
  }

  Future<void> _initialize() async {
    isLoading.value = true;
    try {
      await _fetchBusinessId();
      _setupRealTimeListeners();
    } catch (e) {
      print('[BranchAnalytics] Error initializing: $e');
      isLoading.value = false;
      // Optionally show a snackbar/error message
    }
  }

  /// Fetch the branch document and extract the `branchManagerId` (which is the business ID).
  Future<void> _fetchBusinessId() async {
    final doc = await FirebaseFirestore.instance.collection('branches').doc(branchId).get();
    if (!doc.exists) {
      throw Exception('Branch not found');
    }
    final data = doc.data();
    if (data == null) {
      throw Exception('Branch data is null');
    }
    // Try 'branchManagerId' first, then 'managerId', then 'businessId' as fallback.
    _businessId = data['branchManagerId'] as String? ??
        data['managerId'] as String? ??
        data['businessId'] as String?;
    if (_businessId == null || _businessId!.isEmpty) {
      throw Exception('Business ID (branchManagerId) not found in branch document');
    }
  }

  /// Set up real‑time listeners – **all** queries (bookings, services, reviews)
  /// are filtered by the fetched business ID (branchManagerId).
  void _setupRealTimeListeners() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      isLoading.value = false;
      return;
    }

    // Bookings are filtered by businessId (branchManagerId) — not by branchId.
    _bookingsSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('businessId', isEqualTo: _businessId)
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) {
      _processBookingsSnapshot(snapshot);
      _calculateAllAnalytics();
      isLoading.value = false;
    }, onError: (e) {
      print('[BranchAnalytics] Error loading bookings: $e');
      isLoading.value = false;
    });

    // Services filtered by the same business ID
    _servicesSubscription = FirebaseFirestore.instance
        .collection('services')
        .where('businessId', isEqualTo: _businessId)
        .snapshots()
        .listen((snapshot) {
      _processServicesSnapshot(snapshot);
      _calculateAverageRating();
    });

    // Reviews (unfiltered; filtering happens in _calculateAverageRating)
    _reviewsSubscription = FirebaseFirestore.instance
        .collection('reviews')
        .snapshots()
        .listen((snapshot) {
      _processReviewsSnapshot(snapshot);
      _calculateAverageRating();
    });
  }

  // ------------------------------------------------------------------------
  // All remaining methods are **identical** to BusinessAnalyticsController,
  // operating on the business‑filtered bookings and services/reviews.
  // They are unchanged from your provided code.
  // ------------------------------------------------------------------------

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

  double _calculateRevenueForDate(DateTime date) {
    double revenue = 0.0;
    final targetDate = DateTime(date.year, date.month, date.day);

    for (var booking in _allBookings) {
      final autoCancelled = booking['autoCancelled'] as bool? ?? false;
      if (autoCancelled) continue;

      final createdAtDate = booking['createdAtDate'] as DateTime?;
      if (createdAtDate != null) {
        final createdDate = DateTime(createdAtDate.year, createdAtDate.month, createdAtDate.day);
        if (createdDate == targetDate) {
          final advancePaid = booking['advancePaid'] as double;
          revenue += advancePaid;
        }
      }

      final status = booking['status'] as String;
      if (status == 'completed') {
        final completedAtDate = booking['completedAtDate'] as DateTime?;
        if (completedAtDate != null) {
          final completedDate = DateTime(completedAtDate.year, completedAtDate.month, completedAtDate.day);
          if (completedDate == targetDate) {
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

  int _calculateBookingCountForDate(DateTime date) {
    int count = 0;
    final targetDate = DateTime(date.year, date.month, date.day);

    for (var booking in _allBookings) {
      final createdAtDate = booking['createdAtDate'] as DateTime?;
      if (createdAtDate == null) continue;
      final createdDate = DateTime(createdAtDate.year, createdAtDate.month, createdAtDate.day);
      if (createdDate == targetDate) {
        final autoCancelled = booking['autoCancelled'] as bool? ?? false;
        if (!autoCancelled) count++;
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

      bookings++;
      final status = booking['status'] as String;
      final price = booking['price'] as double;
      final advancePaid = booking['advancePaid'] as double;

      revenue += advancePaid;
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

  Future<void> _calculateWeeklyTrend(DateTime now) async {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<DateTime> last7Days = [];
    for (int i = 6; i >= 0; i--) {
      last7Days.add(DateTime(now.year, now.month, now.day - i));
    }
    final List<String> orderedDays = [];
    final List<int> revenues = [];
    final List<int> bookings = [];

    for (var date in last7Days) {
      final weekdayIndex = date.weekday - 1;
      orderedDays.add(weekdays[weekdayIndex]);
      revenues.add(_calculateRevenueForDate(date).toInt());
      bookings.add(_calculateBookingCountForDate(date));
    }

    final revenueData = <RevenueData>[];
    for (int i = 0; i < orderedDays.length; i++) {
      revenueData.add(RevenueData(orderedDays[i], revenues[i], bookings[i]));
    }
    revenueTrend.value = revenueData;
  }

  Future<void> _calculateMonthlyTrend(DateTime now) async {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final revenueData = <RevenueData>[];
    final startDate = DateTime(now.year, now.month, now.day - 29);
    for (int i = 0; i < 7; i++) {
      final targetWeekday = i + 1;
      double totalRevenue = 0;
      int totalBookings = 0;
      for (int day = 0; day < 30; day++) {
        final date = startDate.add(Duration(days: day));
        if (date.weekday == targetWeekday) {
          totalRevenue += _calculateRevenueForDate(date);
          totalBookings += _calculateBookingCountForDate(date);
        }
      }
      revenueData.add(RevenueData(weekdays[i], totalRevenue.toInt(), totalBookings));
    }
    revenueTrend.value = revenueData;
  }

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
        serviceBookings[serviceName] = {'bookings': 0, 'revenue': 0.0};
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
        .map((e) => TopService(e.key, (e.value['revenue'] as double).toInt(), e.value['bookings'] as int))
        .toList()
      ..sort((a, b) => b.bookings.compareTo(a.bookings));

    topServices.value = sortedServices.take(4).toList();
  }

  Future<void> _calculateBookingStatus() async {
    final startDate = _getStartDate();
    final endDate = _getEndDate();
    int completed = 0, cancelled = 0, confirmed = 0;

    for (var booking in _allBookings) {
      final createdAtDate = booking['createdAtDate'] as DateTime?;
      if (createdAtDate == null) continue;
      final bookingDate = DateTime(createdAtDate.year, createdAtDate.month, createdAtDate.day);
      if (bookingDate.isBefore(startDate) || bookingDate.isAfter(endDate)) continue;

      final status = booking['status'] as String;
      final autoCancelled = booking['autoCancelled'] as bool? ?? false;
      if (status == 'completed') completed++;
      else if (status == 'cancelled' || autoCancelled) cancelled++;
      else if (status == 'confirmed') confirmed++;
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

    final sortedHours = hourCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
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

    int totalCustomersInPeriod = 0, repeatCount = 0;
    for (var count in customerBookingCountInPeriod.values) {
      totalCustomersInPeriod++;
      if (count > 1) repeatCount++;
    }
    repeatCustomers.value = totalCustomersInPeriod > 0 ? ((repeatCount / totalCustomersInPeriod) * 100).toInt() : 0;

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
        if (status == 'completed') totalSpend += booking['price'] as double;
        else totalSpend += booking['advancePaid'] as double;
        paidCount++;
      }
    }
    avgSpend.value = paidCount > 0 ? (totalSpend / paidCount).toInt() : 0;

    final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
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
    int totalUnique = 0, retained = 0;
    for (var count in customerBookingsLast90Days.values) {
      totalUnique++;
      if (count > 1) retained++;
    }
    retentionRate.value = totalUnique > 0 ? ((retained / totalUnique) * 100).toInt() : 0;
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
      final List<String> serviceIds = _allServices.map((s) => s['id'] as String).toList();
      if (serviceIds.isEmpty) {
        averageRating.value = 0.0;
        totalReviews.value = 0;
        return;
      }
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
        sumRatings += (review['rating'] as double).toInt();
      }
      averageRating.value = sumRatings / totalReviews.value;
    } catch (e) {
      print('[BranchAnalytics] Error calculating average rating: $e');
      averageRating.value = 0.0;
      totalReviews.value = 0;
    }
  }

  void changePeriod(String period) {
    selectedPeriod.value = period;
    _calculateAllAnalytics();
  }

  String formatRevenue(int amount) {
    if (amount < 1000) return 'PKR $amount';
    else if (amount < 100000) {
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

  String getCustomersPercentage() => repeatCustomers.value > 0 ? '+${repeatCustomers.value}%' : '+0%';
  String getRatingChange() => averageRating.value > 0 ? '+${averageRating.value.toStringAsFixed(1)}' : '+0.0';
  String getRatingText() {
    final rating = averageRating.value;
    if (rating == 0) return 'Not Rated Yet';
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.5) return 'Good';
    if (rating >= 3.0) return 'Fair';
    return 'Poor';
  }
  double getRoundedRating() => averageRating.value == 0 ? 0 : (averageRating.value * 2).round() / 2;

  int? _extractHourFromTime(String timeStr) {
    if (timeStr.isEmpty) return null;
    try {
      String cleanTime = timeStr;
      if (timeStr.contains(' - ')) {
        cleanTime = timeStr.split(' - ')[0].trim();
      }
      final parts = cleanTime.split(':');
      if (parts.isNotEmpty) return int.parse(parts[0]);
    } catch (e) { return null; }
    return null;
  }
}