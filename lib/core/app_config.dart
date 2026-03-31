class AppConfig {
  AppConfig._();

  static const String appName = 'Colastica XI';

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String cricApiBase = String.fromEnvironment(
    'CRICAPI_BASE_URL',
    defaultValue: 'https://api.cricapi.com/v1/',
  );
  static const String cricApiKey = String.fromEnvironment('CRICAPI_API_KEY');

  static const String premiumFeedBase = String.fromEnvironment('PREMIUM_FEED_BASE_URL');
  static const String premiumFeedApiKey = String.fromEnvironment('PREMIUM_FEED_API_KEY');

  static bool get hasSupabaseConfig => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  static bool get hasCricApiConfig => cricApiKey.isNotEmpty;
  static bool get hasPremiumFeedConfig => premiumFeedBase.isNotEmpty && premiumFeedApiKey.isNotEmpty;

  static List<String> validateForLaunch() {
    final errors = <String>[];

    if (!hasSupabaseConfig) {
      errors.add('Missing SUPABASE_URL or SUPABASE_ANON_KEY.');
    }

    if (!hasCricApiConfig && !hasPremiumFeedConfig) {
      errors.add(
        'Provide either CRICAPI_API_KEY or PREMIUM_FEED_BASE_URL with PREMIUM_FEED_API_KEY.',
      );
    }

    return errors;
  }
}
