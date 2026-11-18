import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/auth/data/account.dart';
import 'package:amber_mobile_client/features/auth/view/sign_out.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/contacts/view/contact_avatar.dart';
import 'package:amber_mobile_client/features/contacts/view/profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Opens your own profile as a dialog, as on the desktop.
Future<void> showMyProfile(BuildContext context) {
  return showShadDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<AuthCubit>(),
      child: const MyProfileScreen(),
    ),
  );
}

/// Your own profile: avatar, name, username, verified badge, bio and dates,
/// with sign-out at the bottom. Sign-out asks for confirmation first.
class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final account = context.select((AuthCubit cubit) => cubit.state.account);

    if (account == null) {
      return const ShadDialog(
        child: SizedBox(
          height: 120,
          child: Center(child: SizedBox(width: 120, child: ShadProgress())),
        ),
      );
    }

    return ShadDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ContactAvatar(
            user: _asContactUser(account),
            size: 96,
            showPresence: false,
          ),
          const SizedBox(height: 12),
          Text(
            account.displayName,
            style: theme.textTheme.large,
            textAlign: TextAlign.center,
          ),
          Text(
            '@${account.username}',
            style: theme.textTheme.muted,
            textAlign: TextAlign.center,
          ),
          if (account.verified) ...[
            const SizedBox(height: 8),
            ShadBadge(child: Text(l10n.t('common.verified'))),
          ],
          const SizedBox(height: 12),
          BioBox(bio: account.bio),
          const SizedBox(height: 12),
          DateRows(
            registeredAt: account.registeredAt,
            online: false,
            lastActiveAt: account.lastActiveAt,
          ),
          const SizedBox(height: 16),
          ShadButton.destructive(
            key: const ValueKey('sign-out'),
            size: ShadButtonSize.sm,
            leading: const Icon(LucideIcons.logOut, size: 14),
            onPressed: () => confirmAndSignOut(context),
            child: Text(l10n.t('settings.account.signOut.action')),
          ),
        ],
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
