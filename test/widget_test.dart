import 'package:amber_mobile_client/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shows the Amber home screen', (tester) async {
    await tester.pumpWidget(const AmberApp());

    expect(find.text('Amber'), findsOneWidget);
  });
}
