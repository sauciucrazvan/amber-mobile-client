import 'package:amber_mobile_client/features/chat/data/chat_file_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps accepted extensions to the content type the backend expects', () {
    expect(ChatFileRules.contentTypeFor('png'), 'image/png');
    expect(ChatFileRules.contentTypeFor('PDF'), 'application/pdf');
    expect(ChatFileRules.contentTypeFor('svg'), isNull);
    expect(ChatFileRules.contentTypeFor(null), isNull);
  });

  test('the picker filter lists the accepted extensions', () {
    expect(ChatFileRules.extensions, containsAll(['jpg', 'pdf', 'docx']));
    expect(ChatFileRules.extensions, isNot(contains('exe')));
  });

  test('problemFor reports an unsupported type first', () {
    expect(
      ChatFileRules.problemFor(extension: 'exe', size: 0),
      'conversations.files.type_not_accepted',
    );
  });

  test('problemFor rejects empty and oversized files', () {
    expect(
      ChatFileRules.problemFor(extension: 'pdf', size: 0),
      'conversations.files.empty',
    );
    expect(
      ChatFileRules.problemFor(
        extension: 'pdf',
        size: ChatFileRules.maxBytes + 1,
      ),
      'conversations.files.too_big',
    );
  });

  test('problemFor accepts a file at the size limit', () {
    expect(
      ChatFileRules.problemFor(extension: 'pdf', size: ChatFileRules.maxBytes),
      isNull,
    );
  });

  test('images are recognised by content type', () {
    expect(ChatFileRules.isImage('image/heic'), isTrue);
    expect(ChatFileRules.isImage('application/pdf'), isFalse);
  });
}
