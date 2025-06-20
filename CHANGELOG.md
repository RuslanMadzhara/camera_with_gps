## 1.1.1 - 2025-06-19 
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
