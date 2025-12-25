/// Central export file for all providers
/// Import this file to get access to all providers
export 'auth_provider.dart';
export 'user_provider.dart';
export 'transaction_provider.dart';
export 'budget_provider.dart';
export 'inflation_provider.dart';
export 'prediction_provider.dart';
export 'analytics_provider.dart' show 
  MonthlySpendingData, 
  CategorySpendingData,
  monthlySpendingWithNamesProvider,
  categorySpendingWithColorsProvider,
  analyticsExpensePredictionsProvider,
  inflationImpactProvider,
  categorySpendingAnalyticsProvider,
  monthlySpendingTrendProvider;
export 'notification_provider.dart';
export 'upcoming_bills_provider.dart';
export 'bill_provider.dart';
export 'suggestion_provider.dart';
export 'preferences_provider.dart';
export '../models/upcoming_bill_model.dart' show UpcomingBillModel;
export '../models/bill_model.dart' show BillModel;

