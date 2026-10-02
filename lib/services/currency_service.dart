// lib/services/currency_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  double? _cachedUsdPerPkr;
  DateTime? _cacheTime;
  final Duration _cacheDuration = const Duration(minutes: 10);
  // Fallback: 1 USD = 280 PKR => usdPerPkr = 1/280 ≈ 0.0035714
  final double _fallbackUsdPerPkr = 1 / 280.0;

  /// Returns the USD equivalent of the given PKR amount.
  Future<double> getUsdFromPkr(double pkrAmount) async {
    final usdPerPkr = await _getUsdPerPkrRate();
    return pkrAmount * usdPerPkr;
  }

  /// Fetches the current USD per PKR exchange rate.
  Future<double> _getUsdPerPkrRate() async {
    // Use cached rate if still valid
    if (_cachedUsdPerPkr != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedUsdPerPkr!;
      }
    }

    try {
      // Free API – no key required for limited requests
      final url = Uri.parse('https://api.exchangerate-api.com/v4/latest/PKR');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rate = data['rates']['USD'] as double?;
        if (rate != null && rate > 0) {
          _cachedUsdPerPkr = rate;
          _cacheTime = DateTime.now();
          return rate;
        } else {
          throw Exception('Invalid rate from API');
        }
      } else {
        throw Exception('API returned status ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ CurrencyService: Failed to fetch rate, using fallback. Error: $e');
      return _fallbackUsdPerPkr;
    }
  }
}