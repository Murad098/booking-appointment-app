import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import 'email_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('[ReminderService] WorkManager task executed: $task');

    if (task == 'checkAppointmentReminders') {
      await ReminderService.checkUpcomingAppointments();
    }
    return Future.value(true);
  });
}

class ReminderService {
  static const String reminderTask = 'checkAppointmentReminders';

  // Track which reminders have been sent to avoid duplicates
  static final Set<String> _sentReminders = {};

  static Future<void> initialize() async {
    print('[ReminderService] Initializing...');

    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Register periodic task - runs every 15 minutes
    await Workmanager().registerPeriodicTask(
      'reminderCheck',
      reminderTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    print('[ReminderService] Initialized successfully');
  }

  /// Check all upcoming appointments and send reminders if needed
  static Future<void> checkUpcomingAppointments() async {
    try {
      print('[ReminderService] Checking upcoming appointments...');
      final now = DateTime.now();

      // Get all confirmed appointments that haven't had a 30-minute reminder sent
      final bookingsQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'confirmed')
          .get();

      print('[ReminderService] Found ${bookingsQuery.docs.length} confirmed appointments without reminder');

      for (final doc in bookingsQuery.docs) {
        final data = doc.data();
        final bookingId = doc.id;
        final alreadySent = data['hasSentThirtyMinReminder'] ?? false;
        if (alreadySent) continue;

        final appointmentDate = data['selectedDate']?.toString() ?? data['date']?.toString() ?? '';
        final appointmentTime = data['selectedTime']?.toString() ?? data['time']?.toString() ?? '';

        if (appointmentDate.isEmpty || appointmentTime.isEmpty) {
          print('[ReminderService] Skipping booking $bookingId - missing date/time');
          continue;
        }

        final appointmentDateTime = _parseAppointmentDateTime(appointmentDate, appointmentTime);
        if (appointmentDateTime == null) {
          print('[ReminderService] Skipping booking $bookingId - failed to parse date/time');
          continue;
        }

        final timeRemaining = appointmentDateTime.difference(now);
        final minutesRemaining = timeRemaining.inMinutes;

        // Send reminder when 28-32 minutes remain (buffer for background task timing)
        final isThirtyMinWindow = minutesRemaining >= 25 && minutesRemaining <= 35;

        if (isThirtyMinWindow && appointmentDateTime.isAfter(now)) {
          print('[ReminderService] Sending 30-minute reminder for booking: $bookingId (${minutesRemaining} minutes remaining)');
          await _sendReminderNotification(bookingId, data);
          _sentReminders.add(bookingId);
        }
      }

      // Clear sent reminders set occasionally to prevent memory issues
      if (_sentReminders.length > 100) {
        _sentReminders.clear();
      }

      print('[ReminderService] Reminder check completed');
    } catch (e) {
      print('[ReminderService] Error checking appointments: $e');
    }
  }

  static DateTime? _parseAppointmentDateTime(String dateStr, String timeStr) {
    try {
      String cleanDateStr = dateStr;
      if (dateStr.contains('T')) {
        cleanDateStr = dateStr.split('T')[0];
      }

      final dateParts = cleanDateStr.split('-');
      if (dateParts.length != 3) return null;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      String cleanTimeStr = timeStr;
      if (timeStr.contains(' - ')) {
        cleanTimeStr = timeStr.split(' - ')[0].trim();
      }

      final timeParts = cleanTimeStr.split(':');
      if (timeParts.length < 2) return null;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      print('[ReminderService] Parse error: $e');
      return null;
    }
  }

