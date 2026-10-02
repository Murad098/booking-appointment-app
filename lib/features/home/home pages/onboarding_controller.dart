import 'package:get/get.dart';
import '../../../services/shared_preferences_service.dart';
import '../../login/login_screen.dart';
import '../../signup/signup_screen.dart';

class OnboardingController extends GetxController {
  final currentStep = 0.obs;
  final int totalSteps = 3;

  // Loading states for different actions
  final isLoadingNext = false.obs;
  final isLoadingGetStarted = false.obs;
  final isLoadingLogin = false.obs;

  // Method to update step without loading (for page navigation)
  void updateStep(int step) {
    if (step >= 0 && step < totalSteps) {
      currentStep.value = step;
    }
  }

  // Method for next button with loading and navigation
  Future<void> handleNextButton(Function() navigateToNextPage) async {
    if (isLoadingNext.value) return;

    isLoadingNext.value = true;

    // Simulate a minimum 1-second loading time for smooth transition
    await Future.delayed(const Duration(milliseconds: 1000));

    isLoadingNext.value = false;

    // Update the step indicator
    if (currentStep.value < totalSteps - 1) {
      currentStep.value++;
    }

    // Navigate to next page
    navigateToNextPage();
  }

  Future<void> getStarted() async {
    if (isLoadingGetStarted.value) return;

    isLoadingGetStarted.value = true;

    // Simulate a minimum 1-second loading time for smooth transition
    await Future.delayed(const Duration(milliseconds: 1000));

    isLoadingGetStarted.value = false;

    // Mark onboarding as completed
    await SharedPreferencesService.setOnboardingCompleted();

    Get.offAll(() => const SignupScreen());
  }

  Future<void> login() async {
    if (isLoadingLogin.value) return;

    isLoadingLogin.value = true;

    // Simulate a minimum 1-second loading time for smooth transition
    await Future.delayed(const Duration(milliseconds: 1000));

    isLoadingLogin.value = false;

    // Mark onboarding as completed
    await SharedPreferencesService.setOnboardingCompleted();

    Get.offAll(() => const LoginScreen());
  }
}