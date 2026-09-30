import 'package:flutter_test/flutter_test.dart';
import 'package:openzip/app.dart';

void main() {
  testWidgets('OpenZip app smoke test', (tester) async {
    await tester.pumpWidget(const OpenZipApp());
    await tester.pump(const Duration(milliseconds: 400));
    // 核心 UI 元素
    expect(find.textContaining('收藏夹'), findsWidgets);
    expect(find.textContaining('新建'), findsWidgets);
    expect(find.textContaining('解压'), findsWidgets);
    expect(find.textContaining('文件(F)'), findsWidgets);
  });
}
