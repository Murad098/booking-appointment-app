import 'dart:core';

import 'package:bookify/features/home/book%20appointment/booking_step3_summary.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../app/custom_snackbar.dart';
import '../../../services/currency_service.dart';
import '../../../services/stripe_service.dart';
import '../../../services/user_service.dart';
import '../../../services/supabase_storage_service.dart';
import '../../../services/notification_service.dart';
import 'booking_step2_payment.dart';
import 'booking_success_screen.dart';

class BookingController extends GetxController {
// ... (all existing observable variables remain unchanged) ...
  final serviceId = ''.obs;
  final userType = 'customer'.obs;
  final businessId = ''.obs;
  final businessName = ''.obs;
  final serviceName = ''.obs;
  final serviceDescription = ''.obs;
  final serviceCategory = ''.obs;
  final servicePrice = ''.obs;
  final serviceDuration = ''.obs;
  final serviceImageUrl = ''.obs;
  final businessPaymentMethods = <Map<String, dynamic>>[].obs;

  // lib/features/home/book appointment/booking_controller.dart
//
// STRIPE DIRECT PAYMENT CHANGES:
// - Removed platformFee from all payment calls
// - processStripePayment now reads stripeAccountId from Firestore and
//   calls StripeService.processFullPayment without any platform fee
// - saveStripeBooking / confirmBookingWithStripe updated accordingly


  bool get hasStripePaymentMethod {
    return businessPaymentMethods.any((m) => m['id'] == 'stripe');
  }

  String? get stripeAccountId {
    final stripeMethod =
    businessPaymentMethods.firstWhereOrNull((m) => m['id'] == 'stripe');
    return stripeMethod?['stripeAccountId'];
  }

  bool get isSelectedMethodIsStripe {
    if (selectedPaymentMethod.value.isEmpty) return false;
    final method = businessPaymentMethods.firstWhereOrNull(
            (m) => m['name'] == selectedPaymentMethod.value);
    return method?['id'] == 'stripe';
  }

  // ─── Main Stripe payment flow ──────────────────────────────────────────────