  static Future<void> _sendReminderNotification(String bookingId, Map<String, dynamic> data) async {
    try {
      final businessId = data['businessId'] ?? '';
      final customerId = data['customerId'] ?? '';
      final businessName = data['businessName'] ?? 'the business';
      final customerName = data['customerName'] ?? 'a customer';
      final customerEmail = data['customerEmail'] ?? '';  // ✅ Use email from booking
      final serviceName = data['serviceName'] ?? 'appointment';
      final appointmentDate = data['selectedDate']?.toString() ?? data['date']?.toString() ?? '';
      final appointmentTime = data['selectedTime']?.toString() ?? data['time']?.toString() ?? '';

      final formattedTime = _formatTimeForNotification(appointmentTime);
      final formattedDate = _formatDateForNotification(appointmentDate);

      print('[ReminderService] Sending reminders for booking $bookingId');
      print('[ReminderService] Business ID: $businessId, Customer ID: $customerId, Customer Email: $customerEmail');

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // SEND TO BUSINESS
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      if (businessId.isNotEmpty) {
        // Push Notification - this already stores in Firestore, so we don't call _saveNotificationToFirestore separately
        await NotificationService().sendPushNotification(
          userId: businessId,
          title: '⏰ Appointment in 30 Minutes',
          body: 'Your appointment with $customerName for "$serviceName" is scheduled at $formattedTime on $formattedDate.',
          data: {
            'type': 'thirty_min_reminder',
            'bookingId': bookingId,
            'role': 'business',
          },
        );

        // Send Email to Business
        await _sendReminderEmailToBusiness(
          businessId: businessId,
          businessName: businessName,
          customerName: customerName,
          serviceName: serviceName,
          formattedDate: formattedDate,
          formattedTime: formattedTime,
        );
      }

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // SEND TO CUSTOMER
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      if (customerId.isNotEmpty) {
        // Push Notification - this already stores in Firestore, so we don't call _saveNotificationToFirestore separately
        await NotificationService().sendPushNotification(
          userId: customerId,
          title: '⏰ Upcoming Appointment in 30 Minutes',
          body: 'Your appointment at $businessName for "$serviceName" is scheduled at $formattedTime on $formattedDate.',
          data: {
            'type': 'thirty_min_reminder',
            'bookingId': bookingId,
            'role': 'customer',
          },
        );

        // Send Email to Customer - using email from booking directly
        await _sendReminderEmailToCustomer(
          customerEmail: customerEmail,
          customerName: customerName,
          businessName: businessName,
          serviceName: serviceName,
          formattedDate: formattedDate,
          formattedTime: formattedTime,
        );
      }

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // MARK REMINDER AS SENT
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'hasSentThirtyMinReminder': true,
        'thirtyMinReminderSentAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('[ReminderService] 30-minute reminder sent successfully for booking: $bookingId');
    } catch (e) {
      print('[ReminderService] Error sending reminder: $e');
    }
  }

