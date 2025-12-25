# 📱 iOS Setup Guide - Smart Budget App

## ✅ **COMPLETED:**
- ✅ App registered in Firebase (Bundle ID: `com.smartbudgetios.ph`)
- ✅ Config file ready to download

---

## 🎯 **STEP 1: Download GoogleService-Info.plist**

### Sa Firebase Console:
1. **Click "Download config file"** button (yung may pencil icon)
2. **Download** ang `GoogleService-Info.plist` file
3. **Save** ito sa iyong computer (Desktop o Downloads folder)

---

## 📂 **STEP 2: Add GoogleService-Info.plist to Project**

### Option A: Via Finder (Easiest)
1. **Open Finder**
2. **Navigate** to your project folder: `/Users/neodelatorre/Repository/smartbudget/ios/Runner/`
3. **Copy** ang downloaded `GoogleService-Info.plist` file
4. **Paste** ito sa `ios/Runner/` folder

### Option B: Via Terminal
```bash
# Navigate to project root
cd /Users/neodelatorre/Repository/smartbudget

# Copy GoogleService-Info.plist to ios/Runner/
# (Replace ~/Downloads/GoogleService-Info.plist with your actual file path)
cp ~/Downloads/GoogleService-Info.plist ios/Runner/
```

### Option C: Via Xcode (Recommended for verification)
1. **Open** `ios/Runner.xcworkspace` sa Xcode
2. **Right-click** sa `Runner` folder (left sidebar)
3. **Select** "Add Files to Runner..."
4. **Choose** ang `GoogleService-Info.plist` file
5. **Make sure** "Copy items if needed" is checked
6. **Click** "Add"

---

## ✅ **STEP 3: Verify Setup**

### Check if file exists:
```bash
# Run this command to verify
ls -la ios/Runner/GoogleService-Info.plist
```

**Expected output:** Should show the file details (not "No such file or directory")

---

## 🔧 **STEP 4: Verify Bundle ID Match**

### Check your Bundle ID:
1. **Open** `ios/Runner.xcworkspace` sa Xcode
2. **Select** "Runner" project (left sidebar)
3. **Select** "Runner" target
4. **Go to** "General" tab
5. **Check** "Bundle Identifier" - dapat `com.smartbudgetios.ph`

**If different:**
- Update Bundle ID sa Xcode to match Firebase (`com.smartbudgetios.ph`)
- OR update Firebase app registration to match Xcode Bundle ID

---

## 📝 **STEP 5: Add to Xcode Project (If not done via Option C)**

### Manual addition:
1. **Open** `ios/Runner.xcworkspace` sa Xcode
2. **Right-click** sa `Runner` folder
3. **Select** "Add Files to Runner..."
4. **Navigate** to `ios/Runner/GoogleService-Info.plist`
5. **Select** the file
6. **Make sure:**
   - ✅ "Copy items if needed" is **UNCHECKED** (file already in folder)
   - ✅ "Add to targets: Runner" is **CHECKED**
7. **Click** "Add"

---

## ⚠️ **IMPORTANT NOTES:**

### ❌ **DO NOT:**
- ❌ Manually add Firebase SDK via Swift Package Manager (Flutter handles this)
- ❌ Modify `GoogleService-Info.plist` manually
- ❌ Add it to `.gitignore` (it's already configured)

### ✅ **DO:**
- ✅ Keep `GoogleService-Info.plist` in `ios/Runner/` folder
- ✅ Verify Bundle ID matches Firebase
- ✅ Test build after adding the file

---

## 🚀 **STEP 6: Test Build**

### After adding GoogleService-Info.plist:
```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build for iOS (simulator)
flutter build ios --simulator

# OR run on device
flutter run
```

---

## ✅ **VERIFICATION CHECKLIST:**

- [ ] `GoogleService-Info.plist` downloaded from Firebase
- [ ] File placed in `ios/Runner/` folder
- [ ] File added to Xcode project (if using Xcode)
- [ ] Bundle ID matches Firebase (`com.smartbudgetios.ph`)
- [ ] `flutter clean` and `flutter pub get` run
- [ ] Build successful (`flutter build ios`)

---

## 🐛 **TROUBLESHOOTING:**

### Error: "GoogleService-Info.plist not found"
**Solution:**
- Verify file is in `ios/Runner/` folder
- Check file name is exactly `GoogleService-Info.plist` (case-sensitive)
- Re-add to Xcode project if needed

### Error: "Bundle ID mismatch"
**Solution:**
- Check Bundle ID sa Xcode matches Firebase
- Update either Xcode or Firebase to match

### Error: "Firebase not initialized"
**Solution:**
- Verify `GoogleService-Info.plist` is in correct location
- Run `flutter clean` and rebuild
- Check Firebase dependencies in `pubspec.yaml`

---

## 📋 **QUICK COMMANDS:**

```bash
# Navigate to project
cd /Users/neodelatorre/Repository/smartbudget

# Verify file exists
ls -la ios/Runner/GoogleService-Info.plist

# Clean and rebuild
flutter clean
flutter pub get
flutter build ios --simulator
```

---

## 🎉 **DONE!**

Once `GoogleService-Info.plist` is in place, your iOS app is ready to use Firebase!

**Next Steps:**
- Test authentication (Email, Gmail)
- Test Firestore operations
- Test push notifications (if configured)

---

**Need help?** Check the file location and Bundle ID first!

