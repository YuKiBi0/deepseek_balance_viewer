import 'package:flutter_test/flutter_test.dart';
import 'package:deepseek_balance_viewer/main.dart';

void main() {
  testWidgets('App starts with splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DeepSeekBalanceApp());
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
