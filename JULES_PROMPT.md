# 🚀 POCKIFY - Complete Flutter Application Implementation Prompt for Jules AI

## 📋 PROJECT OVERVIEW

**Project Name:** Pockify  
**Tagline:** "Cebine Al, Her Yerde İzle" / "Pocket Your Favorites"  
**Platform:** Flutter (Android + iOS)  
**Category:** Tools / Utilities - Video Link Manager & Media Organizer  
**Target Audience:** 16-35 age, social media content consumers

---

## 🎯 OBJECTIVE

You are tasked with making the **Pockify** Flutter application fully functional with all buttons, features, and services working correctly. The app already has a solid UI foundation but needs backend logic implementation and integration fixes.

---

## 📁 PROJECT STRUCTURE

```
lib/
├── main.dart                           # App entry point
├── app/
│   └── routes.dart                     # App routing
├── core/
│   ├── constants/
│   │   └── app_constants.dart          # App constants
│   ├── theme/
│   │   ├── app_colors.dart             # Color palette
│   │   ├── app_theme.dart              # Theme configuration
│   │   ├── app_typography.dart         # Typography styles
│   │   └── glass_container.dart        # Glassmorphism widget
│   ├── utils/
│   │   ├── file_helper.dart            # File operations helper
│   │   └── link_parser.dart            # URL parsing utility
│   └── widgets/
│       └── pockify_logo.dart           # Logo widget
├── features/
│   ├── home/
│   │   ├── home_screen.dart            # Main home with bottom nav
│   │   └── widgets/
│   │       └── home_view.dart          # Link paste interface
│   ├── downloads/
│   │   ├── downloads_screen.dart       # Downloaded videos list
│   │   ├── bloc/
│   │   │   ├── download_bloc.dart      # Download state management
│   │   │   ├── download_event.dart     # Bloc events
│   │   │   └── download_state.dart     # Bloc states
│   │   └── widgets/
│   │       └── video_player_screen.dart # Video player
│   ├── onboarding/
│   │   ├── splash_screen.dart          # App splash screen
│   │   ├── onboarding_screen.dart      # First-time user guide
│   │   └── disclaimer_dialog.dart      # Legal disclaimer
│   ├── premium/
│   │   └── premium_screen.dart         # Subscription UI
│   └── settings/
│       └── settings_screen.dart        # App settings
├── models/
│   ├── download_model.dart             # Download data model
│   ├── download_model.g.dart           # Hive adapter (generated)
│   ├── video_model.dart                # Video data model
│   └── video_model.g.dart              # Hive adapter (generated)
└── services/
    ├── ad_service.dart                 # AdMob integration
    ├── download_service.dart           # Video download logic
    ├── purchase_service.dart           # In-app purchases
    └── storage_service.dart            # Local storage (Hive)
```

---

## 🔧 TASKS TO COMPLETE

### 1. DOWNLOAD SERVICE FIXES (High Priority)

**File:** `lib/services/download_service.dart`

**Current Issue:** The Cobalt API endpoint may change, and error handling needs improvement.

**Tasks:**
- [ ] Implement fallback API endpoints if primary fails
- [ ] Add proper error handling with user-friendly Turkish messages
- [ ] Implement retry logic (3 attempts with exponential backoff)
- [ ] Add connection timeout handling
- [ ] Ensure proper file permissions for Android 13+ (MANAGE_EXTERNAL_STORAGE)

**Implementation:**
```dart
// Add multiple API endpoints with fallback
static const List<String> _apiEndpoints = [
  'https://co.wuk.sh/api/json',
  'https://api.cobalt.tools/api/json',
];

// Add retry logic
Future<T> _retryWithBackoff<T>(Future<T> Function() operation, {int maxAttempts = 3}) async {
  int attempts = 0;
  while (attempts < maxAttempts) {
    try {
      return await operation();
    } catch (e) {
      attempts++;
      if (attempts >= maxAttempts) rethrow;
      await Future.delayed(Duration(seconds: attempts * 2));
    }
  }
  throw Exception('Maximum retry attempts reached');
}
```

### 2. STORAGE SERVICE ENHANCEMENT

**File:** `lib/services/storage_service.dart`

**Tasks:**
- [ ] Add proper initialization check
- [ ] Implement data encryption for sensitive data
- [ ] Add migration logic for future updates
- [ ] Implement proper error handling

