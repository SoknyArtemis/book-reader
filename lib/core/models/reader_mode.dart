/// 阅读翻页模式。
enum ReaderMode { scroll, page }

extension ReaderModeX on ReaderMode {
  String get label => this == ReaderMode.scroll ? '滚动' : '分页';
}
