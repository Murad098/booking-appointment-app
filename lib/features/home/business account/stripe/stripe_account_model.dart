// lib/features/home/business account/stripe payment/stripe_account_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'stripe_constants.dart';

class StripeAccountModel {
  final String accountId;
  final String businessId;
  final String status; // 'pending', 'restricted', 'enabled', 'disabled'
  final bool chargesEnabled; // ✅ Changed from String? to bool
  final bool payoutsEnabled; // ✅ Changed from String? to bool
  final bool detailsSubmitted; // ✅ Changed from String? to bool
  final Map<String, dynamic>? requirements;
  final Map<String, dynamic>? capabilities;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String country;
  final String email;

  StripeAccountModel({
    required this.accountId,
    required this.businessId,
    required this.status,
    required this.chargesEnabled,
    required this.payoutsEnabled,
    required this.detailsSubmitted,
    this.requirements,
    this.capabilities,
    this.createdAt,
    this.updatedAt,
    this.country = 'PK',
    this.email = '',
  });

  factory StripeAccountModel.fromMap(Map<String, dynamic> map, String id) {
    return StripeAccountModel(
      accountId: id,
      businessId: map['businessId'] ?? '',
      status: map['status'] ?? StripeConstants.statusPending,
      chargesEnabled: map['chargesEnabled'] ?? false,
      payoutsEnabled: map['payoutsEnabled'] ?? false,
      detailsSubmitted: map['detailsSubmitted'] ?? false,
      requirements: map['requirements'] is Map
          ? Map<String, dynamic>.from(map['requirements'])
          : null,
      capabilities: map['capabilities'] is Map
          ? Map<String, dynamic>.from(map['capabilities'])
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      country: map['country'] ?? 'PK',
      email: map['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'status': status,
      'chargesEnabled': chargesEnabled,
      'payoutsEnabled': payoutsEnabled,
      'detailsSubmitted': detailsSubmitted,
      'requirements': requirements,
      'capabilities': capabilities,
      'country': country,
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ✅ FIXED: Proper status determination based on actual Stripe flags
  bool get isConnected => chargesEnabled && payoutsEnabled;
  bool get isPending => !detailsSubmitted && !chargesEnabled && !payoutsEnabled;
  bool get isRestricted => !chargesEnabled || !payoutsEnabled;
  bool get isDisabled => status == StripeConstants.statusDisabled;

  bool get canAcceptPayments => chargesEnabled;
  bool get canReceivePayouts => payoutsEnabled;
  bool get hasSubmittedDetails => detailsSubmitted;

  // ✅ FIXED: Better status messages
  String getStatusMessage() {
    if (isConnected) return 'Connected ✓';
    if (isRestricted) {
      if (chargesEnabled && !payoutsEnabled) return 'Payouts Disabled';
      if (!chargesEnabled && payoutsEnabled) return 'Payments Disabled';
      return 'Account Restricted';
    }
    if (isPending) return 'Pending Verification';
    return 'Not Connected';
  }

  Color getStatusColor() {
    if (isConnected) return Colors.green;
    if (isPending) return Colors.orange;
    if (isRestricted) return Colors.red;
    return Colors.grey;
  }

  String getRequirementsMessage() {
    if (requirements == null) return 'No pending requirements';
    final currentlyDue = requirements?['currently_due'] as List? ?? [];
    if (currentlyDue.isEmpty) return 'All requirements satisfied';
    return 'Pending: ${currentlyDue.join(', ')}';
  }

  // ✅ Helper to get currently due requirements
  List<String> get currentlyDueRequirements {
    if (requirements == null) return [];
    final due = requirements?['currently_due'] as List? ?? [];
    return due.cast<String>();
  }

  // ✅ Helper to get missing requirements
  List<String> get eventuallyDueRequirements {
    if (requirements == null) return [];
    final due = requirements?['eventually_due'] as List? ?? [];
    return due.cast<String>();
  }

  // ✅ Helper to get past due requirements
  List<String> get pastDueRequirements {
    if (requirements == null) return [];
    final due = requirements?['past_due'] as List? ?? [];
    return due.cast<String>();
  }

  bool get hasPendingRequirements => currentlyDueRequirements.isNotEmpty;
}