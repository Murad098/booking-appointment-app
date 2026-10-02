import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../app/app_colors.dart';

class NoInternetScreen extends StatefulWidget {
  final VoidCallback onRetry;
  const NoInternetScreen({super.key, required this.onRetry});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Listen for connectivity changes
    _listenForConnectivity();
  }

  void _listenForConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      print('Connectivity changed: $result'); // Debug log
      if (result != ConnectivityResult.none) {
        // Internet came back, automatically retry
        if (mounted && !_isChecking) {
          _autoRetry();
        }
      }
    });
  }

  Future<void> _autoRetry() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    // Small delay to ensure connection is stable
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      widget.onRetry();
    }
  }

  Future<void> _checkInternetAndRetry() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();

    print('Manual retry connectivity result: $connectivityResult'); // Debug log

    if (connectivityResult != ConnectivityResult.none) {
      // Internet is available, call the retry callback
      widget.onRetry();
    } else {
      // Still no internet
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection found. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Professional Animated No Internet Icon with gradient background
                Container(
                  width: size.width * 0.35,
                  height: size.width * 0.35,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey.shade50,
                        Colors.grey.shade100,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.signal_wifi_off_rounded,
                    size: size.width * 0.18,
                    color: AppColors.primaryPurple.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 40),

                // Professional Title
                Text(
                  'No Internet Connection',
                  style: TextStyle(
                    fontSize: size.width * 0.07,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Professional Description Container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Please check your internet connection and try again.',
                    style: TextStyle(
                      fontSize: size.width * 0.04,
                      color: Colors.grey.shade700,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 48),

                // Professional Retry Button with gradient
                SizedBox(
                  width: size.width * 0.6,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _checkInternetAndRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                          if (states.contains(WidgetState.disabled)) {
                            return Colors.grey.shade400;
                          }
                          return AppColors.primaryPurple;
                        },
                      ),
                    ),
                    child: _isChecking
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh_rounded, size: 20),
                        const SizedBox(width: 10),
                        const Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Professional Auto-retry Hint Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sync_rounded,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Auto-retry when connection restored',
                        style: TextStyle(
                          fontSize: size.width * 0.03,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Professional Help Text
                Text(
                  'Check your Wi-Fi or mobile data settings',
                  style: TextStyle(
                    fontSize: size.width * 0.032,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}