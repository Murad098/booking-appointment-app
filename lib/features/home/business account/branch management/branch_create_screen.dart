// lib/features/home/business account/branch management/branch_create_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import 'branch_controller.dart';

class BranchCreateScreen extends StatefulWidget {
  const BranchCreateScreen({super.key});

  @override
  State<BranchCreateScreen> createState() => _BranchCreateScreenState();
}

class _BranchCreateScreenState extends State<BranchCreateScreen> {
  int currentStep = 1;
  final controller = Get.find<BranchController>();

  // Controllers for text fields
  late TextEditingController branchNameController;
  late TextEditingController branchLocationController;
  late TextEditingController regEmailController;        // renamed
  late TextEditingController regPasswordController;
  late TextEditingController regConfirmPasswordController;

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    branchNameController = TextEditingController(text: controller.branchName.value);
    branchLocationController = TextEditingController(text: controller.branchLocation.value);
    regEmailController = TextEditingController(text: controller.regEmail.value);
    regPasswordController = TextEditingController(text: controller.regPassword.value);
    regConfirmPasswordController = TextEditingController(text: controller.regConfirmPassword.value);

    ever(controller.branchName, (val) {
      if (branchNameController.text != val) branchNameController.text = val;
    });
    ever(controller.branchLocation, (val) {
      if (branchLocationController.text != val) branchLocationController.text = val;
    });
    ever(controller.regEmail, (val) {
      if (regEmailController.text != val) regEmailController.text = val;
    });
    ever(controller.regPassword, (val) {
      if (regPasswordController.text != val) regPasswordController.text = val;
    });
    ever(controller.regConfirmPassword, (val) {
      if (regConfirmPasswordController.text != val) regConfirmPasswordController.text = val;
    });
  }

  @override
  void dispose() {
    branchNameController.dispose();
    branchLocationController.dispose();
    regEmailController.dispose();
    regPasswordController.dispose();
    regConfirmPasswordController.dispose();
    super.dispose();
  }

  void goToStep2() {
    if (controller.validateBranchForm()) {
      setState(() => currentStep = 2);
    } else {
      Get.snackbar(
        "Validation Error",
        "Please fill all fields correctly.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    }
  }

  void goBackToStep1() {
    setState(() => currentStep = 1);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (currentStep == 2) {
          goBackToStep1();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(AppIcons.arrowLeft, color: AppColors.textHeadline),
            onPressed: () {
              if (currentStep == 2) {
                goBackToStep1();
              } else {
                Get.back();
              }
            },
          ),
          title: Text(
            'Add New Branch',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textHeadline,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.scaffoldBackground,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with step indicator (unchanged)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStep == 1 ? 'Branch Information' : 'Set Access Credentials',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHeadline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentStep == 1
                          ? 'Enter the basic details for your new location.'
                          : 'Create login credentials for branch-level access.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textBody,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildStepDot(1, currentStep >= 1),
                        _buildStepLine(currentStep > 1),
                        _buildStepDot(2, currentStep >= 2),
                        const SizedBox(width: 8),
                        Text(
                          'Credentials',
                          style: TextStyle(
                            fontSize: 12,
                            color: currentStep >= 2 ? AppColors.textHeadline : AppColors.textPlaceholder,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: currentStep == 1
                    ? _buildStep1Content()
                    : _buildStep2Content(),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Obx(() {
            final bool isLoading = controller.isLoading.value;
            return ElevatedButton(
              onPressed: isLoading
                  ? null
                  : (currentStep == 1 ? goToStep2 : controller.createBranch), // ← changed
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              child: isLoading
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentStep == 1 ? 'Continue to Credentials' : 'Create Branch',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    currentStep == 1 ? Icons.arrow_forward_rounded : Icons.check_circle_outline,
                    size: 20,
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // --- Step 1 (unchanged) ---
  Widget _buildStep1Content() {
    return Padding(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputCard(
            label: 'Branch Name',
            hint: 'e.g., Elite Salon - Downtown',
            icon: Icons.business_center_outlined,
            controller: branchNameController,
            onChanged: (val) => controller.branchName.value = val,
          ),
          const SizedBox(height: 16),
          _buildInputCard(
            label: 'Location / Address',
            hint: 'e.g., 123 Main St, City, Country',
            icon: Icons.location_on_outlined,
            controller: branchLocationController,
            onChanged: (val) => controller.branchLocation.value = val,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryPurple.withOpacity(0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.primaryPurple, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Next, you will set up secure login credentials for this branch manager.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textBody,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2 (updated to email) ---
  Widget _buildStep2Content() {
    return Padding(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "These credentials will be used by the branch manager to log in to their specific dashboard.",
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Email field (instead of username)
          Obx(() {
            String? errorText;
            if (controller.showRegErrors.value &&
                (controller.regEmail.value.isEmpty ||
                    !GetUtils.isEmail(controller.regEmail.value))) {
              errorText = "Valid email required";
            }
            return _buildInputCard(
              label: 'Branch Manager Email',
              hint: 'manager@branch.com',
              icon: Icons.email_outlined,
              controller: regEmailController,
              onChanged: (val) => controller.regEmail.value = val,
              errorText: errorText,
            );
          }),

          const SizedBox(height: 16),

          // Password
          Obx(() {
            String? errorText;
            if (controller.showRegErrors.value && controller.regPassword.value.length < 6) {
              errorText = "Min 6 characters";
            }
            return _buildPasswordInputCard(
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline,
              controller: regPasswordController,
              onChanged: (val) => controller.regPassword.value = val,
              isPassword: !isPasswordVisible,
              toggleVisibility: () {
                setState(() => isPasswordVisible = !isPasswordVisible);
              },
              errorText: errorText,
            );
          }),

          const SizedBox(height: 16),

          // Confirm Password
          Obx(() {
            String? errorText;
            if (controller.showRegErrors.value &&
                controller.regPassword.value != controller.regConfirmPassword.value &&
                controller.regConfirmPassword.value.isNotEmpty) {
              errorText = "Passwords do not match";
            }
            return _buildPasswordInputCard(
              label: 'Confirm Password',
              hint: '••••••••',
              icon: Icons.lock_outline,
              controller: regConfirmPasswordController,
              onChanged: (val) => controller.regConfirmPassword.value = val,
              isPassword: !isConfirmPasswordVisible,
              toggleVisibility: () {
                setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible);
              },
              errorText: errorText,
            );
          }),
        ],
      ),
    );
  }

  // --- Helpers (unchanged, except the input card now uses email icon) ---
  Widget _buildStepDot(int step, bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryPurple : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (step < 2) const SizedBox(width: 8),
        if (step < 2)
          Text(
            step == 1 ? 'Details' : '',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHeadline,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isActive ? AppColors.primaryPurple : Colors.grey.shade300,
    );
  }

  Widget _buildInputCard({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required Function(String) onChanged,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textHeadline,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textHeadline,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.textPlaceholder,
                fontSize: 14,
              ),
              errorText: errorText,
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryPurple, size: 20),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordInputCard({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required Function(String) onChanged,
    required bool isPassword,
    required VoidCallback toggleVisibility,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textHeadline,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            textDirection: TextDirection.ltr,
            obscureText: isPassword,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textHeadline,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.textPlaceholder,
                fontSize: 14,
              ),
              errorText: errorText,
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryPurple, size: 20),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textPlaceholder,
                ),
                onPressed: toggleVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}