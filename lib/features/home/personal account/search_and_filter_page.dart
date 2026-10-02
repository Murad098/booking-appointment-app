import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_icons.dart';
import 'business details page/business_detail_screen.dart';
import 'personal_home_controller.dart';

class SearchAndFilteredPageScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;
  final bool isSearchTab;

  const SearchAndFilteredPageScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.isSearchTab = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PersonalHomeController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final double scale = isTablet ? 1.05 : 1.0;
    final double horizontalPadding = isTablet ? 24 : 16;

    if (!isSearchTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.onCategorySelected(categoryId);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: isSearchTab
          ? null
          : AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(AppIcons.arrowLeft, color: AppColors.textHeadline),
          onPressed: () {
            controller.searchQuery.value = '';
            controller.isSearching.value = false;
            Get.back();
          },
        ),
        title: Obx(() {
          final activeCategory = controller.allCategories.firstWhere(
                (c) => c.id == controller.appliedCategoryId.value,
            orElse: () => CategoryData(id: 'all', name: 'All', icon: Icons.apps),
          );
          return Text(
            activeCategory.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeadline,
            ),
          );
        }),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isSearchTab) ...[
                    Text(
                      "Search",
                      style: TextStyle(
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeadline,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Find services near you",
                      style: TextStyle(
                        fontSize: 14 * scale,
                        color: AppColors.textBody,
                      ),
                    ),
                  ] else ...[
                    Obx(() {
                      final activeCategory = controller.allCategories.firstWhere(
                            (c) => c.id == controller.appliedCategoryId.value,
                        orElse: () => CategoryData(id: 'all', name: 'All', icon: Icons.apps),
                      );
                      return Text(
                        activeCategory.id == 'all'
                            ? "All Categories"
                            : "All ${activeCategory.name}",
                        style: TextStyle(
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHeadline,
                          letterSpacing: -0.5,
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                    Obx(() {
                      final activeCategoryId = controller.appliedCategoryId.value;
                      final count = activeCategoryId == 'all'
                          ? controller.allBusinesses.length
                          : controller.allBusinesses.where((b) => b['category'] == activeCategoryId).length;
                      return Text(
                        "$count services available",
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: AppColors.textBody,
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 16),
                  _buildEnhancedSearchBar(
                    context,
                    controller,
                    scale,
                    isSearchTab ? "services" : categoryName,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isSearching.value || isSearchTab) {
                  return _buildSearchResults(controller, scale, horizontalPadding);
                }
                return _buildCategoryList(controller, scale, horizontalPadding);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSearchBar(BuildContext context, PersonalHomeController controller, double scale, String hintCategory) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: TextField(
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: isSearchTab ? "Search services, businesses..." : "Search in $hintCategory...",
                hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
                prefixIcon: Icon(AppIcons.search, color: AppColors.primaryPurple),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => _showFilterSheet(context, controller),
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(AppIcons.filter, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(PersonalHomeController controller, double scale, double horizontalPadding) {
    final activeCategoryId = controller.appliedCategoryId.value;
    final businesses = activeCategoryId == 'all'
        ? controller.allBusinesses
        : controller.allBusinesses.where((b) => b['category'] == activeCategoryId).toList();

    if (businesses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.searchOff, size: 60, color: AppColors.textPlaceholder.withOpacity(0.6)),
              const SizedBox(height: 16),
              Text("No services found", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textBody)),
              const SizedBox(height: 8),
              Text("Check back later for new additions", style: TextStyle(fontSize: 13, color: AppColors.textPlaceholder), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(horizontalPadding),
      itemCount: businesses.length,
      itemBuilder: (context, index) => _buildDetailedCard(businesses[index], scale),
    );
  }

  Widget _buildSearchResults(PersonalHomeController controller, double scale, double horizontalPadding) {
    return Obx(() {
      final activeCategoryId = controller.appliedCategoryId.value;
      final results = activeCategoryId == 'all'
          ? controller.filteredBusinesses
          : controller.filteredBusinesses.where((b) => b['category'] == activeCategoryId).toList();

      if (results.isEmpty && !controller.isLoading.value) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.searchOff, size: 60, color: AppColors.textPlaceholder.withOpacity(0.6)),
                const SizedBox(height: 16),
                Text("No services found", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textBody)),
                const SizedBox(height: 8),
                Text("Try adjusting your search terms", style: TextStyle(fontSize: 13, color: AppColors.textPlaceholder), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }
      return ListView.builder(
        padding: EdgeInsets.all(horizontalPadding),
        itemCount: results.length,
        itemBuilder: (context, index) => _buildDetailedCard(results[index], scale),
      );
    });
  }

  Widget _buildDetailedCard(Map<String, dynamic> business, double scale) {
    final imageUrl = business['profileImage'] ?? '';

    return GestureDetector(
      onTap: () {
        Get.to(
              () => BusinessDetailScreen(businessId: business['id']),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 300),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 80,
                width: 80,
                color: AppColors.primaryPurple.withOpacity(0.1),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderImageLarge(),
                )
                    : _buildPlaceholderImageLarge(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(business['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textHeadline), maxLines: 1, overflow: TextOverflow.ellipsis)),

                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(business['description'] ?? '', maxLines: 2, style: TextStyle(fontSize: 11, color: AppColors.textBody, height: 1.3)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(AppIcons.location, size: 13, color: AppColors.primaryPurple),
                      const SizedBox(width: 3),
                      Expanded(child: Text(business['city'] ?? business['address'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textHeadline), maxLines: 1, overflow: TextOverflow.ellipsis)),
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

  Widget _buildPlaceholderImageLarge() {
    return Container(
      color: AppColors.primaryPurple.withOpacity(0.1),
      child: Center(
        child: Icon(
          AppIcons.businessCenter,
          color: AppColors.primaryPurple,
          size: 30,
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, PersonalHomeController controller) {
    final originalCategoryId = categoryId;
    String selectedCategoryId = controller.appliedCategoryId.value;
    TextEditingController cityController = TextEditingController(text: controller.appliedCityQuery.value);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filters",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHeadline,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(AppIcons.close, size: 18),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Category",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHeadline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.chipBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategoryId,
                        isExpanded: true,
                        icon: Icon(AppIcons.arrowDown),
                        items: controller.allCategories
                            .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedCategoryId = val!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "City",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHeadline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.chipBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: TextField(
                      controller: cityController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Enter city name...",
                        hintStyle: TextStyle(color: AppColors.textPlaceholder),
                        prefixIcon: Icon(AppIcons.location, size: 18),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategoryId = originalCategoryId;
                              cityController.clear();
                            });
                          },
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              "Clear",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textHeadline,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            controller.applyFiltersDirect(
                              categoryId: selectedCategoryId,
                              city: cityController.text,
                            );
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryPurple.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Text(
                              "Apply Filters",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}