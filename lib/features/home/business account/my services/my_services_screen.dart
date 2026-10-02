import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import '../business services/business_service_controller.dart';
import 'my_services_controller.dart';

class MyServicesScreen extends StatelessWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MyServicesController controller = Get.put(MyServicesController());

    final BusinessServiceController businessController = Get.isRegistered<BusinessServiceController>()
        ? Get.find<BusinessServiceController>()
        : Get.put(BusinessServiceController());

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final padding = isMobile ? 16.0 : 24.0;

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
          'My Services',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(AppIcons.add, color: AppColors.primaryPurple),
            onPressed: () async {
              businessController.showAddService();
              await Future.delayed(const Duration(milliseconds: 500));
              await controller.refreshServices();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.refreshServices(),
        color: AppColors.primaryPurple,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage your offered services',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPlaceholder,
                ),
              ),
              const SizedBox(height: 16),

              Obx(() {
                if (controller.isLoading.value) {
                  return const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                      ),
                    ),
                  );
                }

                if (controller.myServices.isEmpty) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            AppIcons.business,
                            size: 60,
                            color: AppColors.textPlaceholder.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No services found',
                            style: TextStyle(
                              color: AppColors.textPlaceholder,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button to add your first service',
                            style: TextStyle(
                              color: AppColors.textBody,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: controller.myServices.length,
                    itemBuilder: (context, index) {
                      final service = controller.myServices[index];
                      return _buildServiceCard(service, controller, businessController);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(
      ServiceData service,
      MyServicesController controller,
      BusinessServiceController businessController,
      ) {
    // Get the first image URL from the list
    final String displayImageUrl = service.imageUrls != null && service.imageUrls!.isNotEmpty
        ? service.imageUrls!.first
        : (service.imageUrl ?? '');

    return GestureDetector(
      onTap: () => controller.onServiceTap(service),
      child: Container(
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 100,
                width: double.infinity,
                color: AppColors.primaryPurple.withOpacity(0.1),
                child: displayImageUrl.isNotEmpty
                    ? Image.network(
                  displayImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        AppIcons.business,
                        color: AppColors.primaryPurple,
                        size: 30,
                      ),
                    );
                  },
                )
                    : Center(
                  child: Icon(
                    AppIcons.business,
                    color: AppColors.primaryPurple,
                    size: 30,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeadline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      service.category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PKR ${service.price}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHeadline,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            AppIcons.clock,
                            size: 12,
                            color: AppColors.textPlaceholder,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${service.duration} min',
                            style: TextStyle(
                              fontSize: 10,
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
      ),
    );
  }
}