import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../firebase_options.dart';
import '../../services/notification_service.dart';
import '../../services/reminder_service.dart';
import '../../app/app_colors.dart';
import 'splash_screen.dart';
import 'no_internet_screen.dart';

class InitialCheckScreen extends StatefulWidget {
  const InitialCheckScreen({super.key});

  @override
  State<InitialCheckScreen> createState() => _InitialCheckScreenState();
}

class _InitialCheckScreenState extends State<InitialCheckScreen> {
  bool _isChecking = true;
  bool _hasInternet = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInternetAndInitialize();

    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasInternet = results.any((result) => result != ConnectivityResult.none);
      if (hasInternet && !_hasInternet && !_isChecking) {
        // Internet came back, automatically retry
        _retry();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInternetAndInitialize() async {
    setState(() {
      _isChecking = true;
    });

    // First check internet - with timeout to prevent hanging
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

    final hasInternet = connectivityResult != ConnectivityResult.none;
    print('Initial check - Internet available: $hasInternet, result: $connectivityResult');

    if (hasInternet) {
      // Only initialize Firebase and other services if we have internet
      try {
        // Check if Firebase is already initialized
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ).timeout(const Duration(seconds: 10));
        }

        // Initialize reminder service
        await ReminderService.initialize();
        ReminderService.startForegroundCheck();

        // Initialize notifications
        await NotificationService().initialize();

        // Initialize Supabase
        await Supabase.initialize(
          url: 'https://xzwglkpjazvzajzlamlf.supabase.co',
          anonKey: 'sb_publishable_Xkoq6bNysg3df-GUa_vAJg_Exnx5if_',
        );

        print('All services initialized successfully');

        if (mounted) {
          setState(() {
            _hasInternet = true;
            _isChecking = false;
          });
        }
      } catch (e) {
        print('Error initializing services: $e');
        if (mounted) {
          setState(() {
            _hasInternet = false;
            _isChecking = false;
          });
        }
      }
    } else {
      // No internet - immediately show no internet screen
      if (mounted) {
        setState(() {
          _hasInternet = false;
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _retry() async {
    if (_isChecking) return;

    print('Retrying internet check...');
    await _checkInternetAndInitialize();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Show loading while checking internet - but with timeout protection
    if (_isChecking) {
      // Add automatic timeout to prevent infinite loading
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted && _isChecking) {
          print('Checking timed out - showing no internet screen');
          setState(() {
            _isChecking = false;
            _hasInternet = false;
          });
        }
      });

      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Professional Animated Logo Container with gradient and shadow
              Container(
                width: size.width * 0.35,
                height: size.width * 0.35,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryPurple.withOpacity(0.1),
                      AppColors.primaryPurple.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/png/bookify_transparent1.png',
                    width: size.width * 0.22,
                    height: size.width * 0.22,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Professional Loading Indicator
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryPurple,
                      AppColors.primaryPurple.withOpacity(0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Professional Loading Text
              Text(
                'Connecting to Bookify',
                style: TextStyle(
                  fontSize: size.width * 0.05,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 12),

              // Animated Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAnimatedDot(0),
                  _buildAnimatedDot(1),
                  _buildAnimatedDot(2),
                ],
              ),

              const SizedBox(height: 16),

              // Subtle Status Text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Please wait while we establish connection',
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show no internet screen if no connection
    if (!_hasInternet) {
      return NoInternetScreen(onRetry: _retry);
    }

    // Internet is available, show actual splash screen
    return const SplashScreen();
  }

  Widget _buildAnimatedDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.5 + (index * 0.2)),
        shape: BoxShape.circle,
      ),
    );
  }
}