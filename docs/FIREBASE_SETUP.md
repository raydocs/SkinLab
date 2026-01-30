# Firebase Crashlytics Setup Guide

This guide walks you through setting up Firebase Crashlytics for SkinLab iOS app.

## Prerequisites

- Xcode 15.0+
- CocoaPods or Swift Package Manager
- Apple Developer account
- Firebase account

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select existing project
3. Enter project name: `SkinLab`
4. Enable/disable Google Analytics as needed
5. Click "Create project"

## Step 2: Register iOS App

1. In Firebase Console, click "Add app" → iOS
2. Enter iOS bundle ID: `com.yourcompany.SkinLab`
3. Enter app nickname: `SkinLab iOS`
4. (Optional) Enter App Store ID
5. Click "Register app"

## Step 3: Download Configuration File

1. Download `GoogleService-Info.plist`
2. Add to Xcode project root (ensure "Copy items if needed" is checked)
3. Make sure it's added to the SkinLab target

> ⚠️ **Important**: Add `GoogleService-Info.plist` to `.gitignore` if it contains sensitive data

## Step 4: Add Firebase SDK

### Option A: Swift Package Manager (Recommended)

1. In Xcode: File → Add Package Dependencies
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select version: "Up to Next Major Version" from `10.0.0`
4. Select packages to add:
   - `FirebaseCore`
   - `FirebaseCrashlytics`
   - `FirebaseAnalytics` (optional, for better insights)
5. Click "Add Package"

### Option B: CocoaPods

Add to `Podfile`:

```ruby
platform :ios, '17.0'

target 'SkinLab' do
  use_frameworks!
  
  pod 'Firebase/Core'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'  # Optional
end
```

Run:
```bash
pod install
```

## Step 5: Initialize Firebase

Update `SkinLabApp.swift`:

```swift
import SwiftUI
import FirebaseCore
import FirebaseCrashlytics

@main
struct SkinLabApp: App {
    init() {
        FirebaseApp.configure()
        
        // Configure Crashlytics
        #if DEBUG
        // Disable Crashlytics in debug builds
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        #else
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Step 6: Add Build Phase Script

1. In Xcode, select SkinLab target
2. Go to "Build Phases"
3. Click "+" → "New Run Script Phase"
4. Name it "Upload Crashlytics Symbols"
5. Add script:

```bash
# Run Crashlytics upload script
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
```

Or if using CocoaPods:

```bash
"${PODS_ROOT}/FirebaseCrashlytics/run"
```

6. Add input files:
   - `${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}`
   - `${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}`
   - `${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist`
   - `$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist`
   - `$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)`

## Step 7: Enable dSYM Upload

1. Go to Build Settings
2. Search for "Debug Information Format"
3. Set to `DWARF with dSYM File` for Release configuration

## Step 8: Add Crashlytics Helper (Optional)

Create `CrashlyticsManager.swift`:

```swift
import Foundation
import FirebaseCrashlytics

enum CrashlyticsManager {
    
    // MARK: - User Identification
    
    static func setUserID(_ userID: String?) {
        Crashlytics.crashlytics().setUserID(userID ?? "")
    }
    
    // MARK: - Custom Keys
    
    static func setCustomKey(_ key: String, value: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
    
    static func setCustomKey(_ key: String, value: Int) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
    
    static func setCustomKey(_ key: String, value: Bool) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
    
    // MARK: - Logging
    
    static func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
    
    // MARK: - Non-Fatal Errors
    
    static func recordError(_ error: Error, userInfo: [String: Any]? = nil) {
        var info = userInfo ?? [:]
        info["timestamp"] = Date().ISO8601Format()
        
        Crashlytics.crashlytics().record(error: error, userInfo: info)
    }
    
    static func recordError(
        domain: String,
        code: Int,
        description: String,
        userInfo: [String: Any]? = nil
    ) {
        var info = userInfo ?? [:]
        info[NSLocalizedDescriptionKey] = description
        
        let error = NSError(domain: domain, code: code, userInfo: info)
        recordError(error)
    }
    
    // MARK: - Context
    
    static func setAnalysisContext(analysisID: String, skinType: String) {
        setCustomKey("last_analysis_id", value: analysisID)
        setCustomKey("skin_type", value: skinType)
    }
    
    static func setFeatureContext(feature: String) {
        setCustomKey("current_feature", value: feature)
    }
}
```

## Step 9: Usage Examples

### Log Non-Fatal Errors

```swift
do {
    try await analysisService.analyze(image)
} catch {
    CrashlyticsManager.recordError(error, userInfo: [
        "feature": "skin_analysis",
        "image_size": "\(image.size)"
    ])
    throw error
}
```

### Add Breadcrumbs

```swift
func startAnalysis() {
    CrashlyticsManager.log("User started skin analysis")
    CrashlyticsManager.setFeatureContext(feature: "analysis")
    // ... perform analysis
}
```

### Track User Context

```swift
func onUserLogin(user: User) {
    CrashlyticsManager.setUserID(user.id)
    CrashlyticsManager.setCustomKey("subscription_tier", value: user.tier)
}
```

## Step 10: Test Crashlytics

### Force a Test Crash (Debug Only)

```swift
#if DEBUG
Button("Test Crash") {
    fatalError("Test crash for Crashlytics")
}
#endif
```

### Verify Setup

1. Build and run the app
2. Force a crash using the test button
3. Reopen the app (crashes are uploaded on next launch)
4. Check Firebase Console → Crashlytics
5. Crash should appear within 5-10 minutes

## Privacy Considerations

### User Consent

```swift
func updateCrashlyticsConsent(enabled: Bool) {
    Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(enabled)
    UserDefaults.standard.set(enabled, forKey: "crashlytics_enabled")
}
```

### Privacy Policy

Add to your privacy policy:
- Crash data collection purpose
- What data is collected (stack traces, device info)
- How long data is retained
- User's right to opt-out

### App Store Privacy Labels

In App Store Connect, declare:
- **Crash Data**: Collected, linked to user (if using user ID)
- **Performance Data**: Collected
- **Usage**: Analytics, App Functionality

## Troubleshooting

### Crashes Not Appearing

1. Ensure `GoogleService-Info.plist` is in target
2. Check build phase script is running
3. Verify dSYM files are being uploaded
4. Wait 5-10 minutes after crash

### Missing Symbolication

1. Check Debug Information Format is set correctly
2. Verify dSYM upload script has correct paths
3. Run script manually to check for errors

### Build Errors

```bash
# If SPM cache issues:
rm -rf ~/Library/Caches/org.swift.swiftpm/
rm -rf .build/

# If CocoaPods issues:
pod deintegrate
pod install
```

## Dashboard Setup

### Recommended Alerts

1. **New Crash Cluster**: When a new crash type is detected
2. **Crash Spike**: When crash rate increases significantly
3. **Regression**: When a fixed crash reoccurs

### Custom Dashboards

Create views for:
- Crashes by feature area
- Crashes by iOS version
- Crashes by device model
- Crash-free user percentage

## Resources

- [Firebase Crashlytics Documentation](https://firebase.google.com/docs/crashlytics)
- [Crashlytics Best Practices](https://firebase.google.com/docs/crashlytics/customize-crash-reports)
- [Debugging with Crashlytics](https://firebase.google.com/docs/crashlytics/debug)
