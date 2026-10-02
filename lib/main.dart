import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'features/Auth/auth_controller.dart';
import 'features/home/Notifications screen/notifications_controller.dart';
import 'features/home/Notifications screen/notifications_screen.dart';
import 'features/home/appointment_details/appointment_details_screen.dart';
import 'features/home/business account/branch management/branch_create_screen.dart';
import 'features/home/business account/branch management/branch_list_screen.dart';
import 'features/home/chat system/chat/chat_list_screen.dart';
import 'features/home/chat system/chat/chat_screen.dart';
import 'features/home/home pages/home_page_one.dart';
import 'features/home/home pages/home_page_two.dart';
import 'features/home/home pages/home_page_three.dart';
import 'features/home/personal account/Rating screen/rating_screen.dart';
import 'features/home/personal account/Rating screen/rating_success_screen.dart';
import 'features/login/login_screen.dart';
import 'features/signup/signup_screen.dart';
import 'features/splash/splash_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[FCM Background] ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(AuthController(), permanent: true);

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bookify',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff3B82F6),
        ),
      ),
      initialRoute: '/splash', // 👈 now starts with SplashScreen
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/onboarding-1', page: () => const HomePageOne()),
        GetPage(name: '/onboarding-2', page: () => const HomePageTwo()),
        GetPage(name: '/onboarding-3', page: () => const HomePageThree()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/signup', page: () => const SignupScreen()),
        GetPage(name: '/branch-list', page: () => BranchListScreen()),
        GetPage(name: '/branch-create', page: () => BranchCreateScreen()),
        GetPage(name: '/rating', page: () => const RatingScreen()),
        GetPage(name: '/notifications', page: () => const NotificationsScreen(), binding: BindingsBuilder(() { Get.put(NotificationsController()); }),),
        GetPage(name: '/appointment-details', page: () => const AppointmentDetailsScreen(),),
        GetPage(name: '/rating-success', page: () => const RatingSuccessScreen(),),
        GetPage(name: '/chat-list', page: () => const ChatListScreen()),
        GetPage(name: '/chat', page: () => const ChatScreen()),
      ],
    );
  }
}