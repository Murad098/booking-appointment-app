// lib/features/home/business account/stripe payment/stripe_payment_intent_model.dart

class StripePaymentIntentModel {
  final String clientSecret;
  final String paymentIntentId;
  final String status;
  final double amount;
  final String currency;
  final String stripeAccountId;
  final bool isDestinationCharge; // ✅ New: indicates if using destination charges

  // ✅ New: Transfer data
  final String? transferId;
  final double? applicationFeeAmount;

  StripePaymentIntentModel({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.status,
    required this.amount,
    required this.currency,
    required this.stripeAccountId,
    this.isDestinationCharge = true,
    this.transferId,
    this.applicationFeeAmount,
  });

  factory StripePaymentIntentModel.fromJson(Map<String, dynamic> json) {
    return StripePaymentIntentModel(
      clientSecret: json['clientSecret'] ?? '',
      paymentIntentId: json['paymentIntentId'] ?? '',
      status: json['status'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'usd',
      stripeAccountId: json['stripeAccountId'] ?? '',
      isDestinationCharge: json['isDestinationCharge'] ?? true,
      transferId: json['transferId'],
      applicationFeeAmount: json['applicationFeeAmount']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientSecret': clientSecret,
      'paymentIntentId': paymentIntentId,
      'status': status,
      'amount': amount,
      'currency': currency,
      'stripeAccountId': stripeAccountId,
      'isDestinationCharge': isDestinationCharge,
      'transferId': transferId,
      'applicationFeeAmount': applicationFeeAmount,
    };
  }

  bool get isSucceeded => status == 'succeeded';
  bool get isProcessing => status == 'processing';
  bool get requiresAction => status == 'requires_action';
  bool get requiresPaymentMethod => status == 'requires_payment_method';
  bool get requiresConfirmation => status == 'requires_confirmation';
  bool get isCanceled => status == 'canceled';
  bool get isFailed => status == 'failed';
}