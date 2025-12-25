🧠 GLOBAL ARCHITECTURE (MANDATORY)
📌 CORE RULE (NON-NEGOTIABLE)
❌ NO UI screen should directly access Firebase
❌ NO Firebase calls inside Widgets

✅ ALL data flow must be:
UI → Provider → Service → Firebase

🔐 AUTHENTICATION (Firebase Auth)

Use Firebase Authentication

Supported methods:

Email / Password

Google Sign-In

Auth state must be globally observable

🗄️ DATABASE (Firebase Firestore)

Use Cloud Firestore

Structure must be user-scoped

Offline persistence enabled

No hardcoded data inside UI

🔔 NOTIFICATIONS

Use Firebase Cloud Messaging (FCM)

Notifications must deep-link to screens

🔄 STATE MANAGEMENT

Use Riverpod (preferred) or Provider

Every screen consumes data ONLY via providers

🧩 REQUIRED SERVICES LAYER

Create and use the following service files:

auth_service.dart
transaction_service.dart
budget_service.dart
inflation_service.dart
prediction_service.dart
notification_service.dart


Each service:

Handles Firebase calls

Handles business logic

Returns clean models

NO UI logic

🧭 SCREEN-BY-SCREEN WORKFLOW (FOLLOW EXACTLY)
1️⃣ Splash Screen
🔄 Workflow

App launches

Check Firebase Auth state

Decide next screen

📦 Data Source

FirebaseAuth.currentUser

🔗 Dependencies

AuthService

UserProvider

🔀 Navigation
Splash
 ├── User authenticated → Home / Dashboard
 └── No user → Onboarding

2️⃣ Onboarding Screen
🔄 Workflow

User swipes intro slides

User taps Skip or Finish

Save onboarding completion locally

📦 Data Source

SharedPreferences (local only)

🔗 Dependencies

None (UI only)

Optional: OnboardingProvider

🔀 Navigation
Onboarding → Login

3️⃣ Login / Signup Screen
🔄 Workflow

User enters credentials

Validate input

Authenticate using Firebase Auth

Create Firestore user document if new

📦 Data Source

Firebase Auth

Firestore /users/{userId}

🔗 Dependencies

AuthService

UserProvider

🔀 Navigation
Login / Signup → Home / Dashboard

4️⃣ 🏠 Home / Dashboard (CRITICAL SCREEN)
🔄 Workflow (STRICT ORDER)

Load authenticated user profile

Fetch transactions from Firestore

Compute total balance

Fetch inflation data

Run prediction logic

Render dashboard widgets

📦 Dashboard Data Mapping
Dashboard Section	Firebase Source
Total Balance	/users/{uid}/transactions
Category Chart	/users/{uid}/transactions
Inflation Alerts	/inflation_items
Expense Predictions	PredictionService
Recent Transactions	/users/{uid}/transactions
🔗 Dependencies

TransactionProvider

InflationProvider

PredictionProvider

BudgetProvider

🔀 Navigation
Dashboard
 ├── Category tap → Expenses List (filtered)
 ├── Inflation alert → Inflation Tracker
 └── Add button → Add Expense / Income

5️⃣ Add Expense / Income Screen
🔄 Workflow

User fills form

Validate inputs

Save transaction to Firestore

Update providers

Navigate back

📦 Data Source

Firestore /users/{uid}/transactions

🔗 Dependencies

TransactionProvider

TransactionService

🔁 Side Effects

Recalculate total balance

Update budget usage

Update predictions

6️⃣ Expenses / Income List Screen
🔄 Workflow

Load transactions from Firestore

Apply filters and search

Display list

📦 Data Source

Firestore /users/{uid}/transactions

🔗 Dependencies

TransactionProvider

Optional FilterProvider

🔀 Navigation
Expenses List
 ├── Tap item → Transaction Detail
 └── Swipe → Edit / Delete

7️⃣ Budget Planner Screen
🔄 Workflow

Load budgets from Firestore

Compare budgets vs transactions

Highlight overspending categories

📦 Data Source

Firestore /users/{uid}/budgets

Firestore /users/{uid}/transactions

🔗 Dependencies

BudgetProvider

TransactionProvider

⚠️ NOTE
Budget Planner MUST depend on transaction data

8️⃣ 📈 Inflation Tracker Screen
🔄 Workflow

Load tracked items

Fetch latest prices from API

Cache prices in Firestore

Compare historical data

Predict future prices

📦 Data Source

External Inflation API

Firestore /inflation_items

🔗 Dependencies

InflationProvider

PredictionService

🔀 Navigation
Inflation Tracker
 ├── Tap item → Inflation Detail
 └── Add item → Track new item

9️⃣ Smart Suggestions Screen
🔄 Workflow

Detect items with high inflation

Search cheaper alternatives

Sort by price or distance

📦 Data Source

Inflation data

Optional Google Maps / Places API

🔗 Dependencies

InflationProvider

LocationService

🔟 Analytics / Reports Screen
🔄 Workflow

Aggregate transactions

Generate charts

Predict future spending

📦 Data Source

Firestore /users/{uid}/transactions

PredictionService

🔗 Dependencies

AnalyticsProvider

1️⃣1️⃣ Settings / Profile Screen
🔄 Workflow

Load user profile

Update preferences

Save to Firestore

📦 Data Source

Firestore /users/{uid}

🔗 Dependencies

UserProvider

1️⃣2️⃣ Notifications (BACKGROUND – FCM)
🔄 Workflow

Detect trigger condition

Send push notification

Deep-link user to screen

📦 Data Source

Firebase Cloud Messaging

🔗 Dependencies

BudgetService

InflationService

PredictionService

NotificationService

🧩 FIREBASE DEPENDENCY SUMMARY
Transactions
 ├── Dashboard
 ├── Budget Planner
 ├── Analytics
 └── Predictions

Inflation
 ├── Dashboard
 ├── Inflation Tracker
 └── Smart Suggestions

✅ FINAL CODING RULES

Clean architecture only

Feature-based folders

Providers handle state

Services handle Firebase

No business logic in widgets

Comment WHY each logic exists