import Flutter
import UIKit
import ImageIO
import MobileCoreServices
import Photos

public class CameraWithGpsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "camera_with_gps", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(CameraWithGpsPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "convertPhoto":
      handleConvertPhoto(call, result: result)
    case "checkGps":
      handleCheckGps(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleConvertPhoto(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let path = args["path"] as? String else {
      return result(FlutterError(code: "INVALID_ARGS", message: "Expected path", details: nil))
    }

    let latitude = args["latitude"] as? Double
    let longitude = args["longitude"] as? Double

    // If no coordinates or (0.0, 0.0), remove GPS
    if latitude == nil || longitude == nil || (latitude == 0.0 && longitude == 0.0) {
      let removed = removeGps(from: path)
      return result(removed)
    }

    let success = addOrUpdateGps(to: path, latitude: latitude!, longitude: longitude!)
    result(success)
  }

  private func addOrUpdateGps(to filePath: String, latitude: Double, longitude: Double) -> Bool {
    let url = URL(fileURLWithPath: filePath)

    guard let data = try? Data(contentsOf: url),
          let source = CGImageSourceCreateWithData(data as CFData, nil),
          var metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
          let dstData = CFDataCreateMutable(nil, 0),
          let destination = CGImageDestinationCreateWithData(dstData, kUTTypeJPEG, 1, nil) else {
      return false
    }

    // Clean up invalid GPS if present
    if let gps = metadata["{GPS}"] as? [String: Any],
       let lat = gps["Latitude"] as? Double,
       let lon = gps["Longitude"] as? Double,
       lat == 0.0, lon == 0.0 {
      metadata.removeValue(forKey: "{GPS}")
    }

    // Always overwrite GPS with known correct values
    metadata["{GPS}"] = [
      "Latitude": abs(latitude),
      "LatitudeRef": latitude >= 0 ? "N" : "S",
      "Longitude": abs(longitude),
      "LongitudeRef": longitude >= 0 ? "E" : "W",
      "Version": "2.3.0.0"
    ]

    CGImageDestinationAddImageFromSource(destination, source, 0, metadata as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { return false }

    do {
      try (dstData as Data).write(to: url)
      return true
    } catch {
      return false
    }
  }

  private func removeGps(from filePath: String) -> Bool {
    let url = URL(fileURLWithPath: filePath)

    guard let data = try? Data(contentsOf: url),
          let source = CGImageSourceCreateWithData(data as CFData, nil),
          var metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
          let dstData = CFDataCreateMutable(nil, 0),
          let destination = CGImageDestinationCreateWithData(dstData, kUTTypeJPEG, 1, nil) else {
      return false
    }

    metadata.removeValue(forKey: "{GPS}")

    CGImageDestinationAddImageFromSource(destination, source, 0, metadata as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { return false }

    do {
      try (dstData as Data).write(to: url)
      return true
    } catch {
      return false
    }
  }

  private func handleCheckGps(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let path = args["path"] as? String else {
      return result("ERROR")
    }

    let url = URL(fileURLWithPath: path)

    guard let data = try? Data(contentsOf: url),
          let source = CGImageSourceCreateWithData(data as CFData, nil),
          let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
      return result("ERROR")
    }

    // Check if GPS data exists and is valid
    if let gps = metadata["{GPS}"] as? [String: Any],
       let lat = gps["Latitude"] as? Double,
       let lon = gps["Longitude"] as? Double {

      // Check if coordinates are (0,0) which might indicate fake GPS data
      if lat == 0.0 && lon == 0.0 {
        return result("FAKE")
      }

      // Check if date is 1970-01-01 which might indicate fake GPS data
      if let dateStamp = gps["DateStamp"] as? String, dateStamp == "1970:01:01" {
        return result("FAKE")
      }

      return result("OK")
    }

    // No GPS data found
    return result("FAKE")
  }
}
