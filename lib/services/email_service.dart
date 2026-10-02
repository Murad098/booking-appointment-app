import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmailService {
  static const String _queueKey = 'email_queue';
  // TODO: set this to your deployed stripe-backend URL (the same one used for Stripe endpoints)
  static const String _backendBaseUrl = 'https://YOUR-BACKEND-URL.example.com';

  /// Queue a welcome email (will be sent in background)
  static Future<void> queueWelcomeEmail(String userEmail, String userName) async {
    final emailData = {
      'to': userEmail,
      'name': userName,
      'subject': 'Welcome to Bookify! 🎉',
      'htmlContent': _getWelcomeEmailHtml(userName),
    };
    await _addToQueue(emailData);
    _processEmailQueue();
  }

  /// Queue a password‑changed notification email
  static Future<void> queuePasswordChangedEmail(String userEmail, String userName) async {
    final emailData = {
      'to': userEmail,
      'name': userName,
      'subject': 'Your Bookify password has been changed',
      'htmlContent': _getPasswordChangedEmailHtml(userName),
    };
    await _addToQueue(emailData);
    _processEmailQueue();
  }

  static Future<void> _addToQueue(Map<String, dynamic> emailData) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> queue = prefs.getStringList(_queueKey) ?? [];
    queue.add(jsonEncode(emailData));
    await prefs.setStringList(_queueKey, queue);
    print('[EmailService] Queued email for ${emailData['to']}');
  }

  static Future<void> _processEmailQueue() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> queue = prefs.getStringList(_queueKey) ?? [];
    if (queue.isEmpty) return;

    final String emailJson = queue.first;
    final Map<String, dynamic> emailData = jsonDecode(emailJson);
    final bool success = await _sendViaBackend(
      emailData['to'],
      emailData['name'],
      emailData['subject'],
      emailData['htmlContent'],
    );

    if (success) {
      queue.removeAt(0);
      await prefs.setStringList(_queueKey, queue);
      print('[EmailService] Sent email to ${emailData['to']}. Remaining: ${queue.length}');
      _processEmailQueue();
    } else {
      print('[EmailService] Failed to send to ${emailData['to']}. Will retry later.');
    }
  }

  static Future<bool> _sendViaBackend(String toEmail, String name, String subject, String htmlContent) async {
    final String url = '$_backendBaseUrl/send-email';

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      if (idToken == null) {
        print('[EmailService] No signed-in user; cannot authenticate email request');
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
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Backend email error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Network error: $e');
      return false;
    }
  }

  static String _getWelcomeEmailHtml(String name) {
    return '''
    <!DOCTYPE html>
    <html>
    <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"></head>
    <body style="margin:0;padding:0;font-family:Arial,sans-serif;background:#f4f4f4;">
      <div style="max-width:600px;margin:20px auto;background:white;border-radius:12px;overflow:hidden;box-shadow:0 4px 8px rgba(0,0,0,0.05);">
        <div style="background:#7B2CBF;padding:20px;text-align:center;color:white;">
          <h1 style="margin:0;">Welcome to Bookify! 🎉</h1>
        </div>
        <div style="padding:30px;color:#333;line-height:1.6;">
          <p>Dear ${name},</p>
          <p>Thank you for choosing <strong>Bookify</strong> – your smart appointment management platform.</p>
          <p>We're excited to help you streamline your bookings.</p>
          <a href="https://bookifyapp.com/get-started" style="display:inline-block;background:#7B2CBF;color:white;text-decoration:none;padding:12px 24px;border-radius:8px;margin:20px 0;">Get Started</a>
          <p>Happy scheduling!<br><strong>The Bookify Team</strong></p>
        </div>
        <div style="background:#f8f9fa;text-align:center;padding:15px;font-size:12px;color:#777;">
          © 2025 Bookify. All rights reserved.
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  static String _getPasswordChangedEmailHtml(String name) {
    return '''
    <!DOCTYPE html>
    <html>
    <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"></head>
    <body style="margin:0;padding:0;font-family:Arial,sans-serif;background:#f4f4f4;">
      <div style="max-width:600px;margin:20px auto;background:white;border-radius:12px;overflow:hidden;box-shadow:0 4px 8px rgba(0,0,0,0.05);">
        <div style="background:#7B2CBF;padding:20px;text-align:center;color:white;">
          <h1 style="margin:0;">Password Changed Successfully</h1>
        </div>
        <div style="padding:30px;color:#333;line-height:1.6;">
          <p>Dear ${name},</p>
          <p>This is a confirmation that the password for your <strong>Bookify</strong> account was changed on ${DateTime.now().toLocal().toString().split('.')[0]}.</p>
          <p>If you made this change, you can safely ignore this email.</p>
          <div style="background:#fff3cd;border-left:4px solid #ffc107;padding:12px;margin:20px 0;border-radius:4px;">
            <strong>⚠️ Didn't request this?</strong><br>
            Please <a href="https://bookifyapp.com/reset-password" style="color:#7B2CBF;">reset your password immediately</a> and contact our support team.
          </div>
          <p>For your security, we recommend using a strong, unique password.</p>
          <p>Best regards,<br><strong>The Bookify Team</strong></p>
        </div>
        <div style="background:#f8f9fa;text-align:center;padding:15px;font-size:12px;color:#777;">
          © 2025 Bookify. All rights reserved.
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  // Add these inside the EmailService class (after the existing methods)

  /// Queue an email to both customer and business when an appointment is confirmed (pending → confirmed)
  static Future<void> queueAppointmentConfirmed({
    required String customerEmail,
    required String customerName,
    required String? businessEmail,
    required String businessName,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    // Email to customer
    final customerData = {
      'to': customerEmail,
      'name': customerName,
      'subject': 'Your Appointment is Confirmed! ✅',
      'htmlContent': _getAppointmentConfirmedCustomerHtml(customerName, businessName, serviceName, date, time),
    };
    await _addToQueue(customerData);

    // Email to business
    final businessData = {
      'to': businessEmail,
      'name': businessName,
      'subject': 'New Appointment Confirmed',
      'htmlContent': _getAppointmentConfirmedBusinessHtml(businessName, customerName, serviceName, date, time),
    };
    await _addToQueue(businessData);

    _processEmailQueue();
  }

  /// Queue an email to the customer when the appointment is cancelled by business
  static Future<void> queueAppointmentCancelledByBusiness({
    required String customerEmail,
    required String customerName,
    required String businessName,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final emailData = {
      'to': customerEmail,
      'name': customerName,
      'subject': 'Your Appointment Has Been Cancelled',
      'htmlContent': _getAppointmentCancelledCustomerHtml(customerName, businessName, serviceName, date, time),
    };
    await _addToQueue(emailData);
    _processEmailQueue();
  }

  /// Queue an email to the business when the customer cancels
  static Future<void> queueAppointmentCancelledByCustomer({
    required String businessEmail,
    required String businessName,
    required String customerName,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final emailData = {
      'to': businessEmail,
      'name': businessName,
      'subject': 'Appointment Cancelled by Customer',
      'htmlContent': _getAppointmentCancelledBusinessHtml(businessName, customerName, serviceName, date, time),
    };
    await _addToQueue(emailData);
    _processEmailQueue();
  }

  /// Queue an email to the customer when the business reschedules (immediate confirmation)
  static Future<void> queueAppointmentRescheduledByBusiness({
    required String customerEmail,
    required String customerName,
    required String businessName,
    required String serviceName,
    required String oldDate,
    required String oldTime,
    required String newDate,
    required String newTime,
  }) async {
    final emailData = {
      'to': customerEmail,
      'name': customerName,
      'subject': 'Your Appointment Has Been Rescheduled',
      'htmlContent': _getAppointmentRescheduledCustomerHtml(customerName, businessName, serviceName, oldDate, oldTime, newDate, newTime),
    };
    await _addToQueue(emailData);
    _processEmailQueue();
  }

  /// Queue an email to the customer when the appointment is completed
  static Future<void> queueAppointmentCompleted({
    required String customerEmail,
    required String customerName,
    required String businessName,
    required String serviceName,
  }) async {
    final emailData = {
      'to': customerEmail,
      'name': customerName,
      'subject': 'Your Appointment is Complete! ⭐',
      'htmlContent': _getAppointmentCompletedCustomerHtml(customerName, businessName, serviceName),
    };
    await _addToQueue(emailData);
    _processEmailQueue();
  }


// ---------- HTML templates for appointment emails ----------
  static String _getAppointmentConfirmedCustomerHtml(String customerName, String businessName, String serviceName, String date, String time) {
    return '''
  <!DOCTYPE html>
  <html>
  <head><meta charset="UTF-8"></head>
  <body style="margin:0;padding:0;font-family:Arial,sans-serif;background:#f4f4f4;">
    <div style="max-width:600px;margin:20px auto;background:white;border-radius:12px;overflow:hidden;">
      <div style="background:#7B2CBF;padding:20px;text-align:center;color:white;">
        <h1 style="margin:0;">Appointment Confirmed ✅</h1>
      </div>
      <div style="padding:30px;color:#333;line-height:1.6;">
        <p>Dear $customerName,</p>
        <p>Your appointment at <strong>$businessName</strong> for <strong>$serviceName</strong> has been confirmed.</p>
        <p><strong>Date:</strong> $date<br><strong>Time:</strong> $time</p>
        <p>We look forward to serving you. If you need to make changes, please contact the business directly.</p>
        <p>Best regards,<br><strong>The Bookify Team</strong></p>
      </div>
      <div style="background:#f8f9fa;text-align:center;padding:15px;font-size:12px;color:#777;">
        © 2025 Bookify. All rights reserved.
      </div>
    </div>
  </body>
  </html>
  ''';
  }

  static String _getAppointmentConfirmedBusinessHtml(String businessName, String customerName, String serviceName, String date, String time) {
    return '''
  <!DOCTYPE html>
  <html>
  <head><meta charset="UTF-8"></head>
  <body style="margin:0;padding:0;font-family:Arial,sans-serif;background:#f4f4f4;">
    <div style="max-width:600px;margin:20px auto;background:white;border-radius:12px;overflow:hidden;">
      <div style="background:#7B2CBF;padding:20px;text-align:center;color:white;">
        <h1 style="margin:0;">Appointment Confirmed</h1>
      </div>
      <div style="padding:30px;color:#333;line-height:1.6;">
        <p>Dear $businessName,</p>
        <p>You have a confirmed appointment with <strong>$customerName</strong> for <strong>$serviceName</strong>.</p>
        <p><strong>Date:</strong> $date<br><strong>Time:</strong> $time</p>
        <p>Please ensure everything is ready for the customer's arrival.</p>
        <p>Best regards,<br><strong>The Bookify Team</strong></p>
      </div>
      <div style="background:#f8f9fa;text-align:center;padding:15px;font-size:12px;color:#777;">
        © 2025 Bookify. All rights reserved.
      </div>
    </div>
  </body>
  </html>
  ''';
  }

  static String _getAppointmentCancelledCustomerHtml(String customerName, String businessName, String serviceName, String date, String time) {
    return '''
  <!DOCTYPE html>
  <html>
  <head><meta charset="UTF-8"></head>
  <body style="margin:0;padding:0;font-family:Arial,sans-serif;background:#f4f4f4;">
    <div style="max-width:600px;margin:20px auto;background:white;border-radius:12px;overflow:hidden;">
      <div style="background:#dc3545;padding:20px;text-align:center;color:white;">
        <h1 style="margin:0;">Appointment Cancelled</h1>
      </div>
      <div style="padding:30px;color:#333;line-height:1.6;">
        <p>Dear $customerName,</p>
        <p>Your appointment at <strong>$businessName</strong> for <strong>$serviceName</strong> on <strong>$date at $time</strong> has been cancelled.</p>
        <p>If you have already made an advance payment, a refund will be processed within 3‑5 business days.</p>
        <p>We apologise for any inconvenience. Please contact the business directly if you have any questions.</p>
        <p>Best regards,<br><strong>The Bookify Team</strong></p>
      </div>
      <div style="background:#f8f9fa;text-align:center;padding:15px;font-size:12px;color:#777;">
        © 2025 Bookify. All rights reserved.
      </div>
    </div>
  </body>
  </html>
  ''';
  }

  static String _getAppointmentCancelledBusinessHtml(String businessName, String customerName, String serviceName, String date, String time) {
    return '''
  <!DOCTYPE html>
  <html>
  <head><meta charset="UTF-8"></head>
  <body style="margin:0;padding:0;font-family:Arial,sans-serif;background:#f4f4f4;">
    <div style="max-width:600px;margin:20px auto;background:white;border-radius:12px;overflow:hidden;">
      <div style="background:#dc3545;padding:20px;text-align:center;color:white;">
        <h1 style="margin:0;">Appointment Cancelled by Customer</h1>
      </div>
      <div style="padding:30px;color:#333;line-height:1.6;">
        <p>Dear $businessName,</p>
        <p><strong>$customerName</strong> has cancelled their appointment for <strong>$serviceName</strong> on <strong>$date at $time</strong>.</p>
        <p>Please update your schedule accordingly.</p>
        <p>Best regards,<br><strong>The Bookify Team</strong></p>
      </div>
      <div style="background:#f8f9fa;text-align:center;padding:15px;font-size:12px;color:#777;">
        © 2025 Bookify. All rights reserved.
      </div>
    </div>
  </body>
  </html>
  ''';
  }

  static String _getAppointmentRescheduledCustomerHtml(String customerName, String businessName, String serviceName, String oldDate, String oldTime, String newDate, String newTime) {
    return '''
  <!DOCTYPE html>
  <html>
  <head><meta charset="UTF-8"></head>
  <body style="margin:0;padding:0;font-family:Arial,sans-serif;background:#f4f4f4;">
    <div style="max-width:600px;margin:20px auto;background:white;border-radius:12px;overflow:hidden;">
      <div style="background:#ffc107;padding:20px;text-align:center;color:#333;">
        <h1 style="margin:0;">Appointment Rescheduled</h1>
      </div>
      <div style="padding:30px;color:#333;line-height:1.6;">
        <p>Dear $customerName,</p>
        <p>Your appointment at <strong>$businessName</strong> for <strong>$serviceName</strong> has been rescheduled.</p>
        <p><strong>Old date & time:</strong> $oldDate at $oldTime<br>
        <strong>New date & time:</strong> $newDate at $newTime</p>
        <p>If this doesn’t work for you, please contact the business directly.</p>
        <p>Best regards,<br><strong>The Bookify Team</strong></p>
      </div>
      <div style="background:#f8f9fa;text-align:center;padding:15px;font-size:12px;color:#777;">
        © 2025 Bookify. All rights reserved.
      </div>
    </div>
  </body>
  </html>
  ''';
  }

  static String _getAppointmentCompletedCustomerHtml(String customerName, String businessName, String serviceName) {
    return '''
  <!DOCTYPE html>
  <html>
  <head><meta charset="UTF-8"></head>
  <body style="margin:0;padding:0;font-family:Arial,sans-serif;background:#f4f4f4;">
    <div style="max-width:600px;margin:20px auto;background:white;border-radius:12px;overflow:hidden;">
      <div style="background:#28a745;padding:20px;text-align:center;color:white;">
        <h1 style="margin:0;">Appointment Completed! ⭐</h1>
      </div>
      <div style="padding:30px;color:#333;line-height:1.6;">
        <p>Dear $customerName,</p>
        <p>Your appointment at <strong>$businessName</strong> for <strong>$serviceName</strong> has been marked as completed.</p>
        <p>We would love to hear about your experience. Please take a moment to <a href="https://bookifyapp.com/rate-appointment" style="color:#7B2CBF;">rate your appointment</a> and share your feedback.</p>
        <p>Your input helps us improve!</p>
        <p>Best regards,<br><strong>The Bookify Team</strong></p>
      </div>
      <div style="background:#f8f9fa;text-align:center;padding:15px;font-size:12px;color:#777;">
        © 2025 Bookify. All rights reserved.
      </div>
    </div>
  </body>
  </html>
  ''';
  }
}