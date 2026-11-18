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
    final subtitle = preview.isNotEmpty
        ? preview
        : l10n.t(user.online ? 'common.online' : 'common.offline');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ContactAvatar(user: user),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: theme.textTheme.p.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.muted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (contact.notifications > 0) ...[
              const SizedBox(width: 8),
              ShadBadge(child: Text('${contact.notifications}')),
            ],
          ],
        ),
      ),
    );
  }
}
