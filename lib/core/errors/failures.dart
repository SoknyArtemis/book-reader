/// 书籍加载失败。解析器抛出后由阅读器统一展示。
class BookLoadFailure implements Exception {
  const BookLoadFailure(this.message);
  final String message;

  @override
  String toString() => 'BookLoadFailure: $message';
}
