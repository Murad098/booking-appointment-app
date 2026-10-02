// lib/core/models/stripe_transaction_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class StripeTransactionModel {
  final String transactionId;
  final String bookingId;
  final String businessId;
  final String customerId;
  final String paymentIntentId;
  final double amount;
  final double platformFee;
  final double businessAmount;
  final String status;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime? completedAt;

  StripeTransactionModel({
    required this.transactionId,
    required this.bookingId,
    required this.businessId,
    required this.customerId,
    required this.paymentIntentId,
    required this.amount,
    required this.platformFee,
    required this.businessAmount,
    required this.status,
    this.failureReason,
    required this.createdAt,
    this.completedAt,
  });

  factory StripeTransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return StripeTransactionModel(
      transactionId: id,
      bookingId: map['bookingId'] ?? '',
      businessId: map['businessId'] ?? '',
      customerId: map['customerId'] ?? '',
      paymentIntentId: map['paymentIntentId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      platformFee: (map['platformFee'] ?? 0).toDouble(),
      businessAmount: (map['businessAmount'] ?? 0).toDouble(),
      status: map['status'] ?? '',
      failureReason: map['failureReason'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'businessId': businessId,
      'customerId': customerId,
      'paymentIntentId': paymentIntentId,
      'amount': amount,
      'platformFee': platformFee,
      'businessAmount': businessAmount,
      'status': status,
      'failureReason': failureReason,
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isRefunded => status == 'refunded';
  bool get isPending => status == 'pending';
}