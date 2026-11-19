import 'package:amber_mobile_client/core/app_services.dart';
import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/l10n/dates.dart';
import 'package:amber_mobile_client/core/l10n/relative_time.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/core/ui/amber_page.dart';
import 'package:amber_mobile_client/core/ui/confirmation_dialog.dart';
import 'package:amber_mobile_client/features/contacts/bloc/contacts_cubit.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/contacts/data/contacts_api.dart';
import 'package:amber_mobile_client/features/contacts/view/contact_avatar.dart';
import 'package:amber_mobile_client/features/contacts/view/contact_feedback.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Opens a contact's profile as a page, with the same layout as the desktop's
/// dialog. [contactsCubit] is passed in because the page sits outside the home
/// screen's provider.
Future<void> showContactProfile(
  BuildContext context,
  String username,
  ContactsCubit contactsCubit,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(
        value: contactsCubit,
        child: ContactProfileScreen(username: username),
      ),
    ),
  );
}

class ContactProfileScreen extends StatefulWidget {
  const ContactProfileScreen({super.key, required this.username});

  final String username;

  @override
  State<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends State<ContactProfileScreen> {
  ContactProfile? _profile;
  String? _errorKey;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ContactsApi(context.read<AppServices>().apiClient);
    try {
      final profile = await api.profile(widget.username);
      if (mounted) setState(() => _profile = profile);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _errorKey = failure.messageKey);
    }
  }

  /// Runs remove or block after the user confirms. On success it returns to
  /// home, since the contact is gone.
  Future<void> _act(
    ContactUser user, {
    required String titleKey,
    required String descriptionKey,
    required String actionKey,
    required Future<void> Function(ContactsCubit cubit) run,
    required String successKey,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmationDialog(
      context,
      title: l10n.t(titleKey),
      description: l10n.t(descriptionKey, params: {'user': user.displayName}),
      confirmText: l10n.t(actionKey),
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final cubit = context.read<ContactsCubit>();
    setState(() => _busy = true);
    try {
      await run(cubit);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      showContactToast(context, successKey, username: user.displayName);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      showContactToast(
        context,
        failure.messageKey,
        username: user.displayName,
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final profile = _profile;
    final errorKey = _errorKey;

    if (profile == null) {
      return AmberPage(
        child: SizedBox(
          height: 120,
          child: Center(
            child: errorKey == null
                ? const SizedBox(width: 120, child: ShadProgress(minHeight: 2))
                : Text(l10n.t(errorKey)),
          ),
        ),
      );
    }

    final user = profile.user;
    return AmberPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ContactAvatar(user: user, size: 96),
          const SizedBox(height: 12),
          Text(user.displayName, style: theme.textTheme.large),
          Text('@${user.username}', style: theme.textTheme.muted),
          const SizedBox(height: 12),
          BioBox(bio: profile.bio),
          const SizedBox(height: 12),
          DateRows(
            registeredAt: profile.registeredAt,
            online: user.online,
            lastActiveAt: user.lastActiveAt,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShadButton.outline(
                key: const ValueKey('remove-contact'),
                size: ShadButtonSize.sm,
                leading: const Icon(LucideIcons.x, size: 14),
                onPressed: _busy
                    ? null
                    : () => _act(
                        user,
                        titleKey: 'contacts.removeConfirm.title',
                        descriptionKey: 'contacts.removeConfirm.description',
                        actionKey: 'common.remove',
                        successKey: 'contacts.removed',
                        run: (cubit) => cubit.remove(user),
                      ),
                child: Text(l10n.t('contacts.remove')),
              ),
              const SizedBox(width: 8),
              ShadButton.outline(
                key: const ValueKey('block-contact'),
                size: ShadButtonSize.sm,
                leading: const Icon(LucideIcons.ban, size: 14),
                onPressed: _busy
                    ? null
                    : () => _act(
                        user,
                        titleKey: 'contacts.blockConfirm.title',
                        descriptionKey: 'contacts.blockConfirm.description',
                        actionKey: 'common.block',
                        successKey: 'contacts.blocked.success',
                        run: (cubit) => cubit.block(user),
                      ),
                child: Text(l10n.t('contacts.block')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The bio in a bordered box, as on the desktop.
class BioBox extends StatelessWidget {
  const BioBox({super.key, required this.bio});

  final String? bio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final text = bio?.trim() ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.t('profile.bio.title'),
            style: theme.textTheme.small.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text.isEmpty ? l10n.t('profile.bio.empty') : text,
            style: theme.textTheme.small.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// "Member since" (month and year) and "Last active" (now, or a relative
/// time), as on the desktop.
class DateRows extends StatelessWidget {
  const DateRows({
    super.key,
    required this.registeredAt,
    required this.online,
    required this.lastActiveAt,
  });

  final DateTime? registeredAt;
  final bool online;
  final DateTime? lastActiveAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final lastActive = online
        ? l10n.t('calls.history.relative.now')
        : formatRelativeTime(l10n, lastActiveAt);
    return Column(
      children: [
        _DateRow(
          label: l10n.t('stats.member_since'),
          value: formatMonthYear(l10n.localeCode, registeredAt),
          theme: theme,
        ),
        const SizedBox(height: 8),
        _DateRow(
          label: l10n.t('stats.last_active'),
          value: lastActive,
          theme: theme,
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ShadThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.muted),
        Text(value),
      ],
    );
  }
}
