import 'package:amber_mobile_client/core/app_services.dart';
import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/theme/app_theme.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/calls/bloc/call_history_cubit.dart';
import 'package:amber_mobile_client/features/calls/data/call_history.dart';
import 'package:amber_mobile_client/features/calls/view/call_history_tab.dart';
import 'package:amber_mobile_client/features/contacts/bloc/contacts_cubit.dart';
import 'package:amber_mobile_client/features/contacts/data/contacts_api.dart';
import 'package:amber_mobile_client/features/contacts/view/add_contact_dialog.dart';
import 'package:amber_mobile_client/features/contacts/view/contact_avatar.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/profile/view/my_profile_screen.dart';
import 'package:amber_mobile_client/features/contacts/view/blocked_accounts_screen.dart';
import 'package:amber_mobile_client/features/contacts/view/contacts_list.dart';
import 'package:amber_mobile_client/features/chat/view/conversation_screen.dart';
import 'package:amber_mobile_client/features/home/realtime_status_bar.dart';
import 'package:amber_mobile_client/features/contacts/view/requests_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The signed-in home: contacts and the requests inbox.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final services = context.read<AppServices>();
            final myUserId = context.read<AuthCubit>().state.account?.id ?? -1;
            return ContactsCubit(
              api: ContactsApi(services.apiClient),
              myUserId: myUserId,
              events: services.realtimeEvents,
            )..load();
          },
        ),
        BlocProvider(
          create: (context) => CallHistoryCubit(
            api: CallHistoryApi(context.read<AppServices>().apiClient),
          )..load(),
        ),
      ],
      child: const _HomeView(),
    );
  }
}

enum _HomeTab { chats, inbox, calls }

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
    final services = context.read<AppServices>();

    return Column(
      children: [
        RealtimeStatusBar(states: services.realtimeStates),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(switch (_tab) {
                  _HomeTab.chats => l10n.t('contacts.title'),
                  _HomeTab.inbox => l10n.t('contacts.requests.title'),
                  _HomeTab.calls => l10n.t('calls.history.title'),
                }, style: theme.textTheme.h3),
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
              _MyProfileButton(onPressed: () => showMyProfile(context)),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              IndexedStack(
                index: _tab.index,
                children: [
                  ContactsList(
                    onOpen: (contact) => showConversation(
                      context,
                      contact.user,
                      context.read<ContactsCubit>(),
                    ),
                  ),
                  const RequestsList(),
                  const CallHistoryTab(),
                ],
              ),
              // The add button floats over the contacts, bottom right, as on
              // the desktop's sidebar.
              if (_tab == _HomeTab.chats)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: ShadIconButton(
                    key: const ValueKey('add-contact'),
                    width: 56,
                    height: 56,
                    iconSize: 24,
                    decoration: const ShadDecoration(shape: BoxShape.circle),
                    backgroundColor: AppColors.brand,
                    foregroundColor: const Color(0xFFFFFFFF),
                    icon: const Icon(LucideIcons.userRoundPlus),
                    onPressed: () => showAddContactDialog(context),
                  ),
                ),
            ],
          ),
        ),
        _BottomBar(
          selected: _tab,
          requestCount: requestCount,
          onSelected: (tab) => setState(() => _tab = tab),
        ),
      ],
    );
  }
}

/// The bottom navigation bar. Each destination is a shadcn button, so the bar
/// matches the rest of the app. Add destinations here as features arrive.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.selected,
    required this.requestCount,
    required this.onSelected,
  });

  final _HomeTab selected;
  final int requestCount;
  final ValueChanged<_HomeTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.colorScheme.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                key: const ValueKey('nav-chats'),
                icon: LucideIcons.messageCircle,
                label: l10n.t('contacts.title'),
                selected: selected == _HomeTab.chats,
                onPressed: () => onSelected(_HomeTab.chats),
              ),
            ),
            Expanded(
              child: _NavItem(
                key: const ValueKey('nav-calls'),
                icon: LucideIcons.phone,
                label: l10n.t('calls.history.title'),
                selected: selected == _HomeTab.calls,
                onPressed: () => onSelected(_HomeTab.calls),
              ),
            ),
            Expanded(
              child: _NavItem(
                key: const ValueKey('nav-inbox'),
                icon: LucideIcons.inbox,
                label: l10n.t('contacts.requests.title'),
                selected: selected == _HomeTab.inbox,
                badge: requestCount,
                onPressed: () => onSelected(_HomeTab.inbox),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 20),
            if (badge > 0)
              Positioned(
                right: -10,
                top: -6,
                child: ShadBadge(child: Text('$badge')),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
    // Taller than the default button height, so the icon and label fit.
    return selected
        ? ShadButton.secondary(height: 56, onPressed: onPressed, child: content)
        : ShadButton.ghost(height: 56, onPressed: onPressed, child: content);
  }
}

/// Your avatar in the header. Opens your profile, where sign-out lives.
class _MyProfileButton extends StatelessWidget {
  const _MyProfileButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final account = context.select((AuthCubit cubit) => cubit.state.account);
    if (account == null) return const SizedBox.shrink();
    return GestureDetector(
      key: const ValueKey('my-profile'),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ContactAvatar(
          user: ContactUser(
            id: account.id,
            username: account.username,
            fullName: account.fullName,
            avatarUrl: account.avatarUrl,
          ),
          size: 32,
          showPresence: false,
        ),
      ),
    );
  }
}
