import 'dart:io';
import 'package:flutter/services.dart';

/// Android SAF（存储访问框架）桥接：选择外部文件夹并持久化授权、原地读取。
///
/// 非 Android 平台不调用本服务（调用方需自行按平台分支）。
class SafService {
  static const _channel = MethodChannel('org.sokny.bookreader/saf');

  /// 打开系统目录选择器，持久化授权，返回 tree URI（content://...）；取消返回 null。
  static Future<String?> pickLibraryTree() async {
    return _channel.invokeMethod<String?>('pickLibraryTree');
  }

  /// 对单个文件 URI 持久化读取授权（导入分散文件时使用）。
  static Future<void> persistUriPermission(String uri) async {
    await _channel.invokeMethod<void>('persistUriPermission', {'uri': uri});
  }

  /// 递归列出 tree 下的所有书籍文件，每项含 uri/name/size。
  static Future<List<Map<String, dynamic>>> listTree(String treeUri) async {
    final list =
        await _channel.invokeMethod<List<dynamic>>('listTree', {'treeUri': treeUri});
    return (list ?? [])
        .cast<Map<dynamic, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// 经 ContentResolver 读取文档 URI 的字节（翻书用）。
  static Future<Uint8List> readUri(String uri) async {
    final bytes = await _channel.invokeMethod<Uint8List>('readUri', {'uri': uri});
    if (bytes == null) throw Exception('读取失败: $uri');
    return bytes;
  }

  /// 统一读取书籍字节：content:// 走 SAF，其余走 dart:io（桌面/真实路径）。
  static Future<Uint8List> readBookBytes(String path) {
    if (path.startsWith('content://')) return readUri(path);
    return File(path).readAsBytes();
  }
}
