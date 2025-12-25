import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

/// API Configuration
/// Stores API endpoints and keys for external services
class ApiConfig {
  // API Ninjas Configuration
  static const String apiNinjasBaseUrl = 'https://api.api-ninjas.com/v1';
  static const String apiNinjasInflationEndpoint = '/inflation';
  
  // SharedPreferences key for storing API key
  static const String _apiKeyPrefsKey = 'api_ninjas_key';
  
  // Get API Ninjas key from SharedPreferences, environment variable, or empty string
  // Priority: SharedPreferences > Environment Variable > Empty
  static Future<String> getApiNinjasKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedKey = prefs.getString(_apiKeyPrefsKey);
      if (storedKey != null && storedKey.isNotEmpty) {
        return storedKey;
      }
    } catch (e) {
      // If SharedPreferences fails, fall back to environment variable
    }
    
    // Fall back to environment variable
    return const String.fromEnvironment('API_NINJAS_KEY', defaultValue: '');
  }
  
  // Save API Ninjas key to SharedPreferences
  static Future<bool> saveApiNinjasKey(String key) async {
    try {
      // Trim whitespace and validate
      final trimmedKey = key.trim();
      if (trimmedKey.isEmpty) {
        return false;
      }
      
      // Basic validation: API Ninjas keys are typically alphanumeric with possible special chars
      // Check for suspicious patterns (like == in the middle, which might indicate a copy-paste error)
      if (trimmedKey.contains('==') && trimmedKey.indexOf('==') < trimmedKey.length - 2) {
        // == found not at the end - might be two keys concatenated or copy-paste error
        // But we'll still save it and let the API validate it
      }
      
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_apiKeyPrefsKey, trimmedKey);
      
      // Verify it was saved correctly
      if (success) {
        final saved = prefs.getString(_apiKeyPrefsKey);
        final verified = saved == trimmedKey;
        return verified;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Get API Ninjas key synchronously (for backward compatibility)
  // This will only return environment variable, not SharedPreferences
  // Use getApiNinjasKey() for full functionality
  @Deprecated('Use getApiNinjasKey() instead for SharedPreferences support')
  static String get apiNinjasKey {
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

