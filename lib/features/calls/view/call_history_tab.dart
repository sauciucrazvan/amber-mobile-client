import 'dart:async';

import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/l10n/relative_time.dart';
import 'package:amber_mobile_client/features/calls/bloc/call_cubit.dart';
import 'package:amber_mobile_client/features/calls/bloc/call_history_cubit.dart';
import 'package:amber_mobile_client/features/calls/bloc/call_state.dart';
import 'package:amber_mobile_client/features/calls/data/call_history.dart';
import 'package:amber_mobile_client/features/contacts/bloc/contacts_cubit.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/contacts/view/contact_avatar.dart';
import 'package:amber_mobile_client/features/chat/view/conversation_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The calls tab: recent calls, newest first. Each row opens the contact's
/// chat. The list refreshes every 30 seconds, as on the desktop, and when a
/// call ends, so the new entry appears without a restart.
class CallHistoryTab extends StatefulWidget {
  const CallHistoryTab({super.key});

  @override
  State<CallHistoryTab> createState() => _CallHistoryTabState();
}

class _CallHistoryTabState extends State<CallHistoryTab> {
  static const _refreshEvery = Duration(seconds: 30);

  // The server records a call's end a moment after the app sends it, so the
  // refresh after a call waits briefly.
  static const _afterCallDelay = Duration(seconds: 1);

  final _scroll = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _timer = Timer.periodic(_refreshEvery, (_) {
      if (mounted) context.read<CallHistoryCubit>().load();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 200) {
      context.read<CallHistoryCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallCubit, CallState>(
      listenWhen: (previous, current) =>
          current.phase == CallPhase.ended && previous.phase != CallPhase.ended,
      listener: (context, _) => Future<void>.delayed(_afterCallDelay, () {
        if (context.mounted) context.read<CallHistoryCubit>().load();
      }),
      child: BlocBuilder<CallHistoryCubit, CallHistoryState>(
        builder: (context, state) => _body(context, state),
      ),
    );
  }

  Widget _body(BuildContext context, CallHistoryState state) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);

    if (state.entries.isEmpty) {
      if (state.status == CallHistoryStatus.loading) {
        return const Center(
          child: SizedBox(width: 160, child: ShadProgress(minHeight: 2)),
        );
      }
      if (state.status == CallHistoryStatus.failed) {
        return Center(child: Text(l10n.t('calls.history.failedLoading')));
      }
      return Center(
        child: Text(
          l10n.t('calls.history.empty'),
          style: theme.textTheme.muted,
        ),
      );
    }

    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.entries.length + (state.loadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const ShadSeparator.horizontal(
        margin: EdgeInsets.symmetric(horizontal: 16),
      ),
      itemBuilder: (context, index) {
        if (index == state.entries.length) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: ShadProgress(minHeight: 2)),
          );
        }
        return _CallRow(entry: state.entries[index]);
      },
    );
  }
}

class _CallRow extends StatelessWidget {
  const _CallRow({required this.entry});

  final CallHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final peer = entry.peer;
    final id = peer.id;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: id == null
          ? null
          : () => showConversation(
              context,
              ContactUser(
                id: id,
                username: peer.username,
                fullName: peer.displayName,
                avatarUrl: peer.avatarUrl,
              ),
              context.read<ContactsCubit>(),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ContactAvatar(
              user: ContactUser(
                id: id ?? 0,
                username: peer.username,
                fullName: peer.displayName,
                avatarUrl: peer.avatarUrl,
              ),
              size: 40,
              showPresence: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peer.displayName,
                    style: theme.textTheme.small.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _reasonLabel(l10n, entry.reason),
                    style: theme.textTheme.small.copyWith(
                      fontSize: 12,
                      color: entry.isMissed
                          ? theme.colorScheme.destructive
                          : theme.colorScheme.mutedForeground,
                      fontWeight: entry.isMissed
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatRelativeTime(l10n, entry.when),
                  style: theme.textTheme.muted.copyWith(fontSize: 12),
                ),
                if (entry.durationSeconds > 0)
                  Text(
                    formatCallDuration(entry.durationSeconds),
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// `mm:ss`, as the desktop shows a call's length.
String formatCallDuration(int totalSeconds) {
  final seconds = totalSeconds < 0 ? 0 : totalSeconds;
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// The reason a call ended, from the history keys the desktop uses, then the
/// status keys. Unknown reasons are shown as they are.
String _reasonLabel(AppLocalizations l10n, String reason) {
  final camel = reason.replaceAllMapped(
    RegExp(r'-([a-z])'),
    (match) => match[1]!.toUpperCase(),
  );
  for (final key in ['calls.history.reasons.$reason', 'calls.status.$camel']) {
    final text = l10n.t(key);
    if (text != key) return text;
  }
  return reason.replaceAll('_', ' ');
}
