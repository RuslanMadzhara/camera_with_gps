package camera_gps_plugin

import androidx.exifinterface.media.ExifInterface
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.io.File
import java.io.IOException
import kotlin.math.abs

class CameraWithGpsPlugin : FlutterPlugin, MethodCallHandler {
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "camera_with_gps")
        channel!!.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if ("convertPhoto" == call.method) {
            // Retrieve arguments safely
            val args = call.arguments<Map<String, Any>>()
            val path = args!!["path"] as String?
            val latitude = args["latitude"] as Double?
            val longitude = args["longitude"] as Double?

            if (path == null || latitude == null || longitude == null) {
                result.error("INVALID_ARGS", "Expected path, latitude, and longitude", null)
                return
            }

            val success = addGps(path, latitude, longitude)
            result.success(success)
        } else {
            result.notImplemented()
        }
    }

    /**
     * Adds GPS metadata to the JPEG image at the given file path.
     * If the GPS metadata already exists, it returns true.
     *
     * @param filePath  the absolute path to the JPEG file.
     * @param latitude  the GPS latitude to embed.
     * @param longitude the GPS longitude to embed.
     * @return true if the operation is successful (or GPS already exists), false otherwise.
     */
    private fun addGps(filePath: String, latitude: Double, longitude: Double): Boolean {
        val file = File(filePath)
        if (!file.exists()) {
            return false
        }

        try {
            val exif = ExifInterface(filePath)
            // Check if GPS metadata is already present
            val existingLat = exif.getAttribute(ExifInterface.TAG_GPS_LATITUDE)
            if (existingLat != null) {
                return true // GPS metadata already exists
            }

            val latStr = convertToDMS(latitude)
            val latRef = if (latitude >= 0) "N" else "S"
            val lonStr = convertToDMS(longitude)
            val lonRef = if (longitude >= 0) "E" else "W"

            exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE, latStr)
            exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE_REF, latRef)
            exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE, lonStr)
            exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE_REF, lonRef)
            exif.saveAttributes()
            return true
        } catch (e: IOException) {
            e.printStackTrace()
            return false
        }
    }

    /**
     * Converts a decimal coordinate into DMS (degrees/minutes/seconds) format as a string.
     *
     * The ExifInterface expects a string in the format: "degrees/1,minutes/1,seconds/1000"
     *
     * @param coordinate the coordinate (latitude or longitude)
     * @return a string representing the coordinate in DMS format.
     */
    private fun convertToDMS(coordinate: Double): String {
        val absCoord = abs(coordinate)
        val degrees = absCoord.toInt()
        val minutes = ((absCoord - degrees) * 60).toInt()
        val seconds = ((((absCoord - degrees) * 60) - minutes) * 60 * 1000).toInt()
        return "$degrees/1,$minutes/1,$seconds/1000"
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        channel!!.setMethodCallHandler(null)
    }
}