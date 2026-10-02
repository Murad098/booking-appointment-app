import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../firebase_options.dart';
import '../../services/notification_service.dart';
import '../../services/reminder_service.dart';
import '../home/business account/business_home_screen.dart';
import '../home/home pages/home_page_one.dart';
import '../home/home pages/onboarding_controller.dart';
import '../../services/shared_preferences_service.dart';
import '../../services/user_service.dart';
import '../../features/login/login_screen.dart';
import '../../features/account type/account_type_screen.dart';
import '../home/personal account/personal_home_screen.dart';
import '../home/business account/business profile setup/business_profile_screen1.dart';
import '../home/Notifications screen/notifications_controller.dart';
import 'splash_controller.dart';
import 'no_internet_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late SplashController splash;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  bool _showNoInternet = false;
  bool _initializationDone = false;
  bool _showProgress = false;
  bool _progressComplete = false;

  @override
  void initState() {
    super.initState();

    // Progress animation controller (smooth from 0 to 1 over 2.5 seconds)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2, milliseconds: 500),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    // Listen for progress completion
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _progressComplete = true;
        });
        _checkAndNavigate();
      }
    });

    // Start the splash sequence
    _startSplashSequence();
  }

  // --------------------------------------------------------------------------
  // Start the splash animation and the background initialization
  // --------------------------------------------------------------------------
  Future<void> _startSplashSequence() async {
    // Create and start the animation controller
    splash = SplashController(this);
    splash.start();

    // Initialize OnboardingController
    if (!Get.isRegistered<OnboardingController>()) {
      Get.put(OnboardingController(), permanent: true);
    }

    // Check internet and initialize services
    final success = await _initializeServices();

    if (!success) {
      // No internet or initialization failed – show NoInternetScreen
      if (mounted) {
        setState(() {
          _showNoInternet = true;
          _initializationDone = false;
        });
      }
      return;
    }

    // Initialization succeeded
    if (mounted) {
      setState(() {
        _initializationDone = true;
      });
      _checkAndNavigate();
    }

    // Show the progress bar after the tagline fades in (~5 seconds)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_showNoInternet) {
        setState(() {
          _showProgress = true;
        });
        _progressController.forward();
      }
    });
  }

  // --------------------------------------------------------------------------
  // Check connectivity and initialize Firebase, Supabase, etc.
  // --------------------------------------------------------------------------
  Future<bool> _initializeServices() async {
    try {
      // 1. Check internet with timeout
      ConnectivityResult? connectivityResult;
      try {
        final result = await Connectivity().checkConnectivity().timeout(
          const Duration(seconds: 5),
          onTimeout: () => [ConnectivityResult.none],
        );
        connectivityResult = result.isNotEmpty ? result.first : ConnectivityResult.none;
      } catch (e) {
        print('Connectivity check error: $e');
        connectivityResult = ConnectivityResult.none;
      }

      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // 2. Initialize Firebase
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 10));
      }

      // 3. Initialize ReminderService
      await ReminderService.initialize();
      ReminderService.startForegroundCheck();

      // 4. Initialize NotificationService
      await NotificationService().initialize();

      // 5. Initialize Supabase
      await Supabase.initialize(
        url: 'https://xzwglkpjazvzajzlamlf.supabase.co',
        anonKey: 'sb_publishable_Xkoq6bNysg3df-GUa_vAJg_Exnx5if_',
      );

      return true;
    } catch (e) {
      print('Error initializing services: $e');
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // Retry when user presses "Try Again" on the NoInternetScreen
  // --------------------------------------------------------------------------
  Future<void> _retry() async {
    // Reset state
    setState(() {
      _showNoInternet = false;
      _initializationDone = false;
      _showProgress = false;
      _progressComplete = false;
    });

    // Dispose old controllers
    splash.dispose();
    _progressController.reset();

    // Restart the sequence
    await _startSplashSequence();
  }

  // --------------------------------------------------------------------------
  // Check if both initialization and progress are done, then navigate
  // --------------------------------------------------------------------------
  void _checkAndNavigate() {
    if (_initializationDone && _progressComplete && mounted) {
      _handleNavigation();
    }
  }

  // --------------------------------------------------------------------------
  // Navigation after splash (login check, role, etc.)
  // --------------------------------------------------------------------------
  Future<void> _handleNavigation() async {
    final isLoggedIn = await SharedPreferencesService.isLoggedIn();

    if (isLoggedIn) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final hasRole = await UserService.hasUserRole(user.uid);
        if (hasRole) {
          final role = await UserService.getUserRole(user.uid);
          if (role == 'business') {
            final isProfileCompleted = await UserService.isBusinessProfileCompleted(user.uid);
            if (isProfileCompleted) {
              Get.offAll(
                    () => BusinessHomeScreen(),
                binding: BindingsBuilder(() {
                  Get.put(NotificationsController());
                }),
              );
            } else {
              Get.offAll(
                    () => BusinessProfileStep1(),
                binding: BindingsBuilder(() {
                  Get.put(NotificationsController());
                }),
              );
            }
          } else if (role == 'personal') {
            Get.offAll(
                  () => const PersonalHomeScreen(),
              binding: BindingsBuilder(() {
                Get.put(NotificationsController(), permanent: true);
              }),
            );
          } else {
            Get.offAll(() => AccountTypeScreen());
          }
        } else {
          Get.offAll(() => AccountTypeScreen());
        }
      } else {
        await SharedPreferencesService.setLoggedIn(false);
        Get.offAll(() => const LoginScreen());
      }
    } else {
      final isOnboardingCompleted = await SharedPreferencesService.isOnboardingCompleted();
      if (isOnboardingCompleted) {
        Get.offAll(() => const LoginScreen());
      } else {
        Get.off(() => const HomePageOne());
      }
    }
  }

  @override
  void dispose() {
    splash.dispose();
    _progressController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Build – either show splash with loading bar at bottom or NoInternetScreen
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // If no internet or init failed, show the dedicated NoInternetScreen
    if (_showNoInternet) {
      return NoInternetScreen(onRetry: _retry);
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Centered content (logo, title, tagline)
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO
                    FadeTransition(
                      opacity: splash.calendarFade,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/png/calendar1.png',
                            width: size.width * 0.30,
                          ),
                          Positioned(
                            top: size.width * 0.07,
                            child: ScaleTransition(
                              scale: splash.tickScale,
                              child: Image.asset(
                                'assets/png/tick1.png',
                                width: size.width * 0.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // BOOKIFY TEXT
                    AnimatedBuilder(
                      animation: splash.controller,
                      builder: (context, child) {
                        const text = "Bookify";
                        double progress = (splash.controller.value * 3.0);
                        int count = (progress * text.length)
                            .clamp(0, text.length)
                            .toInt();
                        String visibleText = text.substring(0, count);

                        return Text(
                          visibleText,
                          style: TextStyle(
                            fontSize: size.width * 0.09,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF162161),
                          ),
                        );
                      },
                    ),

                    // TAGLINE
                    FadeTransition(
                      opacity: splash.taglineFade,
                      child: Text(
                        "Schedule Made Easy",
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    // Extra bottom space when loading bar is shown to avoid overlap
                    if (_showProgress) const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // LOADING BAR AT BOTTOM (centered, 75% width, solid color, no gradient)
            // -----------------------------------------------------------------
            if (_showProgress)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: SizedBox(
                    width: size.width * 0.5,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Solid progress bar with shadow
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: size.width * 0.75 * _progressAnimation.value,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF162161), // solid dark blue
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        // Percentage text
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            final percent = (_progressAnimation.value * 100).round();
                            return Text(
                              '$percent%',
                              style: TextStyle(
                                fontSize: size.width * 0.04,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF162161),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}