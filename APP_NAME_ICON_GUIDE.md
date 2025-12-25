# 📱 App Name & Icon Setup Guide

## 📝 **APP NAME**

### **Android:**
**File:** `android/app/src/main/AndroidManifest.xml`

**Line 5:** Change `android:label="smartbudget"` to your desired app name

**Example:**
```xml
<application
    android:label="Smart Budget"  <!-- Change this -->
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">
```

**Location:** `/Users/neodelatorre/Repository/smartbudget/android/app/src/main/AndroidManifest.xml`

---

### **iOS:**
**File:** `ios/Runner/Info.plist`

**Line 8:** Change `CFBundleDisplayName` value

**Example:**
```xml
<key>CFBundleDisplayName</key>
<string>Smart Budget</string>  <!-- Change this -->
```

**Location:** `/Users/neodelatorre/Repository/smartbudget/ios/Runner/Info.plist`

---

## 🎨 **APP ICON**

### **Android Icons:**
**Location:** `android/app/src/main/res/`

Replace the icon files in these folders:
- `mipmap-mdpi/ic_launcher.png` (48x48 px)
- `mipmap-hdpi/ic_launcher.png` (72x72 px)
- `mipmap-xhdpi/ic_launcher.png` (96x96 px)
- `mipmap-xxhdpi/ic_launcher.png` (144x144 px)
- `mipmap-xxxhdpi/ic_launcher.png` (192x192 px)

**Full Path:** `/Users/neodelatorre/Repository/smartbudget/android/app/src/main/res/mipmap-*/ic_launcher.png`

**How to create:**
1. Create a 1024x1024 px icon
2. Use online tools like:
   - https://www.appicon.co/
   - https://icon.kitchen/
   - https://makeappicon.com/
3. Generate Android icons and replace files in each `mipmap-*` folder

---

### **iOS Icons:**
**Location:** `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

Replace these icon files:
- `Icon-App-20x20@1x.png` (20x20 px)
- `Icon-App-20x20@2x.png` (40x40 px)
- `Icon-App-20x20@3x.png` (60x60 px)
- `Icon-App-29x29@1x.png` (29x29 px)
- `Icon-App-29x29@2x.png` (58x58 px)
- `Icon-App-29x29@3x.png` (87x87 px)
- `Icon-App-40x40@1x.png` (40x40 px)
- `Icon-App-40x40@2x.png` (80x80 px)
- `Icon-App-40x40@3x.png` (120x120 px)
- `Icon-App-60x60@2x.png` (120x120 px)
- `Icon-App-60x60@3x.png` (180x180 px)
- `Icon-App-76x76@1x.png` (76x76 px)
- `Icon-App-76x76@2x.png` (152x152 px)
- `Icon-App-83.5x83.5@2x.png` (167x167 px)
- `Icon-App-1024x1024@1x.png` (1024x1024 px) ⭐ **Most Important**

**Full Path:** `/Users/neodelatorre/Repository/smartbudget/ios/Runner/Assets.xcassets/AppIcon.appiconset/`

**How to create:**
1. Create a 1024x1024 px icon
2. Use online tools (same as Android) or Xcode
3. Generate iOS icons and replace files

**OR use Xcode:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Go to `Assets.xcassets` > `AppIcon`
3. Drag and drop your icons to the appropriate slots

---

## 🚀 **QUICK STEPS:**

### **Step 1: Change App Name**

#### Android:
```bash
# Edit this file:
nano android/app/src/main/AndroidManifest.xml
# Change line 5: android:label="Your App Name"
```

#### iOS:
```bash
# Edit this file:
nano ios/Runner/Info.plist
# Change line 8: <string>Your App Name</string>
```

---

### **Step 2: Replace Icons**

#### Android:
1. Create your icon (1024x1024 px)
2. Use online tool to generate Android icons
3. Replace files in:
   - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
   - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
   - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
   - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
   - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

#### iOS:
1. Create your icon (1024x1024 px)
2. Use online tool to generate iOS icons
3. Replace files in:
   - `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

**OR use Xcode:**
1. Open `ios/Runner.xcworkspace`
2. Navigate to `Assets.xcassets` > `AppIcon`
3. Drag icons to appropriate slots

---

## 📋 **ICON REQUIREMENTS:**

### **Android:**
- Format: PNG (transparent background recommended)
- Sizes needed:
  - mdpi: 48x48 px
  - hdpi: 72x72 px
  - xhdpi: 96x96 px
  - xxhdpi: 144x144 px
  - xxxhdpi: 192x192 px

### **iOS:**
- Format: PNG (no transparency for App Store)
- Sizes needed: See list above
- **Most important:** 1024x1024 px for App Store

---

## 🛠️ **ONLINE TOOLS:**

1. **AppIcon.co** - https://www.appicon.co/
   - Upload 1024x1024 icon
   - Generates both Android & iOS icons
   - Free

2. **Icon Kitchen** - https://icon.kitchen/
   - Google's official tool
   - Generates Android icons
   - Free

3. **MakeAppIcon** - https://makeappicon.com/
   - Generates both platforms
   - Free

4. **AppIcon Generator** - https://appicon.co/
   - Simple and fast
   - Free

---

## ✅ **VERIFICATION:**

After changing:

### **Test App Name:**
```bash
# Build and check app name appears correctly
flutter build apk --debug
flutter build ios --simulator
```

### **Test Icons:**
- Install app on device/emulator
- Check home screen for new icon
- Check app name in app drawer/launcher

---

## 📝 **CURRENT SETTINGS:**

### **App Name:**
- Android: `smartbudget`
- iOS: `Smartbudget`

### **Icon Location:**
- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

---

## 💡 **TIPS:**

1. **Use same icon design** for both Android and iOS
2. **Test on real devices** to see how icon looks
3. **Keep icon simple** - complex designs don't scale well
4. **Follow platform guidelines**:
   - Android: Material Design guidelines
   - iOS: Human Interface Guidelines
5. **No text in icon** - app name appears below icon
6. **Square icon with rounded corners** - platforms add rounding automatically

---

**Ready to customize!** 🎨



