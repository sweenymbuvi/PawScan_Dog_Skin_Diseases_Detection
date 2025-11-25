import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:pawscan/core/utils/helper.dart';
import 'package:pawscan/features/auth/data/repository/authentication_repository.dart';
import 'package:pawscan/features/auth/presentation/screens/signin/signin_screen.dart';

class MailVerificationController extends GetxController {
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    //sendVerificationEmail();
    // setTimeForAutoRedirect();
  }

  Future<void> sendVerificationEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      await AuthenticationRepository.instance.sendEmailVerification();
      Get.snackbar(
        'Success',
        'Verification email sent!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send verification email',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // void setTimeForAutoRedirect() {
  //   _timer = Timer.periodic(Duration(seconds: 3), (timer) async {
  //     await FirebaseAuth.instance.currentUser?.reload();
  //     final user = FirebaseAuth.instance.currentUser;
  //     if (user != null && user.emailVerified) {
  //       timer.cancel();
  //       // Redirect to the dashboard
  //       Get.offAll(() => const LoginScreen());
  //     }
  //   });
  // }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void manuallyCheckEmailVerificationStatus() async {
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      _timer?.cancel();
      Get.off(() => const SigninScreen());
    } else {
      Helper.errorSnackBar(
        title: "Oh Snap!",
        message: "Email not verified yet.",
      );
    }
  }
}