**Current Code to Fix:**
```dart
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Box? _settingsBox;
  Box<DownloadModel>? _downloadsBox;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      _settingsBox = await Hive.openBox('settings');
      _downloadsBox = await Hive.openBox<DownloadModel>('downloads');
      _isInitialized = true;
    } catch (e) {
      // Handle corrupted storage
      await Hive.deleteBoxFromDisk('settings');
      await Hive.deleteBoxFromDisk('downloads');
      _settingsBox = await Hive.openBox('settings');
      _downloadsBox = await Hive.openBox<DownloadModel>('downloads');
      _isInitialized = true;
    }
  }
  
  // Null-safe getters
  T? getValue<T>(String key) {
    return _settingsBox?.get(key) as T?;
  }
  
  Future<void> setValue<T>(String key, T value) async {
    await _settingsBox?.put(key, value);
  }
  
  List<T> getAll<T>(String boxName) {
    if (boxName == 'downloads' && _downloadsBox != null) {
      return _downloadsBox!.values.toList().cast<T>();
    }
    return [];
  }
  
  Box<T>? getBox<T>(String boxName) {
    if (boxName == 'downloads') {
      return _downloadsBox as Box<T>?;
    }
    return null;
  }
  
  Future<void> clearAll() async {
    await _settingsBox?.clear();
    await _downloadsBox?.clear();
  }
}
```

### 3. AD SERVICE CONFIGURATION

**File:** `lib/services/ad_service.dart`

**Tasks:**
- [ ] Update test Ad Unit IDs (already done, verify they're correct)
- [ ] Add native ad support for premium upsell
- [ ] Implement ad loading preemptively
- [ ] Add proper ad consent management (for EU users)

**Test Ad Units (Keep for development):**
```dart
// These are Google's official test ad unit IDs
static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
```

### 4. PURCHASE SERVICE COMPLETION

**File:** `lib/services/purchase_service.dart`

**Tasks:**
- [ ] Add proper subscription verification
- [ ] Implement grace period handling
- [ ] Add receipt validation (basic client-side for MVP)
- [ ] Handle subscription expiry checks
- [ ] Add proper error messages in Turkish

**Product IDs to register in Play Console/App Store Connect:**
```dart
static const String weeklyProductId = 'pockify_premium_weekly';
static const String monthlyProductId = 'pockify_premium_monthly';
static const String yearlyProductId = 'pockify_premium_yearly';
static const String lifetimeProductId = 'pockify_premium_lifetime';
```

### 5. DOWNLOAD BLOC FIXES

**File:** `lib/features/downloads/bloc/download_bloc.dart`

**Tasks:**
- [ ] Add active download tracking with real-time progress
- [ ] Implement concurrent download queue (max 2 simultaneous)
- [ ] Add download pause/resume functionality
- [ ] Proper cleanup on download failure

**Add to state:**
```dart
// In download_state.dart
final List<DownloadModel> activeDownloads;
final Map<String, Stream<int>> progressStreams;
```

### 6. HOME VIEW CLIPBOARD INTEGRATION

**File:** `lib/features/home/widgets/home_view.dart`

**Tasks:**
- [ ] Add automatic clipboard monitoring on app resume
- [ ] Show "Link detected" toast when valid link is in clipboard
- [ ] Add haptic feedback on successful paste
- [ ] Improve error messages with specific platform detection

**Implementation:**
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _checkClipboard();
}

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _checkClipboard();
  }
}

