// lib/features/home/business account/stripe/stripe_webview_screen.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/custom_snackbar.dart';
import '../payment method/payment_methods_controller.dart';

class StripeWebViewScreen extends StatefulWidget {
  final String url;
  final String businessId;

  const StripeWebViewScreen({
    Key? key,
    required this.url,
    required this.businessId,
  }) : super(key: key);

  @override
  State<StripeWebViewScreen> createState() => _StripeWebViewScreenState();
}

class _StripeWebViewScreenState extends State<StripeWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _onboardingComplete = false;
  bool _isFinalizing = false;
  bool _showManualButton = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
            print('[StripeWebView] Loading: $url');
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
            print('[StripeWebView] Finished: $url');
            _checkUrlForCompletion(url);
            _maybeShowManualButton(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            print('[StripeWebView] Navigation request: $url');

            // ✅ FIXED: Only check for return URL, no text detection
            if (url.startsWith('bookify://stripe-return') ||
                url.startsWith('https://bookify.app/stripe-return')) {
              print('[StripeWebView] Return URL detected — onboarding complete');
              _onOnboardingComplete();
              return NavigationDecision.prevent;
            }

            // ✅ Also detect Stripe's native completion URLs
            if (url.contains('/connect/return') ||
                url.contains('/setup/complete') ||
                url.contains('/onboarding/complete')) {
              print('[StripeWebView] Stripe completion URL detected: $url');
              _onOnboardingComplete();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('[StripeWebView] Resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _checkUrlForCompletion(String url) {
    if (_onboardingComplete) return;

    // ✅ FIXED: Only check for specific return patterns
    if (url.contains('bookify://stripe-return') ||
        url.contains('https://bookify.app/stripe-return') ||
        url.contains('/connect/return') ||
        url.contains('/setup/complete') ||
        url.contains('/onboarding/complete')) {
      print('[StripeWebView] Completion URL detected: $url');
      _onOnboardingComplete();
    }
  }

  void _maybeShowManualButton(String url) {
    if (_onboardingComplete || _showManualButton) return;

    // Show manual button after user has been on Stripe pages for a while
    if (url.contains('connect.stripe.com') &&
        !url.contains('/setup/e/') &&
        !url.contains('/onboarding/complete')) {
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted && !_onboardingComplete) {
          setState(() => _showManualButton = true);
        }
      });
    }
  }

  void _onOnboardingComplete() async {
    if (_onboardingComplete) return;
    _onboardingComplete = true;

    if (!mounted) return;

    setState(() {
      _isFinalizing = true;
      _isLoading = false;
      _showManualButton = false;
    });

    print('[StripeWebView] Starting finalization...');

    try {
      final controller = Get.find<PaymentMethodsController>();
      await controller.finalizeFromWebView(widget.businessId);

      print('[StripeWebView] Finalization complete');

      // ✅ Check actual status
      if (controller.stripeChargesEnabled.value &&
          controller.stripePayoutsEnabled.value) {
        AppSnackbar.success('Stripe account connected successfully!');
      } else {
        AppSnackbar.info('Stripe account saved. Please complete the remaining requirements.');
      }
    } catch (e) {
      print('[StripeWebView] Finalization error: $e');
      AppSnackbar.info('Stripe account saved. It may take a moment to fully activate.');
    } finally {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        Get.back(result: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isFinalizing
          ? null
          : AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textHeadline),
          onPressed: _showExitDialog,
        ),
        title: const Text(
          'Connect Stripe Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textHeadline,
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),

          if (_isLoading && !_isFinalizing)
            const LinearProgressIndicator(
              color: AppColors.primaryPurple,
              backgroundColor: Colors.transparent,
            ),

          if (_isFinalizing)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                        color: AppColors.primaryPurple),
                    const SizedBox(height: 24),
                    const Text(
                      'Connecting your Stripe account...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHeadline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait, this takes a few seconds',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_showManualButton && !_isFinalizing && !_onboardingComplete)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _onOnboardingComplete,
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.white),
                  label: const Text(
                    'I\'ve completed the Stripe setup',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Exit Setup?'),
        content: const Text(
          'Your Stripe account setup is not complete yet. '
              'You can return to finish it later by tapping "Add Payment Method" again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Continue Setup'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.back(result: false);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deleteColor),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}