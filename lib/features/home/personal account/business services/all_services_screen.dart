import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import '../service details/service_detail_screen.dart';
import 'all_services_controller.dart';

class AllServicesScreen extends StatelessWidget {
  final String businessId;
  final String? businessName;

  const AllServicesScreen({super.key, required this.businessId, this.businessName});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AllServicesController());
    controller.initBusiness(businessId, name: businessName);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final padding = isMobile ? 12.0 : 20.0;

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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'All Services',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeadline,
              ),
            ),
            const SizedBox(height: 4),
            Obx(() {
              final businessNameText = controller.businessName.value.isNotEmpty
                  ? controller.businessName.value
                  : 'Loading...';
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  businessNameText,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPlaceholder,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }),
          ],
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.refreshServices(),
        color: AppColors.primaryPurple,
        child: Obx(() {
          if (controller.isLoading.value && controller.services.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
              ),
            );
          }

          final services = controller.services;

          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.searchOff,
                    size: 64,
                    color: AppColors.textPlaceholder,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No services found',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textBody,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This business has not added any services yet',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.all(padding),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              return _buildServiceGridCard(services[index], controller);
            },
          );
        }),
      ),
    );
  }

  Widget _buildServiceGridCard(ServiceData service, AllServicesController controller) {
    final displayImageUrl = service.imageUrls.isNotEmpty ? service.imageUrls.first : service.imageUrl;

    return GestureDetector(
      onTap: () {
        Get.to(
              () => ServiceDetailScreen(serviceId: service.id),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 300),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Container(
                height: 100,
                width: double.infinity,
                color: AppColors.primaryPurple.withOpacity(0.1),
                child: displayImageUrl.isNotEmpty
                    ? Image.network(
                  displayImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildGridPlaceholder(),
                )
                    : _buildGridPlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    service.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeadline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.description,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textBody,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PKR ${service.price}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      Text(
                        '${service.duration} min',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textPlaceholder,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Book',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridPlaceholder() {
    return Center(
      child: Icon(
        AppIcons.business,
        color: AppColors.primaryPurple.withOpacity(0.5),
        size: 28,
      ),
    );
  }
}