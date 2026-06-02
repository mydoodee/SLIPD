import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:slip_d/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Test', () {
    testWidgets('Verify app starts and displays dashboard', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify dashboard is shown
      expect(find.text('slipD'), findsWidgets);
      expect(find.text('หน้าหลัก'), findsWidgets);
      expect(find.text('รายการ'), findsWidgets);
    });
  });
}
