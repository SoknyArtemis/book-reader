package org.sokny.bookreader

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.ArrayDeque

/// 通过 SAF（存储访问框架）实现"选择外部文件夹 → 授权 → 原地读取"，
/// 兼容 Android 11+ 作用域存储：文件夹 tree URI 与单文件 URI 均持久化授权，
/// 之后经 ContentResolver 直接读取，无需把文件拷进应用私有目录。
///
/// 注：本 Flutter 版次 app 模块未稳定暴露 androidx.activity 的 registerForActivityResult，
/// 故选目录改用标准 startActivityForResult/onActivityResult。
class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null
    private val reqTree = 7351

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickLibraryTree" -> {
                        pendingResult = result
                        @Suppress("DEPRECATION")
                        startActivityForResult(
                            Intent(Intent.ACTION_OPEN_DOCUMENT_TREE),
                            reqTree,
                        )
                    }
                    "persistUriPermission" -> {
                        val uri = call.argument<String>("uri")
                        if (uri == null) {
                            result.error("NO_URI", "uri required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            contentResolver.takePersistableUriPermission(
                                Uri.parse(uri),
                                Intent.FLAG_GRANT_READ_URI_PERMISSION,
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("PERM_FAIL", e.message, null)
                        }
                    }
                    "listTree" -> {
                        val treeUri = call.argument<String>("treeUri")
                        if (treeUri == null) {
                            result.error("NO_TREE", "treeUri required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(listTree(Uri.parse(treeUri)))
                        } catch (e: Exception) {
                            result.error("LIST_FAIL", e.message, null)
                        }
                    }
                    "readUri" -> {
                        val uri = call.argument<String>("uri")
                        if (uri == null) {
                            result.error("NO_URI", "uri required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(readUriBytes(Uri.parse(uri)))
                        } catch (e: Exception) {
                            result.error("READ_FAIL", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != reqTree) return
        val result = pendingResult
        pendingResult = null
        if (result == null) return
        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }
        val uri = data?.data
        if (uri == null) {
            result.success(null)
            return
        }
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        } catch (_: Exception) {
            // 某些卷不支持持久化权限，但本次返回会话内仍可读取。
        }
        result.success(uri.toString())
    }

    /// 递归列出 tree 下所有受支持的书籍文件，返回 {uri, name, size}。
    private fun listTree(treeUri: Uri): List<Map<String, Any?>> {
        val root = DocumentFile.fromTreeUri(this, treeUri) ?: return emptyList()
        val out = ArrayList<HashMap<String, Any?>>()
        val stack = ArrayDeque<DocumentFile>()
        root.listFiles()?.forEach { stack.add(it) }
        while (stack.isNotEmpty()) {
            val f = stack.removeFirst()
            if (f.isDirectory) {
                f.listFiles()?.forEach { stack.add(it) }
            } else {
                val name = f.name ?: continue
                if (!isBook(name)) continue
                val info = HashMap<String, Any?>()
                info["uri"] = f.uri.toString()
                info["name"] = name
                info["size"] = f.length()
                out.add(info)
            }
        }
        return out
    }

    /// 经 ContentResolver 读取文档 URI 的完整字节（用于翻书）。
    private fun readUriBytes(uri: Uri): ByteArray {
        val buf = ByteArrayOutputStream()
        val input = contentResolver.openInputStream(uri)
            ?: throw IllegalStateException("无法打开 URI: $uri")
        input.use {
            val chunk = ByteArray(8192)
            var n: Int
            while (it.read(chunk).also { r -> n = r } >= 0) {
                buf.write(chunk, 0, n)
            }
        }
        return buf.toByteArray()
    }

    private fun isBook(name: String): Boolean {
        val lower = name.lowercase()
        return lower.endsWith(".epub") || lower.endsWith(".pdf") ||
            lower.endsWith(".txt") || lower.endsWith(".mobi") ||
            lower.endsWith(".azw") || lower.endsWith(".azw3") ||
            lower.endsWith(".fb2") || lower.endsWith(".cbz") ||
            lower.endsWith(".cbr") || lower.endsWith(".html") ||
            lower.endsWith(".htm") || lower.endsWith(".md")
    }

    companion object {
        const val CHANNEL = "org.sokny.bookreader/saf"
    }
}
