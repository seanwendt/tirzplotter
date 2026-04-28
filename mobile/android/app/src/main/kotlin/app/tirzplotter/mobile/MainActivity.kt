package app.tirzplotter.mobile

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private companion object {
        const val DOWNLOADS_CHANNEL = "tirzplotter/downloads"
        const val SAVE_TO_DOWNLOADS = "saveToDownloads"
        const val DEFAULT_EXPORT_FILENAME = "tirzepatide-doses.json"
        const val JSON_MIME_TYPE = "application/json"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DOWNLOADS_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != SAVE_TO_DOWNLOADS) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val rawFilename = call.argument<String>("filename") ?: DEFAULT_EXPORT_FILENAME
                val contents = call.argument<String>("contents") ?: "[]"
                val filename = rawFilename.replace(Regex("[^A-Za-z0-9._-]"), "-")

                try {
                    val savedPath = saveToDownloads(filename, contents)
                    result.success(savedPath)
                } catch (error: Exception) {
                    result.error("EXPORT_FAILED", error.message, null)
                }
            }
    }

    private fun saveToDownloads(filename: String, contents: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, filename)
                put(MediaStore.Downloads.MIME_TYPE, JSON_MIME_TYPE)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Could not create Downloads entry.")

            try {
                resolver.openOutputStream(uri)?.use { output ->
                    output.write(contents.toByteArray(Charsets.UTF_8))
                } ?: throw IllegalStateException("Could not open Downloads entry.")
            } catch (error: Exception) {
                resolver.delete(uri, null, null)
                throw error
            }

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)

            return "${Environment.DIRECTORY_DOWNLOADS}/$filename"
        }

        @Suppress("DEPRECATION")
        val downloads = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!downloads.exists()) downloads.mkdirs()

        val file = File(downloads, filename)
        file.writeText(contents, Charsets.UTF_8)
        return file.absolutePath
    }
}
