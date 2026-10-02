import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import 'booking_controller.dart';
import 'booking_step4_payment_upload.dart';

class BookingStep3Summary extends StatelessWidget {
  const BookingStep3Summary({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();
    final padding = MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(AppIcons.arrowLeft, color: AppColors.textHeadline),
          onPressed: () => Get.back(),
        ),
        title: Column(
          children: [
            Text(
              'Book Appointment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeadline,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Step 3 of 4: Summary',
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

        final isStripeSelected = controller.isSelectedMethodIsStripe;

        return Column(
          children: [
            LinearProgressIndicator(
              value: 0.75,
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
                    _buildServiceCard(controller),
                    const SizedBox(height: 24),
                    _buildBookingSummary(controller),
                    const SizedBox(height: 24),
                    // Only show manual approval notice for non-Stripe methods
                    if (!isStripeSelected)
                      _buildManualApprovalNotice(controller),
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
                  // Use the correct loading observable for Stripe
                  final isLoading = isStripeSelected
                      ? controller.isProcessingStripe.value
                      : controller.isConfirmPaymentLoading.value;

                  return ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                      if (isStripeSelected) {
                        final success = await controller
                            .processStripePaymentDuringCheckout();
                        if (success) {
                          Get.to(() =>
                          const BookingStep4PaymentUpload());
                        }
                      } else {
                        Get.to(
                                () => const BookingStep4PaymentUpload());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
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
                      isStripeSelected
                          ? 'Pay with Stripe (${controller.advancePayment.toStringAsFixed(0)} PKR)'
                          : 'Confirm & Pay PKR ${controller.advancePayment.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
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

  Widget _buildServiceCard(BookingController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              width: 70,
              height: 70,
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeadline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  controller.businessName.value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textBody,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      controller.servicePrice.value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(AppIcons.clock,
                        size: 14, color: AppColors.textPlaceholder),
                    const SizedBox(width: 4),
                    Text(
                      '${controller.serviceDuration.value} min',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPlaceholder,
                      ),
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

  Widget _buildBookingSummary(BookingController controller) {
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
              Icon(
                AppIcons.calendar,
                color: AppColors.primaryPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Booking Summary',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeadline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryRow('Service', controller.serviceName.value),
          const SizedBox(height: 16),
          _buildSummaryRow('Date',
              controller.formatFullDate(controller.selectedDate.value!)),
          const SizedBox(height: 16),
          _buildSummaryRow('Time', controller.selectedTime.value),
          const SizedBox(height: 16),
          _buildSummaryRow(
              'Duration', '${controller.serviceDuration.value} min'),
          const SizedBox(height: 16),
          _buildSummaryRow(
              'Payment Method', controller.selectedPaymentMethod.value),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Paying Now (20%)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBody,
                  ),
                ),
                Obx(() => Text(
                  'PKR ${controller.advancePayment.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryPurple,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textBody,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textHeadline,
          ),
        ),
      ],
    );
  }

  Widget _buildManualApprovalNotice(BookingController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFC107).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFC107),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manual Approval Required',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B5E3C),
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                  'Your booking will be confirmed by ${controller.businessName.value} within 15-20 minutes. You\'ll receive an SMS and email notification once approved.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B5E3C),
                    height: 1.4,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}