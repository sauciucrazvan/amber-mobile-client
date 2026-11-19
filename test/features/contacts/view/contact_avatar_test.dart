import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/contacts/view/contact_avatar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<void> _pump(WidgetTester tester, ContactUser user) async {
  await tester.pumpWidget(
    ShadApp.custom(
      appBuilder: (_) => MaterialApp(
        home: Scaffold(body: ContactAvatar(user: user)),
      ),
    ),
  );
}

void main() {
  testWidgets('an online contact shows a green presence dot', (tester) async {
    await _pump(
      tester,
      const ContactUser(id: 2, username: 'bob', online: true),
    );

    expect(find.byKey(const ValueKey('presence-online')), findsOneWidget);
    expect(find.byKey(const ValueKey('presence-offline')), findsNothing);
  });

  testWidgets('an offline contact shows a red presence dot', (tester) async {
    await _pump(tester, const ContactUser(id: 2, username: 'bob'));

    expect(find.byKey(const ValueKey('presence-offline')), findsOneWidget);
    expect(find.byKey(const ValueKey('presence-online')), findsNothing);
  });
}
