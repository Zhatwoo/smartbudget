# 🚀 BUILD CHECKLIST - Smart Budget App

## ✅ **READY TO BUILD (Functional Features):**
- ✅ All screens functional
- ✅ Firebase authentication (Email, Gmail, Mobile)
- ✅ Forgot password functionality
- ✅ Dark mode
- ✅ Currency formatter
- ✅ Dynamic data (transactions, budgets, predictions)
- ✅ Push notifications setup
- ✅ No compilation errors
- ✅ No linter errors

---

## ⚠️ **BEFORE BUILDING - Required Fixes:**

### 🔴 **CRITICAL (Must Fix Before Build):**

#### 1. **iOS Firebase Configuration** ⚠️
**Status:** ❌ Missing
**File:** `ios/Runner/GoogleService-Info.plist`
**Action:** 
- Download from Firebase Console
- Place in `ios/Runner/` directory
- Required for iOS Firebase services (Auth, Firestore, FCM)

**Steps:**
1. Go to Firebase Console > Project Settings
2. Click "iOS app" tab
3. Download `GoogleService-Info.plist`
4. Place in `ios/Runner/` folder
5. Add to Xcode project (if needed)

---

#### 2. **Android Internet Permission** ⚠️
**Status:** ⚠️ May be missing
**File:** `android/app/src/main/AndroidManifest.xml`
**Action:** Add INTERNET permission if not present

**Check if this exists:**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

---

#### 3. **Android Signing Configuration** (For Release Build)
**Status:** ⚠️ Using debug keys
**File:** `android/app/build.gradle.kts`
**Action:** 
- For **testing/debugging**: Current setup is OK
- For **production release**: Need to add signing config

**Current (OK for testing):**
```kotlin
signingConfig = signingConfigs.getByName("debug")
```

**For Production:**
- Create keystore file
- Add signing config to `build.gradle.kts`
- See: https://docs.flutter.dev/deployment/android#signing-the-app

---

### 🟡 **RECOMMENDED (Should Fix):**

#### 4. **App Name & Icon**
**Status:** ⚠️ Using default
**Files:**
- `android/app/src/main/AndroidManifest.xml` - `android:label="smartbudget"`
- `ios/Runner/Info.plist` - `CFBundleDisplayName`

**Action:** Update to your desired app name

---

#### 5. **App Version**
**Status:** ✅ Set to `1.0.0+1`
**File:** `pubspec.yaml`
**Action:** Update if needed

---

#### 6. **Firebase Security Rules**
**Status:** ⚠️ Check if set
**Action:** 
- Go to Firebase Console > Firestore > Rules
- Ensure security rules are published
- See `FIREBASE RULES.md` for reference

---

### 🟢 **OPTIONAL (Future Enhancements):**

#### 7. **TODO Items** (Not blocking build)
- Image picker for receipts
- PDF export for analytics
- Edit transaction functionality
- Help screen

---

## 🚀 **BUILD COMMANDS:**

### **For Testing (Debug Build):**
```bash
# Android
flutter build apk --debug
# or
flutter build appbundle --debug

# iOS
flutter build ios --debug
```

### **For Production (Release Build):**
```bash
# Android (requires signing config)
flutter build apk --release
# or
flutter build appbundle --release

# iOS (requires Apple Developer account)
flutter build ios --release
```

---

## ✅ **QUICK CHECKLIST:**

### **Before First Build:**
- [ ] Download and add `GoogleService-Info.plist` for iOS
- [ ] Verify Android `INTERNET` permission exists
- [ ] Check Firebase Security Rules are published
- [ ] Update app name if desired
- [ ] Run `flutter pub get` to ensure dependencies

### **For Production Release:**
- [ ] Set up Android signing configuration
- [ ] Set up iOS provisioning profiles
- [ ] Update version number
- [ ] Test on physical devices
- [ ] Test all features end-to-end

---

## 📝 **SUMMARY:**

**Can you build now?** 
- ✅ **YES for DEBUG/TESTING** (after adding iOS GoogleService-Info.plist)
- ⚠️ **For PRODUCTION**: Need signing configs

**Minimum requirements:**
1. ✅ Add `GoogleService-Info.plist` for iOS
2. ✅ Verify Android permissions
3. ✅ Run `flutter pub get`
4. ✅ Build!

---

## 🔧 **QUICK FIXES:**

### Fix 1: Add Android Internet Permission (if missing)
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <!-- ... rest of manifest -->
</manifest>
```

### Fix 2: Download iOS GoogleService-Info.plist
1. Firebase Console > Project Settings > iOS app
2. Download `GoogleService-Info.plist`
3. Place in `ios/Runner/` folder

---

**🎉 Once these are done, you're ready to build!**


