import Flutter
import UIKit
import ImageIO
import MobileCoreServices

public class CameraWithGpsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "camera_with_gps", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(CameraWithGpsPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "convertPhoto",
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String,
          let latitude = args["latitude"] as? Double,
          let longitude = args["longitude"] as? Double else {
      return result(FlutterError(code: "INVALID_ARGS", message: "Expected path, latitude and longitude", details: nil))
    }

    let success = addGps(to: path, latitude: latitude, longitude: longitude)
    result(success) // 🔁 Return true/false (bool), not string
  }

  private func addGps(to filePath: String, latitude: Double, longitude: Double) -> Bool {
    let url = URL(fileURLWithPath: filePath)

    guard let data = try? Data(contentsOf: url),
          let source = CGImageSourceCreateWithData(data as CFData, nil),
          let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
          let dstData = CFDataCreateMutable(nil, 0),
          let destination = CGImageDestinationCreateWithData(dstData, kUTTypeJPEG, 1, nil) else {
      return false
    }

    // If GPS metadata already exists, skip rewriting
    if metadata["{GPS}"] != nil {
      return true
    }

    var updatedMetadata = metadata
    updatedMetadata["{GPS}"] = [
      "Latitude": abs(latitude),
      "LatitudeRef": latitude >= 0 ? "N" : "S",
      "Longitude": abs(longitude),
      "LongitudeRef": longitude >= 0 ? "E" : "W"
    ]

    CGImageDestinationAddImageFromSource(destination, source, 0, updatedMetadata as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { return false }

    do {
      try (dstData as Data).write(to: url)
      return true
    } catch {
      return false
    }
  }
}