  /// Called from booking summary when customer taps "Pay with Card".
  /// Charges the advance amount (20%) directly to the business's Stripe account.
  Future<bool> processStripePayment() async {
    if (!isCustomerDetailsValid) {
      AppSnackbar.error('Please fill in all customer details correctly');
      return false;
    }
    if (selectedDate.value == null) {
      AppSnackbar.error('Please select a date');
      return false;
    }
    if (selectedTime.value.isEmpty) {
      AppSnackbar.error('Please select a time');
      return false;
    }

    isProcessingStripePayment.value = true;

    try {
      // Fetch fresh business data from Firestore
      final businessDoc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId.value)
          .get();

      final bizStripeAccountId =
      businessDoc.data()?['stripeAccountId'] as String?;
      final bizStripeStatus =
      businessDoc.data()?['stripeAccountStatus'] as String?;

      if (bizStripeAccountId == null ||
          bizStripeAccountId.isEmpty ||
          bizStripeStatus != 'enabled') {
        AppSnackbar.error(
            'This business cannot accept card payments yet. Please choose another payment method.');
        return false;
      }

      final amountToChargePKR = advancePayment; // 20% advance in PKR

      // 🔁 Convert PKR to USD
      final amountToChargeUSD = await CurrencyService().getUsdFromPkr(amountToChargePKR);
      if (amountToChargeUSD <= 0) {
        AppSnackbar.error('Invalid amount after currency conversion.');
        return false;
      }

      final bookingRef = DateTime.now().millisecondsSinceEpoch.toString();

      final stripeService = StripeService();
      await stripeService.initialize();

      bool paymentSuccess = false;
      String? paymentError;

      // ✅ Use USD amount and currency 'usd'
      await stripeService.processFullPayment(
        amount: amountToChargeUSD,
        currency: 'usd',
        businessStripeAccountId: bizStripeAccountId,
        bookingId: bookingRef,
        onSuccess: () => paymentSuccess = true,
        onError: (error) {
          paymentError = error;
          paymentSuccess = false;
        },
      );

      if (!paymentSuccess) {
        AppSnackbar.error(paymentError ?? 'Payment failed. Please try again.');
      }
      return paymentSuccess;
    } catch (e) {
      print('[BookingController] Stripe payment error: $e');
      AppSnackbar.error('Payment failed: $e');
      return false;
    } finally {
      isProcessingStripePayment.value = false;
    }
  }

  /// Called after processStripePayment() returns true.
  /// Saves the confirmed booking to Firestore.
  Future<void> saveStripeBooking() async {
    isConfirmPaymentLoading.value = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppSnackbar.error('Please login to continue');
        return;
      }

      final bookingId = DateTime.now().millisecondsSinceEpoch.toString();

      final bookingData = {
        'bookingId': bookingId,
        'customerId': user.uid,
        'customerName': customerName.value.trim(),
        'customerEmail': customerEmail.value.trim(),
        'customerPhone': customerPhone.value.trim(),
        'businessId': businessId.value,
        'businessName': businessName.value,
        'serviceId': serviceId.value,
        'serviceName': serviceName.value,
        'serviceDescription': serviceDescription.value,
        'serviceCategory': serviceCategory.value,
        'servicePrice': servicePrice.value,
        'serviceDuration': serviceDuration.value,
        'serviceImageUrl': serviceImageUrl.value,
        'selectedDate': _formatDateForQuery(selectedDate.value!),
        'selectedTime': selectedTime.value,
        'paymentMethod': 'stripe',
        'paymentStatus': 'paid', // advance is paid via Stripe
        'advanceAmount': advancePayment,
        'remainingAmount': remainingPayment,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
        'userType': userType.value,
      };

      await FirebaseFirestore.instance.collection('bookings').add(bookingData);

      await NotificationService().sendPushNotification(
        userId: businessId.value,
        title: 'New Booking Confirmed',
        body:
        '${customerName.value.trim()} has booked ${serviceName.value} and paid the advance via Stripe.',
        data: {'type': 'new_booking', 'bookingId': bookingId},
      );

      Get.offAll(() => const BookingSuccessScreen());
    } catch (e) {
      print('[BookingController] Save Stripe booking error: $e');
      AppSnackbar.error('Failed to save booking: $e');
    } finally {
      isConfirmPaymentLoading.value = false;
    }
  }

  /// Single-step flow: process payment AND save booking in one call.
  /// Use this if your Step 3 summary screen has a single "Pay & Confirm" button.
  Future<void> confirmBookingWithStripe() async {
    if (!isCustomerDetailsValid) {
      AppSnackbar.error('Please fill in all customer details correctly');
      return;
    }
    if (selectedDate.value == null) {
      AppSnackbar.error('Please select a date');
      return;
    }
    if (selectedTime.value.isEmpty) {
      AppSnackbar.error('Please select a time');
      return;
    }

    isConfirmPaymentLoading.value = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppSnackbar.error('Please login to continue');
        isConfirmPaymentLoading.value = false;
        return;
      }

      final businessDoc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId.value)
          .get();

      if (!businessDoc.exists) {
        AppSnackbar.error('Business not found');
        isConfirmPaymentLoading.value = false;
        return;
      }

      final bizStripeAccountId =
      businessDoc.data()?['stripeAccountId'] as String?;
      final bizStripeStatus =
      businessDoc.data()?['stripeAccountStatus'] as String?;

      if (bizStripeAccountId == null ||
          bizStripeAccountId.isEmpty ||
          bizStripeStatus != 'enabled') {
        AppSnackbar.error('This business cannot accept card payments yet.');
        isConfirmPaymentLoading.value = false;
        return;
      }

      final bookingId = DateTime.now().millisecondsSinceEpoch.toString();
      final amountToChargePKR = advancePayment; // 20% advance in PKR

      // 🔁 Convert PKR to USD
      final amountToChargeUSD = await CurrencyService().getUsdFromPkr(amountToChargePKR);
      if (amountToChargeUSD <= 0) {
        AppSnackbar.error('Invalid amount after currency conversion.');
        isConfirmPaymentLoading.value = false;
        return;
      }

      final stripeService = StripeService();
      await stripeService.initialize();

      bool paymentSuccess = false;
      String? paymentError;

      await stripeService.processFullPayment(
        amount: amountToChargeUSD,
        currency: 'usd',
        businessStripeAccountId: bizStripeAccountId,
        bookingId: bookingId,
        onSuccess: () => paymentSuccess = true,
        onError: (error) {
          paymentError = error;
          paymentSuccess = false;
        },
      );

      if (!paymentSuccess) {
        AppSnackbar.error(paymentError ?? 'Payment failed. Please try again.');
        isConfirmPaymentLoading.value = false;
        return;
      }

      // Payment successful — save booking
      final bookingData = {
        'bookingId': bookingId,
        'customerId': user.uid,
        'customerName': customerName.value.trim(),
        'customerEmail': customerEmail.value.trim(),
        'customerPhone': customerPhone.value.trim(),
        'businessId': businessId.value,
        'businessName': businessName.value,
        'serviceId': serviceId.value,
        'serviceName': serviceName.value,
        'serviceDescription': serviceDescription.value,
        'serviceCategory': serviceCategory.value,
        'servicePrice': servicePrice.value,
        'serviceDuration': serviceDuration.value,
        'serviceImageUrl': serviceImageUrl.value,
        'selectedDate': _formatDateForQuery(selectedDate.value!),
        'selectedTime': selectedTime.value,
        'paymentMethod': 'stripe',
        'paymentStatus': 'paid',
        'advanceAmount': amountToChargePKR,        // store PKR for display
        'remainingAmount': remainingPayment,       // in PKR
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
        'userType': userType.value,
      };

      await FirebaseFirestore.instance.collection('bookings').add(bookingData);

      await NotificationService().sendPushNotification(
        userId: businessId.value,
        title: 'New Booking Confirmed',
        body:
        '${customerName.value.trim()} has booked ${serviceName.value} and paid the advance via Stripe.',
        data: {'type': 'new_booking', 'bookingId': bookingId},
      );

      isConfirmPaymentLoading.value = false;
      Get.offAll(() => const BookingSuccessScreen());
    } catch (e) {
      print('[BookingController] confirmBookingWithStripe error: $e');
      isConfirmPaymentLoading.value = false;
      AppSnackbar.error('Failed to confirm booking: $e');
    }
  }

