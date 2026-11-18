import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/contacts/bloc/contacts_cubit.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/contacts/view/contact_avatar.dart';
import 'package:amber_mobile_client/features/contacts/view/last_message_preview.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The contacts tab: one row per contact, most recent activity first.
class ContactsList extends StatelessWidget {
  const ContactsList({super.key, this.onOpen});

  /// Called when a contact row is tapped.
  final ValueChanged<Contact>? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<ContactsCubit>().state;

    return switch (state.status) {
      ContactsStatus.loading when state.contacts.isEmpty => const Center(
        child: SizedBox(width: 160, child: ShadProgress()),
      ),
      ContactsStatus.failed => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.t('contacts.failed_loading')),
            const SizedBox(height: 12),
            ShadButton.outline(
              onPressed: () => context.read<ContactsCubit>().load(),
              // No shared translation key for "Retry" exists yet.
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      _ when state.contacts.isEmpty => Center(
        child: Text(
          l10n.t('contacts.none'),
          style: ShadTheme.of(context).textTheme.muted,
        ),
      ),
      // No pull-to-refresh: realtime events keep the list current.
      _ => ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.contacts.length,
        separatorBuilder: (_, _) => const ShadSeparator.horizontal(
          margin: EdgeInsets.symmetric(horizontal: 16),
        ),
        itemBuilder: (context, index) {
          final contact = state.contacts[index];
          return ContactTile(
            contact: contact,
            onTap: onOpen == null ? null : () => onOpen!(contact),
          );
        },
      ),
    };
  }
}

class ContactTile extends StatelessWidget {
  const ContactTile({super.key, required this.contact, this.onTap});

  final Contact contact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final myUserId = context.select(
      (AuthCubit cubit) => cubit.state.account?.id,
    );
    final user = contact.user;
    final preview = lastMessagePreview(
      l10n,
      contact.lastMessage,
      myUserId: myUserId,
    );
    // Like the desktop: the last message, or the @username when there is none.
    final subtitle = preview.isNotEmpty ? preview : '@${user.username}';
    final unread = contact.notifications > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              ContactAvatar(user: user),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: theme.textTheme.small.copyWith(
                              fontSize: 14,
                              height: 1.25,
                              fontWeight: unread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            subtitle,
                            style: theme.textTheme.muted.copyWith(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (unread) _UnreadBadge(count: contact.notifications),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round unread count, 20px, like the desktop's badge. Counts above 99 show
/// as 99+.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(right: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        shape: BoxShape.circle,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: theme.textTheme.small.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.secondaryForeground,
        ),
      ),
    );
  }
}
