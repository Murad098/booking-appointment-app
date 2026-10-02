import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _isLoggedInKey = 'is_logged_in';

  static Future<SharedPreferences> _getInstance() async {
    return await SharedPreferences.getInstance();
  }

  // Onboarding methods
  static Future<void> setOnboardingCompleted() async {
    final prefs = await _getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await _getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  // Login session methods
  static Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await _getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await _getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Clear only login session (preserve onboarding status)
  static Future<void> clearLoginSession() async {
    final prefs = await _getInstance();
    await prefs.remove(_isLoggedInKey);
  }

  // Clear all preferences (for testing or complete reset)
  static Future<void> clearAll() async {
    final prefs = await _getInstance();
    await prefs.clear();
  }
}