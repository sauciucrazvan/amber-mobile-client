import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/chat/data/emoji_catalog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Icon for each category tab, as on the desktop.
const _categoryIcons = {
  'people': '😀',
  'nature': '🐶',
  'foods': '🍔',
  'activity': '🎉',
  'places': '✈️',
  'objects': '💡',
  'symbols': '🔥',
  'flags': '🏳️',
};

/// Translation key for each category name, as on the desktop.
const _categoryKeys = {
  'people': 'smileys',
  'nature': 'animals',
  'foods': 'food',
  'activity': 'activities',
  'places': 'travel',
  'objects': 'objects',
  'symbols': 'symbols',
  'flags': 'flags',
};

/// Full emoji picker in a bottom sheet. Resolves to the chosen emoji, or
/// null when dismissed.
Future<String?> showEmojiPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const EmojiPickerSheet(),
  );
}

/// The desktop's emoji panel: a search box, category tabs and a grid.
class EmojiPickerSheet extends StatefulWidget {
  const EmojiPickerSheet({super.key});

  @override
  State<EmojiPickerSheet> createState() => _EmojiPickerSheetState();
}

class _EmojiPickerSheetState extends State<EmojiPickerSheet> {
  final _catalog = EmojiCatalog.load();
  int _category = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: FutureBuilder<List<EmojiCategory>>(
          future: _catalog,
          builder: (context, snapshot) {
            final categories = snapshot.data;
            if (categories == null) {
              return const Center(
                child: SizedBox(width: 160, child: ShadProgress(minHeight: 2)),
              );
            }

            final query = _query.trim().toLowerCase();
            final emojis = query.isEmpty
                ? categories[_category].emojis
                : [
                    for (final category in categories)
                      for (final entry in category.emojis)
                        if (entry.search.contains(query)) entry,
                  ];

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      l10n.t('conversations.reactions.title'),
                      style: theme.textTheme.large,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ShadInput(
                    key: const ValueKey('emoji-search'),
                    placeholder: Text(l10n.t('emoji.panel.search_placeholder')),
                    leading: const Icon(LucideIcons.search, size: 16),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                if (query.isEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < categories.length; i++)
                          _CategoryTab(
                            key: ValueKey('emoji-category-${categories[i].id}'),
                            icon: _categoryIcons[categories[i].id] ?? '🙂',
                            label: l10n.t(
                              'emoji.categories.'
                              '${_categoryKeys[categories[i].id]}',
                            ),
                            selected: i == _category,
                            onPressed: () => setState(() => _category = i),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: emojis.isEmpty
                      ? Center(
                          child: Text(
                            l10n.t('emoji.panel.no_results'),
                            style: theme.textTheme.muted,
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 52,
                              ),
                          itemCount: emojis.length,
                          itemBuilder: (context, index) {
                            final emoji = emojis[index].emoji;
                            return ShadButton.ghost(
                              width: 44,
                              height: 44,
                              padding: EdgeInsets.zero,
                              onPressed: () => Navigator.of(context).pop(emoji),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A category tab: the category icon, selected like the desktop's active tab.
class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Text(icon, style: const TextStyle(fontSize: 18));
    final button = selected
        ? ShadIconButton.secondary(
            width: 40,
            height: 40,
            padding: EdgeInsets.zero,
            icon: iconWidget,
            onPressed: onPressed,
          )
        : ShadIconButton.ghost(
            width: 40,
            height: 40,
            padding: EdgeInsets.zero,
            icon: iconWidget,
            onPressed: onPressed,
          );
    return Tooltip(message: label, child: button);
  }
}
