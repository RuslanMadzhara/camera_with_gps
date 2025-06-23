## 2.0.0 - 2025-06-23
- **Major refactoring of camera app structure:**
  - Split monolithic file into small, testable components
  - Created dedicated services, widgets, and utility classes
  - Improved code organization with clear separation of concerns
  - Enhanced maintainability and testability
- **Fixed iOS photo rotation issue:**
  - Corrected rotation angle for photos taken in landscape right orientation on iOS devices
- **Updated code for better compatibility:**
  - Replaced pattern matching switch expressions with traditional switch statements

## 1.1.7 - 2025-06-22
 - "Fix Android orientation detection issue where devices were always detecting landscapeLeft"
 - "Improve image rotation logic for Android devices in landscape mode"

## 1.1.6 - 2025-06-22
 - "Fix Android photo orientation issue when taking photos in landscape-right orientation"

## 1.1.5 - 2025-06-221
 - "Add `removeGps` method to handle GPS metadata removal and enable corresponding iOS build warning for quoted includes"
## 1.1.4 - 2025-06-221
 - "Refactor GPS metadata handling: remove confirmation dialog for invalid coordinates, streamline EXIF parsing,
 - add `removeGps` method, and enhance gallery feature with detailed metadata display."
## 1.1.3 - 2025-06-20
 - "Fix crash on launch in release APK by adding ProGuard rules to prevent obfuscation of critical classes"
## 1.1.2 - 2025-06-19 
 - "Update Android build configs: adjust minSdkVersion for example app and plugin to maintain compatibility"
## 1.1.1 - 2025-06-18 
 - **Refactor CameraPreviewPage:**
  - Add orientation-aware UI, optimize GPS handling, and improve photo cropping/rotation logic"
  - "Add device detection using `device_info_plus` for Samsung-specific gallery handling, 
  - refine GPS checks, and update orientation-aware UI with enhanced margin adjustments"
## 0.2.0 - 2025-06-13
- **Integrate permission_handler package and update configurations**
  - Added `permission_handler` dependency in `pubspec.yaml` and example project
  - Updated iOS project configuration to include `permission_handler_apple`
  - Removed unused permissions and microphone description in `Info.plist`
  - Updated AndroidManifest.xml for clean-up of blank lines

## 0.1.1+1 - 2025-03-31
- Update `openCamera` to require `BuildContext` for navigation 
- Replaced `navigatorKey` with a `BuildContext` parameter in `openCamera` for improved navigation handling

## 0.1.0+2 - 2025-03-24
- "Allow camera usage without GPS permission and enhance GPS status warnings"
## 0.1.0+3 - 2025-06-18
- "Allow camera usage without GPS permission and enhance GPS status warnings"
- 
