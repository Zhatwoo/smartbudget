/// API Configuration
/// Stores API endpoints and keys for external services
class ApiConfig {
  // API Ninjas Configuration
  static const String apiNinjasBaseUrl = 'https://api.api-ninjas.com/v1';
  static const String apiNinjasInflationEndpoint = '/inflation';
  
  // Get API Ninjas key from environment or use placeholder
  // In production, this should be stored securely (e.g., environment variables)
  // For now, users need to register at https://api-ninjas.com and get their own key
  static String get apiNinjasKey {
    // TODO: Replace with actual API key from environment variables or secure storage
    // For development, you can temporarily hardcode here, but remove before production
    return const String.fromEnvironment('API_NINJAS_KEY', defaultValue: '');
  }
  
  // Econdb API Configuration
  static const String econdbBaseUrl = 'https://www.econdb.com/api/series';
  
  // Statbureau.org Configuration
  static const String statbureauBaseUrl = 'https://www.statbureau.org/en/inflation-api';
  
  // Default country
  static const String defaultCountry = 'Philippines';
  
  // Cache duration (24 hours in milliseconds)
  static const Duration cacheDuration = Duration(hours: 24);
  
  // Rate limiting
  static const int maxRequestsPerMinute = 10;
}