//stripe
  final isProcessingStripePayment = false.obs;

  final currentStep = 0.obs;

// Customer Details
  final customerName = ''.obs;
  final customerEmail = ''.obs;
  final customerPhone = ''.obs;

// Validation Errors
  final RxMap<String, String> step1Errors = <String, String>{}.obs;
  final isPhoneValid = false.obs;

// Add these observable variables
  final isProcessingStripe = false.obs;
  final stripePaymentSuccess = false.obs;


// Process Stripe payment during checkout (charges only the 20% advance payment)
  Future<bool> processStripePaymentDuringCheckout() async {
    if (!isCustomerDetailsValid) {
      AppSnackbar.error('Please fill customer details correctly');
      return false;
    }
    if (selectedDate.value == null) {
      AppSnackbar.error('Please select a date');
      return false;
    }
    if (selectedTime.value.isEmpty) {
      AppSnackbar.error('Please select a time');
      return false;
    }

    final stripeAccId = stripeAccountId;
    if (stripeAccId == null) {
      AppSnackbar.error('Stripe not configured for this business');
      return false;
    }

    isProcessingStripe.value = true;

    try {
      final amountToChargePKR = advancePayment; // 20% in PKR

      // 🔁 Convert PKR to USD
      final amountToChargeUSD = await CurrencyService().getUsdFromPkr(amountToChargePKR);
      if (amountToChargeUSD <= 0) {
        AppSnackbar.error('Invalid amount after currency conversion.');
        return false;
      }

      final bookingId = DateTime.now().millisecondsSinceEpoch.toString();

      final stripeService = StripeService();
      await stripeService.initialize();

      bool paymentSuccess = false;
      String? paymentError;

      await stripeService.processFullPayment(
        amount: amountToChargeUSD,
        currency: 'usd',
        businessStripeAccountId: stripeAccId,
        bookingId: bookingId,
        onSuccess: () => paymentSuccess = true,
        onError: (error) {
          paymentError = error;
          paymentSuccess = false;
        },
      );

      if (!paymentSuccess) {
        AppSnackbar.error(paymentError ?? 'Payment failed');
        return false;
      }

      stripePaymentSuccess.value = true;
      return true;
    } catch (e) {
      print('Stripe payment error: $e');
      AppSnackbar.error('Payment failed: $e');
      return false;
    } finally {
      isProcessingStripe.value = false;
    }
  }

