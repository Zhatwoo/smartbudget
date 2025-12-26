import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/preferences_service.dart';
import 'inflation_provider.dart';

/// Preferences Service Provider
final preferencesServiceProvider = FutureProvider<PreferencesService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return PreferencesService(prefs);
});

/// Currency Provider
final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  return CurrencyNotifier(ref);
});

class CurrencyNotifier extends StateNotifier<String> {
  final Ref _ref;
  PreferencesService? _prefsService;

  CurrencyNotifier(this._ref) : super('PHP (₱)') {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    try {
      _prefsService = await _ref.read(preferencesServiceProvider.future);
      state = _prefsService!.getCurrency();
    } catch (e) {
      // Use default
    }
  }

  Future<void> setCurrency(String currency) async {
    try {
      _prefsService ??= await _ref.read(preferencesServiceProvider.future);
      await _prefsService!.setCurrency(currency);
      state = currency;
    } catch (e) {
      // Silently fail
    }
  }
}

/// Dark Mode Provider
final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier(ref);
});

class DarkModeNotifier extends StateNotifier<bool> {
  final Ref _ref;
  PreferencesService? _prefsService;

  DarkModeNotifier(this._ref) : super(false) {
    _loadDarkMode();
  }

  Future<void> _loadDarkMode() async {
    try {
      _prefsService = await _ref.read(preferencesServiceProvider.future);
      state = _prefsService!.getDarkMode();
    } catch (e) {
      // Use default
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    try {
      _prefsService ??= await _ref.read(preferencesServiceProvider.future);
      await _prefsService!.setDarkMode(enabled);
      state = enabled;
    } catch (e) {
      // Silently fail
    }
  }
}

/// Notifications Enabled Provider
final notificationsEnabledProvider = StateNotifierProvider<NotificationsEnabledNotifier, bool>((ref) {
  return NotificationsEnabledNotifier(ref);
});

class NotificationsEnabledNotifier extends StateNotifier<bool> {
  final Ref _ref;
  PreferencesService? _prefsService;

  NotificationsEnabledNotifier(this._ref) : super(true) {
    _loadNotificationsEnabled();
  }

  Future<void> _loadNotificationsEnabled() async {
    try {
      _prefsService = await _ref.read(preferencesServiceProvider.future);
      state = _prefsService!.getNotificationsEnabled();
    } catch (e) {
      // Use default
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      _prefsService ??= await _ref.read(preferencesServiceProvider.future);
      await _prefsService!.setNotificationsEnabled(enabled);
      state = enabled;
    } catch (e) {
      // Silently fail
    }
  }
}

/// Budget Alerts Provider
final budgetAlertsProvider = StateNotifierProvider<BudgetAlertsNotifier, bool>((ref) {
  return BudgetAlertsNotifier(ref);
});

class BudgetAlertsNotifier extends StateNotifier<bool> {
  final Ref _ref;
  PreferencesService? _prefsService;

  BudgetAlertsNotifier(this._ref) : super(true) {
    _loadBudgetAlerts();
  }

  Future<void> _loadBudgetAlerts() async {
    try {
      _prefsService = await _ref.read(preferencesServiceProvider.future);
      state = _prefsService!.getBudgetAlertsEnabled();
    } catch (e) {
      // Use default
    }
  }

  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    try {
      _prefsService ??= await _ref.read(preferencesServiceProvider.future);
      await _prefsService!.setBudgetAlertsEnabled(enabled);
      state = enabled;
    } catch (e) {
      // Silently fail
    }
  }
}

/// Inflation Alerts Provider
final inflationAlertsProvider = StateNotifierProvider<InflationAlertsNotifier, bool>((ref) {
  return InflationAlertsNotifier(ref);
});

class InflationAlertsNotifier extends StateNotifier<bool> {
  final Ref _ref;
  PreferencesService? _prefsService;

  InflationAlertsNotifier(this._ref) : super(true) {
    _loadInflationAlerts();
  }

  Future<void> _loadInflationAlerts() async {
    try {
      _prefsService = await _ref.read(preferencesServiceProvider.future);
      state = _prefsService!.getInflationAlertsEnabled();
    } catch (e) {
      // Use default
    }
  }

  Future<void> setInflationAlertsEnabled(bool enabled) async {
    try {
      _prefsService ??= await _ref.read(preferencesServiceProvider.future);
      await _prefsService!.setInflationAlertsEnabled(enabled);
      state = enabled;
    } catch (e) {
      // Silently fail
    }
  }
}

/// Spending Alerts Provider
final spendingAlertsProvider = StateNotifierProvider<SpendingAlertsNotifier, bool>((ref) {
  return SpendingAlertsNotifier(ref);
});

class SpendingAlertsNotifier extends StateNotifier<bool> {
  final Ref _ref;
  PreferencesService? _prefsService;

  SpendingAlertsNotifier(this._ref) : super(true) {
    _loadSpendingAlerts();
  }

  Future<void> _loadSpendingAlerts() async {
    try {
      _prefsService = await _ref.read(preferencesServiceProvider.future);
      state = _prefsService!.getSpendingAlertsEnabled();
    } catch (e) {
      // Use default
    }
  }

  Future<void> setSpendingAlertsEnabled(bool enabled) async {
    try {
      _prefsService ??= await _ref.read(preferencesServiceProvider.future);
      await _prefsService!.setSpendingAlertsEnabled(enabled);
      state = enabled;
    } catch (e) {
      // Silently fail
    }
  }
}