Future<void> _checkClipboard() async {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  if (data?.text != null && LinkParser.isValidUrl(data!.text!)) {
    _showClipboardToast(data.text!);
  }
}
```

### 7. VIDEO PLAYER ENHANCEMENTS

**File:** `lib/features/downloads/widgets/video_player_screen.dart`

**Tasks:**
- [ ] Add picture-in-picture support (Android 8.0+)
- [ ] Implement playback speed control
- [ ] Add loop toggle
- [ ] Implement full-screen mode
- [ ] Save playback position for resume

### 8. SETTINGS SCREEN FUNCTIONALITY

**File:** `lib/features/settings/settings_screen.dart`

**Tasks:**
- [ ] Make theme switching actually work (update ThemeMode)
- [ ] Implement "Clear All Data" with confirmation
- [ ] Add language selection (Turkish/English)
- [ ] Make all links actually open (verify URL launcher)
- [ ] Show actual storage usage

**Theme implementation:**
```dart
// Create a ThemeProvider or use ValueNotifier
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  
  ThemeMode get themeMode => _themeMode;
  
  void setTheme(String theme) {
    switch (theme) {
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }
}
```

### 9. PREMIUM SCREEN INTEGRATION

**File:** `lib/features/premium/premium_screen.dart`

**Tasks:**
- [ ] Connect purchase buttons to actual in-app purchase flow
- [ ] Show loading state during purchase
- [ ] Handle purchase errors gracefully
- [ ] Add "Already Premium" state UI
- [ ] Implement restore purchases functionality

### 10. ONBOARDING & DISCLAIMER

**Files:** `lib/features/onboarding/*.dart`

**Tasks:**
- [ ] Save onboarding completion state properly
- [ ] Add analytics events for onboarding steps
- [ ] Ensure disclaimer acceptance is persisted
- [ ] Add "Don't show again" option for disclaimer

---

## 📦 DEPENDENCIES (pubspec.yaml)

Ensure all these dependencies are properly configured:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Network
  dio: ^5.4.0
  
  # Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.2
  
  # Media
  video_player: ^2.8.2
  chewie: ^1.7.4
  
  # Permissions
  permission_handler: ^11.2.0
  
  # Clipboard
  clipboard: ^0.1.3
  
  # Sharing
  share_plus: ^7.2.1
  
  # Monetization
  google_mobile_ads: ^4.0.0
  in_app_purchase: ^3.1.13
  
  # UI Components
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  lottie: ^3.0.0
  
  # Utils
  url_launcher: ^6.2.3
  package_info_plus: ^5.0.1
  connectivity_plus: ^5.0.2
  
  # Analytics (optional, can be added later)
  firebase_core: ^2.24.2
  firebase_analytics: ^10.8.0
  firebase_crashlytics: ^3.4.8
  
  # UI Enhancements
  cupertino_icons: ^1.0.8
  google_fonts: ^7.0.2
  flutter_animate: ^4.5.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.13
  hive_generator: ^2.0.1
  flutter_launcher_icons: ^0.13.1
```

---

## 🔐 ANDROID CONFIGURATION

### AndroidManifest.xml Permissions
**File:** `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Internet permission -->
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <!-- Storage permissions -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
    
    <!-- For Android 13+ media permissions -->
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    
    <!-- AdMob -->
    <uses-permission android:name="com.google.android.gms.permission.AD_ID"/>
    
    <!-- Network state -->
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    
    <application
        android:label="Pockify"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:requestLegacyExternalStorage="true"
        android:usesCleartextTraffic="true">
        
        <!-- AdMob App ID -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-XXXXXXXXXXXXX~XXXXXXXXXX"/>
            
        <!-- ... rest of configuration -->
    </application>
</manifest>
```

### build.gradle (app level)
**File:** `android/app/build.gradle`

```gradle
android {
    compileSdk 34  // or flutter.compileSdkVersion
    
    defaultConfig {
        applicationId "app.pockify"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

## 🍎 iOS CONFIGURATION

### Info.plist
**File:** `ios/Runner/Info.plist`

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Pockify needs access to save downloaded videos to your photo library.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>Pockify needs permission to save videos to your photo library.</string>

<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXX~XXXXXXXXXX</string>

<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
</array>
```

---

## 🧪 TESTING CHECKLIST

After implementation, verify these features work:

### Basic Flow
- [ ] App launches without crashes
- [ ] Splash screen shows for 2 seconds
- [ ] Onboarding appears on first launch
- [ ] Onboarding can be skipped
- [ ] Disclaimer dialog appears
- [ ] Disclaimer acceptance is saved
- [ ] Bottom navigation works

### Download Feature
- [ ] Paste button reads clipboard
- [ ] Valid TikTok link is detected
- [ ] Valid Instagram link is detected
- [ ] Invalid links show error
- [ ] Download progress shows
- [ ] Downloaded video appears in Downloads tab
- [ ] Downloaded video can be played
- [ ] Downloaded video can be shared
- [ ] Downloaded video can be deleted

### Premium Features
- [ ] Premium screen opens
- [ ] Plan cards are selectable
- [ ] Purchase button triggers in-app purchase
- [ ] Restore purchases works
- [ ] Free user daily limit (3) works
- [ ] Premium users have no limit

### Settings
- [ ] Video quality selection works
- [ ] Theme switching works
- [ ] Clear data removes all downloads
- [ ] External links open correctly
- [ ] App version displays correctly

### Ads (Debug Mode)
- [ ] Banner ads load (test ads)
- [ ] Interstitial ads appear after 2 downloads
- [ ] Rewarded ads play when triggered

---

## 🚀 BUILD COMMANDS

```bash
# Get dependencies
flutter pub get

# Generate Hive adapters
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run on device
flutter run

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build release AAB (for Play Store)
flutter build appbundle --release
```

---

## ⚠️ IMPORTANT NOTES

1. **API Endpoint:** The Cobalt API (`https://co.wuk.sh/api/json`) may change. Implement fallback logic.

2. **Store Compliance:** This app is positioned as a "Video Link Manager" not a "downloader" to comply with store policies.

3. **Disclaimer:** Always show the copyright disclaimer on first launch and keep it accessible in settings.

4. **Test Ads:** Use test ad unit IDs during development. Replace with production IDs before release.

5. **Firebase:** Firebase dependencies are included but not configured. If you need analytics/crashlytics, create a Firebase project and add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).

6. **Language:** All user-facing strings should be in Turkish for the Turkish market. Consider adding English localization later.

---

## 📞 SUPPORT INFORMATION

- **Email:** support@pockify.app
- **Website:** https://pockify.app
- **Privacy Policy:** https://pockify.app/privacy
- **Terms of Service:** https://pockify.app/terms

---

## ✅ FINAL VERIFICATION

When complete, ensure:
1. App compiles without errors: `flutter analyze`
2. App runs on Android emulator
3. App runs on iOS simulator (if available)
4. All 4 main screens accessible (Home, Downloads, Premium, Settings)
5. At least one test video can be downloaded and played

---

**This prompt provides everything needed to make Pockify fully functional. Execute each task systematically, test after each major change, and ensure proper error handling throughout.**

*Created: January 2026*