// Business Operating Hours from Firestore
  final RxMap<String, Map<String, dynamic>> businessOperatingHours = <String, Map<String, dynamic>>{}.obs;
  final businessOffDays = <String>[].obs;
  final isLoadingTimeSlots = false.obs;
  final bookedSlots = <BookedSlot>[].obs;
  final availableDates = <DateTime>[].obs;
  final isLoadingDates = false.obs;
  final isLoadingBusiness = false.obs;

// Date & Time
  final selectedDate = Rxn<DateTime>();
  final selectedTime = ''.obs;

// Payment Method
  final selectedPaymentMethod = ''.obs;

// Payment Screenshot
  final paymentScreenshot = Rxn<File>();
  final paymentScreenshotUrl = ''.obs;
  final isUploading = false.obs;

// Loading states for buttons
  final isContinueToPaymentLoading = false.obs;
  final isProceedToCheckoutLoading = false.obs;
  final isConfirmPaymentLoading = false.obs;

// Calculate Prices
  double get totalPrice {
    final priceStr = servicePrice.value.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(priceStr) ?? 0.0;
  }

  double get advancePayment => totalPrice * 0.2;
  double get remainingPayment => totalPrice - advancePayment;

// --------------------------------------------------------------
// NEW: Load current user's role and personal details (if any)
// --------------------------------------------------------------
  Future<void> _loadCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
// Fetch user document from 'users' collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final data = userDoc.data();
      final String? role = data?['role'] as String?;

// Only auto-fill for personal users
      if (role == 'personal') {
// Name: try displayName from Auth, then Firestore 'fullName', then empty
        String name = user.displayName ?? '';
        if (name.isEmpty && data?['fullName'] != null) {
          name = data?['fullName'] as String;
        }
        if (name.isNotEmpty) customerName.value = name;

// Email: from Auth (always available if user is signed in)
        if (user.email != null && user.email!.isNotEmpty) {
          customerEmail.value = user.email!;
        }

// Phone: from Firestore 'phone' field if exists
        if (data?['phone'] != null && data!['phone'].toString().isNotEmpty) {
          customerPhone.value = data['phone'].toString();
// Also validate phone number format
          _validatePhoneNumber(customerPhone.value);
        }
      }
