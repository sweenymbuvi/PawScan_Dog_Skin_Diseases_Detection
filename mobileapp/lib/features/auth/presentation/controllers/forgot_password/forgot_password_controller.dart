import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pawscan/features/auth/data/repository/authentication_repository.dart';

class ForgotPasswordController extends GetxController {
  static ForgotPasswordController get instance => Get.find();

  // Variables
  final email = TextEditingController();
  final forgotPasswordFormKey = GlobalKey<FormState>();

  /// Send password reset email
  Future<void> sendPasswordResetEmail() async {
    try {
      if (!forgotPasswordFormKey.currentState!.validate()) return;

      await AuthenticationRepository.instance.sendPasswordResetEmail(
        email.text.trim(),
      );

      // Show success confirmation
      // Removed controller snackbar, feedback handled in screen
    } on FirebaseAuthException catch (e) {
      final message = handleFirebaseAuthError(e.code);
      Get.snackbar(
        'Error',
        message,
        backgroundColor: Colors.red.withOpacity(0.2),
        colorText: Colors.black,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
        backgroundColor: Colors.red.withOpacity(0.2),
        colorText: Colors.black,
      );
    }
  }

  /// Resend password reset email
  Future<void> resendPasswordResetEmail(String email) async {
    try {
      await AuthenticationRepository.instance.sendPasswordResetEmail(email);
      // Removed controller snackbar, feedback handled in screen
    } on FirebaseAuthException catch (e) {
      final message = handleFirebaseAuthError(e.code);
      Get.snackbar(
        'Error',
        message,
        backgroundColor: Colors.red.withOpacity(0.2),
        colorText: Colors.black,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
        backgroundColor: Colors.red.withOpacity(0.2),
        colorText: Colors.black,
      );
    }
  }

  /// Handle Firebase Auth error codes
  String handleFirebaseAuthError(String code) {
    switch (code) {
      case "user-not-found":
        return "The email address you entered is not associated with an account.";
      case "invalid-email":
        return "The email address is not valid.";
      case "too-many-requests":
        return "Too many requests. Try again later.";
      default:
        return "An error occurred. Please try again.";
    }
  }
}
