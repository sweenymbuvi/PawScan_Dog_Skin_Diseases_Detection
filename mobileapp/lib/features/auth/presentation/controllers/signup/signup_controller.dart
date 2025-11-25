import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pawscan/features/auth/data/models/user_model.dart';
import 'package:pawscan/features/auth/data/repository/authentication_repository.dart';
import 'package:pawscan/features/auth/data/repository/user_repository.dart';
import 'package:pawscan/features/auth/presentation/screens/signup/mail_verification.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  // Text editing controllers
  final email = TextEditingController();
  final password = TextEditingController();
  final fullName = TextEditingController();

  // Observable properties
  final Rx<String?> emailInUseError = Rx<String?>(null);
  var _isLoading = false.obs;

  // Repository instance
  final userRepo = Get.put(UserRepository());

  // Getter for isLoading
  bool get isLoading => _isLoading.value;

  /// Register user with email and password
  Future<void> registerUser(String email, String password) async {
    try {
      _isLoading(true);

      // Create user in Firebase Authentication
      await AuthenticationRepository.instance.createUserWithEmailAndPassword(
        email,
        password,
      );

      // Get the UID after registration
      final uid = AuthenticationRepository.instance.getUserID;

      // Send verification email
      await AuthenticationRepository.instance.sendEmailVerification();

      // Create user document in Firestore with UID as id
      UserModel newUser = UserModel(
        id: uid,
        email: email,
        fullName: fullName.text.trim(),
        password: password,
      );

      await userRepo.createUser(newUser);

      // Success message
      Get.snackbar(
        'Success',
        'Sign up successful! Verification email sent.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      clearFormFields();

      // Redirect to verification screen
      Get.off(() => const MailVerification());
    } catch (error) {
      // Handle specific email-in-use error
      if (error.toString().contains('email-already-in-use')) {
        handleSignUpError('An account already exists for this email');
      }

      Get.snackbar(
        'Error',
        error.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading(false);
    }
  }

  void handleSignUpError(String? signUpError) {
    emailInUseError.value = signUpError;
  }

  void clearFormFields() {
    email.clear();
    password.clear();
    fullName.clear();
    emailInUseError.value = null;
  }
}
