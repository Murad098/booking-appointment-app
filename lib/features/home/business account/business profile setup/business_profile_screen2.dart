import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import 'business_profile_controller.dart';

class BusinessProfileStep2 extends StatelessWidget {
  const BusinessProfileStep2({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BusinessProfileController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMobile = screenWidth < 600;
    final padding = isMobile ? 16.0 : 24.0;
    final maxWidth = isMobile ? double.infinity : 600.0;

    final titleScale = isSmallScreen ? 0.85 : 1.0;
    final textScale = isSmallScreen ? 0.9 : 1.0;
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Business Profile Setup',
              style: TextStyle(
                fontSize: 18 * titleScale,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeadline,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Step 2 of 2',
              style: TextStyle(
                fontSize: 12 * textScale,
                color: AppColors.textBody.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: 1.0,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(AppIcons.clock, color: AppColors.primaryPurple, size: 24 * textScale),
                          SizedBox(width: 8 * textScale),
                          Expanded(
                            child: Text(
                              'Operating Hours',
                              style: TextStyle(
                                fontSize: 20 * titleScale,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHeadline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8 * textScale),
                      Text(
                        'Set your business hours for each day of the week',
                        style: TextStyle(
                          fontSize: 14 * textScale,
                          color: AppColors.textBody.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 24 * textScale),
                      ...days.map((day) => _buildDayRow(context, controller, day, textScale)),
                      SizedBox(height: 32 * textScale),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton(
                                onPressed: () => Get.back(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Previous',
                                  style: TextStyle(
                                    fontSize: 16 * textScale,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textHeadline,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12 * textScale),
                          Expanded(
                            child: Obx(() => SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: controller.isLoading.value ? null : () => controller.submitProfile(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryPurple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: controller.isLoading.value
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                    : Text(
                                  'Complete',
                                  style: TextStyle(
                                    fontSize: 16 * textScale,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )),
                          ),
                        ],
                      ),
                      SizedBox(height: 16 * textScale),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(BuildContext context, BusinessProfileController controller, String day, double scale) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 360) {
            return _buildCompactDayRow(context, controller, day, scale);
          }
          return _buildFullDayRow(context, controller, day, scale);
        },
      ),
    );
  }

  Widget _buildFullDayRow(BuildContext context, BusinessProfileController controller, String day, double scale) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            day,
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
              color: AppColors.textHeadline,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Obx(() {
            final open = controller.isOpen[day]!.value;
            return Row(
              children: [
                GestureDetector(
                  onTap: () => controller.toggleOpen(day),
                  child: Container(
                    width: 20 * scale,
                    height: 20 * scale,
                    decoration: BoxDecoration(
                      color: open ? AppColors.primaryPurple : Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 14 * scale,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8 * scale),
                Text(
                  open ? 'Open' : 'Closed',
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w500,
                    color: open ? AppColors.textHeadline : AppColors.textPlaceholder,
                  ),
                ),
              ],
            );
          }),
        ),
        Expanded(
          flex: 5,
          child: Obx(() {
            final open = controller.isOpen[day]!.value;
            if (!open) {
              return Text(
                'Closed',
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: AppColors.textPlaceholder,
                  fontStyle: FontStyle.italic,
                ),
              );
            }
            return Row(
              children: [
                _buildTimeButton(
                  context,
                  controller,
                  day,
                  controller.openTime[day]!.value,
                  true,
                  scale,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                  child: Text(
                    'to',
                    style: TextStyle(
                      fontSize: 14 * scale,
                      color: AppColors.textBody,
                    ),
                  ),
                ),
                _buildTimeButton(
                  context,
                  controller,
                  day,
                  controller.closeTime[day]!.value,
                  false,
                  scale,
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCompactDayRow(BuildContext context, BusinessProfileController controller, String day, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              day,
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w500,
                color: AppColors.textHeadline,
              ),
            ),
            Obx(() {
              final open = controller.isOpen[day]!.value;
              return Row(
                children: [
                  GestureDetector(
                    onTap: () => controller.toggleOpen(day),
                    child: Container(
                      width: 20 * scale,
                      height: 20 * scale,
                      decoration: BoxDecoration(
                        color: open ? AppColors.primaryPurple : Colors.grey[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 14 * scale,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  Text(
                    open ? 'Open' : 'Closed',
                    style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w500,
                      color: open ? AppColors.textHeadline : AppColors.textPlaceholder,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        SizedBox(height: 8 * scale),
        Obx(() {
          final open = controller.isOpen[day]!.value;
          if (!open) {
            return Text(
              'Closed',
              style: TextStyle(
                fontSize: 13 * scale,
                color: AppColors.textPlaceholder,
                fontStyle: FontStyle.italic,
              ),
            );
          }
          return Row(
            children: [
              Expanded(
                child: _buildTimeButton(
                  context,
                  controller,
                  day,
                  controller.openTime[day]!.value,
                  true,
                  scale,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                child: Text(
                  'to',
                  style: TextStyle(
                    fontSize: 13 * scale,
                    color: AppColors.textBody,
                  ),
                ),
              ),
              Expanded(
                child: _buildTimeButton(
                  context,
                  controller,
                  day,
                  controller.closeTime[day]!.value,
                  false,
                  scale,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTimeButton(
      BuildContext context,
      BusinessProfileController controller,
      String day,
      String time,
      bool isStartTime,
      double scale,
      ) {
    return GestureDetector(
      onTap: () => controller.selectTime(context, day, isStartTime),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          controller.formatTime(time),
          style: TextStyle(
            fontSize: 13 * scale,
            fontWeight: FontWeight.w500,
            color: AppColors.textHeadline,
          ),
        ),
      ),
    );
  }
}