// For business role, leave all fields empty (already default)
    } catch (e) {
      print('[BookingController] Error loading user data: $e');
// Do not show error to user – just leave fields empty
    }
  }

  void initBooking({
    required String serviceId,
    required String businessId,
    required String businessName,
    required String serviceName,
    required String serviceDescription,
    required String serviceCategory,
    required String servicePrice,
    required String serviceDuration,
    required String serviceImageUrl,
    required String userType,
  }) {
    this.serviceId.value = serviceId;
    this.businessId.value = businessId;
    this.businessName.value = businessName;
    this.serviceName.value = serviceName;
    this.serviceDescription.value = serviceDescription;
    this.serviceCategory.value = serviceCategory;
    this.servicePrice.value = servicePrice;
    this.serviceDuration.value = serviceDuration;
    this.serviceImageUrl.value = serviceImageUrl;
    this.userType.value = userType;
    currentStep.value = 0;

// Reset all state
    selectedDate.value = null;
    selectedTime.value = '';
    customerName.value = '';
    customerEmail.value = '';
    customerPhone.value = '';
    step1Errors.clear();
    selectedPaymentMethod.value = '';
    paymentScreenshot.value = null;
    paymentScreenshotUrl.value = '';
    businessOperatingHours.clear();
    businessOffDays.clear();
    availableDates.clear();
    bookedSlots.clear();

// Load business data (operating hours, payment methods)
    loadBusinessOperatingHours();
    loadBusinessPaymentMethods();

// 🔥 NEW: Auto-fill personal user details (async – does not block UI)
    _loadCurrentUserData();
  }

  Future<void> loadBusinessOperatingHours() async {
    try {
      isLoadingBusiness.value = true;
      isLoadingDates.value = true;

      final businessDoc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId.value)
          .get();

      if (businessDoc.exists) {
        final businessData = businessDoc.data();

        if (businessData != null && businessData['operatingHours'] != null) {
          final operatingHours =
          businessData['operatingHours'] as Map<String, dynamic>;

          businessOperatingHours.clear();
          final offDaysList = <String>[];

          const days = [
            'Monday', 'Tuesday', 'Wednesday', 'Thursday',
            'Friday', 'Saturday', 'Sunday'
          ];

          for (final day in days) {
            if (operatingHours.containsKey(day)) {
              final dayData = operatingHours[day] as Map<String, dynamic>;
              final isOpen = dayData['isOpen'] == true;

              if (isOpen) {
                businessOperatingHours[day] = {
                  'isOpen': true,
                  'openTime': dayData['openTime'] ?? '09:00',
                  'closeTime': dayData['closeTime'] ?? '18:00',
                };
              } else {
                offDaysList.add(day);
                businessOperatingHours[day] = {
                  'isOpen': false,
                  'openTime': null,
                  'closeTime': null,
                };
              }
            } else {
              offDaysList.add(day);
              businessOperatingHours[day] = {
                'isOpen': false,
                'openTime': null,
                'closeTime': null,
              };
            }
          }

          businessOffDays.value = offDaysList;
        } else {
          _setDefaultOperatingHours();
        }
      } else {
        _setDefaultOperatingHours();
      }

      await generateAvailableDates();
    } catch (e) {
      print('Error loading business operating hours: $e');
      _setDefaultOperatingHours();
      await generateAvailableDates();
    } finally {
      isLoadingBusiness.value = false;
      isLoadingDates.value = false;
    }
  }

  void _setDefaultOperatingHours() {
    businessOperatingHours.clear();
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    for (final day in days) {
      final isWorkday = day != 'Saturday' && day != 'Sunday';
      businessOperatingHours[day] = {
        'isOpen': isWorkday,
        'openTime': isWorkday ? '09:00' : null,
        'closeTime': isWorkday ? '18:00' : null,
      };
    }
    businessOffDays.value = ['Saturday', 'Sunday'];
  }

  Future<void> generateAvailableDates() async {
    final dates = <DateTime>[];
    final today = DateTime.now();

    int daysChecked = 0;
    int daysAdded = 0;

    while (daysAdded < 14 && daysChecked < 90) {
      final date = today.add(Duration(days: daysChecked));
      final dayName = _getDayName(date.weekday);

      final dayInfo = businessOperatingHours[dayName];
      if (dayInfo != null && dayInfo['isOpen'] == true) {
        dates.add(date);
        daysAdded++;
      }

      daysChecked++;
    }

    availableDates.value = dates;
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[weekday - 1];
  }

  Future<void> loadBookedSlotsForDate(DateTime date) async {
    isLoadingTimeSlots.value = true;
    bookedSlots.clear();

    try {
      final dateStr = _formatDateForQuery(date);
      final nextDayStr = _getNextDayDateStr(dateStr);

      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('businessId', isEqualTo: businessId.value)
          .where('selectedDate', isGreaterThanOrEqualTo: dateStr)
          .where('selectedDate', isLessThan: nextDayStr)
          .get();

      final List<BookedSlot> slots = [];

      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final time = data['selectedTime'] as String?;
        final duration =
            int.tryParse(data['serviceDuration']?.toString() ?? '0') ?? 0;
        final status = data['status'] as String? ?? '';

        if (time != null &&
            time.isNotEmpty &&
            ['pending', 'confirmed', 'completed'].contains(status)) {
          final startTime = time.contains(' - ')
              ? time.split(' - ')[0].trim()
              : time.trim();
          slots.add(BookedSlot(startTime: startTime, duration: duration));
        }
      }

      bookedSlots.value = slots;
    } catch (e) {
      print('Error loading booked slots: $e');
    } finally {
      isLoadingTimeSlots.value = false;
    }
  }

  String _formatDateForQuery(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getNextDayDateStr(String dateStr) {
    final date = DateTime.parse(dateStr);
    final nextDay = date.add(const Duration(days: 1));
    return '${nextDay.year}-${nextDay.month.toString().padLeft(2, '0')}-${nextDay.day.toString().padLeft(2, '0')}';
  }

// ===========================================================================
// Slot Generation Logic
// ===========================================================================

  List<TimeSlot> getAvailableTimeSlots() {
    if (selectedDate.value == null) return [];

    final dayName = _getDayName(selectedDate.value!.weekday);
    final dayInfo = businessOperatingHours[dayName];

    if (dayInfo == null || dayInfo['isOpen'] != true) return [];

    final openTime = dayInfo['openTime'] as String;
    final closeTime = dayInfo['closeTime'] as String;

    int openMinutes = _timeToMinutes(openTime);
    final closeMinutes = _timeToMinutes(closeTime);
    final serviceDurationMinutes = int.tryParse(serviceDuration.value) ?? 60;

    final selectedDateValue = selectedDate.value!;
    final now = DateTime.now();
    final isToday = selectedDateValue.year == now.year &&
        selectedDateValue.month == now.month &&
        selectedDateValue.day == now.day;

    if (isToday) {
      final currentMinutes = now.hour * 60 + now.minute;
      final roundedStartMinutes =
      _roundUpToNextSlot(currentMinutes, serviceDurationMinutes);

      if (roundedStartMinutes >= closeMinutes) {
        return [];
      }

      openMinutes =
      openMinutes > roundedStartMinutes ? openMinutes : roundedStartMinutes;
    }

    final List<BookedRange> bookedRanges = [];
    for (final booked in bookedSlots) {
      final startMin = _timeToMinutes(booked.startTime);
      final endMin = startMin + booked.duration;
      bookedRanges.add(BookedRange(start: startMin, end: endMin));
    }

    final mergedBookedRanges = _mergeBookedRanges(bookedRanges);

    final List<FreeRange> freeRanges = [];
    int currentStart = openMinutes;

    for (final booked in mergedBookedRanges) {
      if (currentStart < booked.start) {
        freeRanges.add(FreeRange(start: currentStart, end: booked.start));
      }
      currentStart = currentStart > booked.end ? currentStart : booked.end;
    }

    if (currentStart < closeMinutes) {
      freeRanges.add(FreeRange(start: currentStart, end: closeMinutes));
    }

    final List<TimeSlot> slots = [];

    for (final freeRange in freeRanges) {
      final slotsInRange = _generateSlotsInFreeRange(
        freeRange.start,
        freeRange.end,
        serviceDurationMinutes,
      );
      slots.addAll(slotsInRange);
    }

    return slots;
  }

  int _roundUpToNextSlot(int currentMinutes, int serviceDuration) {
    if (serviceDuration <= 30) {
      return ((currentMinutes + 29) ~/ 30) * 30;
    } else if (serviceDuration <= 60) {
      return ((currentMinutes + 59) ~/ 60) * 60;
    } else {
      return ((currentMinutes + 59) ~/ 60) * 60;
    }
  }

  List<BookedRange> _mergeBookedRanges(List<BookedRange> ranges) {
    if (ranges.isEmpty) return [];

    final sorted = List<BookedRange>.from(ranges)
      ..sort((a, b) => a.start.compareTo(b.start));

    final merged = <BookedRange>[];
    BookedRange current = sorted[0];

    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].start <= current.end) {
        current = BookedRange(
          start: current.start,
          end: current.end > sorted[i].end ? current.end : sorted[i].end,
        );
      } else {
        merged.add(current);
        current = sorted[i];
      }
    }
    merged.add(current);

    return merged;
  }

  List<TimeSlot> _generateSlotsInFreeRange(
      int rangeStart,
      int rangeEnd,
      int serviceDuration,
      ) {
    final List<TimeSlot> slots = [];
    int currentStart = rangeStart;

    while (currentStart + serviceDuration <= rangeEnd) {
      final slotEnd = currentStart + serviceDuration;
      slots.add(TimeSlot(
        time:
        '${_minutesToTimeString(currentStart)} - ${_minutesToTimeString(slotEnd)}',
        startDateTime:
        DateTime(2000, 1, 1, currentStart ~/ 60, currentStart % 60),
        endDateTime: DateTime(2000, 1, 1, slotEnd ~/ 60, slotEnd % 60),
        status: SlotStatus.available,
      ));
      currentStart += serviceDuration;
    }

    if (currentStart < rangeEnd) {
      final remainingMinutes = rangeEnd - currentStart;
      if (remainingMinutes > 0) {
        slots.add(TimeSlot(
          time:
          '${_minutesToTimeString(currentStart)} - ${_minutesToTimeString(rangeEnd)}',
          startDateTime:
          DateTime(2000, 1, 1, currentStart ~/ 60, currentStart % 60),
          endDateTime: DateTime(2000, 1, 1, rangeEnd ~/ 60, rangeEnd % 60),
          status: SlotStatus.insufficientTime,
        ));
      }
    }

    return slots;
  }

  int _timeToMinutes(String time) {
    String cleanTime = time;

    if (cleanTime.contains(' - ')) {
      cleanTime = cleanTime.split(' - ')[0].trim();
    }

    if (cleanTime.contains(':')) {
      final parts = cleanTime.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        return hour * 60 + minute;
      }
    }

    return 0;
  }

  String _minutesToTimeString(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<TimeSlot> getBookedSlotsAsTimeSlots() {
    final List<TimeSlot> bookedTimeSlots = [];

    final List<BookedRange> bookedRanges = [];
    for (final booked in bookedSlots) {
      final startMin = _timeToMinutes(booked.startTime);
      final endMin = startMin + booked.duration;
      bookedRanges.add(BookedRange(start: startMin, end: endMin));
    }

    final mergedBookedRanges = _mergeBookedRanges(bookedRanges);

    for (final bookedRange in mergedBookedRanges) {
      bookedTimeSlots.add(TimeSlot(
        time:
        '${_minutesToTimeString(bookedRange.start)} - ${_minutesToTimeString(bookedRange.end)}',
        startDateTime: DateTime(
            2000, 1, 1, bookedRange.start ~/ 60, bookedRange.start % 60),
        endDateTime:
        DateTime(2000, 1, 1, bookedRange.end ~/ 60, bookedRange.end % 60),
        status: SlotStatus.fullyBooked,
      ));
    }

    return bookedTimeSlots;
  }

// Customer details helpers
  void updateCustomerName(String value) {
    customerName.value = value;
    _validateCustomerDetails();
  }

  void updateCustomerEmail(String value) {
    customerEmail.value = value;
    _validateCustomerDetails();
  }

  void updateCustomerPhone(String value) {
    customerPhone.value = value;
    _validatePhoneNumber(value);
    _validateCustomerDetails();
  }

  void _validatePhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    isPhoneValid.value = cleaned.length == 11 && cleaned.startsWith('03');
  }

  void _validateCustomerDetails() {
    step1Errors.clear();
    final name = customerName.value.trim();
    final email = customerEmail.value.trim();
    final phone = customerPhone.value.trim();
    final cleanedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (name.isEmpty) step1Errors['name'] = 'Name is required';
    if (email.isEmpty) {
      step1Errors['email'] = 'Email is required';
    } else if (!GetUtils.isEmail(email)) {
      step1Errors['email'] = 'Enter a valid email address';
    }
    if (phone.isEmpty) {
      step1Errors['phone'] = 'Phone number is required';
    } else if (!cleanedPhone.startsWith('03')) {
      step1Errors['phone'] = 'Phone number must start with 03';
    } else if (cleanedPhone.length != 11) {
      step1Errors['phone'] = 'Phone number must be exactly 11 digits';
    }
  }

  bool get isCustomerDetailsValid =>
      step1Errors.isEmpty &&
          customerName.value.isNotEmpty &&
          customerEmail.value.isNotEmpty &&
          isPhoneValid.value;

  void selectDate(DateTime date) async {
    selectedDate.value = date;
    selectedTime.value = '';
    await loadBookedSlotsForDate(date);
  }

  void selectTime(String time) {
    selectedTime.value = time.trim();
    update();
  }

  Future<void> goToStep2() async {
    if (!isCustomerDetailsValid) {
      AppSnackbar.error('Please fill in all customer details correctly');
      return;
    }
    if (selectedDate.value == null) {
      AppSnackbar.error('Please select a date');
      return;
    }
    if (selectedTime.value.isEmpty) {
      AppSnackbar.error('Please select a time');
      return;
    }

    isContinueToPaymentLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    Get.to(() => const BookingStep2Payment());
    currentStep.value = 1;
    isContinueToPaymentLoading.value = false;
  }

  List<TimeSlot> getAllTimeSlotsForDisplay() {
    final available = getAvailableTimeSlots();
    final booked = getBookedSlotsAsTimeSlots();

    final all = [...available, ...booked];

    all.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    return all;
  }

  void selectPaymentMethod(String method) =>
      selectedPaymentMethod.value = method;

  Future<void> goToStep3() async {
    if (selectedPaymentMethod.value.isEmpty) {
      AppSnackbar.error('Please select a payment method');
      return;
    }

    isProceedToCheckoutLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    Get.to(() => const BookingStep3Summary());
    currentStep.value = 2;
    isProceedToCheckoutLoading.value = false;
  }

  Future<void> pickPaymentScreenshot() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        paymentScreenshot.value = File(image.path);
        paymentScreenshotUrl.value = image.path;
      }
    } catch (e) {
      AppSnackbar.error('Failed to pick image');
    }
  }

