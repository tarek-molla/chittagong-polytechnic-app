import 'package:flutter_test/flutter_test.dart';
import 'package:cpi_app/main.dart';

void main() {
  testWidgets('CPIApp renders and displays login gateway screen', (WidgetTester tester) async {
    // Build the CPIApp widget.
    await tester.pumpWidget(const CPIApp());

    // Verify that the login gateway elements are displayed.
    expect(find.text('CPI Portal'), findsOneWidget);
    expect(find.text('Chittagong Polytechnic Institute'), findsOneWidget);
    
    // Verify that role-based tab text is present.
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });
}
