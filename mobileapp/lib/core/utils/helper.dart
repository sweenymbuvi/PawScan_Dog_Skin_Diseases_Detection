import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class Helper {
  static void errorSnackBar({required String title, required String message}) {
    // Show error snackbar
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static double screenWidth() {
    return MediaQuery.of(Get.context!).size.width;
  }

  // Other utility functions can be added here as static methods
}
