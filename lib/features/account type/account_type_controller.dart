import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/custom_snackbar.dart';
import '../../services/user_service.dart';
import '../home/Notifications screen/notifications_controller.dart';
import '../home/business account/business profile setup/business_profile_screen1.dart';
import '../home/business account/business_home_screen.dart';
import '../home/personal account/personal_home_screen.dart';

class AccountTypeController extends GetxController {
  final RxnString selectedAccountType = RxnString();

  final RxBool isLoading = false.obs;

  bool get isNextEnabled => selectedAccountType.value != null;
  RxBool isDialogLoading = false.obs;

  void selectAccountType(String type) {
    selectedAccountType.value = type;
  }

  Future<void> onNext() async {
    if (!isNextEnabled) return;

    final type = selectedAccountType.value;
    isLoading.value = true;

    try {
      // Save role to Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && type != null) {
        await UserService.saveUserRole(user.uid, type);
      }

      await Future.delayed(const Duration(seconds: 2));

      String message = type == 'business'
          ? "Your business account created successfully!"
          : "Your personal account created successfully!";

      Get.defaultDialog(
        title: "Success",
        middleText: message,
        barrierDismissible: false,
        backgroundColor: Colors.white,
        radius: 14,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        titleStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        middleTextStyle: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.4,
        ),
        confirm: Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 0,
              side: const BorderSide(color: Colors.green),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: isDialogLoading.value
                ? null
                : () async {
              isDialogLoading.value = true;
              await Future.delayed(const Duration(milliseconds: 800));
              Get.back();

              if (type == 'business') {
                // Check if business profile already exists
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final isProfileCompleted = await UserService.isBusinessProfileCompleted(user.uid);
                  if (isProfileCompleted) {
                    // Skip setup, go directly to Business Home
                    Get.offAll(
                          () => BusinessHomeScreen(),
                      binding: BindingsBuilder(() {
                        Get.put(NotificationsController());
                      }),
                    );
                  } else {
                    // First time - show setup flow
                    Get.offAll(
                          () => BusinessProfileStep1(),
                      binding: BindingsBuilder(() {
                        Get.put(NotificationsController());
                      }),
                    );
                  }
                } else {
                  Get.offAll(() => BusinessProfileStep1());
                }
              } else {
                Get.offAll(
                      () => const PersonalHomeScreen(),
                  binding: BindingsBuilder(() {
                    Get.put(NotificationsController(), permanent: true);
                  }),
                );
              }
              isDialogLoading.value = false;
            },
            child: isDialogLoading.value
                ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.green,
              ),
            )
                : const Text(
              "OK",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        )),
      );
    } catch (e) {
      AppSnackbar.error("Something went wrong");
    } finally {
      isLoading.value = false;
    }
  }
}