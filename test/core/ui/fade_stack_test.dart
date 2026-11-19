import 'package:amber_mobile_client/core/ui/fade_stack.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('only the selected child is shown and can be tapped', (
    tester,
  ) async {
    var taps = <String>[];
    Widget child(String name) =>
        GestureDetector(onTap: () => taps.add(name), child: Text(name));

    await tester.pumpWidget(
      MaterialApp(
        home: FadeStack(index: 0, children: [child('first'), child('second')]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('first'));
    expect(taps, ['first']);

    await tester.pumpWidget(
      MaterialApp(
        home: FadeStack(index: 1, children: [child('first'), child('second')]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('second'), findsOneWidget);
    await tester.tap(find.text('second'));
    expect(taps, ['first', 'second']);
  });
}
