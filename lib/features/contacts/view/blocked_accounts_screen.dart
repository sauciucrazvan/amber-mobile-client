import 'package:amber_mobile_client/core/app_services.dart';
import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/contacts/data/contacts_api.dart';
import 'package:amber_mobile_client/features/contacts/view/contact_feedback.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Lists blocked accounts with an Unblock action. Unblocking sends no
/// realtime event, so the list reloads after each change.
class BlockedAccountsScreen extends StatefulWidget {
  const BlockedAccountsScreen({super.key});

  @override
  State<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends State<BlockedAccountsScreen> {
  late final ContactsApi _api;
  List<BlockedUser>? _blocked;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    _api = ContactsApi(context.read<AppServices>().apiClient);
    _load();
  }

  Future<void> _load() async {
    try {
      final blocked = await _api.blocked();
      if (mounted) setState(() => _blocked = blocked);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _errorKey = failure.messageKey);
    }
  }

  Future<void> _unblock(BlockedUser user) async {
    try {
      await _api.unblock(user.username);
      if (!mounted) return;
      showContactToast(context, 'contacts.unblocked', username: user.username);
      await _load();
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      showContactToast(
        context,
        failure.messageKey,
        username: user.username,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final blocked = _blocked;
    final errorKey = _errorKey;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('contacts.blocked.title'))),
      body: SafeArea(
        child: errorKey != null
            ? Center(child: Text(l10n.t(errorKey)))
            : blocked == null
            ? const Center(
                child: SizedBox(width: 160, child: ShadProgress(minHeight: 2)),
              )
            : blocked.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.t('contacts.blocked.none'),
                    style: ShadTheme.of(context).textTheme.muted,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: blocked.length,
                separatorBuilder: (_, _) => const ShadSeparator.horizontal(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                ),
                itemBuilder: (context, index) {
                  final user = blocked[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '@${user.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ShadButton.outline(
                          size: ShadButtonSize.sm,
                          onPressed: () => _unblock(user),
                          child: Text(l10n.t('contacts.unblock')),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
