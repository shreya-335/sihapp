import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';

void main() {
  testWidgets('Renders home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CameraApp());

    // Verify that the home screen is displayed.
    expect(find.text('File New Crop Claim'), findsOneWidget);
  });
}
