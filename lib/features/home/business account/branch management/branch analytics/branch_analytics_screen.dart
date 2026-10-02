// lib/features/home/business account/branch management/branch_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../app/app_colors.dart';
import '../../../../../app/app_icons.dart';
import '../../business analytics/business_analytics_controller.dart';
import 'branch_analytics_controller.dart'; // for data models

class BranchAnalyticsScreen extends StatelessWidget {
  final String branchId;
  const BranchAnalyticsScreen({super.key, required this.branchId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BranchAnalyticsController(branchId));
    final screenWidth = MediaQuery.of(context).size.width;

    final isVerySmall = screenWidth < 340;
    final isSmall = screenWidth < 600;
    final isMobile = screenWidth < 768;

    final padding = isMobile ? 12.0 : 20.0;
    final scale = isVerySmall ? 0.85 : isSmall ? 0.92 : 1.0;
    final spacing = 16.0 * scale;

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
          'Branch Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
        centerTitle: false,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primaryPurple),
                const SizedBox(height: 16),
                Text(
                  'Loading analytics data...',
                  style: TextStyle(color: AppColors.textBody),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodSelector(controller, scale),
                SizedBox(height: spacing),
                _buildStatsGrid(controller, scale, spacing),
                SizedBox(height: spacing),
                _buildRevenueTrend(scale, spacing),
                SizedBox(height: spacing),
                if (controller.topServices.isNotEmpty) ...[
                  _buildTopServices(scale, spacing),
                  SizedBox(height: spacing),
                ],
                if (controller.bookingStatus.isNotEmpty) ...[
                  _buildBookingStatus(scale, spacing),
                  SizedBox(height: spacing),
                ],
                _buildPeakHours(scale, spacing),
                SizedBox(height: spacing),
                _buildCustomerInsights(scale, spacing),
              ],
            ),
          ),
        );
      }),
    );
  }

  // All helper methods are identical to BusinessAnalyticsScreen, but using BranchAnalyticsController.
  // We'll copy them exactly, replacing controller type.
  Widget _buildPeriodSelector(BranchAnalyticsController controller, double scale) {
    final periods = ['Last 7 Days', 'Last 30 Days', 'Last 365 Days'];
    return Container(
      padding: EdgeInsets.all(4 * scale),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Row(
        children: periods.map((period) {
          return Expanded(
            child: Obx(() {
              final isSelected = controller.selectedPeriod.value == period;
              return GestureDetector(
                onTap: () => controller.changePeriod(period),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10 * scale),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryPurple : Colors.transparent,
                    borderRadius: BorderRadius.circular(10 * scale),
                  ),
                  child: Text(
                    period,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11 * scale,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.grey700,
                    ),
                  ),
                ),
              );
            }),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsGrid(BranchAnalyticsController controller, double scale, double spacing) {
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    int crossAxisCount = screenWidth < 400 ? 2 : (screenWidth < 900 ? 2 : 4);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: screenWidth < 600 ? 1.2 : 2.4,
      children: [
        _buildStatCard(
          icon: AppIcons.money,
          label: 'Revenue',
          value: controller.formatRevenue(controller.totalRevenue.value),
          percentage: controller.getRevenuePercentage(),
          iconColor: AppColors.statusSuccess,
          iconBgColor: AppColors.iconBgGreen,
          scale: scale,
        ),
        _buildStatCard(
          icon: AppIcons.eventNote,
          label: 'Bookings',
          value: controller.totalBookings.value.toString(),
          percentage: controller.getBookingsPercentage(),
          iconColor: AppColors.primaryPurple,
          iconBgColor: AppColors.iconBgPurple,
          scale: scale,
        ),
        _buildStatCard(
          icon: AppIcons.people,
          label: 'New Customers',
          value: controller.newCustomers.value.toString(),
          percentage: controller.getCustomersPercentage(),
          iconColor: AppColors.primaryPurple,
          iconBgColor: AppColors.iconBgLightPurple,
          scale: scale,
        ),
        _buildStatCard(
          icon: AppIcons.star,
          label: 'Avg. Rating',
          value: controller.averageRating.value > 0 ? controller.averageRating.value.toStringAsFixed(1) : '0.0',
          percentage: controller.getRatingChange(),
          iconColor: AppColors.amber,
          iconBgColor: AppColors.iconBgAmber,
          scale: scale,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String percentage,
    required Color iconColor,
    required Color iconBgColor,
    required double scale,
  }) {
    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8 * scale),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
                child: Icon(icon, color: iconColor, size: 22 * scale),
              ),
              SizedBox(width: 10 * scale),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13 * scale,
                  color: AppColors.grey700,
                ),
              ),
            ],
          ),
          SizedBox(height: 10 * scale),
          Text(
            value,
            style: TextStyle(
              fontSize: 22 * scale,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnCard,
            ),
          ),
          SizedBox(height: 4 * scale),
          Row(
            children: [
              Icon(
                AppIcons.trendingUp,
                size: 12 * scale,
                color: AppColors.statusSuccess,
              ),
              SizedBox(width: 4 * scale),
              Text(
                percentage,
                style: TextStyle(
                  fontSize: 11 * scale,
                  color: AppColors.statusSuccess,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4 * scale),
              Text(
                'vs last period',
                style: TextStyle(
                  fontSize: 11 * scale,
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTrend(double scale, double spacing) {
    final controller = Get.find<BranchAnalyticsController>();
    final maxRevenue = controller.revenueTrend.isEmpty ? 1 : controller.revenueTrend.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
            'Revenue Trend',
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnCard,
            ),
          ),
          SizedBox(height: 16 * scale),
          Obx(() => Column(
            children: controller.revenueTrend.map((day) =>
                _buildRevenueBar(day, maxRevenue, scale, spacing)
            ).toList(),
          )),
        ],
      ),
    );
  }

  Widget _buildRevenueBar(RevenueData day, int maxRevenue, double scale, double spacing) {
    final widthPercentage = maxRevenue > 0 ? day.amount / maxRevenue : 0;
    final formattedAmount = day.amount < 1000 ? 'PKR ${day.amount}' : 'PKR ${(day.amount / 1000).toStringAsFixed(day.amount % 1000 == 0 ? 0 : 1)}K';
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * scale),
      child: Row(
        children: [
          SizedBox(
            width: 40 * scale,
            child: Text(
              day.day,
              style: TextStyle(
                fontSize: 13 * scale,
                color: AppColors.grey700,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final containerWidth = constraints.maxWidth;
                final barWidth = containerWidth * widthPercentage;
                return Stack(
                  children: [
                    Container(
                      height: 40 * scale,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                    ),
                    Container(
                      height: 40 * scale,
                      width: barWidth,
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                    ),
                    if (day.amount > 0)
                      Positioned(
                        left: barWidth > 60 * scale ? barWidth - 60 * scale : barWidth,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            formattedAmount,
                            style: TextStyle(
                              fontSize: 12 * scale,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopServices(double scale, double spacing) {
    final controller = Get.find<BranchAnalyticsController>();
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
            'Top Services',
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnCard,
            ),
          ),
          SizedBox(height: 16 * scale),
          Obx(() => Column(
            children: controller.topServices.take(4).map((service) =>
                _buildServiceItem(service, scale, spacing)
            ).toList(),
          )),
        ],
      ),
    );
  }

  Widget _buildServiceItem(TopService service, double scale, double spacing) {
    final index = Get.find<BranchAnalyticsController>().topServices.indexOf(service) + 1;
    final formattedRevenue = service.revenue < 1000 ? 'PKR ${service.revenue}' : 'PKR ${(service.revenue / 1000).toStringAsFixed(service.revenue % 1000 == 0 ? 0 : 1)}K';
    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
      child: Row(
        children: [
          Container(
            width: 32 * scale,
            height: 32 * scale,
            decoration: BoxDecoration(
              color: AppColors.iconBgPurple,
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: Center(
              child: Text(
                '#$index',
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: TextStyle(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnCard,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4 * scale),
                Text(
                  '${service.bookings} bookings',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedRevenue,
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnCard,
                ),
              ),
              SizedBox(height: 4 * scale),
              Text(
                'revenue',
                style: TextStyle(
                  fontSize: 11 * scale,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingStatus(double scale, double spacing) {
    final controller = Get.find<BranchAnalyticsController>();
    Color getStatusColor(String label) {
      switch (label.toLowerCase()) {
        case 'completed': return AppColors.statusSuccess;
        case 'confirmed': return AppColors.primaryPurple;
        case 'cancelled': return AppColors.statusError;
        default: return AppColors.grey500;
      }
    }
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
            'Booking Status',
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnCard,
            ),
          ),
          SizedBox(height: 16 * scale),
          Obx(() => Column(
            children: controller.bookingStatus.map((status) =>
                Padding(
                  padding: EdgeInsets.only(bottom: 16 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            status.label,
                            style: TextStyle(
                              fontSize: 14 * scale,
                              color: AppColors.grey700,
                            ),
                          ),
                          Text(
                            '${status.count} (${status.percentage}%)',
                            style: TextStyle(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textOnCard,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8 * scale),
                      Container(
                        height: 6 * scale,
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                          borderRadius: BorderRadius.circular(3 * scale),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: (MediaQuery.of(Get.context!).size.width - (32 * scale * 2)) * (status.percentage / 100),
                              decoration: BoxDecoration(
                                color: getStatusColor(status.label),
                                borderRadius: BorderRadius.circular(3 * scale),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ).toList(),
          )),
        ],
      ),
    );
  }

  Widget _buildPeakHours(double scale, double spacing) {
    final controller = Get.find<BranchAnalyticsController>();
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    final isSmall = screenWidth < 360;
    final cardWidth = isSmall ? (screenWidth - 56 * scale) / 2 - 6 * scale : (screenWidth - 80 * scale) / 4 - 9 * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
            'Peak Booking Hours',
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnCard,
            ),
          ),
          SizedBox(height: 16 * scale),
          Obx(() => Wrap(
            spacing: 12 * scale,
            runSpacing: 12 * scale,
            children: controller.peakHours.map((hour) =>
                Container(
                  width: cardWidth,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * scale,
                    vertical: 12 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        hour.timeSlot,
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: AppColors.grey700,
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      Text(
                        '${hour.bookings}',
                        style: TextStyle(
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                )
            ).toList(),
          )),
        ],
      ),
    );
  }

  Widget _buildCustomerInsights(double scale, double spacing) {
    final controller = Get.find<BranchAnalyticsController>();
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
            'Customer Insights',
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnCard,
            ),
          ),
          SizedBox(height: 16 * scale),
          Obx(() => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12 * scale,
            crossAxisSpacing: 12 * scale,
            childAspectRatio: screenWidth < 600 ? 1.8 : 3.6,
            children: [
              _buildInsightCard(
                'Repeat Customers',
                '${controller.repeatCustomers}%',
                AppColors.iconBgPurple,
                AppColors.primaryPurple,
                scale,
              ),
              _buildInsightCard(
                'Avg. Spend',
                controller.avgSpend.value < 1000 ? 'PKR ${controller.avgSpend.value}' : 'PKR ${(controller.avgSpend.value / 1000).toStringAsFixed(controller.avgSpend.value % 1000 == 0 ? 0 : 1)}K',
                AppColors.iconBgLightPurple,
                AppColors.primaryPurple,
                scale,
              ),
              _buildInsightCard(
                'Retention Rate',
                '${controller.retentionRate}%',
                AppColors.iconBgGreen,
                AppColors.statusSuccess,
                scale,
              ),
              _buildInsightCard(
                'Total Customers',
                controller.newCustomers.value.toString(),
                AppColors.iconBgAmber,
                AppColors.statusWarning,
                scale,
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String label, String value, Color bgColor, Color textColor, double scale) {
    return Container(
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12 * scale,
              color: AppColors.grey700,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            value,
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}