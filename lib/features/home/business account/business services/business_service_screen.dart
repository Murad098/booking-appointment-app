import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import '../payment method/payment_methods_screen.dart';
import 'business_service_controller.dart';

class BusinessServicesScreen extends StatelessWidget {
  final bool showAppBar;

  const BusinessServicesScreen({super.key, this.showAppBar = false});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BusinessServiceController());
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final padding = isMobile ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: showAppBar
          ? AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(AppIcons.arrowLeft, color: AppColors.textHeadline),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Business Services',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
        centerTitle: false,
      )
          : null,
      bottomNavigationBar: _buildAddServiceButton(padding, controller),
      body: SafeArea(
        top: !showAppBar,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryPurple,
              ),
            );
          }

          if (controller.services.isEmpty) {
            return _buildEmptyState(controller);
          }

          // Services exist -> show list with warning banner if no payment methods
          return Column(
            children: [
              if (!controller.hasPaymentMethods.value)
                _buildPaymentMethodWarning(controller),
              Expanded(
                child: _buildServiceList(controller, padding),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(BusinessServiceController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.textPlaceholder,
          ),
          const SizedBox(height: 16),
          Text(
            'No Services Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add your first service',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textBody,
            ),
          ),
          // Optional: hint about payment method
          if (!controller.hasPaymentMethods.value) ...[
            const SizedBox(height: 12),
            Text(
              'You need to add a payment method first.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // NEW: Warning banner when no payment methods
  Widget _buildPaymentMethodWarning(BusinessServiceController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontSize: 13,
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: 'No booking can proceed until you add a '),
                  TextSpan(
                    text: 'payment method',
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await Get.to(() => PaymentMethodsScreen());
                        await controller.checkPaymentMethods(); // refresh after return
                      },
                  ),
                  TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddServiceButton(double padding, BusinessServiceController controller) {
    return Container(
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
      child: SafeArea(
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextButton(
            onPressed: () => controller.showAddService(), // updated method
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.add, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Add New Service',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceList(BusinessServiceController controller, double padding) {
    return ListView.separated(
      padding: EdgeInsets.only(
        top: padding,
        left: padding,
        right: padding,
        bottom: 80,
      ),
      itemCount: controller.services.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final service = controller.services[index];
        return _buildServiceCard(service, controller);
      },
    );
  }

  // Helper to format duration
  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes > 0) {
        return '${hours}h ${remainingMinutes}m';
      } else {
        return '${hours}h';
      }
    }
    return '${minutes}m';
  }

  Widget _buildServiceCard(Service service, BusinessServiceController controller) {
    // Get the first image URL from the list
    final String displayImageUrl = service.imageUrls != null && service.imageUrls!.isNotEmpty
        ? service.imageUrls!.first
        : (service.imageUrl ?? '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Service Image with Category Overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: SizedBox(
                  width: 120,
                  height: 160,
                  child: displayImageUrl.isNotEmpty
                      ? Image.network(
                    displayImageUrl,
                    width: 120,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 160,
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        child: const Icon(
                          Icons.image_outlined,
                          size: 40,
                        ),
                      );
                    },
                  )
                      : Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryPurple.withOpacity(0.2),
                          AppColors.primaryPurple.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      size: 40,
                    ),
                  ),
                ),
              ),
              // Category Chip Overlay on Image (Bottom Left - Very Small)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    service.category,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),

          // Right side - Service Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Name
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeadline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Service Description (Limited to 2 lines)
                  Text(
                    service.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textBody,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Price and Duration (Using Wrap for responsiveness)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Price Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(AppIcons.money, size: 14, color: AppColors.primaryPurple),
                            const SizedBox(width: 4),
                            Text(
                              'PKR ${service.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Duration Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGrey50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(AppIcons.clock, size: 14, color: AppColors.iconMuted),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(service.duration),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textHeadline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Edit and Delete Buttons (Horizontal with text)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Edit Button
                      GestureDetector(
                        onTap: () => controller.showEditService(service),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.editColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.editColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, size: 14, color: AppColors.editColor),
                              const SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.editColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Delete Button
                      GestureDetector(
                        onTap: () => _showDeleteConfirmation(controller, service.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.deleteColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.deleteColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline, size: 14, color: AppColors.deleteColor),
                              const SizedBox(width: 4),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.deleteColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BusinessServiceController controller, String serviceId) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Service',
          style: TextStyle(color: AppColors.textHeadline),
        ),
        content: Text(
          'Are you sure you want to delete this service?',
          style: TextStyle(color: AppColors.textBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: AppColors.textBody)),
          ),
          TextButton(
            onPressed: () {
              controller.deleteService(serviceId);
              Get.back();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.deleteColor),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}