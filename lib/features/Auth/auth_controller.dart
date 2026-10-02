// lib/features/auth/auth_controller.dart
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';   // required for isBranchUser

class AuthController extends GetxController {
  final RxBool isBranchUser = false.obs;

  void setBranchUser(bool value) {
    isBranchUser.value = value;
  }

  /// Refresh the branch status for the currently logged-in user.
  /// This ensures correct state after app restart or when user data changes.
  Future<void> refreshBranchStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final bool isBranch = await UserService.isBranchUser(user.uid);
      isBranchUser.value = isBranch;
    } else {
      // If no user, reset to false (should not happen if home screen is shown)
      isBranchUser.value = false;
    }
  }
}