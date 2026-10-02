import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import 'booking_controller.dart';

class BookingStep1DateTime extends StatefulWidget {
  const BookingStep1DateTime({super.key});

  @override
  State<BookingStep1DateTime> createState() => _BookingStep1DateTimeState();
}

class _BookingStep1DateTimeState extends State<BookingStep1DateTime> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<BookingController>();
    // Initialize controllers with current values (auto-filled by BookingController)
    _nameController = TextEditingController(text: controller.customerName.value);
    _emailController = TextEditingController(text: controller.customerEmail.value);
    _phoneController = TextEditingController(text: controller.customerPhone.value);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();
    final padding = MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0;
    final screenWidth = MediaQuery.of(context).size.width;

    // Sync controllers when observables change from outside (e.g., auto-fill)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_nameController.text != controller.customerName.value) {
        _nameController.text = controller.customerName.value;
      }
      if (_emailController.text != controller.customerEmail.value) {
        _emailController.text = controller.customerEmail.value;
      }
      if (_phoneController.text != controller.customerPhone.value) {
        _phoneController.text = controller.customerPhone.value;
      }
    });

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
            Text(
              'Step 1 of 4: Details & Date',
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
        final isLoadingBusiness = controller.isLoadingBusiness.value;

        if (isLoadingBusiness || !hasService || !hasBusiness) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            LinearProgressIndicator(
              value: 0.25,
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
                    const SizedBox(height: 20),
                    _buildCustomerDetailsSection(controller),
                    const SizedBox(height: 24),
                    Obx(() {
                      if (!controller.isCustomerDetailsValid) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.grey200.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.dividerColor),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock_outline,
                                  color: AppColors.textPlaceholder, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Please complete customer details above to select a date.',
                                  style: TextStyle(
                                      color: AppColors.textPlaceholder,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateSection(controller, screenWidth),
                          if (controller.selectedDate.value != null) ...[
                            const SizedBox(height: 24),
                            _buildTimeSection(controller, screenWidth),
                          ],
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            Obx(() {
              final dateReady = controller.selectedDate.value != null;
              final timeReady = controller.selectedTime.value.isNotEmpty;
              if (!dateReady || !timeReady) return const SizedBox.shrink();
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
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isContinueToPaymentLoading.value
                        ? null
                        : () => controller.goToStep2(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isContinueToPaymentLoading.value
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'Continue to Payment',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )),
                ),
              );
            }),
          ],
        );
      }),
    );
  }

  Widget _buildCustomerDetailsSection(BookingController controller) {
    // Update controllers when auto-filled values change (ensures UI sync)
    _nameController.text = controller.customerName.value;
    _emailController.text = controller.customerEmail.value;
    _phoneController.text = controller.customerPhone.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 1.0,
        ),
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
          const Text(
            'Customer Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => _buildInputField(
            label: 'Full Name',
            hint: 'John Doe',
            icon: AppIcons.navProfileOutlined,
            controller: _nameController,
            onChanged: controller.updateCustomerName,
            errorText: controller.step1Errors['name'],
          )),
          const SizedBox(height: 12),
          Obx(() => _buildInputField(
            label: 'Email Address',
            hint: 'john@example.com',
            icon: AppIcons.email,
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
            onChanged: controller.updateCustomerEmail,
            errorText: controller.step1Errors['email'],
          )),
          const SizedBox(height: 12),
          Obx(() => _buildInputField(
            label: 'Phone Number',
            hint: '03XXXXXXXXX',
            icon: AppIcons.phone,
            keyboardType: TextInputType.phone,
            controller: _phoneController,
            onChanged: controller.updateCustomerPhone,
            errorText: controller.step1Errors['phone'],
            helperText: 'Must be exactly 11 digits and start with 03',
          )),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required Function(String) onChanged,
    String? errorText,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textHeadline,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          onChanged: (value) {
            onChanged(value);
            // Also update controller's observable (already done by onChanged)
          },
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            helperText: helperText,
            helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryPurple, size: 20),
            ),
            errorText: errorText,
            errorStyle: TextStyle(
                color: Colors.red.shade700, fontSize: 11, height: 0.8),
            isDense: true,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? Colors.red.shade300
                    : AppColors.inputBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? Colors.red.shade300
                    : AppColors.inputBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? Colors.red.shade400
                    : AppColors.primaryPurple,
                width: 2,
              ),
            ),
          ),
        ),
      ],
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
                  ? Image.network(
                controller.serviceImageUrl.value,
                fit: BoxFit.cover,
              )
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
                  style: const TextStyle(fontSize: 13, color: AppColors.textBody),
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
                          fontSize: 12, color: AppColors.textPlaceholder),
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

  // Updated Compact Date Section
  Widget _buildDateSection(BookingController controller, double screenWidth) {
    return Obx(() {
      if (controller.isLoadingDates.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        );
      }

      final displayDates = controller.availableDates.take(14).toList();

      if (displayDates.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              'No available dates at this time',
              style: TextStyle(color: AppColors.textBody),
            ),
          ),
        );
      }

      // Split dates into two rows (7 dates each)
      final firstRowDates = displayDates.take(7).toList();
      final secondRowDates = displayDates.skip(7).take(7).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Date (Next 14 Working Days)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 12),
          // First Row
          Row(
            children: firstRowDates.map((date) {
              final isSelected = controller.selectedDate.value?.day == date.day &&
                  controller.selectedDate.value?.month == date.month &&
                  controller.selectedDate.value?.year == date.year;
              return Expanded(
                child: _buildCompactDateTile(date, isSelected, controller),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          // Second Row
          if (secondRowDates.isNotEmpty)
            Row(
              children: secondRowDates.map((date) {
                final isSelected = controller.selectedDate.value?.day == date.day &&
                    controller.selectedDate.value?.month == date.month &&
                    controller.selectedDate.value?.year == date.year;
                return Expanded(
                  child: _buildCompactDateTile(date, isSelected, controller),
                );
              }).toList(),
            ),
        ],
      );
    });
  }

  Widget _buildCompactDateTile(
      DateTime date, bool isSelected, BookingController controller) {
    return GestureDetector(
      onTap: () => controller.selectDate(date),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPurple
                : AppColors.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getDayNameShort(date.weekday),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPlaceholder,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textHeadline,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getMonthShort(date.month),
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? Colors.white70 : AppColors.textPlaceholder,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayNameShort(int weekday) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[weekday - 1];
  }

  String _getMonthShort(int month) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return months[month - 1];
  }

  // Updated Time Section with Responsive Slots - NO OVERFLOW
  Widget _buildTimeSection(BookingController controller, double screenWidth) {
    return Obx(() {
      if (controller.isLoadingTimeSlots.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        );
      }

      final timeSlots = controller.getAllTimeSlotsForDisplay();

      if (timeSlots.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              'No available time slots for this date',
              style: TextStyle(color: AppColors.textBody),
            ),
          ),
        );
      }

      // Adjust grid columns based on screen width
      final crossAxisCount = screenWidth < 400 ? 2 : 2;
      final childAspectRatio = screenWidth < 400 ? 1.6 : 1.8;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Time — ${_formatDateFull(controller.selectedDate.value!)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: AppColors.primaryPurple),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Service duration: ${controller.serviceDuration.value} minutes',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSlotLegend(),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: timeSlots.length,
            itemBuilder: (context, index) {
              final slot = timeSlots[index];
              return _buildResponsiveSlotTile(slot, controller);
            },
          ),
          // Add bottom padding to prevent overflow
          const SizedBox(height: 8),
        ],
      );
    });
  }

  Widget _buildSlotLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _legendItem(color: AppColors.primaryPurple, label: 'Selected'),
        _legendItem(color: Colors.green, label: 'Booked'),
        _legendItem(color: Colors.red, label: 'Short Time'),
        _legendItem(color: AppColors.textHeadline, label: 'Available'),
      ],
    );
  }

  Widget _legendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color == AppColors.textHeadline ? Colors.white : color.withOpacity(0.2),
            border: Border.all(
              color: color,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textPlaceholder),
        ),
      ],
    );
  }

  Widget _buildResponsiveSlotTile(TimeSlot slot, BookingController controller) {
    return Obx(() {
      final isSelected = controller.selectedTime.value.trim() ==
          slot.time.trim();
      final isBooked = slot.isBooked;
      final isInsufficient = slot.hasInsufficientTime;
      final isAvailable = slot.isAvailable;

      // Determine slot state
      Color backgroundColor;
      Color borderColor;
      Color textColor;
      IconData? statusIcon;
      Color iconColor;

      if (isSelected) {
        backgroundColor = AppColors.primaryPurple;
        borderColor = AppColors.primaryPurple;
        textColor = Colors.white;
        statusIcon = Icons.check_circle;
        iconColor = Colors.white;
      } else if (isBooked) {
        backgroundColor = Colors.green.withOpacity(0.12);
        borderColor = Colors.green;
        textColor = AppColors.textHeadline;
        statusIcon = Icons.check_circle;
        iconColor = Colors.green;
      } else if (isInsufficient) {
        backgroundColor = Colors.red.withOpacity(0.12);
        borderColor = Colors.red;
        textColor = AppColors.textPlaceholder;
        statusIcon = Icons.cancel;
        iconColor = Colors.red;
      } else if (isAvailable) {
        backgroundColor = Colors.white;
        borderColor = AppColors.dividerColor;
        textColor = AppColors.textHeadline;
        statusIcon = null;
        iconColor = Colors.transparent;
      } else {
        backgroundColor = AppColors.grey200;
        borderColor = AppColors.grey300;
        textColor = AppColors.textPlaceholder;
        statusIcon = Icons.block;
        iconColor = AppColors.textPlaceholder;
      }

      return GestureDetector(
        onTap: isAvailable
            ? () {
          controller.selectTime(slot.time);
        }
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: AppColors.primaryPurple.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ]
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _formatTimeDisplayProfessional(slot.time),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isBooked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'BOOKED',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                        )
                      else
                        if (isInsufficient)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'SHORT',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                          )
                        else
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'SELECTED',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              if (statusIcon != null)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Icon(
                    statusIcon,
                    size: 12,
                    color: iconColor,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }


  String _formatTimeDisplayProfessional(String time) {
    if (time.contains(' - ')) {
      final parts = time.split(' - ');
      final startFormatted = _formatSingleTimeCompact(parts[0]);
      final endFormatted = _formatSingleTimeCompact(parts[1]);
      return '$startFormatted\n$endFormatted';
    }
    return _formatSingleTimeCompact(time);
  }

  String _formatSingleTimeCompact(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    if (minute == '00') {
      return '$displayHour$period';
    }
    return '$displayHour:$minute$period';
  }

  String _formatDateFull(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}