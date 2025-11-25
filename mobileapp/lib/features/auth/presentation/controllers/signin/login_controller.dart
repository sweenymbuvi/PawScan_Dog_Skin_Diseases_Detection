import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pawscan/features/auth/data/repository/authentication_repository.dart';

class LoginController extends GetxController {
  final email = TextEditingController();
  final password = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();

  var isLoading = false.obs;
  var showPassword = false.obs;

  Future<void> login() async {
    if (loginFormKey.currentState!.validate()) {
      isLoading.value = true;

      String? loginError = await AuthenticationRepository.instance
          .loginWithEmailAndPassword(email.text.trim(), password.text.trim());

      isLoading.value = false;

      if (loginError == null) {
        // Show success message
        Get.snackbar(
          'Success',
          'Login successful',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // Navigate to home screen
        Get.offAllNamed('/home');
      } else {
        // Show error message
        Get.snackbar(
          'Login Failed',
          loginError,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> googleSignIn() async {
    isLoading.value = true;

    try {
      await AuthenticationRepository.instance.signInWithGoogle();
      isLoading.value = false;

      // Show success message
      Get.snackbar(
        'Success',
        'Login successful',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      isLoading.value = false;

      // Show error message
      Get.snackbar(
        'Login Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
