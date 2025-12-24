import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Models for API responses
class InflationRate {
  final String country;
  final String period;
  final double rate;

  InflationRate({
    required this.country,
    required this.period,
    required this.rate,
  });

  factory InflationRate.fromJson(Map<String, dynamic> json) {
    return InflationRate(
      country: json['country'] ?? '',
      period: json['period'] ?? '',
      rate: (json['rate'] ?? 0.0).toDouble(),
    );
  }
}

class CPIData {
  final String country;
  final List<CPIEntry> entries;

  CPIData({
    required this.country,
    required this.entries,
  });
}

class CPIEntry {
  final String date;
  final double value;

  CPIEntry({
    required this.date,
    required this.value,
  });
}

/// Service for fetching inflation data from external APIs
class InflationApiService {
  final http.Client _client;
  final SharedPreferences _prefs;

  InflationApiService({
    http.Client? client,
    required SharedPreferences prefs,
  })  : _client = client ?? http.Client(),
        _prefs = prefs;

  /// Get current inflation rate for a country
  /// Uses API Ninjas Inflation API
  /// Returns cached value if available and not expired
  Future<double?> getInflationRate(String country) async {
    try {
      // Check cache first
      final cached = await _getCachedInflationRate(country);
      if (cached != null) {
        return cached;
      }

      // If no API key, return null (fallback to manual)
      if (ApiConfig.apiNinjasKey.isEmpty) {
        return null;
      }

      final url = Uri.parse(
        '${ApiConfig.apiNinjasBaseUrl}${ApiConfig.apiNinjasInflationEndpoint}?country=$country',
      );

      final response = await _client.get(
        url,
        headers: {
          'X-Api-Key': ApiConfig.apiNinjasKey,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final inflationRate = InflationRate.fromJson(data[0]);
          
          // Cache the result
          await _cacheInflationRate(country, inflationRate.rate);
          
          return inflationRate.rate;
        }
      } else if (response.statusCode == 401) {
        // Invalid API key
        return null;
      }
    } catch (e) {
      // Silently fail - return null to allow fallback
      return null;
    }

    return null;
  }

  /// Get historical inflation data
  /// Returns list of inflation rates for the specified number of months
  Future<List<double>> getHistoricalInflation(
    String country,
    int months,
  ) async {
    try {
      if (ApiConfig.apiNinjasKey.isEmpty) {
        return [];
      }

      final url = Uri.parse(
        '${ApiConfig.apiNinjasBaseUrl}${ApiConfig.apiNinjasInflationEndpoint}?country=$country',
      );

      final response = await _client.get(
        url,
        headers: {
          'X-Api-Key': ApiConfig.apiNinjasKey,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final rates = data
            .take(months)
            .map((json) => InflationRate.fromJson(json))
            .map((rate) => rate.rate)
            .toList();
        return rates;
      }
    } catch (e) {
      // Silently fail
    }

    return [];
  }

  /// Get Consumer Price Index (CPI) data from Econdb
  /// Returns CPI values for historical analysis
  Future<List<double>> getCPI(String country) async {
    try {
      // Map country to Econdb series code
      final seriesCode = _getCountrySeriesCode(country);
      if (seriesCode == null) return [];

      final url = Uri.parse(
        '${ApiConfig.econdbBaseUrl}/?format=json&series_code=$seriesCode',
      );

      final response = await _client.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Parse Econdb response format
        // Note: Actual parsing depends on Econdb response structure
        // This is a placeholder - adjust based on actual API response
        return [];
      }
    } catch (e) {
      // Silently fail
    }

    return [];
  }

  /// Calculate price prediction based on inflation rate
  /// Uses compound inflation formula: futurePrice = currentPrice * (1 + inflationRate/100)^months
  double calculatePricePrediction(
    double currentPrice,
    double inflationRate,
    int months,
  ) {
    if (inflationRate == 0 || months == 0) return currentPrice;
    
    final monthlyRate = inflationRate / 100 / 12; // Convert annual to monthly
    // Use compound interest formula: P * (1 + r)^n
    return currentPrice * math.pow(1 + monthlyRate, months);
  }

  /// Calculate multiple price predictions (for next 3 months)
  /// Each prediction compounds from the previous month
  List<double> calculatePricePredictions(
    double currentPrice,
    double inflationRate,
    int count,
  ) {
    if (inflationRate == 0 || count == 0) {
      return List.filled(count, currentPrice);
    }
    
    final monthlyRate = inflationRate / 100 / 12;
    return List.generate(count, (index) {
      // Compound from base price for each month ahead
      return currentPrice * math.pow(1 + monthlyRate, index + 1);
    });
  }

  /// Cache inflation rate with timestamp
  Future<void> _cacheInflationRate(String country, double rate) async {
    try {
      final key = 'inflation_rate_${country.toLowerCase()}';
      final timestampKey = '${key}_timestamp';
      
      await _prefs.setDouble(key, rate);
      await _prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Silently fail
    }
  }

  /// Get cached inflation rate if not expired
  Future<double?> _getCachedInflationRate(String country) async {
    try {
      final key = 'inflation_rate_${country.toLowerCase()}';
      final timestampKey = '${key}_timestamp';
      
      final cachedRate = _prefs.getDouble(key);
      final timestamp = _prefs.getInt(timestampKey);
      
      if (cachedRate != null && timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        
        // Check if cache is still valid (within 24 hours)
        if (now.difference(cacheTime) < ApiConfig.cacheDuration) {
          return cachedRate;
        }
      }
    } catch (e) {
      // Silently fail
    }

    return null;
  }

  /// Map country name to Econdb series code
  String? _getCountrySeriesCode(String country) {
    final countryMap = {
      'Philippines': 'CPI_PH',
      'United States': 'CPI_US',
      'United Kingdom': 'CPI_GB',
      // Add more countries as needed
    };

    return countryMap[country];
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