// ===========================================================================
// confirmBooking — saves booking to Firestore AND notifies business owner
// ===========================================================================
  Future<void> confirmBooking() async {
    if (paymentScreenshot.value == null) {
      AppSnackbar.error('Please upload payment screenshot');
      return;
    }

    isConfirmPaymentLoading.value = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppSnackbar.error('Please login to continue');
        isConfirmPaymentLoading.value = false;
        return;
      }

// Upload screenshot to Supabase
      final uploadedUrl = await SupabaseStorageService()
          .uploadPaymentScreenshot(paymentScreenshot.value!);

      if (uploadedUrl == null) {
        AppSnackbar.error('Failed to upload payment screenshot');
        isConfirmPaymentLoading.value = false;
        return;
      }

      final bookingId = DateTime.now().millisecondsSinceEpoch.toString();

      final bookingData = {
        'bookingId': bookingId,
        'customerId': user.uid,
        'customerName': customerName.value.trim(),
        'customerEmail': customerEmail.value.trim(),
        'customerPhone': customerPhone.value.trim(),
        'businessId': businessId.value,
        'businessName': businessName.value,
        'serviceId': serviceId.value,
        'serviceName': serviceName.value,
        'serviceDescription': serviceDescription.value,
        'serviceCategory': serviceCategory.value,
        'servicePrice': servicePrice.value,
        'serviceDuration': serviceDuration.value,
        'serviceImageUrl': serviceImageUrl.value,
        'selectedDate': _formatDateForQuery(selectedDate.value!),
        'selectedTime': selectedTime.value,
        'paymentMethod': selectedPaymentMethod.value,
        'advanceAmount': advancePayment,
        'remainingAmount': remainingPayment,
        'paymentScreenshotUrl': uploadedUrl,
        'hasSentThirtyMinReminder': false,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'userType': userType.value,
      };

