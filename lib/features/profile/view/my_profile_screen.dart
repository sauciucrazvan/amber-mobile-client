import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/auth/data/account.dart';
import 'package:amber_mobile_client/features/auth/view/sign_out.dart';
import 'package:amber_mobile_client/features/chat/view/message_bubble.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/contacts/view/contact_avatar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Opens the signed-in user's own profile.
void showMyProfile(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const MyProfileScreen()));
}

/// Your own profile, as the desktop shows it: avatar, name, username,
/// verified badge, bio and dates, with sign-out at the bottom.
class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final account = context.select((AuthCubit cubit) => cubit.state.account);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('contacts.profile'))),
      body: SafeArea(
        child: account == null
            ? const Center(child: SizedBox(width: 160, child: ShadProgress()))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ContactAvatar(
                        user: _asContactUser(account),
                        size: 96,
                        showPresence: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      account.displayName,
                      style: theme.textTheme.h3,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '@${account.username}',
                      style: theme.textTheme.muted,
                      textAlign: TextAlign.center,
                    ),
                    if (account.verified) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: ShadBadge(
                          child: Text(l10n.t('common.verified')),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ShadCard(
                      title: Text(l10n.t('profile.bio.title')),
                      child: Text(
                        account.bio?.trim().isNotEmpty == true
                            ? account.bio!.trim()
                            : l10n.t('profile.bio.empty'),
                        style: theme.textTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ShadCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            label: l10n.t('stats.member_since'),
                            value: _formatDate(account.registeredAt),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: l10n.t('stats.last_active'),
                            value: _formatDate(account.lastActiveAt),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ShadButton.destructive(
                      key: const ValueKey('sign-out'),
                      onPressed: () => confirmAndSignOut(context),
                      child: Text(l10n.t('settings.account.signOut.action')),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  ContactUser _asContactUser(Account account) => ContactUser(
    id: account.id,
    username: account.username,
    fullName: account.fullName,
    avatarUrl: account.avatarUrl,
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: ShadTheme.of(context).textTheme.muted),
        Text(value),
      ],
    );
  }
}

String _formatDate(DateTime? date) =>
    date == null ? '' : formatDay(dayOf(date));
