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

Future<void> _pumpBubble(WidgetTester tester, ChatMessage message) async {
  final localizations = (await tester.runAsync(
    () => AppLocalizations.load('en'),
  ))!;
  await tester.pumpWidget(
    AppLocalizationsScope(
      localizations: localizations,
      child: ShadApp.custom(
        appBuilder: (_) => MaterialApp(
          home: Scaffold(body: MessageBubble(message: message, isMine: false)),
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
}
