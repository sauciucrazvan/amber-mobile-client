# Chat: Emoji picker and reactions panel

Sources: `lib/features/chat/data/emoji_catalog.dart`, `lib/features/chat/view/emoji_sheet.dart`, `lib/features/chat/view/reactions_panel.dart`, `lib/features/chat/view/message_actions.dart`, `lib/features/chat/view/message_bubble.dart`

## Adding a reaction

- **Quick reactions:** 👍 ❤️ 😂 😊 at the top of the long-press sheet, as on the desktop.
- **More reactions:** opens the full emoji picker, built in the app (`EmojiPickerSheet`), in a bottom sheet. It has a search box, category tabs and a grid, with the same categories as the desktop. Choosing an emoji adds it as a reaction. The emoji list is bundled in `assets/emoji/catalog.json`, from the desktop's emoji data (set 15), and loads once.

Both paths call `ConversationCubit.react`. If the current user already reacted with that emoji, it removes the reaction instead.

## The reactions panel

Tapping a reaction chip on a bubble opens a panel listing each emoji with its count and who reacted. Names come from the conversation: the current user is shown as "You" and the contact by name. For each emoji, the button shows **Remove your reaction** if the current user reacted, or **Click to react** if not.

The panel reads the message from the cubit, so it shows the latest reactions rather than the copy from when the bubble was built.

## Platform note

`emoji_picker_flutter` is built on Flutter's own Material widgets. Those look up Flutter's `MaterialLocalizations`, and `material_ui` provides a different class. `showEmojiPicker` therefore gives the picker Flutter's localizations with `Localizations.override`. This is the only place the app imports Flutter's `material.dart`, which is deprecated as a whole library.

## Tests

The tests check that **More reactions** opens the picker, and that quick reactions and the panel's remove action send the right requests. They don't select an emoji inside the picker. The package draws its grid with rich text and its own category bar, which the test finder can't reach reliably. Choosing an emoji on a device still needs a manual check.
