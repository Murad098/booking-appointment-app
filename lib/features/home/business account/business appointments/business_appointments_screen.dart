// business_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import '../../appointment_details/appointment_details_screen.dart';
import 'business_appointments_controller.dart';

class BusinessAppointmentsScreen extends StatelessWidget {
  const BusinessAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BusinessAppointmentsController());
    final screenWidth = MediaQuery.of(context).size.width;

    final isMobile = screenWidth < 600;
    final scale = isMobile ? 1.0 : 1.0;
    final padding = isMobile ? 16.0 : 32.0;
    final maxWidth = isMobile ? double.infinity : 700.0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Range Filter
                        _buildDateRangeFilter(controller, scale),
                        SizedBox(height: 20 * scale),

                        // Status Tabs
                        Obx(() => _buildStatusTabs(controller, scale)),
                        SizedBox(height: 20 * scale),

                        // Appointments List
                        Obx(() => _buildAppointmentsList(controller, scale)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildDateRangeFilter(BusinessAppointmentsController controller, double scale) {
    return GestureDetector(
      onTap: () => _showDateRangePicker(controller, scale),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 14 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8 * scale),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                AppIcons.calendar,
                size: 20 * scale,
                color: AppColors.primaryPurple,
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date Range',
                    style: TextStyle(
                      fontSize: 11 * scale,
                      color: AppColors.textBody,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Obx(() => Text(
                    controller.dateRangeLabel.value,
                    style: TextStyle(
                      fontSize: 14 * scale,
                      color: AppColors.textHeadline,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 24 * scale,
              color: AppColors.textBody,
            ),
          ],
        ),
      ),
    );
  }

  void _showDateRangePicker(BusinessAppointmentsController controller, double scale) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40 * scale,
                height: 4 * scale,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 16 * scale),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter by Date',
                  style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeadline,
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 24 * scale,
                    color: AppColors.textBody,
                  ),
                  onPressed: () => Get.back(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 20 * scale),

            // Quick filter chips
            Wrap(
              spacing: 8 * scale,
              runSpacing: 8 * scale,
              children: [
                _buildFilterChip('All Time', controller.dateRangeFilter.value == 'all', () {
                  controller.setDateRange('all', null, null);
                  Get.back();
                }, scale),
                _buildFilterChip('Today', controller.dateRangeFilter.value == 'today', () {
                  controller.setDateRange('today', DateTime.now(), DateTime.now());
                  Get.back();
                }, scale),
                _buildFilterChip('This Week', controller.dateRangeFilter.value == 'week', () {
                  final now = DateTime.now();
                  final start = now.subtract(Duration(days: now.weekday - 1));
                  final end = start.add(const Duration(days: 6));
                  controller.setDateRange('week', start, end);
                  Get.back();
                }, scale),
                _buildFilterChip('This Month', controller.dateRangeFilter.value == 'month', () {
                  final now = DateTime.now();
                  final start = DateTime(now.year, now.month, 1);
                  final end = DateTime(now.year, now.month + 1, 0);
                  controller.setDateRange('month', start, end);
                  Get.back();
                }, scale),
              ],
            ),
            SizedBox(height: 24 * scale),

            Divider(color: Colors.grey[200], height: 1),
            SizedBox(height: 20 * scale),

            // Custom date range
            Text(
              'Custom Range',
              style: TextStyle(
                fontSize: 15 * scale,
                fontWeight: FontWeight.w600,
                color: AppColors.textHeadline,
              ),
            ),
            SizedBox(height: 12 * scale),

            Row(
              children: [
                Expanded(
                  child: _buildDatePickerField(
                    label: 'From',
                    date: controller.startDate.value,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: Get.context!,
                        initialDate: controller.startDate.value ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors.primaryPurple,
                                onPrimary: Colors.white,
                                onSurface: AppColors.textHeadline,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        controller.setStartDate(picked);
                      }
                    },
                    scale: scale,
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: _buildDatePickerField(
                    label: 'To',
                    date: controller.endDate.value,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: Get.context!,
                        initialDate: controller.endDate.value ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors.primaryPurple,
                                onPrimary: Colors.white,
                                onSurface: AppColors.textHeadline,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        controller.setEndDate(picked);
                      }
                    },
                    scale: scale,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24 * scale),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.startDate.value != null && controller.endDate.value != null) {
                    controller.applyCustomDateRange();
                    Get.back();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16 * scale),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Apply Filter',
                  style: TextStyle(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8 * scale),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, double scale) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 10 * scale),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13 * scale,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textBody,
            letterSpacing: 0.2,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required double scale,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 12 * scale),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16 * scale,
              color: AppColors.textBody,
            ),
            SizedBox(width: 10 * scale),
            Expanded(
              child: Text(
                date != null ? '${date.day}/${date.month}/${date.year}' : label,
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w500,
                  color: date != null ? AppColors.textHeadline : AppColors.textBody.withOpacity(0.6),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTabs(BusinessAppointmentsController controller, double scale) {
    final tabs = [
      {'label': 'Completed', 'icon': Icons.check_circle_outline_rounded},
      {'label': 'Pending', 'icon': Icons.pending_actions_rounded},
      {'label': 'Confirmed', 'icon': Icons.verified_rounded},
      {'label': 'Cancelled', 'icon': Icons.cancel_outlined},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!, width: 1),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value['label'] as String;
          final icon = entry.value['icon'] as IconData;
          final isSelected = controller.statusTabIndex.value == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.changeStatusTab(index),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12 * scale),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20 * scale,
                      color: isSelected ? AppColors.primaryPurple : AppColors.textBody.withOpacity(0.5),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11 * scale,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.primaryPurple : AppColors.textBody,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAppointmentsList(BusinessAppointmentsController controller, double scale) {
    if (controller.isLoading.value) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(60 * scale),
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
              ),
              SizedBox(height: 16 * scale),
              Text(
                'Loading appointments...',
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: AppColors.textBody,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final appointments = controller.filteredAppointments;

    if (appointments.isEmpty) {
      return _buildEmptyState(
        'No appointments found',
        Icons.event_busy_outlined,
        'Try adjusting your filters or check back later',
        scale,
      );
    }

    return Column(
      children: appointments.map((appointment) =>
          _buildAppointmentCard(appointment, controller, scale: scale)
      ).toList(),
    );
  }

  Widget _buildEmptyState(String title, IconData icon, String subtitle, double scale) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60 * scale),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(24 * scale),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48 * scale,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 20 * scale),
            Text(
              title,
              style: TextStyle(
                fontSize: 18 * scale,
                color: AppColors.textHeadline,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8 * scale),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14 * scale,
                color: AppColors.textBody,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, BusinessAppointmentsController controller, {required double scale}) {
    final status = appointment['status'] as String;
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    final isVerySmall = screenWidth < 340;

    final statusColors = {
      'pending': const Color(0xFFFF9800),
      'confirmed': const Color(0xFF2196F3),
      'completed': const Color(0xFF4CAF50),
      'cancelled': const Color(0xFFF44336),
    };

    final statusBgColors = {
      'pending': const Color(0xFFFFF3E0),
      'confirmed': const Color(0xFFE3F2FD),
      'completed': const Color(0xFFE8F5E9),
      'cancelled': const Color(0xFFFFEBEE),
    };

    return GestureDetector(
      onTap: () {
        Get.to(
              () => const AppointmentDetailsScreen(),
          arguments: {
            ...appointment,
            'isBusinessView': true,
          },
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 14 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[100]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status bar
              Container(
                height: 4,
                color: statusColors[status] ?? Colors.grey,
              ),

              Padding(
                padding: EdgeInsets.all(16 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment['services'],
                                style: TextStyle(
                                  fontSize: 16 * scale,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textHeadline,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              SizedBox(height: 4 * scale),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 14 * scale,
                                    color: AppColors.textBody,
                                  ),
                                  SizedBox(width: 4 * scale),
                                  Text(
                                    appointment['customerName'],
                                    style: TextStyle(
                                      fontSize: 13 * scale,
                                      color: AppColors.textBody,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
                          decoration: BoxDecoration(
                            color: statusBgColors[status] ?? Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColors[status] ?? Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6 * scale),
                              Text(
                                status.capitalize!,
                                style: TextStyle(
                                  fontSize: 11 * scale,
                                  fontWeight: FontWeight.w600,
                                  color: statusColors[status] ?? AppColors.textBody,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14 * scale),

                    // Info rows
                    Wrap(
                      spacing: 12 * scale,
                      runSpacing: 8 * scale,
                      children: [
                        _buildInfoChip(
                          Icons.calendar_today_rounded,
                          controller.formatDate(appointment['date']),
                          scale,
                        ),
                        _buildInfoChip(
                          Icons.access_time_rounded,
                          '${appointment['time']} (${appointment['duration']} min)',
                          scale,
                        ),
                        _buildInfoChip(
                          Icons.attach_money_rounded,
                          'PKR ${appointment['price']}',
                          scale,
                        ),
                      ],
                    ),

                    SizedBox(height: 12 * scale),

                    // View details indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 12 * scale,
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4 * scale),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12 * scale,
                          color: AppColors.primaryPurple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, double scale) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[100]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14 * scale,
            color: AppColors.textBody,
          ),
          SizedBox(width: 6 * scale),
          Text(
            text,
            style: TextStyle(
              fontSize: 12 * scale,
              color: AppColors.textBody,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}