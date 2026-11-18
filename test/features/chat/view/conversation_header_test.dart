import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/l10n/relative_time.dart';
import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/session/session_store.dart';
import 'package:amber_mobile_client/features/chat/view/conversation_header.dart';
import 'package:amber_mobile_client/features/contacts/bloc/contacts_cubit.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/contacts/data/contacts_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/memory_key_value_storage.dart';

Future<void> _pumpHeader(WidgetTester tester, ContactUser contact) async {
  final localizations = (await tester.runAsync(
    () => AppLocalizations.load('en'),
  ))!;
  final cubit = ContactsCubit(
    myUserId: 1,
    api: ContactsApi(
      ApiClient(
        sessionStore: SessionStore(MemoryKeyValueStorage()),
        dio: Dio()
          ..httpClientAdapter = FakeHttpAdapter((_) => jsonResponse([], 200)),
      ),
    ),
  );
  addTearDown(cubit.close);
  await tester.pumpWidget(
    AppLocalizationsScope(
      localizations: localizations,
      child: ShadApp.custom(
        appBuilder: (_) => MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: ConversationHeader(contact: contact, onTap: () {}),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test('relative times follow the desktop thresholds', () async {
    final l10n = (await AppLocalizations.load('en'));
    final now = DateTime.utc(2026, 11, 18, 12);

    expect(
      formatRelativeTime(
        l10n,
        now.subtract(const Duration(seconds: 20)),
        now: now,
      ),
      'now',
    );
    expect(
      formatRelativeTime(
        l10n,
        now.subtract(const Duration(minutes: 5)),
        now: now,
      ),
      '5m ago',
    );
    expect(
      formatRelativeTime(
        l10n,
        now.subtract(const Duration(hours: 3)),
        now: now,
      ),
      '3h ago',
    );
    expect(
      formatRelativeTime(l10n, now.subtract(const Duration(days: 2)), now: now),
      '2d ago',
    );
    expect(
      formatRelativeTime(
        l10n,
        now.subtract(const Duration(days: 14)),
        now: now,
      ),
      '2w ago',
    );
    expect(formatRelativeTime(l10n, null, now: now), '');
  });

  testWidgets(
    'an offline contact alternates between username and last active',
    (tester) async {
      final lastActive = DateTime.now().toUtc().subtract(
        const Duration(minutes: 5),
      );
      await _pumpHeader(
        tester,
        ContactUser(
          id: 2,
          username: 'bob',
          fullName: 'Bob Ionescu',
          lastActiveAt: lastActive,
        ),
      );

      expect(find.text('Bob Ionescu'), findsOneWidget);
      expect(find.text('@bob'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.textContaining('Last active 5m ago'), findsOneWidget);
    },
  );

  testWidgets('an online contact keeps showing the username', (tester) async {
    await _pumpHeader(
      tester,
      ContactUser(
        id: 2,
        username: 'bob',
        fullName: 'Bob Ionescu',
        online: true,
        lastActiveAt: DateTime.now().toUtc(),
      ),
    );

    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('@bob'), findsOneWidget);
    expect(find.textContaining('Last active'), findsNothing);
  });
}
