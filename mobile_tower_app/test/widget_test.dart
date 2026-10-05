import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tower_app/main.dart';
import 'package:mobile_tower_app/screens/splash_screen.dart';

void main() {
  testWidgets('MTMMS app initializes and loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MTMMSApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('MTMMS'), findsOneWidget);
    expect(find.text('Mobile Tower Monitoring and Management System'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
  });
}
