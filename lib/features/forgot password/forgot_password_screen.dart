import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/app_icons.dart';
import '../../app/app_colors.dart';
import 'forgot_password_controller.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final ForgotPasswordController controller = Get.put(ForgotPasswordController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive sizing (Matching LoginScreen)
    final double cardHorizontalPadding = screenWidth < 600 ? 20 : 30;
    final double cardVerticalPadding = screenWidth < 600 ? 20 : 35;
    final double logoSize = screenWidth < 600 ? 100 : 120;
    final double titleSize = screenWidth < 600 ? 24 : 28;
    final double subtitleSize = screenWidth < 600 ? 13 : 14;
    final double buttonHeight = screenWidth < 600 ? 45 : 50;
    final double buttonTextSize = screenWidth < 600 ? 14 : 15;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textHeadline),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: cardHorizontalPadding,
              vertical: screenHeight * 0.05,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo Image
                  Image.asset(
                    'assets/png/bookify_transparent1.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: logoSize,
                        height: logoSize,
                        padding: EdgeInsets.all(logoSize * 0.25),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white,
                          size: logoSize * 0.5,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: screenWidth < 600 ? 10 : 15),

                  // Title Text
                  Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeadline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Enter your email address and we\'ll send you a link to reset your password.',
                    style: TextStyle(
                      fontSize: subtitleSize,
                      color: AppColors.textBody,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenWidth < 600 ? 20 : 25),

                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: cardHorizontalPadding,
                      vertical: cardVerticalPadding,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Email Field
                        Obx(() => _buildTextField(
                          controller: controller.emailController,
                          hint: 'you@example.com',
                          label: 'Email Address',
                          prefixIcon: AppIcons.email,
                          errorText: controller.fieldErrors['email'],
                          onChanged: (_) => controller.clearFieldError('email'),
                        )),

                        SizedBox(height: 20),

                        // Reset Button with Cooldown Display
                        Obx(() => SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: (controller.isLoading.value || controller.isCooldown.value)
                                ? null
                                : controller.resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: controller.isLoading.value
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : controller.isCooldown.value
                                ? Text(
                              'Try again in ${controller.cooldownSeconds.value}s',
                              style: TextStyle(
                                fontSize: buttonTextSize,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                                : Text(
                              'Send Reset Link',
                              style: TextStyle(
                                fontSize: buttonTextSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )),

                        SizedBox(height: 15),

                        // Back to Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Remember your password? ",
                              style: TextStyle(
                                color: AppColors.textBody,
                                fontSize: 12,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Get.back(),
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: AppColors.primaryPurple,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textHeadline,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: TextInputType.emailAddress,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
            prefixIcon: Icon(prefixIcon, color: AppColors.textPlaceholder, size: 20),
            suffixIcon: suffixIcon,
            errorText: errorText,
            errorStyle: TextStyle(
              color: Colors.red.shade700,
              fontSize: 11,
              height: 0.8,
            ),
            errorMaxLines: 2,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red.shade300 : AppColors.inputBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red.shade300 : AppColors.inputBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red.shade400 : AppColors.primaryPurple,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}