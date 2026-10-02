import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_icons.dart';
import 'privacy_policy_controller.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PrivacyPolicyController());

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final padding = isMobile ? 16.0 : 24.0;
    final textScale = isMobile ? 1.0 : 1.1;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(AppIcons.arrowLeft, color: AppColors.textHeadline),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.copy, color: AppColors.primaryPurple),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: controller.policyContent.value));
              Get.snackbar('Copied', 'Privacy policy copied to clipboard',
                  snackPosition: SnackPosition.BOTTOM);
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 800,
            ),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: MarkdownBody(
                  data: controller.policyContent.value,
                  styleSheet: MarkdownStyleSheet(
                    h1: TextStyle(
                      fontSize: 24 * textScale,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeadline,
                    ),
                    h2: TextStyle(
                      fontSize: 20 * textScale,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHeadline,
                    ),
                    p: TextStyle(
                      fontSize: 14 * textScale,
                      height: 1.5,
                      color: AppColors.textBody,
                    ),
                    listBullet: TextStyle(
                      fontSize: 14 * textScale,
                      color: AppColors.textBody,
                    ),
                    strong: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeadline,
                    ),
                  ),
                  selectable: true, // Allows text selection (copy/paste)
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}