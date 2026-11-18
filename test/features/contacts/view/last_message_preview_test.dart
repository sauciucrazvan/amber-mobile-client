import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/contacts/view/last_message_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppLocalizations l10n;

  setUpAll(() async => l10n = await AppLocalizations.load('en'));

  String preview(String type, Map<String, dynamic> content, {int sender = 2}) =>
      lastMessagePreview(
        l10n,
        LastMessage(senderId: sender, type: type, content: content),
        myUserId: 1,
      );

  test('text shows the content, prefixed when I sent it', () {
    expect(preview('text', {'text': 'hey'}), 'hey');
    expect(preview('text', {'text': 'hey'}, sender: 1), 'You: hey');
  });

  test('file shows the file name, or Attachment', () {
    expect(preview('file', {'filename': 'photo.png'}), 'photo.png');
    expect(preview('file', {}), 'Attachment');
  });

  test('call logs use the call log translations', () {
    expect(preview('log', {'event': 'call.missed'}), 'Missed call');
    expect(preview('log', {'event': 'call.something_new'}), 'Call');
  });

  test('unknown types and no message', () {
    expect(preview('sticker', {}), 'Message');
    expect(lastMessagePreview(l10n, null, myUserId: 1), '');
  });
}
