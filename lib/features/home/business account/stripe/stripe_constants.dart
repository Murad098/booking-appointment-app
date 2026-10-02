// lib/features/home/business account/stripe payment/stripe_constants.dart

class StripeConstants {
  // ✅ NO trailing slash!
  static const String baseUrl = 'stripe-connect-backend-production-dc13.up.railway.app';

  // ✅ Use getters to avoid double slash
  static String get createConnectedAccountEndpoint => '$baseUrl/createConnectedAccount';
  static String get createAccountLinkEndpoint => '$baseUrl/createAccountLink';
  static String get retrieveAccountStatusEndpoint => '$baseUrl/retrieveAccountStatus';
  static String get createPaymentIntentEndpoint => '$baseUrl/createPaymentIntent';
  static String get retrievePaymentIntentEndpoint => '$baseUrl/retrievePaymentIntent';

  // Publishable key (replace with your actual key)
  static const String publishableKey = 'pk_test_51TgeTEItplhpEWnolonvZgDhx0sIpIaBPHIol31CPBS35unNfBc16VM3Vdk4UE9jGlTSQgsNGo6AoCD9TMmO69hx00yO12Tc9p';

  // Status strings
  static const String statusPending = 'pending';
  static const String statusRestricted = 'restricted';
  static const String statusEnabled = 'enabled';
  static const String statusDisabled = 'disabled';

  static const String defaultCurrency = 'usd';
  static const double platformFeePercentage = 0;

  // ✅ Countries that support card_payments
  static const List<String> supportedCountries = ['US', 'GB', 'CA', 'AU', 'IE', 'NL', 'ES', 'IT', 'FR', 'DE'];

  // ✅ Default to US for Stripe compatibility
  static const String defaultCountry = 'US';

  static const Map<String, String> countryCurrencyMap = {
    'US': 'usd',
    'GB': 'gbp',
    'CA': 'cad',
    'AU': 'aud',
    'IE': 'eur',
    'NL': 'eur',
    'ES': 'eur',
    'IT': 'eur',
    'FR': 'eur',
    'DE': 'eur',
  };
}