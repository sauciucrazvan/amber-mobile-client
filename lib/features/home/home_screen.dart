import 'package:amber_mobile_client/core/app_services.dart';
import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/contacts/bloc/contacts_cubit.dart';
import 'package:amber_mobile_client/features/contacts/data/contacts_api.dart';
import 'package:amber_mobile_client/features/contacts/view/add_contact_dialog.dart';
import 'package:amber_mobile_client/features/contacts/view/blocked_accounts_screen.dart';
import 'package:amber_mobile_client/features/contacts/view/contacts_list.dart';
import 'package:amber_mobile_client/features/contacts/view/profile_screen.dart';
import 'package:amber_mobile_client/features/contacts/view/requests_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The signed-in home: contacts and the requests inbox.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final services = context.read<AppServices>();
        return ContactsCubit(
          api: ContactsApi(services.apiClient),
          events: services.realtimeEvents,
        )..load();
      },
      child: const _HomeView(),
    );
  }
}

enum _HomeTab { chats, inbox }

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  _HomeTab _tab = _HomeTab.chats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final requestCount = context.select(
      (ContactsCubit cubit) => cubit.state.requests.length,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.t('contacts.title'),
                  style: theme.textTheme.h3,
                ),
              ),
              ShadIconButton.ghost(
                key: const ValueKey('blocked-accounts'),
                icon: const Icon(LucideIcons.ban),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BlockedAccountsScreen(),
                  ),
                ),
              ),
              ShadIconButton.ghost(
                key: const ValueKey('add-contact'),
                icon: const Icon(LucideIcons.userPlus),
                onPressed: () => showAddContactDialog(context),
              ),
              ShadIconButton.ghost(
                key: const ValueKey('sign-out'),
                icon: const Icon(LucideIcons.logOut),
                onPressed: () => context.read<AuthCubit>().signOut(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ShadTabs<_HomeTab>(
            value: _tab,
            onChanged: (tab) => setState(() => _tab = tab),
            tabs: [
              ShadTab(
                value: _HomeTab.chats,
                child: Text(l10n.t('contacts.title')),
              ),
              ShadTab(
                value: _HomeTab.inbox,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.t('contacts.requests.title')),
                    if (requestCount > 0) ...[
                      const SizedBox(width: 6),
                      ShadBadge(child: Text('$requestCount')),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _tab.index,
            children: [
              ContactsList(
                onOpen: (contact) => showContactProfile(
                  context,
                  contact.user.username,
                  context.read<ContactsCubit>(),
                ),
              ),
              const RequestsList(),
            ],
          ),
        ),
      ],
    );
  }
}
