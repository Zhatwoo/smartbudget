# Data Isolation & Security Documentation

## Overview
This document explains how data isolation is enforced in the Smart Budget app to ensure each user can only access their own data.

## Data Isolation Architecture

### 1. Firebase Structure
All user data is stored in nested collections under the authenticated user's ID:
```
users/{userId}/
  ├── transactions/{transactionId}
  ├── budgets/{budgetId}
  ├── inflationItems/{itemId}
  ├── notifications/{notificationId}
  └── bills/{billId}
```

### 2. Security Rules
Firebase Security Rules enforce data isolation at the database level:
- **Path-based isolation**: Users can only access data under their own `users/{userId}` path
- **userId validation**: All documents must include `userId` field that matches the path
- **Immutable userId**: The `userId` field cannot be changed in updates
- **Authentication required**: All operations require authentication

### 3. Service Layer Security
All services implement:
- **User ID extraction**: Uses `FirebaseAuth.instance.currentUser?.uid`
- **Nested collection queries**: All queries use `users/{userId}/collection` structure
- **Data validation**: userId is added to all documents before saving
- **Double-check filtering**: Additional filtering by userId in data (defense in depth)

### 4. Shared Data (Live Inflation Information Only)
The ONLY shared data across all accounts is:
- **Inflation Rate**: Fetched from external API (Statbureau.org)
  - Not stored in Firestore
  - Cached locally per device (SharedPreferences)
  - Same rate for all users (it's public economic data)
  - Fetched fresh from API, not from other users' data

### 5. Per-User Data (Completely Isolated)
Each user has their own separate data:
- **Transactions**: Personal spending/income records
- **Budgets**: Personal budget limits and spending
- **Inflation Items**: Personal price tracking (each user tracks their own items)
- **Notifications**: Personal alerts and messages
- **Bills**: Personal bill reminders

### 6. Default Items Initialization
When a new user first opens the app:
- Default inflation items are created **per user** in their own collection
- Each user gets their own copy of default items
- Items are saved to `users/{userId}/inflationItems/`
- No shared default data between users

## Security Measures

### Firebase Rules Enforcement
1. **Path Validation**: `request.auth.uid == userId` ensures users can only access their path
2. **Data Validation**: `request.resource.data.userId == userId` ensures userId in data matches path
3. **Immutable Fields**: Rules prevent changing userId in updates
4. **Type Validation**: All fields are validated for correct types
5. **Required Fields**: All required fields must be present

### Service Layer Protection
1. **Authentication Check**: All operations check `currentUser != null`
2. **Explicit User ID**: Uses authenticated user's ID, never hardcoded
3. **Nested Collections**: All queries use user-specific paths
4. **Error Handling**: Returns empty data if user not authenticated

### Code-Level Security
1. **No Hardcoded User IDs**: All user IDs come from FirebaseAuth
2. **No Global Collections**: All data is under users/{userId}
3. **No Cross-User Queries**: Services never query across users
4. **Provider Isolation**: Riverpod providers are per-user (watch auth state)

## Verification Checklist

✅ **Transactions**: Isolated per user in `users/{userId}/transactions`
✅ **Budgets**: Isolated per user in `users/{userId}/budgets`
✅ **Inflation Items**: Isolated per user in `users/{userId}/inflationItems`
✅ **Notifications**: Isolated per user in `users/{userId}/notifications`
✅ **Bills**: Isolated per user in `users/{userId}/bills`
✅ **Inflation Rate**: Shared (from external API, not stored in Firestore)
✅ **Default Items**: Created per user, not shared
✅ **Firebase Rules**: Enforce path-based and data-based isolation
✅ **Service Layer**: All queries use authenticated user's ID
✅ **No Hardcoded Data**: All user-specific data comes from authenticated user

## Testing Data Isolation

To verify data isolation:
1. Create two test accounts
2. Add transactions/budgets/items to Account A
3. Log in as Account B
4. Verify Account B cannot see Account A's data
5. Verify Account B sees empty/their own data only
6. Verify both accounts see the same inflation rate (from API)

## Important Notes

- **Inflation Rate is Shared**: This is intentional - it's public economic data from external API
- **Inflation Items are Isolated**: Each user tracks their own items with their own prices
- **Caching is Per-Device**: SharedPreferences cache is local to device, not shared between users
- **No Global Collections**: All user data must be under users/{userId} path



