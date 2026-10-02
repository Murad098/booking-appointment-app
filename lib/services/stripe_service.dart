// lib/services/stripe_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/home/business account/stripe/payment_intent_model.dart';
import '../features/home/business account/stripe/stripe_constants.dart';

class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      Stripe.publishableKey = StripeConstants.publishableKey;
      await Stripe.instance.applySettings();
      _initialized = true;
      print('✅ Stripe initialized');
    } catch (e) {
      print('❌ Stripe init error: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    final idToken = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };
  }

  Future<StripePaymentIntentModel> createPaymentIntent({
    required double amount,
    required String currency,
    required String businessStripeAccountId,
    required String bookingId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse(StripeConstants.createPaymentIntentEndpoint);

      print('📍 Creating PaymentIntent at: $url');
      print('📍 Account ID: $businessStripeAccountId');

      // ✅ Amount is already in cents (smallest currency unit)
      final amountInCents = (amount * 100).round();
      print('📍 Amount: $amountInCents ${currency.toLowerCase()}');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'amount': amountInCents,
          'currency': currency.toLowerCase(),
          'businessStripeAccountId': businessStripeAccountId,
          'bookingId': bookingId,
        }),
      );

      print('📍 Response status: ${response.statusCode}');
      print('📍 Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        throw Exception('Server returned HTML instead of JSON. Please check if the backend is running and the URL is correct.');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StripePaymentIntentModel.fromJson(data);
      } else {
        String errorMessage;
        try {
          final error = jsonDecode(response.body);
          errorMessage = error['message'] ?? 'Failed to create payment intent';
        } catch (e) {
          errorMessage = 'Server error: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ createPaymentIntent error: $e');
      rethrow;
    }
  }

  Future<bool> handlePaymentSheet({
    required String clientSecret,
    required String stripeAccountId,
    required VoidCallback onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      // For connected account payments using destination charges,
      // we don't need to set stripeAccountId on the Stripe instance
      Stripe.stripeAccountId = null;
      // ✅ Build parameters conditionally for Android/iOS
      final params = SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Bookify',
        style: ThemeMode.light,
        // ✅ Google Pay – only on Android
        googlePay: Platform.isAndroid
            ? const PaymentSheetGooglePay(
          merchantCountryCode: 'US', // Stripe account country
          testEnv: true,
        )
            : null,
        // ✅ Apple Pay – only on iOS, with merchant identifier
        applePay: Platform.isIOS
            ? const PaymentSheetApplePay(
          merchantCountryCode: 'US',
          // ⚠️ Replace with your actual Apple Merchant ID
          // You must register this in your Apple Developer account
        )
            : null,
      );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: params,
      );

      await Stripe.instance.presentPaymentSheet();

      Stripe.stripeAccountId = null;
      onSuccess();
      return true;
    } on StripeException catch (e) {
      Stripe.stripeAccountId = null;
      if (e.error.code == FailureCode.Canceled) {
        onError('Payment cancelled');
      } else {
        onError(e.error.localizedMessage ?? 'Payment failed');
      }
      return false;
    } catch (e) {
      Stripe.stripeAccountId = null;
      if (e.toString().toLowerCase().contains('cancel')) {
        onError('Payment cancelled');
      } else {
        onError('Payment failed: ${e.toString()}');
      }
      return false;
    }
  }

  Future<bool> processFullPayment({
    required double amount,
    required String currency,
    required String businessStripeAccountId,
    required String bookingId,
    required VoidCallback onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      await initialize();

      final paymentIntent = await createPaymentIntent(
        amount: amount,
        currency: currency,
        businessStripeAccountId: businessStripeAccountId,
        bookingId: bookingId,
      );

      return await handlePaymentSheet(
        clientSecret: paymentIntent.clientSecret,
        stripeAccountId: businessStripeAccountId,
        onSuccess: onSuccess,
        onError: onError,
      );
    } catch (e) {
      onError('Payment setup failed: ${e.toString()}');
      return false;
    }
  }

  Future<bool> checkBackendHealth() async {
    try {
      final url = Uri.parse(StripeConstants.baseUrl);
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Backend health check failed: $e');
      return false;
    }
  }
}