  static Future<void> _sendReminderEmailToBusiness({
    required String businessId,
    required String businessName,
    required String customerName,
    required String serviceName,
    required String formattedDate,
    required String formattedTime,
  }) async {
    try {
      // Fetch business email from businesses collection
      final businessDoc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .get();

      String businessEmail = '';
      if (businessDoc.exists) {
        businessEmail = businessDoc.data()?['email'] ?? '';
      }

      // Fallback to users collection if not found
      if (businessEmail.isEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(businessId)
            .get();
        businessEmail = userDoc.data()?['email'] ?? '';
      }

      if (businessEmail.isNotEmpty) {
        // ✅ Send email directly using Brevo API (same as AppointmentDetailsController)
        final bool success = await _sendEmailViaBackend(
          toEmail: businessEmail,
          name: businessName,
          subject: '⏰ Appointment Reminder: In 30 Minutes',
          htmlContent: '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;font-family:Arial,sans-serif;background:#f4f4f4;">
  <div style="max-width:600px;margin:20px auto;background:white;border-radius:12px;overflow:hidden;">
    <div style="background:#7B2CBF;padding:20px;text-align:center;color:white;">
      <h1 style="margin:0;">⏰ Appointment Reminder</h1>
    </div>
    <div style="padding:30px;color:#333;line-height:1.6;">
      <p>Dear $businessName,</p>
      <p>This is a reminder that you have an appointment scheduled in <strong>30 minutes</strong>.</p>
      <div style="background:#f8f9fa;padding:15px;border-radius:8px;margin:20px 0;">
        <p><strong>📋 Appointment Details:</strong></p>
        <p>• Customer: $customerName<br>
        • Service: $serviceName<br>
        • Date: $formattedDate<br>
        • Time: $formattedTime</p>
      </div>
      <p>Please ensure you're ready to provide the best service.</p>
      <p>Best regards,<br><strong>The Bookify Team</strong></p>
    </div>
    <div style="background:#f8f9fa;text-align:center;padding:15px;font-size:12px;color:#777;">
      © 2025 Bookify. All rights reserved.
    </div>
  </div>
</body>
</html>
          ''',
        );

        if (success) {
          print('[ReminderService] Reminder email sent successfully to business: $businessEmail');
        } else {
          print('[ReminderService] Failed to send reminder email to business: $businessEmail');
        }
      } else {
        print('[ReminderService] No email found for business: $businessId');
      }
    } catch (e) {
      print('[ReminderService] Error sending business reminder email: $e');
    }
  }

  static Future<void> _sendReminderEmailToCustomer({
    required String customerEmail,
    required String customerName,
    required String businessName,
    required String serviceName,
    required String formattedDate,
    required String formattedTime,
  }) async {
    try {
      if (customerEmail.isEmpty) {
        print('[ReminderService] No customer email found in booking data');
        return;
      }

      // ✅ Send email directly using Brevo API (same as AppointmentDetailsController)
      final bool success = await _sendEmailViaBackend(
        toEmail: customerEmail,
        name: customerName,
        subject: '⏰ Appointment Reminder: In 30 Minutes',
        htmlContent: '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;font-family:Arial,sans-serif;background:#f4f4f4;">
  <div style="max-width:600px;margin:20px auto;background:white;border-radius:12px;overflow:hidden;">
    <div style="background:#7B2CBF;padding:20px;text-align:center;color:white;">
      <h1 style="margin:0;">⏰ Appointment Reminder</h1>
    </div>
    <div style="padding:30px;color:#333;line-height:1.6;">
      <p>Dear $customerName,</p>
      <p>This is a reminder that you have an appointment scheduled in <strong>30 minutes</strong>.</p>
      <div style="background:#f8f9fa;padding:15px;border-radius:8px;margin:20px 0;">
        <p><strong>📋 Appointment Details:</strong></p>
        <p>• Business: $businessName<br>
        • Service: $serviceName<br>
        • Date: $formattedDate<br>
        • Time: $formattedTime</p>
      </div>
      <p>Please arrive on time for your appointment.</p>
      <p>We look forward to serving you!</p>
      <p>Best regards,<br><strong>The Bookify Team</strong></p>
    </div>
    <div style="background:#f8f9fa;text-align:center;padding:15px;font-size:12px;color:#777;">
      © 2025 Bookify. All rights reserved.
    </div>
  </div>
</body>
</html>
        ''',
      );

      if (success) {
        print('[ReminderService] Reminder email sent successfully to customer: $customerEmail');
      } else {
        print('[ReminderService] Failed to send reminder email to customer: $customerEmail');
      }
    } catch (e) {
      print('[ReminderService] Error sending customer reminder email: $e');
    }
  }

  /// Send email via our backend (which proxies to Brevo), keeping the API key server-side only
  static Future<bool> _sendEmailViaBackend({
    required String toEmail,
    required String name,
    required String subject,
    required String htmlContent,
  }) async {
    // TODO: set this to your deployed stripe-backend URL (the same one used for Stripe endpoints)
    const String backendBaseUrl = 'https://YOUR-BACKEND-URL.example.com';
    final String url = '$backendBaseUrl/send-email';

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      if (idToken == null) {
        print('[ReminderService] No signed-in user; cannot authenticate email request');
        return false;
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $idToken',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'to': toEmail,
          'name': name,
          'subject': subject,
          'html': htmlContent,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('[ReminderService] Backend email error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('[ReminderService] Network error sending email: $e');
      return false;
    }
  }

  // ❌ REMOVED _saveNotificationToFirestore - no longer needed since sendPushNotification already does this
  // ❌ REMOVED duplicate _storeInFirestore call

  static String _formatTimeForNotification(String timeStr) {
    try {
      String cleanTimeStr = timeStr;
      if (timeStr.contains(' - ')) {
        cleanTimeStr = timeStr.split(' - ')[0].trim();
      }

      final timeParts = cleanTimeStr.split(':');
      if (timeParts.length >= 2) {
        int hour = int.parse(timeParts[0]);
        final minute = timeParts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        hour = hour % 12;
        if (hour == 0) hour = 12;
        return '$hour:$minute $period';
      }
      return timeStr;
    } catch (e) {
      return timeStr;
    }
  }

  static String _formatDateForNotification(String dateStr) {
    try {
      String cleanDateStr = dateStr;
      if (dateStr.contains('T')) {
        cleanDateStr = dateStr.split('T')[0];
      }
      final date = DateTime.parse(cleanDateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  /// Force check reminders (can be called manually for testing)
  static Future<void> forceCheckReminders() async {
    print('[ReminderService] Force checking reminders...');
    await checkUpcomingAppointments();
  }

  static Timer? _foregroundTimer;

  static void startForegroundCheck() {
    _foregroundTimer?.cancel();
    _foregroundTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      checkUpcomingAppointments();
    });
  }

  static void stopForegroundCheck() {
    _foregroundTimer?.cancel();
    _foregroundTimer = null;
  }
}