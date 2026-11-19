import 'package:amber_mobile_client/features/chat/view/swipe_to_reply.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<int> _drag(WidgetTester tester, double dx) async {
  var replies = 0;
  await tester.pumpWidget(
    ShadApp.custom(
      appBuilder: (_) => MaterialApp(
        home: Scaffold(
          body: SwipeToReply(
            onReply: () => replies++,
            child: const SizedBox(
              key: ValueKey('bubble'),
              width: 300,
              height: 60,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.drag(find.byKey(const ValueKey('bubble')), Offset(dx, 0));
  await tester.pumpAndSettle();
  return replies;
}

void main() {
  testWidgets('a drag to the right past the threshold replies', (tester) async {
    expect(await _drag(tester, 120), 1);
  });

  testWidgets('a drag to the left past the threshold replies', (tester) async {
    expect(await _drag(tester, -120), 1);
  });

  testWidgets('a short drag does not reply', (tester) async {
    expect(await _drag(tester, 20), 0);
  });

  testWidgets('the bubble springs back after a drag', (tester) async {
    await _drag(tester, 120);
    final bubble = tester.getTopLeft(find.byKey(const ValueKey('bubble')));
    expect(bubble.dx, 0);
  });
}
