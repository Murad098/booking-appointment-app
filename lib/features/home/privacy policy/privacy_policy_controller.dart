import 'package:flutter/services.dart';
import 'package:get/get.dart';

class PrivacyPolicyController extends GetxController {
  final policyContent = ''.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadPrivacyPolicy();
  }

  /// Loads the privacy policy text.
  /// You can change the source to Firestore or a remote URL later.
  Future<void> loadPrivacyPolicy() async {
    isLoading.value = true;
    try {
      // Option 1: Load from assets (recommended for static content)
      final content = await rootBundle.loadString('assets/privacy_policy.txt');
      policyContent.value = content;
    } catch (e) {
      // Fallback: built-in text (in case the asset is missing)
      policyContent.value = _getDefaultPrivacyPolicy();
      print('Privacy policy asset not found, using built-in text.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Returns a professional, booking‑oriented privacy policy.
  String _getDefaultPrivacyPolicy() {
    return '''
# Privacy Policy for Bookify

**Last updated:** ${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}

## 1. Introduction
Welcome to **Bookify** ("we", "our", "us"). We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application ("App") for booking appointments and managing services.

Please read this policy carefully. If you do not agree with the terms, do not access or use the App.

## 2. Information We Collect
We collect personal information that you voluntarily provide to us when you register, make a booking, or communicate with us.

### 2.1 Information you provide
- **Account data**: Name, email address, phone number, profile picture, and business details (if you are a service provider).
- **Booking data**: Service details, appointment date/time, special requests, customer notes.
- **Payment data**: Payment method, transaction amount, advance payment details. **Note:** We do not store full credit card numbers; payment processing is handled by secure third‑party gateways (e.g., Stripe, JazzCash, Easypaisa).

### 2.2 Automatically collected information
- **Device information**: IP address, device type, operating system, unique device identifiers.
- **Usage data**: App interactions, pages visited, appointment history, and crash logs.
- **Location data** (with your permission): We may collect your approximate location to recommend nearby services or calculate travel times. You can disable location permissions in your device settings.

### 2.3 Push notifications
We use Firebase Cloud Messaging to send you appointment reminders, booking confirmations, and promotional offers. You can opt out of notifications in the app settings or your device settings.

## 3. How We Use Your Information
We use the collected information for:
- Creating and managing your account.
- Processing and confirming bookings.
- Sending appointment reminders, status updates, and receipts.
- Improving our services, analytics, and troubleshooting.
- Preventing fraud and ensuring the security of the App.
- Complying with legal obligations.

## 4. Sharing Your Information
We do not sell your personal data. We may share information in the following situations:

- **With service providers**: To facilitate payments, send notifications, analyse usage (e.g., Google Analytics, Firebase). These providers are contractually bound to protect your data.
- **With business partners**: If you book a service with a business, we share your name, contact details, and booking preferences with that business to complete the appointment.
- **Legal requirements**: If required by law or to protect our rights, users, or the public.
- **Business transfers**: In case of a merger, acquisition, or sale of assets, your information may be transferred with notice.

## 5. Data Retention
We retain your personal information only as long as necessary for the purposes described in this policy. Booking records are kept for up to 7 years for tax and legal compliance. You may request deletion of your account and associated data by contacting us.

## 6. Your Rights
Depending on your location (e.g., GDPR for EU users, CCPA for California residents), you may have the right to:
- Access, correct, or delete your personal data.
- Object to or restrict certain processing.
- Data portability.
- Withdraw consent at any time.

To exercise your rights, please email us at **support@bookifyapp.com**.

## 7. Security
We implement industry‑standard security measures (encryption, firewalls, secure authentication) to protect your data. However, no method of transmission over the internet is 100% secure.

## 8. Children’s Privacy
The App is not intended for children under 13. We do not knowingly collect personal information from children. If you believe we have inadvertently collected such data, contact us to delete it.

## 9. Changes to This Policy
We may update this Privacy Policy from time to time. We will notify you of any material changes via the App or email. Your continued use after the effective date constitutes acceptance.

## 10. Contact Us
If you have questions about this Privacy Policy, please contact us:

- Email: **privacy@bookifyapp.com**
- Address: Bookify HQ, 123 Business Street, City, Country

---
*Bookify – Your trusted booking companion.*
''';
  }
}