import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One emoji, with its search text: name, keywords and emoticons in lower case.
class EmojiEntry {
  const EmojiEntry(this.emoji, this.search);

  final String emoji;
  final String search;
}

/// One tab of the picker, in the desktop's order.
class EmojiCategory {
  const EmojiCategory(this.id, this.emojis);

  final String id;
  final List<EmojiEntry> emojis;
}

/// The emoji list, bundled from the desktop's emoji data (set 15). Loaded once.
abstract final class EmojiCatalog {
  static const _asset = 'assets/emoji/catalog.json';
  static List<EmojiCategory>? _loaded;

  /// Caches the parsed list, not the future, so a load that started in one
  /// zone does not block later loads.
  static Future<List<EmojiCategory>> load() async {
    return _loaded ??= _parse(await rootBundle.loadString(_asset));
  }

  static List<EmojiCategory> _parse(String source) {
    final categories = jsonDecode(source) as List<dynamic>;
    return [
      for (final category in categories)
        EmojiCategory(category['id'] as String, [
          for (final pair in category['e'] as List<dynamic>)
            EmojiEntry((pair as List<dynamic>)[0] as String, pair[1] as String),
        ]),
    ];
  }
}
