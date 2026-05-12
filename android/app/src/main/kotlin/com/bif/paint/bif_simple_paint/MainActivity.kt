package com.bif.paint.bif_simple_paint

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL_NAME = "com.bif.paint.bif_simple_paint/document_file"
        const val MIME_TYPE_ANY = "*/*"
        const val OPEN_DOCUMENT_REQUEST_CODE = 1001
        const val CREATE_DOCUMENT_REQUEST_CODE = 1002
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingSuggestedFileName: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" -> result.success(true)
                    "openDocument" -> openDocument(result)
                    "createDocument" -> createDocument(call, result)
                    "readDocument" -> readDocument(call, result)
                    "writeDocument" -> writeDocument(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun openDocument(result: MethodChannel.Result) {
        if (!setPendingResult(result)) {
            return
        }

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = MIME_TYPE_ANY
        }
        startActivityForResult(intent, OPEN_DOCUMENT_REQUEST_CODE)
    }

    private fun createDocument(call: MethodCall, result: MethodChannel.Result) {
        if (!setPendingResult(result)) {
            return
        }

        val suggestedFileName = call.argument<String>("suggestedFileName").orEmpty()
        pendingSuggestedFileName = suggestedFileName
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/octet-stream"
            putExtra(Intent.EXTRA_TITLE, suggestedFileName)
        }
        startActivityForResult(intent, CREATE_DOCUMENT_REQUEST_CODE)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        when (requestCode) {
            OPEN_DOCUMENT_REQUEST_CODE -> handleOpenDocumentResult(resultCode, data)
            CREATE_DOCUMENT_REQUEST_CODE -> handleCreateDocumentResult(resultCode, data)
        }
    }

    private fun readDocument(call: MethodCall, result: MethodChannel.Result) {
        val rawUri = call.argument<String>("uri")
        if (rawUri.isNullOrBlank()) {
            result.error("missing_uri", "Document URI is required.", null)
            return
        }

        try {
            val uri = Uri.parse(rawUri)
            val bytes = requireNotNull(readBytes(uri)) {
                "Unable to read document bytes."
            }
            val displayName = resolveDisplayName(uri) ?: uri.lastPathSegment ?: "Untitled"
            result.success(
                mapOf(
                    "uri" to uri.toString(),
                    "displayName" to displayName,
                    "bytes" to bytes,
                )
            )
        } catch (error: Exception) {
            result.error("read_failed", error.message, null)
        }
    }

    private fun writeDocument(call: MethodCall, result: MethodChannel.Result) {
        val rawUri = call.argument<String>("uri")
        val bytes = call.argument<ByteArray>("bytes")
        if (rawUri.isNullOrBlank()) {
            result.error("missing_uri", "Document URI is required.", null)
            return
        }
        if (bytes == null) {
            result.error("missing_bytes", "Bytes are required to write a document.", null)
            return
        }

        try {
            val uri = Uri.parse(rawUri)
            writeBytes(uri, bytes)
            result.success(null)
        } catch (error: Exception) {
            result.error("write_failed", error.message, null)
        }
    }

    private fun handleOpenDocumentResult(resultCode: Int, intent: Intent?) {
        val pending = pendingResult ?: return
        if (resultCode != Activity.RESULT_OK) {
            pending.success(null)
            clearPendingState()
            return
        }

        val uri = intent?.data
        if (uri == null) {
            pending.error("missing_uri", "No document URI returned.", null)
            clearPendingState()
            return
        }

        try {
            takePersistablePermission(uri, intent)
            val bytes = requireNotNull(readBytes(uri)) {
                "Unable to read selected document."
            }
            val displayName = resolveDisplayName(uri) ?: uri.lastPathSegment ?: "Untitled"
            pending.success(
                mapOf(
                    "uri" to uri.toString(),
                    "displayName" to displayName,
                    "bytes" to bytes,
                )
            )
        } catch (error: Exception) {
            pending.error("open_failed", error.message, null)
        } finally {
            clearPendingState()
        }
    }

    private fun handleCreateDocumentResult(resultCode: Int, intent: Intent?) {
        val pending = pendingResult ?: return
        if (resultCode != Activity.RESULT_OK) {
            pending.success(null)
            clearPendingState()
            return
        }

        val uri = intent?.data
        val suggestedFileName = pendingSuggestedFileName
        if (uri == null) {
            pending.error("missing_uri", "Document creation did not return a writable URI.", null)
            clearPendingState()
            return
        }

        try {
            takePersistablePermission(uri, intent)
            val displayName =
                resolveDisplayName(uri) ?: suggestedFileName ?: uri.lastPathSegment ?: "Untitled"
            pending.success(
                mapOf(
                    "uri" to uri.toString(),
                    "displayName" to displayName,
                )
            )
        } catch (error: Exception) {
            pending.error("create_failed", error.message, null)
        } finally {
            clearPendingState()
        }
    }

    private fun takePersistablePermission(uri: Uri, intent: Intent?) {
        val flags = intent?.flags ?: 0
        val permissionFlags =
            flags and
                (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        if (permissionFlags != 0) {
            runCatching {
                contentResolver.takePersistableUriPermission(uri, permissionFlags)
            }
        }
    }

    private fun readBytes(uri: Uri): ByteArray? {
        contentResolver.openInputStream(uri)?.use { input ->
            return input.readBytes()
        }
        return null
    }

    private fun writeBytes(uri: Uri, bytes: ByteArray) {
        contentResolver.openOutputStream(uri, "wt")?.use { output ->
            output.write(bytes)
            output.flush()
        } ?: error("Unable to open the document for writing.")
    }

    private fun resolveDisplayName(uri: Uri): String? {
        contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0) {
                    return cursor.getString(index)
                }
            }
        }

        return if (DocumentsContract.isDocumentUri(this, uri)) {
            DocumentsContract.getDocumentId(uri).substringAfterLast(':')
        } else {
            null
        }
    }

    private fun setPendingResult(result: MethodChannel.Result): Boolean {
        if (pendingResult != null) {
            result.error("already_active", "A document picker request is already active.", null)
            return false
        }

        pendingResult = result
        pendingSuggestedFileName = null
        return true
    }

    private fun clearPendingState() {
        pendingResult = null
        pendingSuggestedFileName = null
    }
}
