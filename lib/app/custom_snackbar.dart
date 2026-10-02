// lib/app/custom_snackbar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  // 🔹 Success Snackbar (Green)
  static void success(
      String message, {
        SnackPosition position = SnackPosition.TOP,
      }) {
    Get.rawSnackbar(
      messageText: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      backgroundColor: Colors.green,
      snackPosition: position,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      duration: const Duration(seconds: 2),

      // ✅ NEW (width control)
      maxWidth: Get.width * 0.8,
    );
  }

  // 🔹 Error Snackbar (Red)
  static void error(
      String message, {
        SnackPosition position = SnackPosition.TOP,
      }) {
    Get.rawSnackbar(
      messageText: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      backgroundColor: Colors.red,
      snackPosition: position,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      duration: const Duration(seconds: 2),
    );
  }

  // 🔹 Info Snackbar (Blue)
  static void info(
      String message, {
        SnackPosition position = SnackPosition.TOP,
      }) {
    Get.rawSnackbar(
      messageText: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      backgroundColor: Colors.blue,
      snackPosition: position,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      duration: const Duration(seconds: 2),
    );
  }

  // 🔹 Warning Snackbar (Orange/Yellow)
  static void warning(
      String message, {
        SnackPosition position = SnackPosition.TOP,
      }) {
    Get.rawSnackbar(
      messageText: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      backgroundColor: Colors.orange,
      snackPosition: position,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      duration: const Duration(seconds: 2),
      maxWidth: Get.width * 0.8,
    );
  }
}