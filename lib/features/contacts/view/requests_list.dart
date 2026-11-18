import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/features/contacts/bloc/contacts_cubit.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/contacts/view/contact_avatar.dart';
import 'package:amber_mobile_client/features/contacts/view/contact_feedback.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The inbox tab: incoming friend requests with accept and decline.
class RequestsList extends StatelessWidget {
  const RequestsList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requests = context.select(
      (ContactsCubit cubit) => cubit.state.requests,
    );

    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.t('contacts.requests.none'),
            style: ShadTheme.of(context).textTheme.muted,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const ShadSeparator.horizontal(
        margin: EdgeInsets.symmetric(horizontal: 16),
      ),
      itemBuilder: (context, index) => RequestTile(
        key: ValueKey(requests[index].user.id),
        request: requests[index],
      ),
    );
  }
}

class RequestTile extends StatefulWidget {
  const RequestTile({super.key, required this.request});

  final ContactRequest request;

  @override
  State<RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<RequestTile> {
  bool _busy = false;

  Future<void> _respond({required bool accept}) async {
    final cubit = context.read<ContactsCubit>();
    final username = widget.request.user.username;
    setState(() => _busy = true);
    try {
      if (accept) {
        await cubit.accept(widget.request);
      } else {
        await cubit.decline(widget.request);
      }
      if (mounted) {
        showContactToast(
          context,
          accept ? 'contacts.accepted' : 'contacts.declined',
          username: username,
        );
      }
    } on ApiFailure catch (failure) {
      if (mounted) {
        showContactToast(
          context,
          failure.messageKey,
          username: username,
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final user = widget.request.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          ContactAvatar(user: user, showPresence: false),
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
                  '@${user.username}',
                  style: theme.textTheme.muted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: _busy ? null : () => _respond(accept: false),
            child: Text(l10n.t('contacts.requests.decline')),
          ),
          const SizedBox(width: 8),
          ShadButton(
            size: ShadButtonSize.sm,
            onPressed: _busy ? null : () => _respond(accept: true),
            child: Text(l10n.t('contacts.requests.accept')),
          ),
        ],
      ),
    );
  }
}
