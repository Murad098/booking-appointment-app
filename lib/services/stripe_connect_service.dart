// lib/services/stripe_connect_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/home/business account/stripe/stripe_account_model.dart';
import '../features/home/business account/stripe/stripe_constants.dart';

class StripeConnectService {
  static final StripeConnectService _instance = StripeConnectService._internal();
  factory StripeConnectService() => _instance;
  StripeConnectService._internal();

  Future<Map<String, String>> _getAuthHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    final idToken = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };
  }

  // ✅ Create connected account with proper country (US by default for card payments)
  Future<String?> createConnectedAccount({
    required String businessId,
    required String email,
    String country = 'US', // ✅ Use US for Stripe card payments
  }) async {
    try {
      final headers = await _getAuthHeaders();

      print('📤 Creating Stripe account for business: $businessId, country: $country');

      // ✅ Ensure country is supported
      if (!StripeConstants.supportedCountries.contains(country)) {
        print('⚠️ Country $country not supported, using US instead');
        country = 'US';
      }

      final response = await http.post(
        Uri.parse(StripeConstants.createConnectedAccountEndpoint),
        headers: headers,
        body: jsonEncode({
          'businessId': businessId,
          'email': email,
          'country': country,
        }),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['accountId'];
      } else {
        String errorMessage = 'Failed to create account';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? 'Failed to create account';
        } catch (e) {
          errorMessage = 'Server error (${response.statusCode})';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ createConnectedAccount error: $e');
      return null;
    }
  }

  Future<String?> createAccountLink({
    required String accountId,
    required String returnUrl,
    required String refreshUrl,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      print('📤 Creating account link for: $accountId');

      final response = await http.post(
        Uri.parse(StripeConstants.createAccountLinkEndpoint),
        headers: headers,
        body: jsonEncode({
          'accountId': accountId,
          'returnUrl': returnUrl,
          'refreshUrl': refreshUrl,
        }),
      );

      print('📥 Account link response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      } else {
        String errorMessage = 'Failed to create account link';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? 'Failed to create account link';
        } catch (e) {
          errorMessage = 'Server error (${response.statusCode})';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ createAccountLink error: $e');
      return null;
    }
  }

  Future<StripeAccountModel?> retrieveAccountStatus({
    required String accountId,
    required String businessId,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      print('📤 Retrieving account status for: $accountId');

      final response = await http.post(
        Uri.parse(StripeConstants.retrieveAccountStatusEndpoint),
        headers: headers,
        body: jsonEncode({'accountId': accountId}),
      );

      print('📥 Account status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final chargesEnabled = data['chargesEnabled'] as bool? ?? false;
        final payoutsEnabled = data['payoutsEnabled'] as bool? ?? false;
        final detailsSubmitted = data['detailsSubmitted'] as bool? ?? false;

        String status;
        if (chargesEnabled && payoutsEnabled) {
          status = 'enabled';
        } else if (chargesEnabled || payoutsEnabled) {
          status = 'restricted';
        } else {
          status = 'pending';
        }

        return StripeAccountModel(
          accountId: accountId,
          businessId: businessId,
          status: status,
          chargesEnabled: chargesEnabled,
          payoutsEnabled: payoutsEnabled,
          detailsSubmitted: detailsSubmitted,
          requirements: data['requirements'] as Map<String, dynamic>?,
          capabilities: data['capabilities'] as Map<String, dynamic>?,
          country: data['country'] as String? ?? 'US',
          email: data['email'] as String? ?? '',
        );
      }
      return null;
    } catch (e) {
      print('❌ retrieveAccountStatus error: $e');
      return null;
    }
  }

  Future<bool> hasStripeConnected(String businessId) async {
    try {
      final businessDoc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .get();
      if (businessDoc.exists) {
        final data = businessDoc.data();
        final status = data?['stripeAccountStatus'] as String?;
        final chargesEnabled = data?['stripeChargesEnabled'] as bool? ?? false;
        final payoutsEnabled = data?['stripePayoutsEnabled'] as bool? ?? false;
        return status == 'enabled' && chargesEnabled && payoutsEnabled;
      }
      return false;
    } catch (e) {
      print('❌ hasStripeConnected error: $e');
      return false;
    }
  }

  Future<String?> getStripeAccountId(String businessId) async {
    try {
      final businessDoc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .get();
      return businessDoc.data()?['stripeAccountId'] as String?;
    } catch (e) {
      print('❌ getStripeAccountId error: $e');
      return null;
    }
  }

  Future<String?> getStripeAccountStatus(String businessId) async {
    try {
      final businessDoc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .get();
      return businessDoc.data()?['stripeAccountStatus'] as String?;
    } catch (e) {
      print('❌ getStripeAccountStatus error: $e');
      return null;
    }
  }

  Future<bool> getStripeChargesEnabled(String businessId) async {
    try {
      final businessDoc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .get();
      return businessDoc.data()?['stripeChargesEnabled'] as bool? ?? false;
    } catch (e) {
      print('❌ getStripeChargesEnabled error: $e');
      return false;
    }
  }

  Future<bool> getStripePayoutsEnabled(String businessId) async {
    try {
      final businessDoc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .get();
      return businessDoc.data()?['stripePayoutsEnabled'] as bool? ?? false;
    } catch (e) {
      print('❌ getStripePayoutsEnabled error: $e');
      return false;
    }
  }
}