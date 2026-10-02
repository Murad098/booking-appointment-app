import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import 'booking_controller.dart';
import 'booking_step3_summary.dart';

class BookingStep2Payment extends StatelessWidget {
  const BookingStep2Payment({super.key});

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
            const Text(
              'Book Appointment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeadline,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Step 2 of 4: Payment',
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

        return Column(
          children: [
            LinearProgressIndicator(
              value: 0.50,
              backgroundColor: AppColors.grey200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
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
                    _buildAdvancePaymentNotice(controller),
                    const SizedBox(height: 24),
                    _buildPaymentMethods(controller),
                  ],
                ),
              ),
            ),
            if (controller.selectedPaymentMethod.value.isNotEmpty)
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
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isProceedToCheckoutLoading.value
                        ? null
                        : () => controller.goToStep3(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isProceedToCheckoutLoading.value
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'Proceed to Checkout',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )),
                ),
              ),
          ],
        );
      }),
    );
  }

  // ... (rest of the methods remain the same as before)
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
                  ? Image.network(controller.serviceImageUrl.value, fit: BoxFit.cover)
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
                    Icon(AppIcons.clock, size: 14, color: AppColors.textPlaceholder),
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

  Widget _buildAdvancePaymentNotice(BookingController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLightPurple,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.money,
                color: AppColors.primaryPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Advance Payment Required',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeadline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Pay 20% now to confirm your booking. The remaining amount will be paid at the venue.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textBody,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Advance Amount (20%):',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textBody,
                ),
              ),
              Text(
                'PKR ${controller.advancePayment.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryPurple,
                ),
              ),
            ],
          )),
          const SizedBox(height: 4),
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Remaining (80%):',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textBody,
                ),
              ),
              Text(
                'PKR ${controller.remainingPayment.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeadline,
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(BookingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.businessPaymentMethods.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'No payment methods available',
                  style: TextStyle(color: AppColors.textPlaceholder),
                ),
              ),
            );
          }

          return Column(
            children: controller.businessPaymentMethods.map((method) {
              final methodId = method['id'] ?? '';
              final methodName = method['name'] ?? '';
              final isSelected = controller.selectedPaymentMethod.value == methodName;
              String imagePath;

              // Determine icon based on method ID or name
              if (methodId == 'stripe') {
                imagePath = 'assets/png/stripe.png';
              } else if (methodName.toLowerCase().contains('easypaisa')) {
                imagePath = 'assets/png/easypaisa.png';
              } else if (methodName.toLowerCase().contains('jazzcash')) {
                imagePath = 'assets/png/jazzcash.png';
              } else {
                imagePath = 'assets/png/bank.png';
              }

              return GestureDetector(
                onTap: () => controller.selectPaymentMethod(methodName),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryPurple.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryPurple : AppColors.dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryPurple.withOpacity(0.1) : AppColors.grey100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.asset(imagePath, fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          methodName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? AppColors.primaryPurple : AppColors.textHeadline,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: AppColors.primaryPurple, size: 24),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}