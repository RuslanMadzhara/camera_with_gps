package camera_gps_plugin

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.exifinterface.media.ExifInterface
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import kotlin.math.abs

class CameraWithGpsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private var channel: MethodChannel? = null
    private lateinit var context: Context
    private var activity: Activity? = null
    private var pendingResult: MethodChannel.Result? = null

    // ─────────────────────────────────────────────────────────────
    //  Flutter lifecycle
    // ─────────────────────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "camera_with_gps")
        channel!!.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel!!.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener { requestCode, resultCode, data ->
            if (requestCode == 999 && resultCode == Activity.RESULT_OK && data != null) {
                val uri: Uri? = data.data
                if (uri != null) {
                    try {
                        val input = context.contentResolver.openInputStream(uri)
                        val outFile = File(context.cacheDir, "saf_${System.currentTimeMillis()}.jpg")
                        val output = FileOutputStream(outFile)
                        input?.copyTo(output)
                        input?.close()
                        output.close()
                        pendingResult?.success(outFile.absolutePath)
                    } catch (e: Exception) {
                        pendingResult?.error("COPY_ERROR", "Failed to copy file: ${e.message}", null)
                    }
                } else {
                    pendingResult?.error("NO_FILE", "No file returned", null)
                }
                true
            } else {
                false
            }
        }
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }


    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "convertPhoto" -> {
                val args = call.arguments<Map<String, Any>>()!!
                val path = args["path"] as? String
                val latitude = args["latitude"] as? Double
                val longitude = args["longitude"] as? Double

                if (path == null) {
                    result.error("INVALID_ARGS", "Expected path", null)
                    return
                }

                val isFakeGps = containsFakeSamsungGps(path)
                val isZeroCoords = (latitude == 0.0 && longitude == 0.0)
                val isMissingCoords = (latitude == null || longitude == null)

                if (isFakeGps || isZeroCoords || isMissingCoords) {
                    removeGps(path)
                    if (!isMissingCoords && !isZeroCoords) {
                        val success = addGps(path, latitude!!, longitude!!)
                        result.success(success)
                    } else {
                        result.success(true)
                    }
                } else {
                    val success = addGps(path, latitude!!, longitude!!)
                    result.success(success)
                }
            }

            "openDocumentImage" -> openDocumentImage(result)

            "checkGps" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.success("ERROR")
                } else {
                    val isFakeGps = containsFakeSamsungGps(path)


                    val exif = try { ExifInterface(path) } catch (e: IOException) {
                        e.printStackTrace(); null
                    }

                    val latValue = exif?.getAttribute(ExifInterface.TAG_GPS_LATITUDE)
                    val lonValue = exif?.getAttribute(ExifInterface.TAG_GPS_LONGITUDE)

                    val latDec = dmsToDecimal(latValue)
                    val lonDec = dmsToDecimal(lonValue)

                    val isZeroCoords    = isApproximatelyZero(latDec) && isApproximatelyZero(lonDec)
                    val isMissingCoords = latDec == null || lonDec == null

                    val status = if (isFakeGps || isZeroCoords || isMissingCoords) "FAKE" else "OK"
                    result.success(status)
                }
            }

            "removeGps" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("INVALID_ARGS", "Expected path", null)
                    return
                }
                val success = removeGps(path)
                result.success(success)
            }

            else -> result.notImplemented()
        }
    }

    // ─────────────────────────────────────────────────────────────
    //  GPS helpers
    // ─────────────────────────────────────────────────────────────


    private fun dmsToDecimal(dms: String?): Double? {
        if (dms.isNullOrBlank()) return null
        val parts = dms.split(",")
        if (parts.size != 3) return null
        fun frac(r: String) = r.split("/").let { it[0].toDouble() / it[1].toDouble() }

        return try {
            val deg = frac(parts[0])
            val min = frac(parts[1])
            val sec = frac(parts[2])
            deg + min / 60 + sec / 3600
        } catch (e: Exception) {
            null
        }
    }


    private fun isApproximatelyZero(value: Double?, eps: Double = 1e-6): Boolean =
        value != null && abs(value) < eps


    private fun convertToDMS(coordinate: Double): String {
        val absCoord = abs(coordinate)
        val degrees = absCoord.toInt()
        val minutes = ((absCoord - degrees) * 60).toInt()
        val seconds = ((((absCoord - degrees) * 60) - minutes) * 60 * 1000).toInt()
        return "$degrees/1,$minutes/1,$seconds/1000"
    }

    // ─────────────────────────────────────────────────────────────
    //  EXIF operations
    // ─────────────────────────────────────────────────────────────

    private fun addGps(filePath: String, latitude: Double, longitude: Double): Boolean {
        val file = File(filePath)
        if (!file.exists()) return false

        return try {
            val exif = ExifInterface(filePath)
            val latStr = convertToDMS(latitude)
            val latRef = if (latitude >= 0) "N" else "S"
            val lonStr = convertToDMS(longitude)
            val lonRef = if (longitude >= 0) "E" else "W"

            exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE, latStr)
            exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE_REF, latRef)
            exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE, lonStr)
            exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE_REF, lonRef)

            exif.saveAttributes()
            true
        } catch (e: IOException) {
            e.printStackTrace()
            false
        }
    }

    private fun removeGps(filePath: String): Boolean {
        val file = File(filePath)
        if (!file.exists()) return false

        return try {
            val exif = ExifInterface(filePath)
            exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE, null)
            exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE_REF, null)
            exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE, null)
            exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE_REF, null)
            exif.setAttribute(ExifInterface.TAG_GPS_ALTITUDE, null)
            exif.setAttribute(ExifInterface.TAG_GPS_ALTITUDE_REF, null)
            exif.setAttribute(ExifInterface.TAG_GPS_PROCESSING_METHOD, null)
            exif.setAttribute(ExifInterface.TAG_GPS_TIMESTAMP, null)
            exif.setAttribute(ExifInterface.TAG_GPS_DATESTAMP, null)
            exif.saveAttributes()
            true
        } catch (e: IOException) {
            e.printStackTrace()
            false
        }
    }


    private fun containsFakeSamsungGps(filePath: String): Boolean {
        return try {
            val exif = ExifInterface(filePath)

            val latStr = exif.getAttribute(ExifInterface.TAG_GPS_LATITUDE)
            val lonStr = exif.getAttribute(ExifInterface.TAG_GPS_LONGITUDE)
            val date   = exif.getAttribute(ExifInterface.TAG_GPS_DATESTAMP)

            val latDec = dmsToDecimal(latStr)
            val lonDec = dmsToDecimal(lonStr)

            val coordsMissing = latDec == null || lonDec == null
            val coordsZero    = isApproximatelyZero(latDec) && isApproximatelyZero(lonDec)
            val oldDate       = date == "1970:01:01"

            coordsMissing || coordsZero || oldDate
        } catch (e: IOException) {
            false
        }
    }

    // ─────────────────────────────────────────────────────────────
    //  Android SAF helper
    // ─────────────────────────────────────────────────────────────

    private fun openDocumentImage(result: MethodChannel.Result) {
        val act = activity ?: run {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        pendingResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
        }

        act.startActivityForResult(intent, 999)
    }
}