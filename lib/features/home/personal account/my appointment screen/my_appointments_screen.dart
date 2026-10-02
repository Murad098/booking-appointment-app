import 'package:bookify/features/home/personal%20account/personal_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import '../../appointment_details/appointment_details_screen.dart';
import '../search_and_filter_page.dart';
import 'my_appointments_controller.dart';

class MyAppointmentsScreen extends StatelessWidget {
  // Parameter to control AppBar visibility
  final bool showAppBar;

  const MyAppointmentsScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyAppointmentsController());
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final padding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,

      // Conditional App Bar
      appBar: showAppBar
          ? AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(AppIcons.arrowLeft, color: AppColors.textHeadline),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'My Appointments',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
      )
          : null,

      body: SafeArea(
        top: !showAppBar,
        child: Obx(() {
          // Show loading indicator while fetching data
          if (controller.isLoading.value && controller.allAppointments.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              if (!showAppBar) SizedBox(height: 16 * (isMobile ? 1.0 : 1.05)),

              // Custom Collapsible Filter Dropdown
              _buildCustomFilterDropdown(controller, padding),
              SizedBox(height: 16),

              // Appointments List
              Expanded(
                child: _buildAppointmentsList(controller, padding),
              ),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(
                () => const SearchAndFilteredPageScreen(
              categoryId: 'all',
              categoryName: 'All Services',
            ),
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 300),
          );
        },
        backgroundColor: AppColors.primaryPurple,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Custom Collapsible Filter Menu (Responsive & Compact)
  Widget _buildCustomFilterDropdown(MyAppointmentsController controller, double padding) {
    // Define filter options with matching icons and colors
    final filterOptions = [
      {'label': 'Upcoming', 'icon': Icons.calendar_today_rounded, 'color': const Color(0xFF6C5CE7)},
      {'label': 'Pending', 'icon': Icons.hourglass_top_rounded, 'color': const Color(0xFFF39C12)},
      {'label': 'Confirmed', 'icon': Icons.check_box_rounded, 'color': const Color(0xFF27AE60)},
      {'label': 'Completed', 'icon': Icons.check_circle_outline_rounded, 'color': const Color(0xFF3498DB)},
      {'label': 'Cancelled', 'icon': Icons.cancel_rounded, 'color': const Color(0xFFE74C3C)},
      {'label': 'Past', 'icon': Icons.history_rounded, 'color': const Color(0xFF6C5CE7)},
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(Get.context!).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            // ✅ Reduced childrenPadding for compact height
            childrenPadding: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
            collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            leading: Container(
              width: 36, // ✅ Slightly smaller to save space
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.filter_list_rounded, color: AppColors.primaryPurple, size: 18),
            ),
            title: Text(
              controller.selectedFilter.value == 'All' ? 'All Appointments' : controller.selectedFilter.value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeadline,
              ),
            ),
            // Use standard 'trailing' and change icon based on expansion
            trailing: Icon(
              controller.isExpanded.value
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.textHeadline.withOpacity(0.6),
            ),
            // Listen to expansion state to rotate the arrow
            onExpansionChanged: (bool expanded) {
              controller.isExpanded.value = expanded;
            },
            children: [
              const SizedBox(height: 4), // ✅ Reduced gap
              // ✅ Added shrinkWrap and min mainAxisSize to prevent infinite height issues
              ...filterOptions.map((option) {
                final String label = option['label'] as String;
                final bool isSelected = controller.selectedFilter.value == label;

                return GestureDetector(
                  onTap: () {
                    controller.updateFilter(label);
                    controller.isExpanded.value = false;
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6), // ✅ Reduced margin
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // ✅ Reduced padding by half
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF3F0FF) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFE8E3FF) : const Color(0xFFF0F0F5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Icon Box
                        Container(
                          width: 28, // ✅ Smaller icon box
                          height: 28,
                          decoration: BoxDecoration(
                            color: (option['color'] as Color).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            option['icon'] as IconData,
                            size: 14, // ✅ Smaller icon
                            color: option['color'] as Color,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Label
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12, // ✅ Slightly smaller text
                              fontWeight: FontWeight.w600,
                              color: AppColors.textHeadline,
                            ),
                          ),
                        ),

                        // Selection Checkmark / Circle
                        if (isSelected)
                          Container(
                            width: 20, // ✅ Smaller selection ring
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryPurple,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                          )
                        else
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 2),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              // "All" option at the bottom
              GestureDetector(
                onTap: () {
                  controller.updateFilter('All');
                  controller.isExpanded.value = false;
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // ✅ Reduced padding
                  decoration: BoxDecoration(
                    color: controller.selectedFilter.value == 'All' ? const Color(0xFFF3F0FF) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: controller.selectedFilter.value == 'All' ? const Color(0xFFE8E3FF) : const Color(0xFFF0F0F5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.list_rounded, size: 14, color: AppColors.primaryPurple),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'All Appointments',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHeadline,
                          ),
                        ),
                      ),
                      if (controller.selectedFilter.value == 'All')
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryPurple,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                        )
                      else
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Appointments List - Updated to use filtered appointments
  Widget _buildAppointmentsList(
      MyAppointmentsController controller, double padding) {
    final appointments = controller.filteredAppointments;

    if (controller.isLoading.value && appointments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (appointments.isEmpty) {
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
              _getEmptyMessage(controller.selectedFilter.value),
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textBody,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different filter',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPlaceholder,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
      itemCount: appointments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _buildAppointmentCard(appointments[index], controller);
      },
    );
  }

  String _getEmptyMessage(String filter) {
    switch (filter) {
      case 'Upcoming':
        return 'No upcoming appointments';
      case 'Pending':
        return 'No pending appointments';
      case 'Confirmed':
        return 'No confirmed appointments';
      case 'Completed':
        return 'No completed appointments';
      case 'Cancelled':
        return 'No cancelled appointments';
      case 'Past':
        return 'No past appointments';
      default:
        return 'No appointments found';
    }
  }

  // Updated Appointment Card with highly refined UI matching the screenshot
  Widget _buildAppointmentCard(
      Map<String, dynamic> appointment, MyAppointmentsController controller) {
    final status = appointment['status'] as String;
    final statusColor = _getStatusColor(status);
    final statusBgColor = _getStatusBgColor(status);
    final isAutoCancelled = appointment['autoCancelled'] ?? false;

    // Display status text (show "Auto-Cancelled" if applicable)
    String displayStatus = status;
    if (status.toLowerCase() == 'cancelled' && isAutoCancelled) {
      displayStatus = 'Auto-Cancelled';
    } else {
      displayStatus = status.capitalize!;
    }

    // Get date and time for display
    final dateObj = appointment['dateTime'] as DateTime?;
    final formattedDate = dateObj != null
        ? _formatAppointmentDate(dateObj)
        : appointment['date'] ?? '';
    final formattedTime = appointment['time'] ?? '';

    // Icon selection based on service name
    IconData serviceIcon = Icons.cut;
    if (appointment['services'].toString().toLowerCase().contains('manicure')) {
      serviceIcon = Icons.spa_outlined;
    } else if (appointment['services'].toString().toLowerCase().contains('makeup')) {
      serviceIcon = Icons.face_retouching_natural_outlined;
    }

    return GestureDetector(
      onTap: () {
        final Map<String, dynamic> args = Map.from(appointment);
        args['isBusinessView'] = false;

        Get.to(
              () => const AppointmentDetailsScreen(),
          arguments: args,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8E8EF),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Service Icon, Name, Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Service Icon Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusBgColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    serviceIcon,
                    size: 20,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),

                // Service Name (✅ CHANGED TO ROW TO PREVENT OVERFLOW)
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              appointment['services'],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHeadline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.store_outlined,
                                  size: 12,
                                  color: AppColors.textPlaceholder,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    appointment['businessName'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textPlaceholder,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusBgColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'completed'
                            ? Icons.check_rounded
                            : status.toLowerCase() == 'cancelled'
                            ? Icons.close_rounded
                            : Icons.hourglass_empty_rounded,
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        displayStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Divider
            Divider(
              color: const Color(0xFFE8E8EF),
              height: 1,
              thickness: 1,
            ),
            const SizedBox(height: 12),

            // Details Grid: Date, Time, Amount (Equal columns)
            IntrinsicHeight(
              child: Row(
                children: [
                  // Date
                  Expanded(
                    child: _buildDetailColumn(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date',
                      value: formattedDate,
                    ),
                  ),
                  // Vertical Divider
                  Container(
                    width: 1,
                    color: const Color(0xFFE8E8EF),
                  ),
                  // Time
                  Expanded(
                    child: _buildDetailColumn(
                      icon: Icons.access_time_rounded,
                      label: 'Time',
                      value: formattedTime,
                    ),
                  ),
                  // Vertical Divider
                  Container(
                    width: 1,
                    color: const Color(0xFFE8E8EF),
                  ),
                  // Amount
                  Expanded(
                    child: _buildDetailColumn(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Amount',
                      value: 'PKR ${appointment['price']}',
                      isPrice: true,
                    ),
                  ),
                ],
              ),
            ),

            // Booking ID (bottom row with copy icon)
            if (appointment['id'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ID: ${appointment['id'].toString().substring(0, 8)}...',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textPlaceholder,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: AppColors.textPlaceholder.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper for the column detail rows inside the card
  Widget _buildDetailColumn({
    required IconData icon,
    required String label,
    required String value,
    bool isPrice = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 13,
                color: AppColors.textPlaceholder.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textPlaceholder.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isPrice ? FontWeight.w700 : FontWeight.w500,
              color: isPrice ? AppColors.primaryPurple : AppColors.textHeadline,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatAppointmentDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (appointmentDate == today) {
      return 'Today';
    } else if (appointmentDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (appointmentDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.statusWarning;
      case 'confirmed':
        return const Color(0xFF27AE60); // Match screenshot green
      case 'completed':
        return const Color(0xFF3498DB); // Match screenshot blue
      case 'cancelled':
        return AppColors.deleteColor;
      default:
        return AppColors.textBody;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.iconBgAmber;
      case 'confirmed':
        return const Color(0xFFE8F8F0); // Light green bg
      case 'completed':
        return const Color(0xFFEBF5FB); // Light blue bg
      case 'cancelled':
        return const Color(0xFFFFEBEE);
      default:
        return Colors.grey[100]!;
    }
  }
}