import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/ui/amber_page.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/auth/data/account.dart';
import 'package:amber_mobile_client/features/auth/view/sign_out.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/contacts/view/contact_avatar.dart';
import 'package:amber_mobile_client/features/contacts/view/profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Opens your own profile as a page with the same layout as the desktop's
/// dialog.
Future<void> showMyProfile(BuildContext context) {
  final authCubit = context.read<AuthCubit>();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          BlocProvider.value(value: authCubit, child: const MyProfileScreen()),
    ),
  );
}

/// Your own profile: avatar, name, username, bio and dates,
/// with sign-out at the bottom. Sign-out asks for confirmation first.
class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final account = context.select((AuthCubit cubit) => cubit.state.account);

    if (account == null) {
      return const AmberPage(
        child: SizedBox(
          height: 120,
          child: Center(child: SizedBox(width: 120, child: ShadProgress())),
        ),
      );
    }

    return AmberPage(
      footer: SizedBox(
        width: double.infinity,
        child: ShadButton.destructive(
          key: const ValueKey('sign-out'),
          leading: const Icon(LucideIcons.logOut, size: 16),
          onPressed: () => confirmAndSignOut(context),
          child: Text(l10n.t('settings.account.signOut.action')),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ContactAvatar(
            user: _asContactUser(account),
            size: 96,
            showPresence: false,
          ),
          const SizedBox(height: 12),
          Text(account.displayName, style: theme.textTheme.large),
          Text('@${account.username}', style: theme.textTheme.muted),
          const SizedBox(height: 12),
          BioBox(bio: account.bio),
          const SizedBox(height: 12),
          DateRows(
            registeredAt: account.registeredAt,
            online: false,
            lastActiveAt: account.lastActiveAt,
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
