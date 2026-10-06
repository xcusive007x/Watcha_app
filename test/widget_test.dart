import 'package:flutter_test/flutter_test.dart';
import 'package:watcha/main.dart';

void main() {
  testWidgets('shows authentication screen when signed out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const WatchaApp());
    await tester.pumpAndSettle();

    expect(find.text('ยินดีต้อนรับกลับมา'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
    expect(find.text('อีเมล'), findsOneWidget);
  });

  testWidgets('toggles registration form', (WidgetTester tester) async {
    await tester.pumpWidget(const WatchaApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('ยังไม่มีบัญชี? สมัครสมาชิก'));
    await tester.pumpAndSettle();

    expect(find.text('สร้างบัญชี Watcha'), findsOneWidget);
    expect(find.text('สมัครสมาชิก'), findsOneWidget);
    expect(find.text('ชื่อ'), findsOneWidget);
  });
}
