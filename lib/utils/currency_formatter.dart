/// Utility class for formatting currency amounts
/// Extracts currency symbol from currency string and formats amounts
class CurrencyFormatter {
  /// Extract currency symbol from currency string
  /// Format: "PHP (₱)" -> "₱"
  /// Format: "USD ($)" -> "$"
  static String extractSymbol(String currencyString) {
    // Try to extract symbol from parentheses
    final regex = RegExp(r'\(([^)]+)\)');
    final match = regex.firstMatch(currencyString);
    if (match != null && match.groupCount >= 1) {
      return match.group(1) ?? '₱';
    }
    
    // Fallback: try to extract common currency symbols
    if (currencyString.contains('₱')) return '₱';
    if (currencyString.contains('\$')) return '\$';
    if (currencyString.contains('€')) return '€';
    if (currencyString.contains('£')) return '£';
    if (currencyString.contains('¥')) return '¥';
    
    // Default to PHP peso
    return '₱';
  }
  
  /// Format amount with currency symbol
  /// [amount] - The amount to format
  /// [currencyString] - The currency string (e.g., "PHP (₱)")
  /// [decimals] - Number of decimal places (default: 0)
  static String format(double amount, String currencyString, {int decimals = 0}) {
    final symbol = extractSymbol(currencyString);
    final formattedAmount = amount.toStringAsFixed(decimals);
    return '$symbol$formattedAmount';
  }
  
  /// Format amount with currency symbol and sign
  /// [amount] - The amount to format
  /// [currencyString] - The currency string (e.g., "PHP (₱)")
  /// [showSign] - Whether to show + for positive amounts (default: false)
  /// [decimals] - Number of decimal places (default: 0)
  static String formatWithSign(double amount, String currencyString, {bool showSign = false, int decimals = 0}) {
    final symbol = extractSymbol(currencyString);
    final formattedAmount = amount.abs().toStringAsFixed(decimals);
    final sign = amount < 0 ? '-' : (showSign ? '+' : '');
    return '$sign$symbol$formattedAmount';
  }
}




