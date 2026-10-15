// 最小冒烟测试：确认应用能正常构建（替代 flutter create 默认的计数器占位测试）。
import 'package:book_reader/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App 能正常构建', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(App), findsOneWidget);
  });
}
