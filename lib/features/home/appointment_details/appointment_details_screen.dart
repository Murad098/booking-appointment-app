import 'package:bookify/app/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import 'appointment_details_controller.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  const AppointmentDetailsScreen({super.key});

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => FullScreenImagePage(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppointmentDetailsController());

    // Do NOT call loadAppointment here - controller handles it

    return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          title: const Text('Appointment Details', style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          )),
          backgroundColor: AppColors.scaffoldBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Get.back(),
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryPurple),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading appointment details...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
            );
          }

          // Use data from controller.currentAppointment instead of arguments
          if (controller.currentAppointment == null) {
            return const Center(
              child: Text('No appointment data available'),
            );
          }

          final appointment = controller.currentAppointment!;
          final bool isBusinessView = appointment['isBusinessView'] ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking ID
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Booking ID: #${appointment['id']}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBody,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status Section
                Obx(() =>
                    _buildStatusSection(
                      controller.appointmentStatus.value,
                      controller.statusMessage.value,
                    )),
                const SizedBox(height: 16),

                // Service Details - Use appointment data
                _buildServiceDetails(appointment),
                const SizedBox(height: 16),

                // Payment Info - Use appointment data
                Obx(() =>
                    _buildPaymentInfo(
                      appointment,
                      status: controller.appointmentStatus.value,
                      isCompleted: controller.isCompleted.value,
                    )),
                const SizedBox(height: 16),

                // Payment Screenshot
                Obx(() {
                  final currentStatus = controller.appointmentStatus.value
                      .toLowerCase();
                  final isPendingStatus = currentStatus == 'pending';
                  final isCancelledStatus = currentStatus == 'cancelled';
                  final hasScreenshotUrl = controller.paymentScreenshotUrl.value
                      .isNotEmpty;

                  if ((isPendingStatus || isCancelledStatus) &&
                      hasScreenshotUrl) {
                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildPaymentScreenshot(controller.paymentScreenshotUrl
                            .value, context),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // Dynamic Contact Info Section
                isBusinessView
                    ? _buildContactInfo(
                    appointment,
                    "Customer Information",
                    appointment['customerName'] ?? 'N/A',
                    appointment['customerPhone'] ?? '+92 300 1234567',
                    appointment['customerEmail'] ?? appointment['email'] ??
                        'contact@example.com'
                )
                    : _buildContactInfo(
                    appointment,
                    "Business Information",
                    appointment['businessName'] ?? 'Elite Hair Salon',
                    appointment['businessPhone'] ?? '+92 300 7654321',
                    appointment['businessEmail'] ?? 'support@elitehair.com'
                ),

                const SizedBox(height: 16),

                // --- ACTION BUTTONS SECTION ---
                Obx(() {
                  final status = controller.localStatus.value.toLowerCase();
                  final isPending = status == 'pending';
                  final isConfirmed = status == 'confirmed';
                  final isCancelled = status == 'cancelled';
                  final isUpcoming = controller.isUpcoming.value;
                  final isBusinessUser = controller.userRole.value == 'business';
                  final isRefunded = controller.isRefunded.value;
                  final isRescheduling = controller.isRescheduling.value;

                  // Case 1: Business User seeing a Rescheduling Request
                  if (isBusinessUser && isPending && isRescheduling) {
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                  Icons.schedule, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reschedule Request Pending',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Customer requested: ${controller
                                          .pendingNewDate.value} at ${controller
                                          .pendingNewTime.value}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildOutlineButton(
                                  'Cancel',
                                  Colors.red,
                                      () =>
                                      controller.rejectAppointment(
                                          appointment['id']),
                                  icon: Icons.close
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFilledButton(
                                  'Confirm',
                                  Colors.green,
                                      () =>
                                      controller.confirmReschedule(
                                          appointment['id']),
                                  icon: Icons.check
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  // Case 2: Business User seeing a Pending Request (regular)
                  if (isBusinessUser && isPending && !isRescheduling) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildOutlineButton(
                                  'Cancel',
                                  Colors.red,
                                      () =>
                                      controller.rejectAppointment(
                                          appointment['id']),
                                  icon: Icons.close
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFilledButton(
                                  'Approve',
                                  Colors.green,
                                      () =>
                                      controller.approveAppointment(
                                          appointment['id'])
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  // Case 3: Business User seeing a Confirmed Appointment
                  if (isBusinessUser && isConfirmed &&
                      !controller.isCompleted.value) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildOutlineButton(
                                  'Cancel',
                                  Colors.red,
                                      () =>
                                      controller.rejectAppointment(
                                          appointment['id']),
                                  icon: Icons.close
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFilledButton(
                                  'Complete',
                                  Colors.blue,
                                      () =>
                                      controller.markAsCompleted(
                                          appointment['id']),
                                  icon: Icons.check_circle
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: _buildOutlineButton(
                              'Reschedule',
                              AppColors.primaryPurple,
                                  () => controller.directReschedule(appointment),
                              icon: AppIcons.calendar
                          ),
                        ),
                      ],
                    );
                  }

                  // Case 4: Personal User seeing a Confirmed Appointment
                  if (!isBusinessUser && isUpcoming && isConfirmed) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildOutlineButton(
                              'Reschedule',
                              AppColors.primaryPurple,
                                  () => controller.requestReschedule(appointment),
                              icon: AppIcons.calendar
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOutlineButton(
                              'Cancel',
                              Colors.red,
                                  () =>
                                  controller.cancelAppointment(appointment['id']),
                              icon: Icons.close
                          ),
                        ),
                      ],
                    );
                  }

                  // Case 5: Personal User seeing a Pending Appointment with Rescheduling flag
                  if (!isBusinessUser && isPending && isRescheduling) {
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                  Icons.schedule, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reschedule Request Pending',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Requested: ${controller.pendingNewDate
                                          .value} at ${controller.pendingNewTime
                                          .value}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: _buildOutlineButton(
                              'Cancel',
                              Colors.red,
                                  () =>
                                  controller.cancelAppointment(appointment['id']),
                              icon: Icons.close
                          ),
                        ),
                      ],
                    );
                  }

                  // Case 6: Personal User seeing Pending (regular)
                  if (!isBusinessUser && isPending && !isRescheduling) {
                    return SizedBox(
                      width: double.infinity,
                      child: _buildOutlineButton(
                          'Withdraw Request',
                          Colors.red,
                              () =>
                              controller.cancelAppointment(appointment['id']),
                          icon: Icons.close
                      ),
                    );
                  }

                  // Case 7: Business User seeing Cancelled appointment
                  if (isBusinessUser && isCancelled && !isRefunded) {
                    return SizedBox(
                      width: double.infinity,
                      child: _buildFilledButton(
                          'Mark Refunded',
                          Colors.orange,
                              () => controller.markAsRefunded(appointment['id']),
                          icon: Icons.receipt
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                }),

                // Add spacing only if buttons are present
                Obx(() {
                  final status = controller.localStatus.value.toLowerCase();
                  final isPending = status == 'pending';
                  final isConfirmed = status == 'confirmed';
                  final isCancelled = status == 'cancelled';
                  final isUpcoming = controller.isUpcoming.value;
                  final isBusinessUser = controller.userRole.value == 'business';
                  final isRefunded = controller.isRefunded.value;

                  bool hasButtons = false;
                  if (isBusinessUser && isPending) hasButtons = true;
                  if (isBusinessUser && isConfirmed &&
                      !controller.isCompleted.value) hasButtons = true;
                  if (!isBusinessUser && isUpcoming && isConfirmed)
                    hasButtons = true;
                  if (!isBusinessUser && isPending) hasButtons = true;
                  if (isBusinessUser && isCancelled && !isRefunded)
                    hasButtons = true;

                  return hasButtons ? const SizedBox(height: 16) : const SizedBox
                      .shrink();
                }),

                // --- CONTACT / SUPPORT BUTTON --- (Updated to open chat)
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      // Open chat with the relevant person
                      controller.openChatWithPerson();
                    },
                    icon: const Icon(
                        Icons.chat_bubble_outline, color: Colors.white),
                    label: Text(
                      isBusinessView
                          ? 'Contact ${appointment['customerName'] ?? 'Customer'}'
                          : 'Contact ${appointment['businessName'] ?? 'Business'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        })
    );
  }

  Widget _buildPaymentScreenshot(String imageUrl, BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, imageUrl),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: AppColors.primaryPurple, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Payment Screenshot',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeadline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Failed to load image'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Tap to view full screen',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPlaceholder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildContactInfo(Map<String, dynamic> appointment, String title, String name, String phone, String email) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactRow(
            AppIcons.drawerProfile,
            title.contains("Customer") ? 'Customer Name' : 'Business Name',
            name,
            AppColors.primaryPurple,
          ),
          const SizedBox(height: 12),
          _buildContactRow(
            AppIcons.phone,
            'Phone',
            phone,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildContactRow(
            AppIcons.email,
            'Email',
            email,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineButton(String label, Color color, VoidCallback onTap, {IconData icon = Icons.close}) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 20),
        label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 16)),
      ),
    );
  }

  Widget _buildFilledButton(String label, Color color, VoidCallback onTap, {IconData icon = Icons.check}) {
    return Container(
      height: 52,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
      ),
    );
  }

  Widget _buildStatusSection(String status, String message) {
    Color statusColor;
    IconData statusIcon;
    String displayStatus = status;

    final isAutoCancelled = Get.find<AppointmentDetailsController>().isAutoCancelled.value;
    final isRescheduling = Get.find<AppointmentDetailsController>().isRescheduling.value;

    switch (status.toLowerCase()) {
      case 'pending':
        if (isRescheduling) {
          statusColor = Colors.orange;
          statusIcon = Icons.schedule;
          displayStatus = 'Rescheduling';
        } else {
          statusColor = Colors.orange;
          statusIcon = AppIcons.clock;
          displayStatus = 'Pending';
        }
        break;
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        displayStatus = 'Completed ✓';
        break;
      case 'cancelled':
        if (isAutoCancelled) {
          statusColor = Colors.orange.shade700;
          statusIcon = Icons.timer_off_outlined;
          displayStatus = 'Auto-Cancelled';
        } else {
          statusColor = Colors.red;
          statusIcon = AppIcons.close;
          displayStatus = 'Cancelled';
        }
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, size: 32, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayStatus.capitalize!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: statusColor.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetails(Map<String, dynamic> appointment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AppIcons.cut,
                  color: AppColors.primaryPurple,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment['services'] ?? appointment['serviceName'] ?? 'Service',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeadline,
                      ),
                    ),
                    Text(
                      appointment['businessName'] ?? 'Elite Hair Salon',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(AppIcons.calendar, 'Date', _formatDate(appointment['date'] ?? '')),
          const SizedBox(height: 12),
          _buildDetailRow(
            AppIcons.clock,
            'Time & Duration',
            '${appointment['time'] ?? ''} (${appointment['duration'] ?? appointment['serviceDuration'] ?? '0'} minutes)',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.attach_money,
            'Total Price',
            'PKR ${appointment['price'] ?? 0}',
            isPrice: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(Map<String, dynamic> appointment,
      {required String status, required bool isCompleted}) {
    final advancePaid = (appointment['advancePaid'] ?? 0).toDouble();
    final totalPrice = (appointment['price'] ?? 0).toDouble();
    final remaining = totalPrice - advancePaid;
    final advancePercentage = totalPrice > 0 ? ((advancePaid / totalPrice) * 100).toInt() : 0;
    final remainingPercentage = 100 - advancePercentage;
    final isCancelled = status.toLowerCase() == 'cancelled';
    final isRefunded = appointment['refunded'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentRow('Payment Method', appointment['paymentMethod'] ?? 'Credit Card'),
          const SizedBox(height: 12),
          _buildPaymentRow(
            'Advance Paid ($advancePercentage%)',
            'PKR $advancePaid',
            isGreen: true,
          ),
          const SizedBox(height: 12),

          if (isCompleted) ...[
            _buildPaymentRow(
              'Remaining Balance ($remainingPercentage%)',
              'PKR $remaining ✓ Paid',
              isGreen: true,
            ),
          ] else if (isCancelled) ...[
            _buildRefundStatusRow(isRefunded),
          ] else ...[
            _buildPaymentRow(
              'Remaining ($remainingPercentage%)',
              'PKR $remaining',
            ),
          ],

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withOpacity(0.05)
                  : isCancelled
                  ? Colors.red.withOpacity(0.05)
                  : AppColors.primaryPurple.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : isCancelled
                      ? Icons.info_outline
                      : Icons.payment,
                  size: 18,
                  color: isCompleted
                      ? Colors.green
                      : isCancelled
                      ? Colors.red
                      : AppColors.primaryPurple,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCompleted
                        ? 'Full payment has been received!'
                        : isCancelled
                        ? isRefunded
                        ? 'Refund has been processed to your original payment method.'
                        : 'Refund is being processed. Please allow 3-5 business days.'
                        : 'Pay the remaining amount at the venue after your services',
                    style: TextStyle(
                      fontSize: 13,
                      color: isCompleted
                          ? Colors.green
                          : isCancelled
                          ? Colors.red
                          : AppColors.primaryPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundStatusRow(bool isRefunded) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Refund Status',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textBody,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isRefunded ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRefunded ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRefunded ? Icons.check_circle : Icons.pending,
                size: 14,
                color: isRefunded ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                isRefunded ? 'Refunded' : 'Pending',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isRefunded ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isPrice = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textBody),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: AppColors.textBody),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isPrice ? FontWeight.w700 : FontWeight.w500,
              color: isPrice ? AppColors.primaryPurple : AppColors.textHeadline,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isGreen = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: AppColors.textBody),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isGreen ? Colors.green : AppColors.textHeadline,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textBody,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeadline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Not specified';
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      const days = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
      ];
      return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

// Full Screen Image Page
class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          InteractiveViewer(
            minScale: 1.0,
            maxScale: 6.0,
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}