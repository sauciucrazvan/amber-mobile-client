import 'dart:async';

import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/l10n/relative_time.dart';
import 'package:amber_mobile_client/features/calls/bloc/call_cubit.dart';
import 'package:amber_mobile_client/features/calls/bloc/call_state.dart';
import 'package:amber_mobile_client/features/calls/data/call_models.dart';
import 'package:amber_mobile_client/features/contacts/bloc/contacts_cubit.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/contacts/view/contact_avatar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The chat header, as on the desktop: avatar with presence, the name, and a
/// second line that alternates between `@username` and "Last active" every
/// ten seconds while the contact is offline.
///
/// The contact is read from the contacts list, so presence changes show
/// while the chat is open. [contact] is used until the list has it.
class ConversationHeader extends StatefulWidget {
  const ConversationHeader({
    super.key,
    required this.contact,
    required this.onTap,
  });

  final ContactUser contact;
  final VoidCallback onTap;

  @override
  State<ConversationHeader> createState() => _ConversationHeaderState();
}

class _ConversationHeaderState extends State<ConversationHeader> {
  static const _interval = Duration(seconds: 10);

  Timer? _timer;
  bool _showLastActive = false;

  /// Runs the alternation only while it has something to show: the contact
  /// is offline and has a last-active time.
  void _syncTimer({required bool offline, required bool hasLastActive}) {
    final shouldAlternate = offline && hasLastActive;
    if (!shouldAlternate) {
      _timer?.cancel();
      _timer = null;
      // Set during build, so no setState: the build reads it right away.
      _showLastActive = false;
      return;
    }
    _timer ??= Timer.periodic(_interval, (_) {
      if (mounted) setState(() => _showLastActive = !_showLastActive);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final user = context.select((ContactsCubit cubit) {
      for (final contact in cubit.state.contacts) {
        if (contact.user.id == widget.contact.id) return contact.user;
      }
      return widget.contact;
    });

    final lastActive = formatRelativeTime(l10n, user.lastActiveAt);
    _syncTimer(offline: !user.online, hasLastActive: lastActive.isNotEmpty);

    final showLast = !user.online && _showLastActive && lastActive.isNotEmpty;
    final secondLine = showLast
        ? '${l10n.t('stats.last_active')} '
              '${user.online ? l10n.t('calls.history.relative.now') : lastActive}'
        : '@${user.username}';

    return GestureDetector(
      onTap: widget.onTap,
      child: Row(
        children: [
          ContactAvatar(user: user, size: 36),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.displayName,
                  style: theme.textTheme.large.copyWith(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    secondLine,
                    key: ValueKey(secondLine),
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _CallButton(
            key: const ValueKey('call-audio'),
            user: user,
            mode: CallMode.audio,
            icon: LucideIcons.phone,
          ),
          _CallButton(
            key: const ValueKey('call-video'),
            user: user,
            mode: CallMode.video,
            icon: LucideIcons.video,
          ),
        ],
      ),
    );
  }
}

/// Starts a call with [user]. Disabled while another call is going on, and a
/// toast explains an offline contact, as on the desktop.
class _CallButton extends StatelessWidget {
  const _CallButton({
    super.key,
    required this.user,
    required this.mode,
    required this.icon,
  });

  final ContactUser user;
  final CallMode mode;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = context.select(
      (CallCubit cubit) => cubit.state.phase != CallPhase.idle,
    );
    final label = l10n.t(
      mode == CallMode.audio
          ? 'calls.actions.startAudio'
          : 'calls.actions.startVideo',
    );

    return Tooltip(
      message: label,
      child: ShadIconButton.ghost(
        width: 44,
        height: 44,
        icon: Icon(icon, size: 24),
        onPressed: busy
            ? null
            : () {
                if (!user.online) {
                  ShadToaster.of(context).show(
                    ShadToast(
                      description: Text(l10n.t('calls.toasts.contactOffline')),
                    ),
                  );
                  return;
                }
                unawaited(
                  context.read<CallCubit>().startCall(
                    CallPeer(
                      username: user.username,
                      displayName: user.displayName,
                      avatarUrl: user.avatarUrl,
                    ),
                    mode,
                  ),
                );
              },
      ),
    );
  }
}
