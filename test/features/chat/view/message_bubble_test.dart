import 'package:amber_mobile_client/core/l10n/dates.dart';
import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/chat/data/chat_models.dart';
import 'package:amber_mobile_client/features/chat/view/message_bubble.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

ChatMessage _fileMessage({
  required String contentType,
  required String filename,
  String? caption,
  int size = 2048,
}) {
  return ChatMessage.fromJson({
    'id': 'm-1',
    'conversation_id': 'c-1',
    'sender_id': 2,
    'seq': 1,
    'type': 'file',
    'content': {
      'url': 'https://files.example.com/$filename',
      'filename': filename,
      'content_type': contentType,
      'size': size,
      'text': ?caption,
    },
    'reaction_details': [],
    'created_at': '2026-11-18T10:00:00+00:00',
    'edited_at': null,
    'seen': false,
  });
}

Future<void> _pumpBubble(
  WidgetTester tester,
  ChatMessage message, {
  bool isMine = false,
}) async {
  final localizations = (await tester.runAsync(
    () => AppLocalizations.load('en'),
  ))!;
  await tester.pumpWidget(
    AppLocalizationsScope(
      localizations: localizations,
      child: ShadApp.custom(
        appBuilder: (_) => MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: message,
              isMine: isMine,
              myUserId: 1,
              nameOf: (id) => 'Bob',
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('file sizes are shown in B, KB or MB', () {
    expect(formatFileSize(512), '512 B');
    expect(formatFileSize(2048), '2 KB');
    expect(formatFileSize(3 * 1024 * 1024), '3.0 MB');
  });

  testWidgets('a document shows its name and size, not an image', (
    tester,
  ) async {
    await _pumpBubble(
      tester,
      _fileMessage(
        contentType: 'application/pdf',
        filename: 'report.pdf',
        size: 2048,
      ),
    );

    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.text('2 KB'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('an image shows a preview', (tester) async {
    await _pumpBubble(
      tester,
      _fileMessage(contentType: 'image/png', filename: 'photo.png'),
    );

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('a caption is shown under the attachment', (tester) async {
    await _pumpBubble(
      tester,
      _fileMessage(
        contentType: 'application/pdf',
        filename: 'report.pdf',
        caption: 'see attached',
      ),
    );

    expect(find.text('see attached'), findsOneWidget);
  });

  testWidgets('reactions show as emoji only, with +N when there are more', (
    tester,
  ) async {
    final message = ChatMessage.fromJson({
      'id': 'm-1',
      'conversation_id': 'c-1',
      'sender_id': 2,
      'seq': 1,
      'type': 'text',
      'content': {'text': 'hi'},
      'reaction_details': [
        {
          'emoji': '👍',
          'count': 3,
          'user_ids': [1, 2, 3],
        },
        {
          'emoji': '😂',
          'count': 1,
          'user_ids': [2],
        },
      ],
      'created_at': '2026-11-18T10:00:00+00:00',
      'edited_at': null,
      'seen': false,
    });
    await _pumpBubble(tester, message);

    expect(find.text('👍'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('👍 3'), findsNothing);
  });

  testWidgets('a log entry is a centred separator, not a bubble', (
    tester,
  ) async {
    final message = ChatMessage.fromJson({
      'id': 'm-2',
      'conversation_id': 'c-1',
      'sender_id': 2,
      'seq': 2,
      'type': 'log',
      'content': {'event': 'call.missed', 'text': 'Missed'},
      'reaction_details': [],
      'created_at': '2026-11-18T10:00:00+00:00',
      'edited_at': null,
      'seen': false,
    });
    final localizations = (await tester.runAsync(
      () => AppLocalizations.load('en'),
    ))!;
    await tester.pumpWidget(
      AppLocalizationsScope(
        localizations: localizations,
        child: ShadApp.custom(
          appBuilder: (_) => MaterialApp(
            home: Scaffold(body: LogSeparator(message: message)),
          ),
        ),
      ),
    );

    expect(find.text('Missed call'), findsOneWidget);
  });

  testWidgets('a reply quotes the author and the parent text', (tester) async {
    final message = ChatMessage.fromJson({
      'id': 'm-3',
      'conversation_id': 'c-1',
      'sender_id': 1,
      'seq': 3,
      'type': 'text',
      'content': {
        'text': 'agreed',
        'reply_to': {
          'id': 'm-1',
          'sender_id': 2,
          'type': 'text',
          'content': {'text': 'see you tomorrow'},
        },
      },
      'reaction_details': [],
      'created_at': '2026-11-18T10:00:00+00:00',
      'edited_at': null,
      'seen': false,
    });
    await _pumpBubble(tester, message, isMine: true);

    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('see you tomorrow'), findsOneWidget);
    expect(find.text('agreed'), findsOneWidget);
  });

  test('day dividers use the long date, like the desktop', () async {
    final localizations = (await AppLocalizations.load('en'));
    expect(
      formatLongDate(localizations.localeCode, DateTime(2026, 11, 18, 12)),
      'November 18, 2026',
    );
  });

  testWidgets('tapping a reply quote calls onQuoteTap', (tester) async {
    var tapped = false;
    final message = ChatMessage.fromJson({
      'id': 'm-9',
      'conversation_id': 'c-1',
      'sender_id': 1,
      'seq': 9,
      'type': 'text',
      'content': {
        'text': 'agreed',
        'reply_to': {
          'id': 'm-1',
          'sender_id': 2,
          'type': 'text',
          'content': {'text': 'see you tomorrow'},
        },
      },
      'reaction_details': [],
      'created_at': '2026-11-18T10:00:00+00:00',
      'edited_at': null,
      'seen': false,
    });
    final localizations = (await tester.runAsync(
      () => AppLocalizations.load('en'),
    ))!;
    await tester.pumpWidget(
      AppLocalizationsScope(
        localizations: localizations,
        child: ShadApp.custom(
          appBuilder: (_) => MaterialApp(
            home: Scaffold(
              body: MessageBubble(
                message: message,
                isMine: true,
                myUserId: 1,
                nameOf: (_) => 'Bob',
                onQuoteTap: () => tapped = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('see you tomorrow'));

    expect(tapped, isTrue);
  });
}
