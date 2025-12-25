import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user preferences
/// Stores settings in SharedPreferences
class PreferencesService {
  static const String _keyCurrency = 'pref_currency';
  static const String _keyDarkMode = 'pref_dark_mode';
  static const String _keyNotificationsEnabled = 'pref_notifications_enabled';
  static const String _keyBudgetAlertsEnabled = 'pref_budget_alerts_enabled';
  static const String _keyInflationAlertsEnabled = 'pref_inflation_alerts_enabled';
  static const String _keySpendingAlertsEnabled = 'pref_spending_alerts_enabled';
  static const String _keyAutoBackupEnabled = 'pref_auto_backup_enabled';
  static const String _keyBackupFrequency = 'pref_backup_frequency';
  static const String _keyCloudSyncEnabled = 'pref_cloud_sync_enabled';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // Currency
  String getCurrency() {
    return _prefs.getString(_keyCurrency) ?? 'PHP (₱)';
  }

  Future<void> setCurrency(String currency) async {
    await _prefs.setString(_keyCurrency, currency);
  }

  // Dark Mode
  bool getDarkMode() {
    return _prefs.getBool(_keyDarkMode) ?? false;
  }

  Future<void> setDarkMode(bool enabled) async {
    await _prefs.setBool(_keyDarkMode, enabled);
  }

  // Notifications
  bool getNotificationsEnabled() {
    return _prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  // Budget Alerts
  bool getBudgetAlertsEnabled() {
    return _prefs.getBool(_keyBudgetAlertsEnabled) ?? true;
  }

  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    await _prefs.setBool(_keyBudgetAlertsEnabled, enabled);
  }

  // Inflation Alerts
  bool getInflationAlertsEnabled() {
    return _prefs.getBool(_keyInflationAlertsEnabled) ?? true;
  }

  Future<void> setInflationAlertsEnabled(bool enabled) async {
    await _prefs.setBool(_keyInflationAlertsEnabled, enabled);
  }

  // Spending Alerts
  bool getSpendingAlertsEnabled() {
    return _prefs.getBool(_keySpendingAlertsEnabled) ?? true;
  }

  Future<void> setSpendingAlertsEnabled(bool enabled) async {
    await _prefs.setBool(_keySpendingAlertsEnabled, enabled);
  }

  // Auto Backup
  bool getAutoBackupEnabled() {
    return _prefs.getBool(_keyAutoBackupEnabled) ?? true;
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    await _prefs.setBool(_keyAutoBackupEnabled, enabled);
  }

  // Backup Frequency
  String getBackupFrequency() {
    return _prefs.getString(_keyBackupFrequency) ?? 'Daily';
  }

  Future<void> setBackupFrequency(String frequency) async {
    await _prefs.setString(_keyBackupFrequency, frequency);
  }

  // Cloud Sync
  bool getCloudSyncEnabled() {
    return _prefs.getBool(_keyCloudSyncEnabled) ?? false;
  }

  Future<void> setCloudSyncEnabled(bool enabled) async {
    await _prefs.setBool(_keyCloudSyncEnabled, enabled);
  }
}


