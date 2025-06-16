## 1.0.1 - 2023-11-20
- Enhanced GPS status warnings with specific messages:
  - When GPS is disabled: "GPS is disabled..."
  - When GPS permission is denied: "GPS permission denied..."
  - When GPS permission is permanently denied: "GPS permission permanently denied..."
- Fixed issue with camera not opening when location permission is permanently denied
- Allow camera to open regardless of location permission status

## 1.0.0 - 2023-11-15
- First stable release of Camera With GPS plugin
- Improved stability and performance
- Updated documentation
- Added support for taking photos when GPS is disabled
- Added warning message when GPS is disabled

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