// Save booking to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add(bookingData);

// ── Notify the business owner of the new booking request ──
      await NotificationService().sendPushNotification(
        userId: businessId.value,
        title: 'New Booking Request',
        body:
        '${customerName.value.trim()} has requested an appointment for ${serviceName.value} on ${_formatDateForQuery(selectedDate.value!)} at ${selectedTime.value}.',
        data: {
          'type': 'new_booking_request',
          'bookingId': docRef.id,
        },
      );

      isConfirmPaymentLoading.value = false;
      Get.off(() => const BookingSuccessScreen());
    } catch (e) {
      isConfirmPaymentLoading.value = false;
      AppSnackbar.error('Failed to confirm booking: $e');
    }
  }

  Future<void> loadBusinessPaymentMethods() async {
    try {
      final businessProfile =
      await UserService.getBusinessProfile(businessId.value);
      if (businessProfile != null &&
          businessProfile['paymentMethods'] != null) {
        businessPaymentMethods.value = List<Map<String, dynamic>>.from(
            businessProfile['paymentMethods']);
      }
    } catch (e) {
      print('Error loading payment methods: $e');
    }
  }

  String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String formatFullDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// Data classes (unchanged)
enum SlotStatus {
  available,
  fullyBooked,
  insufficientTime,
  partiallyAvailable,
}

class BookedSlot {
  final String startTime;
  final int duration;

  const BookedSlot({required this.startTime, required this.duration});
}

class TimeSlot {
  final String time;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final SlotStatus status;

  const TimeSlot({
    required this.time,
    required this.startDateTime,
    required this.endDateTime,
    required this.status,
  });

  bool get isBooked => status == SlotStatus.fullyBooked;
  bool get hasInsufficientTime => status == SlotStatus.insufficientTime;
  bool get isAvailable => status == SlotStatus.available;
  bool get isPartiallyAvailable => status == SlotStatus.partiallyAvailable;
}

class BookedRange {
  final int start;
  final int end;

  const BookedRange({required this.start, required this.end});
}

class FreeRange {
  final int start;
  final int end;

  const FreeRange({required this.start, required this.end});


}