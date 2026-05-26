# 🔥 RAYS — Release APK Build Guide

Complete guide to generate a production-grade release APK for direct Android installation.

## Prerequisites

1. **Flutter SDK** (3.5.0+)
2. **Android Studio** or **Android SDK** with:
   - Android SDK Platform 35
   - Android SDK Build-Tools 35.0.0
3. **Java JDK 17**

Verify installation:
```powershell
flutter doctor -v
java -version
```

---

## Step 1: Generate Release Keystore

Open PowerShell in the `android` folder and run:

```powershell
cd D:\RAY\rakshak_ai\android

keytool -genkey -v -keystore rays-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias rays_key
```

Follow the prompts:
- **Keystore password**: Choose a strong password
- **Name, Organization, etc.**: Fill in your details
- **Key password**: Same as keystore password (recommended)

---

## Step 2: Configure key.properties

Edit `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=rays_key
storeFile=../rays-release-key.jks
```

**⚠️ IMPORTANT**: Never commit `key.properties` or `.jks` files to version control!

Add to `.gitignore`:
```
android/key.properties
android/*.jks
```

---

## Step 3: Clean & Get Dependencies

```powershell
cd D:\RAY\rakshak_ai

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Generate Hive adapters (if needed)
dart run build_runner build --delete-conflicting-outputs
```

---

## Step 4: Build Release APK

### Option A: Standard APK (Recommended for testing)

```powershell
flutter build apk --release
```

Output: `build\app\outputs\flutter-apk\app-release.apk` (~25-40 MB)

### Option B: Split APKs by ABI (Smaller size)

```powershell
flutter build apk --release --split-per-abi
```

Outputs:
- `app-arm64-v8a-release.apk` (Most modern phones)
- `app-armeabi-v7a-release.apk` (Older 32-bit phones)
- `app-x86_64-release.apk` (Emulators)

### Option C: App Bundle (For Play Store)

```powershell
flutter build appbundle --release
```

---

## Step 5: Verify APK

Check APK size and contents:

```powershell
# Show APK info
flutter build apk --release --analyze-size
```

---

## Step 6: Install on Device

### Via ADB (USB Debugging enabled)

```powershell
# List connected devices
adb devices

# Install APK
adb install build\app\outputs\flutter-apk\app-release.apk
```

### Via File Transfer

1. Copy APK to device via USB/cloud
2. Enable **Install from Unknown Sources** in device settings
3. Open APK file on device
4. Tap **Install**

---

## Required Android Permissions

The app requires these permissions (configured in AndroidManifest.xml):

| Permission | Purpose |
|------------|---------|
| `PACKAGE_USAGE_STATS` | App usage tracking |
| `INTERNET` | Backend sync |
| `FOREGROUND_SERVICE` | Background monitoring |
| `RECEIVE_BOOT_COMPLETED` | Restart monitoring after reboot |
| `WAKE_LOCK` | Background task execution |
| `POST_NOTIFICATIONS` | Smart alerts |
| `health.READ_SLEEP` | Sleep tracking (Health Connect) |
| `health.READ_HEART_RATE` | Heart rate monitoring |
| `health.READ_EXERCISE` | Exercise tracking |
| `ACTIVITY_RECOGNITION` | Movement detection |
| `BODY_SENSORS` | Sensor access |

---

## Background Task Reliability Tips

### Disable Battery Optimization

For reliable background monitoring:

1. Go to **Settings → Apps → RAYS**
2. Tap **Battery**
3. Select **Unrestricted** or **Don't optimize**

### Xiaomi/MIUI Devices

1. Go to **Settings → Apps → Manage apps → RAYS**
2. Enable **Autostart**
3. Set Battery saver to **No restrictions**

### Samsung Devices

1. Go to **Settings → Battery → Background usage limits**
2. Remove RAYS from **Sleeping apps**
3. Add to **Never sleeping apps**

### OPPO/Vivo/Realme

1. Go to **Settings → Battery → High power consumption**
2. Enable for RAYS

---

## Common APK Installation Issues

### "App not installed" Error

**Cause**: Signature mismatch or corrupted APK

**Fix**:
```powershell
# Uninstall existing app first
adb uninstall com.rakshak.ai

# Clean and rebuild
flutter clean
flutter build apk --release
```

### "Parse error" on older devices

**Cause**: minSdkVersion (26) too high for device

**Fix**: Target device must run Android 8.0 (Oreo) or higher

### App crashes on launch

**Cause**: ProGuard stripping required classes

**Fix**: Already configured in `proguard-rules.pro`, but verify:
```groovy
// android/app/build.gradle
release {
    minifyEnabled true
    shrinkResources true
    proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
}
```

### Permission issues

**Usage Stats permission**:
1. App will redirect to Settings
2. Find RAYS in the list
3. Enable toggle

**Health Connect**:
1. Install Google Health Connect from Play Store
2. Open RAYS
3. Grant health permissions when prompted

---

## Verifying the Build

### Check APK signature

```powershell
# Verify APK is signed
jarsigner -verify -verbose -certs build\app\outputs\flutter-apk\app-release.apk
```

### Extract and inspect

```powershell
# List APK contents
unzip -l build\app\outputs\flutter-apk\app-release.apk | head -50
```

---

## Production Checklist

- [ ] Release keystore generated and secured
- [ ] `key.properties` configured
- [ ] API keys set in `.env` (backend)
- [ ] SSL certificates configured for backend
- [ ] ProGuard rules tested
- [ ] Tested on real Android device
- [ ] Battery optimization disabled on test device
- [ ] All permissions granted and working
- [ ] Background task persists after reboot
- [ ] Notifications appearing correctly

---

## Device Compatibility

| Android Version | API Level | Status |
|-----------------|-----------|--------|
| Android 8.0 (Oreo) | 26 | ✅ Minimum |
| Android 9.0 (Pie) | 28 | ✅ Full support |
| Android 10 | 29 | ✅ Full support |
| Android 11 | 30 | ✅ Full support |
| Android 12 | 31 | ✅ Full support |
| Android 13 | 33 | ✅ Full support |
| Android 14 | 34 | ✅ Full support (Health Connect) |
| Android 15 | 35 | ✅ Target SDK |

---

## File Sizes (Approximate)

| Build Type | Size |
|------------|------|
| Debug APK | ~80 MB |
| Release APK (fat) | ~25-40 MB |
| Release APK (arm64-v8a) | ~15-20 MB |
| App Bundle | ~20-25 MB |

---

## Need Help?

1. Run `flutter doctor -v` and check for issues
2. Check `build\app\outputs\logs` for build errors
3. Use `adb logcat` to view runtime logs

```powershell
# Filter RAYS logs
adb logcat | findstr "RAYS"
```

