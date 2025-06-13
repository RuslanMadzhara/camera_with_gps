## 0.1.0+1 - 2025-03-24
- Initial release of Camera With GPS plugin.
- Supports capturing photos and embedding GPS metadata on both iOS and Android.
## 0.1.1+1 - 2025-03-31
 - Update `openCamera` to require `BuildContext` for navigation 
 - Replaced `navigatorKey` with a `BuildContext` parameter in `openCamera` for improved navigation handling. 
 - ## 0.2.0 - 2025-06-13
 - **Integrate permission_handler package and update configurations**
    - Added `permission_handler` dependency in `pubspec.yaml` and example project.
    - Updated iOS project configuration to include `permission_handler_apple`.
    - Removed unused permissions and microphone description in `Info.plist`.
    - Updated AndroidManifest.xml for clean-up of blank lines.

