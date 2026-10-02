import 'package:bookify/features/home/book%20appointment/booking_step3_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import '../../../../app/custom_snackbar.dart';
import 'booking_controller.dart';

class BookingStep4PaymentUpload extends StatelessWidget {
  const BookingStep4PaymentUpload({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final padding = screenWidth < 600 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(AppIcons.arrowLeft, color: AppColors.textHeadline),
          // Prevent going back after Stripe payment succeeds
          onPressed: controller.stripePaymentSuccess.value
              ? null
              : () => Get.back(),
        ),
        title: Column(
          children: const [
            Text(
              'Book Appointment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeadline,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Step 4 of 4: Payment Details',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPlaceholder,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final hasService = controller.serviceName.value.isNotEmpty;
        final hasBusiness = controller.businessName.value.isNotEmpty;

        if (!hasService || !hasBusiness) {
          return const Center(child: CircularProgressIndicator());
        }

        // Stripe flow: payment method contains 'stripe' AND payment succeeded
        final isStripe = controller.isSelectedMethodIsStripe &&
            controller.stripePaymentSuccess.value;

        return Column(
          children: [
            LinearProgressIndicator(
              value: 1.0,
              backgroundColor: AppColors.grey200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryPurple),
              minHeight: 4,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildServiceCard(controller, isSmallScreen),
                    const SizedBox(height: 24),
                    if (isStripe)
                      _buildStripeSuccessCard(controller)
                    else
                      _buildPaymentDetails(controller, isSmallScreen),
                    if (!isStripe) ...[
                      const SizedBox(height: 24),
                      _buildUploadSection(controller),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(() {
                  final canConfirm = isStripe ||
                      controller.paymentScreenshot.value != null;
                  final isLoading =
                      controller.isConfirmPaymentLoading.value;

                  return ElevatedButton(
                    onPressed: (canConfirm && !isLoading)
                        ? () async {
                      if (isStripe) {
                        await controller.saveStripeBooking();
                      } else {
                        await controller.confirmBooking();
                      }
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canConfirm
                          ? AppColors.primaryPurple
                          : AppColors.grey300,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    )
                        : Text(
                      isStripe
                          ? 'Confirm Booking'
                          : 'Confirm Payment',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildServiceCard(BookingController controller, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: isSmallScreen ? 50 : 70,
              height: isSmallScreen ? 50 : 70,
              color: AppColors.primaryPurple.withOpacity(0.1),
              child: controller.serviceImageUrl.value.isNotEmpty
                  ? Image.network(controller.serviceImageUrl.value,
                  fit: BoxFit.cover)
                  : Icon(AppIcons.business, color: AppColors.primaryPurple),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.serviceName.value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeadline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  controller.businessName.value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 13,
                    color: AppColors.textBody,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      controller.servicePrice.value,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.clock,
                            size: isSmallScreen ? 12 : 14,
                            color: AppColors.textPlaceholder),
                        const SizedBox(width: 4),
                        Text(
                          '${controller.serviceDuration.value} min',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: AppColors.textPlaceholder,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStripeSuccessCard(BookingController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.statusSuccess.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statusSuccess, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.statusSuccess.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.statusSuccess,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Paid with Stripe',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.statusSuccess,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Text(
            'PKR ${controller.advancePayment.toStringAsFixed(0)} charged successfully',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textBody,
            ),
          )),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildConfirmRow(
                    Icons.event_available, 'Date',
                    controller.selectedDate.value != null
                        ? controller.formatFullDate(controller.selectedDate.value!)
                        : ''),
                const Divider(height: 20),
                _buildConfirmRow(
                    Icons.access_time, 'Time', controller.selectedTime.value),
                const Divider(height: 20),
                _buildConfirmRow(
                    Icons.design_services_rounded,
                    'Service',
                    controller.serviceName.value),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap "Confirm Booking" below to finalize your appointment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPlaceholder,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryPurple),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textBody)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textHeadline)),
      ],
    );
  }

  Widget _buildPaymentDetails(
      BookingController controller, bool isSmallScreen) {
    final selectedMethod = controller.businessPaymentMethods.firstWhere(
          (method) => method['name'] == controller.selectedPaymentMethod.value,
      orElse: () => {},
    );

    String bankName = controller.selectedPaymentMethod.value;
    if (selectedMethod.isNotEmpty) {
      if (selectedMethod['bankName'] != null &&
          selectedMethod['bankName'].isNotEmpty) {
        bankName = selectedMethod['bankName'];
      } else if (selectedMethod['name'] != null) {
        bankName = selectedMethod['name'];
      }
    }

    final String accountNumber = selectedMethod['accountNumber'] ?? 'N/A';
    final String accountTitle =
        selectedMethod['accountTitle'] ?? controller.businessName.value;
    final String? iban = selectedMethod['iban'];

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.money, color: AppColors.primaryPurple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Payment Details',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeadline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRowWithCopy(
              label: 'Bank Name',
              value: bankName,
              showCopy: false,
              isSmallScreen: isSmallScreen),
          const SizedBox(height: 12),
          _buildDetailRowWithCopy(
            label: 'Account Number',
            value: accountNumber,
            showCopy: true,
            onCopy: () {
              Clipboard.setData(ClipboardData(text: accountNumber));
              AppSnackbar.success('Account number copied to clipboard!');
            },
            isSmallScreen: isSmallScreen,
          ),
          const SizedBox(height: 12),
          _buildDetailRowWithCopy(
              label: 'Account Holder',
              value: accountTitle,
              showCopy: false,
              isSmallScreen: isSmallScreen),
          if (iban != null && iban.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRowWithCopy(
              label: 'IBAN',
              value: iban,
              showCopy: true,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: iban));
                AppSnackbar.success('IBAN copied to clipboard!');
              },
              isSmallScreen: isSmallScreen,
            ),
          ],
          const SizedBox(height: 12),
          Obx(() => _buildDetailRowWithCopy(
            label: 'Amount to Pay',
            value:
            'PKR ${controller.advancePayment.toStringAsFixed(0)}',
            valueColor: AppColors.primaryPurple,
            valueWeight: FontWeight.w700,
            showCopy: false,
            isSmallScreen: isSmallScreen,
          )),
          const SizedBox(height: 16),
          Divider(color: AppColors.dividerColor),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLightPurple,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline,
                    color: AppColors.primaryPurple, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please transfer the exact amount and upload the payment screenshot below.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textBody, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithCopy({
    required String label,
    required String value,
    bool showCopy = false,
    VoidCallback? onCopy,
    Color? valueColor,
    FontWeight? valueWeight,
    required bool isSmallScreen,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isSmallScreen ? 90 : 100,
          child: Text(label,
              style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: AppColors.textBody)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: valueWeight ?? FontWeight.w600,
                    color: valueColor ?? AppColors.textHeadline,
                  ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
              if (showCopy) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCopy,
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.copy,
                        size: isSmallScreen ? 14 : 16,
                        color: AppColors.primaryPurple),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadSection(BookingController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.info, color: AppColors.primaryPurple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Upload Payment Proof',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeadline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() => GestureDetector(
            onTap: () => controller.pickPaymentScreenshot(),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: controller.paymentScreenshot.value != null
                      ? AppColors.primaryPurple
                      : AppColors.dividerColor,
                  width: 2,
                ),
              ),
              child: controller.paymentScreenshot.value != null
                  ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      controller.paymentScreenshot.value!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.statusSuccess,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.add,
                      size: 40, color: AppColors.primaryPurple),
                  const SizedBox(height: 8),
                  const Text('Tap to upload screenshot',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textBody)),
                  const SizedBox(height: 4),
                  const Text('JPG, PNG up to 5MB',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPlaceholder)),
                ],
              ),
            ),
          )),
          const SizedBox(height: 12),
          const Text(
            '* Payment screenshot is required to confirm your booking',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPlaceholder,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}