# Inflation Tracker API Setup Guide

## Required API

### 1. **API Ninjas - Inflation API** (PRIMARY - Currently Used)

**Website:** https://api-ninjas.com  
**API Documentation:** https://api-ninjas.com/api/inflation

**Details:**
- **Base URL:** `https://api.api-ninjas.com/v1`
- **Endpoint:** `/inflation`
- **Authentication:** API Key required (X-Api-Key header)
- **Free Tier:** Available (with rate limits)
- **Purpose:** Get current and historical inflation rates by country

**How to Get API Key:**
1. Go to https://api-ninjas.com
2. Sign up for a free account
3. Navigate to API Keys section
4. Generate a new API key
5. Copy the key

**How to Configure:**
1. Set environment variable `API_NINJAS_KEY` when running the app:
   ```bash
   flutter run --dart-define=API_NINJAS_KEY=your_api_key_here
   ```

2. Or modify `lib/config/api_config.dart` temporarily (NOT recommended for production):
   ```dart
   static String get apiNinjasKey {
     return 'your_api_key_here'; // Remove before production!
   }
   ```

**API Request Example:**
```
GET https://api.api-ninjas.com/v1/inflation?country=Philippines
Headers:
  X-Api-Key: your_api_key_here
  Content-Type: application/json
```

**Response Format:**
```json
[
  {
    "country": "Philippines",
    "period": "2024-01",
    "rate": 2.8
  },
  ...
]
```

**Features Used:**
- ✅ Get current inflation rate
- ✅ Get historical inflation data
- ✅ Calculate price predictions based on inflation rate
- ✅ Auto-update prices when user refreshes

---

## Optional APIs (Mentioned but Not Fully Implemented)

### 2. **Econdb API** (Optional - For CPI Data)

**Website:** https://www.econdb.com  
**Base URL:** `https://www.econdb.com/api/series`

**Status:** Placeholder implementation exists but not fully integrated

**Purpose:** Get Consumer Price Index (CPI) data for more detailed analysis

---

### 3. **Statbureau.org** (Optional - Not Used)

**Website:** https://www.statbureau.org/en/inflation-api  
**Base URL:** `https://www.statbureau.org/en/inflation-api`

**Status:** Only mentioned in config, not implemented

---

## Current Implementation Status

### ✅ Fully Working (with API Ninjas):
- Get inflation rate by country
- Calculate price predictions
- Auto-update prices based on inflation rate
- Cache inflation data (24 hours)
- Historical inflation data retrieval

### ⚠️ Works Without API (Fallback Mode):
- Manual price entry
- Price tracking without API updates
- Default items initialization
- Price history display

### ❌ Not Implemented:
- Econdb CPI integration
- Statbureau.org integration
- Real-time price fetching for specific items

---

## Setup Instructions

### Step 1: Get API Ninjas Key
1. Visit https://api-ninjas.com
2. Create free account
3. Get your API key

### Step 2: Configure API Key

**Option A: Environment Variable (Recommended)**
```bash
# For development
flutter run --dart-define=API_NINJAS_KEY=your_key_here

# For production build
flutter build apk --dart-define=API_NINJAS_KEY=your_key_here
```

**Option B: Temporary Hardcode (Development Only)**
Edit `lib/config/api_config.dart`:
```dart
static String get apiNinjasKey {
  return 'your_api_key_here'; // ⚠️ Remove before production!
}
```

### Step 3: Test the API
1. Open the app
2. Go to Inflation Tracker
3. Pull down to refresh prices
4. If API key is valid, prices will update automatically

---

## API Rate Limits

**API Ninjas Free Tier:**
- Limited requests per day
- Check your account dashboard for current limits
- App caches data for 24 hours to minimize API calls

---

## Troubleshooting

### Error: "API key not configured"
- **Solution:** Set `API_NINJAS_KEY` environment variable or configure in `api_config.dart`

### Error: "Unable to fetch inflation data"
- **Solution:** 
  - Check internet connection
  - Verify API key is correct
  - Check API Ninjas account status
  - Verify country name is correct (default: "Philippines")

### Prices not updating
- **Solution:**
  - Check if API key is set
  - Pull down to refresh in Inflation Tracker
  - Check error messages in console
  - Verify API key has remaining quota

---

## Notes

- The app works **without API** but with limited features (manual price entry only)
- With API key, prices auto-update based on inflation rate
- Default items are created automatically even without API
- API calls are cached for 24 hours to save quota
- All price predictions are calculated locally using inflation rate from API




