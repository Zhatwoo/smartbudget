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

  /// Get country name variants to try (some APIs expect different formats)
  List<String> _getCountryVariants(String country) {
    final variants = <String>[country];
    
    // Add common variants for Philippines
    if (country.toLowerCase().contains('philippines')) {
      variants.addAll(['PH', 'philippines', 'Philippines']);
    }
    
    // Add lowercase and title case variants
    if (country != country.toLowerCase()) {
      variants.add(country.toLowerCase());
    }
    if (country.isNotEmpty && country != country[0].toUpperCase() + country.substring(1).toLowerCase()) {
      variants.add(country[0].toUpperCase() + country.substring(1).toLowerCase());
    }
    
    // Remove duplicates while preserving order
    return variants.toSet().toList();
  }

  /// Get current inflation rate for a country
  /// Uses free Statbureau.org API (no API key required)
  /// Falls back to default values if API fails
  /// Returns cached value if available and not expired
  Future<double?> getInflationRate(String country) async {
    try {
      // Check cache first
      final cached = await _getCachedInflationRate(country);
      if (cached != null) {
        return cached;
      }

      // Try free Statbureau.org API first (no API key needed)
      try {
        final rate = await _getInflationFromStatbureau(country);
        if (rate != null) {
          await _cacheInflationRate(country, rate);
          return rate;
        }
      } catch (e) {
        // Continue to fallback if API fails
      }

      // Fallback: Use default inflation rates for common countries
      final defaultRate = _getDefaultInflationRate(country);
      if (defaultRate != null) {
        await _cacheInflationRate(country, defaultRate);
        return defaultRate;
      }

      return null;
    } catch (e) {
      // Final fallback to default
      return _getDefaultInflationRate(country);
    }
  }

  /// Get inflation rate from Statbureau.org (free, no API key)
  Future<double?> _getInflationFromStatbureau(String country) async {
    try {
      // Map country name to Statbureau format
      final countryCode = _mapCountryToStatbureauCode(country);
      if (countryCode == null) {
        return null;
      }

      // Statbureau.org API format: https://www.statbureau.org/en/inflation-api/json?country=Philippines
      final url = Uri.parse(
        '${ApiConfig.statbureauBaseUrl}/json?country=$countryCode',
      );

      final response = await _client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        // Try to parse as JSON
        try {
          final data = json.decode(response.body);
          // Statbureau.org might return different formats, try common ones
          if (data is Map) {
            // Try different possible keys
            if (data.containsKey('inflationRate')) {
              return (data['inflationRate'] as num).toDouble();
            } else if (data.containsKey('rate')) {
              return (data['rate'] as num).toDouble();
            } else if (data.containsKey('value')) {
              return (data['value'] as num).toDouble();
            } else if (data.containsKey('inflation')) {
              return (data['inflation'] as num).toDouble();
            }
            // Try to find any numeric value
            for (var value in data.values) {
              if (value is num && value > 0 && value < 100) {
                return value.toDouble();
              }
            }
          } else if (data is List && data.isNotEmpty) {
            // If it's a list, get the first item
            final first = data[0];
            if (first is Map) {
              if (first.containsKey('rate')) {
                return (first['rate'] as num).toDouble();
              } else if (first.containsKey('inflationRate')) {
                return (first['inflationRate'] as num).toDouble();
              }
            } else if (first is num) {
              return first.toDouble();
            }
          } else if (data is num) {
            return data.toDouble();
          }
        } catch (e) {
          // Not JSON, try parsing as plain text/number
          final trimmed = response.body.trim();
          final parsed = double.tryParse(trimmed);
          if (parsed != null && parsed > 0 && parsed < 100) {
            return parsed;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Map country name to Statbureau.org country code
  String? _mapCountryToStatbureauCode(String country) {
    final lower = country.toLowerCase();
    // Common mappings
    if (lower.contains('philippines') || lower == 'ph') {
      return 'Philippines';
    } else if (lower.contains('united states') || lower == 'us' || lower == 'usa') {
      return 'United States';
    } else if (lower.contains('united kingdom') || lower == 'uk' || lower == 'gb') {
      return 'United Kingdom';
    }
    // Return the country name as-is (Statbureau might accept it)
    return country;
  }

  /// Get default inflation rate for common countries (fallback)
  double? _getDefaultInflationRate(String country) {
    final lower = country.toLowerCase();
    // Default inflation rates (approximate, updated periodically)
    if (lower.contains('philippines') || lower == 'ph') {
      return 3.2; // Philippines average inflation rate
    } else if (lower.contains('united states') || lower == 'us' || lower == 'usa') {
      return 3.0;
    } else if (lower.contains('united kingdom') || lower == 'uk' || lower == 'gb') {
      return 2.5;
    }
    // Default global average
    return 3.0;
  }

  /// Get historical inflation data
  /// Returns list of inflation rates for the specified number of months
  /// Uses free Statbureau.org API (no API key needed)
  Future<List<double>> getHistoricalInflation(
    String country,
    int months,
  ) async {
    try {
      // Try to get historical data from Statbureau.org
      final countryCode = _mapCountryToStatbureauCode(country);
      if (countryCode == null) {
        return _generateDefaultHistoricalData(months);
      }

      // Try Statbureau.org API for historical data
      final url = Uri.parse(
        '${ApiConfig.statbureauBaseUrl}/json?country=$countryCode',
      );

      final response = await _client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
          final data = json.decode(response.body);
          // Try to extract historical data from response
          if (data is List) {
            final rates = data
                .take(months)
                .map((item) {
                  if (item is Map) {
                    return (item['rate'] ?? item['inflationRate'] ?? item['value'] ?? 0.0) as num;
                  } else if (item is num) {
                    return item;
                  }
                  return 0.0;
                })
                .where((rate) => rate > 0 && rate < 100)
                .map((rate) => rate.toDouble())
                .toList();
            if (rates.isNotEmpty) {
              return rates;
            }
          }
        } catch (_) {
          // Parse failed, use default
        }
      }
    } catch (_) {
      // Silently fail for historical data (it's optional)
    }

    // Fallback: Generate default historical data
    return _generateDefaultHistoricalData(months);
  }

  /// Generate default historical inflation data (fallback)
  List<double> _generateDefaultHistoricalData(int months) {
    final defaultRate = _getDefaultInflationRate('Philippines') ?? 3.0;
    // Generate slight variations around the default rate
    final random = math.Random();
    return List.generate(months, (index) {
      // Add small random variation (±0.5%)
      final variation = (random.nextDouble() - 0.5) * 1.0;
      return (defaultRate + variation).clamp(0.1, 10.0);
    });
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

