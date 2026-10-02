import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'payment_methods_controller.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import '../../../../app/custom_snackbar.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentMethodsController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(AppIcons.arrowLeft, color: AppColors.textHeadline),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Payment Methods',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryPurple,
            ),
          );
        }

        return Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.credit_card_outlined,
                      color: AppColors.primaryPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Methods',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textHeadline,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage your payment methods to receive customer payments.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textBody,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: controller.savedPaymentMethods.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card_off_outlined,
                      size: 80,
                      color: AppColors.textPlaceholder,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Payment Methods Added',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHeadline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the button below to add a payment method',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 0,
                  bottom: 90,
                ),
                itemCount: controller.savedPaymentMethods.length,
                itemBuilder: (context, index) {
                  final method = controller.savedPaymentMethods[index];
                  return _buildPaymentMethodCard(method, index, controller);
                },
              ),
            ),
          ],
        );
      }),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => controller.openSelectMethodModal(),
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: const Text(
                'Add Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(
      Map<String, dynamic> method, int index, PaymentMethodsController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: method['id'] == 'easypaisa'
                        ? const Color(0xFFE8F5E9)
                        : method['id'] == 'jazzcash'
                        ? const Color(0xFFFFEBEE)
                        : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Image.asset(
                      method['id'] == 'easypaisa'
                          ? 'assets/png/easypaisa.png'
                          : method['id'] == 'jazzcash'
                          ? 'assets/png/jazzcash.png'
                          : 'assets/png/bank.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          method['id'] == 'easypaisa'
                              ? Icons.account_balance_wallet
                              : method['id'] == 'jazzcash'
                              ? Icons.phone_android
                              : Icons.account_balance,
                          size: 28,
                          color: method['id'] == 'easypaisa'
                              ? const Color(0xFF4CAF50)
                              : method['id'] == 'jazzcash'
                              ? const Color(0xFFD32F2F)
                              : const Color(0xFF1976D2),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    method['name'] ?? 'Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeadline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          'Title:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textBody,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          method['accountTitle'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHeadline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          'Account:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textBody,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          method['accountNumber'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHeadline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (method['id'] == 'bank') ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Bank:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textBody,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            method['bankName'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHeadline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            'IBAN:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textBody,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            method['iban'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHeadline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ✅ FIXED: Show proper Stripe status
            if (method['id'] == 'stripe') ...[
              const SizedBox(height: 8),
              Obx(() {
                final isFullyEnabled = controller.stripeChargesEnabled.value &&
                    controller.stripePayoutsEnabled.value;

                if (!isFullyEnabled) {
                  String message;
                  IconData icon;
                  Color color;

                  if (controller.stripeChargesEnabled.value && !controller.stripePayoutsEnabled.value) {
                    message = 'Payouts not enabled. Complete setup to receive payouts.';
                    icon = Icons.warning_amber_outlined;
                    color = Colors.orange;
                  } else if (!controller.stripeChargesEnabled.value && controller.stripePayoutsEnabled.value) {
                    message = 'Payments not enabled. Complete setup to accept payments.';
                    icon = Icons.warning_amber_outlined;
                    color = Colors.orange;
                  } else if (controller.pendingRequirements.isNotEmpty) {
                    message = 'Pending: ${controller.pendingRequirements.take(2).join(', ')}${controller.pendingRequirements.length > 2 ? '...' : ''}';
                    icon = Icons.info_outline;
                    color = Colors.blue;
                  } else {
                    message = 'Setup incomplete. Complete your Stripe onboarding.';
                    icon = Icons.warning_amber_outlined;
                    color = Colors.orange;
                  }

                  return Row(
                    children: [
                      Icon(icon, color: color, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(fontSize: 12, color: color),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => controller.resumeStripeOnboarding(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'Complete Setup',
                          style: TextStyle(fontSize: 12, color: AppColors.primaryPurple),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '✓ Accepting payments',
                        style: TextStyle(fontSize: 12, color: Colors.green[700]),
                      ),
                    ],
                  );
                }
              }),
            ],

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => controller.editPaymentMethod(index),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(0, 36),
                    side: BorderSide(color: AppColors.editColor.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: AppColors.editColor.withOpacity(0.05),
                  ),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.editColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _showDeleteConfirmation(controller, index),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(0, 36),
                    side: BorderSide(color: AppColors.deleteColor.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: AppColors.deleteColor.withOpacity(0.05),
                  ),
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deleteColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(PaymentMethodsController controller, int index) {
    final method = controller.savedPaymentMethods[index];
    final isStripe = method['id'] == 'stripe';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Text(
          isStripe ? 'Delete Stripe Payment Method' : 'Delete Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textHeadline,
          ),
        ),
        content: Text(
          isStripe
              ? 'Deleting Stripe will remove it as a payment option. Your Stripe account will be disconnected. You can reconnect later.'
              : 'Are you sure you want to delete ${method['name']}?',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textBody,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textBody,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deletePaymentMethod(index, isStripe: isStripe);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: AppColors.deleteColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Delete',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}