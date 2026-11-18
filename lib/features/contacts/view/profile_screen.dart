import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/core/app_services.dart';
import 'package:amber_mobile_client/features/contacts/bloc/contacts_cubit.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/contacts/data/contacts_api.dart';
import 'package:amber_mobile_client/features/contacts/view/contact_avatar.dart';
import 'package:amber_mobile_client/features/contacts/view/contact_feedback.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Opens a contact's profile. [contactsCubit] is passed in because the route
/// sits outside the home screen's provider.
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

  Future<bool> _confirm({
    required String titleKey,
    required String descriptionKey,
    required String actionKey,
    required String username,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: Text(l10n.t(titleKey)),
        description: Text(l10n.t(descriptionKey, params: {'user': username})),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.t('common.cancel')),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.t(actionKey)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _act(
    ContactUser user, {
    required String titleKey,
    required String descriptionKey,
    required String actionKey,
    required Future<void> Function(ContactsCubit cubit) run,
    required String successKey,
  }) async {
    final confirmed = await _confirm(
      titleKey: titleKey,
      descriptionKey: descriptionKey,
      actionKey: actionKey,
      username: user.displayName,
    );
    if (!confirmed || !mounted) return;

    final cubit = context.read<ContactsCubit>();
    setState(() => _busy = true);
    try {
      await run(cubit);
      if (!mounted) return;
      Navigator.of(context).pop();
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('contacts.profile'))),
      body: SafeArea(
        child: profile == null
            ? Center(
                child: _errorKey == null
                    ? const SizedBox(width: 160, child: ShadProgress())
                    : Text(l10n.t(_errorKey!)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: ContactAvatar(user: profile.user, size: 96)),
                    const SizedBox(height: 16),
                    Text(
                      profile.user.displayName,
                      style: theme.textTheme.h3,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '@${profile.user.username}',
                      style: theme.textTheme.muted,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ShadCard(
                      title: Text(l10n.t('profile.bio.title')),
                      child: Text(
                        profile.bio?.trim().isNotEmpty == true
                            ? profile.bio!.trim()
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
                            value: _formatDate(profile.registeredAt),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: l10n.t('stats.last_active'),
                            value: profile.user.online
                                ? l10n.t('common.online')
                                : _formatDate(profile.user.lastActiveAt),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ShadButton.outline(
                      onPressed: _busy
                          ? null
                          : () => _act(
                              profile.user,
                              titleKey: 'contacts.removeConfirm.title',
                              descriptionKey:
                                  'contacts.removeConfirm.description',
                              actionKey: 'common.remove',
                              successKey: 'contacts.removed',
                              run: (cubit) => cubit.remove(profile.user),
                            ),
                      child: Text(l10n.t('contacts.remove')),
                    ),
                    const SizedBox(height: 8),
                    ShadButton.destructive(
                      onPressed: _busy
                          ? null
                          : () => _act(
                              profile.user,
                              titleKey: 'contacts.blockConfirm.title',
                              descriptionKey:
                                  'contacts.blockConfirm.description',
                              actionKey: 'common.block',
                              successKey: 'contacts.blocked.success',
                              run: (cubit) => cubit.block(profile.user),
                            ),
                      child: Text(l10n.t('contacts.block')),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.muted),
        Text(value),
      ],
    );
  }
}

/// `2026-11-18`, or an empty string when the date is unknown.
String _formatDate(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
