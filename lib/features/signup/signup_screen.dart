import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/app_icons.dart';
import 'signup_controller.dart';
import '../../app/app_colors.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final SignupController controller = Get.put(SignupController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final double cardHorizontalPadding = screenWidth < 600 ? 20 : 30;
    final double cardVerticalPadding = screenWidth < 600 ? 20 : 35;
    final double logoSize = screenWidth < 600 ? 100 : 120;
    final double titleSize = screenWidth < 600 ? 24 : 28;
    final double subtitleSize = screenWidth < 600 ? 13 : 14;
    final double buttonHeight = screenWidth < 600 ? 45 : 50;
    final double buttonTextSize = screenWidth < 600 ? 14 : 15;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
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

                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeadline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sign up to start managing your appointments',
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
                        // Full Name Field
                        Obx(() => _buildTextField(
                          controller: controller.fullNameController,
                          hint: 'John Doe',
                          label: 'Full Name',
                          prefixIcon: AppIcons.drawerProfile,
                          errorText: controller.fieldErrors['fullName'], // ✅ Map lookup
                          onChanged: (_) => controller.clearFieldError('fullName'),
                        )),
                        SizedBox(height: 12),

                        // Email Field
                        Obx(() => _buildTextField(
                          controller: controller.emailController,
                          hint: 'you@example.com',
                          label: 'Email Address',
                          prefixIcon: AppIcons.email,
                          errorText: controller.fieldErrors['email'], // ✅ Map lookup
                          onChanged: (_) => controller.clearFieldError('email'),
                        )),
                        SizedBox(height: 12),

                        // Password Field
                        Obx(() => _buildTextField(
                          controller: controller.passwordController,
                          hint: 'Create a password',
                          label: 'Password',
                          prefixIcon: AppIcons.password,
                          obscureText: controller.obscurePassword.value,
                          errorText: controller.fieldErrors['password'], // ✅ Map lookup
                          onChanged: (_) => controller.clearFieldError('password'),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.obscurePassword.value
                                  ? AppIcons.eye
                                  : AppIcons.eyeOff,
                              color: AppColors.textPlaceholder,
                            ),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                        )),
                        SizedBox(height: 12),

                        // Confirm Password Field
                        Obx(() => _buildTextField(
                          controller: controller.confirmPasswordController,
                          hint: 'Confirm your password',
                          label: 'Confirm Password',
                          prefixIcon: AppIcons.password,
                          obscureText: controller.obscureConfirmPassword.value,
                          errorText: controller.fieldErrors['confirmPassword'], // ✅ Map lookup
                          onChanged: (_) => controller.clearFieldError('confirmPassword'),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.obscureConfirmPassword.value
                                  ? AppIcons.eye
                                  : AppIcons.eyeOff,
                              color: AppColors.textPlaceholder,
                            ),
                            onPressed: controller.toggleConfirmPasswordVisibility,
                          ),
                        )),

                        // Sign Up Button
                        SizedBox(height: 15),
                        Obx(() => SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: controller.isSigningUp.value
                                ? null
                                : controller.signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: controller.isSigningUp.value
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: buttonTextSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )),
                        SizedBox(height: 15),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.inputBorder)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'Or continue with',
                                style: TextStyle(
                                  color: AppColors.textBody,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: AppColors.inputBorder)),
                          ],
                        ),
                        SizedBox(height: 15),

                        // Google Sign Up
                        Obx(() => SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: OutlinedButton.icon(
                            onPressed: controller.isSigningUpWithGoogle.value
                                ? null
                                : controller.signUpWithGoogle,
                            icon: controller.isSigningUpWithGoogle.value
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textHeadline),
                              ),
                            )
                                : Image.asset(
                              'assets/png/google.png',
                              width: 20,
                              height: 20,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.g_mobiledata, size: 20);
                              },
                            ),
                            label: Text(
                              'Sign up with Google',
                              style: TextStyle(
                                color: AppColors.textHeadline,
                                fontSize: screenWidth < 600 ? 13 : 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textHeadline,
                              side: BorderSide(color: AppColors.googleButtonBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        )),
                        SizedBox(height: 18),

                        // Sign In
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: AppColors.textBody,
                                fontSize: 12,
                              ),
                            ),
                            GestureDetector(
                              onTap: controller.navigateToSignIn,
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
                        SizedBox(height: 12),
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