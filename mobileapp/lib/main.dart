import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pawscan/features/auth/data/repository/authentication_repository.dart';
import 'package:pawscan/features/auth/data/repository/user_repository.dart';
import 'package:pawscan/features/auth/presentation/screens/signup/mail_verification.dart';
import 'package:pawscan/features/detection/presentation/screens/find_vets_screen.dart';
import 'core/theme.dart';
import 'package:get_storage/get_storage.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/auth/presentation/screens/signup/signup_screen.dart';
import 'features/auth/presentation/screens/signin/signin_screen.dart';
import 'features/auth/presentation/screens/forgot_password/forgot_password_screen.dart';
import 'features/dog_profile/presentation/screens/create_dog_profile_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'package:pawscan/features/detection/data/repository/detection_repository.dart';
import 'features/detection/presentation/screens/history_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Get.put(AuthenticationRepository());
  await GetStorage.init();
  Get.put<UserRepository>(UserRepository());
  Get.put<DetectionRepository>(DetectionRepository());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PawScan App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const OnboardingScreen()),
        GetPage(name: '/signup', page: () => const SignupScreen()),
        GetPage(name: '/signin', page: () => const SigninScreen()),
        GetPage(
          name: '/forgot-password',
          page: () => const ForgotPasswordScreen(),
        ),
        GetPage(
          name: '/create-dog-profile',
          page: () => const CreateDogProfileScreen(),
        ),
        GetPage(
          name: '/mail-verification',
          page: () => const MailVerification(),
        ),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/history', page: () => const HistoryScreen()),
        GetPage(name: '/profile', page: () => const ProfileScreen()),
        GetPage(name: '/find-vets', page: () => const FindVetsScreen()),
      ],
    );
  }
}
