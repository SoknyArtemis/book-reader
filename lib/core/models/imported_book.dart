/// 通过"导入书籍"单独加入书架的一本书。
///
/// 在 Android 上 [path] 为 SAF 文档 URI（content://...），桌面为真实文件路径。
/// 元数据（名称/大小）在挑选时即由 file_picker 提供，避免额外 stat 调用。
class ImportedBook {
  const ImportedBook({
    required this.path,
    required this.name,
    required this.size,
  });

  final String path;
  final String name;
  final int size;

  Map<String, dynamic> toJson() => {'path': path, 'name': name, 'size': size};

  factory ImportedBook.fromJson(Map<String, dynamic> j) => ImportedBook(
        path: j['path'] as String,
        name: j['name'] as String,
        size: (j['size'] as num?)?.toInt() ?? 0,
      );
}
