import 'dart:async';

import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/theme/app_theme.dart';
import 'package:amber_mobile_client/features/calls/bloc/call_cubit.dart';
import 'package:amber_mobile_client/features/calls/bloc/call_state.dart';
import 'package:amber_mobile_client/features/calls/data/call_models.dart';
import 'package:amber_mobile_client/features/calls/data/flutter_call_media.dart';
import 'package:amber_mobile_client/features/calls/view/call_video_view.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/contacts/view/contact_avatar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The call, full screen, as on the desktop: the peer's video or avatar, a
/// small preview of ourselves, the status, and the controls.
class CallScreen extends StatelessWidget {
  const CallScreen({super.key, required this.state});

  final CallState state;

  @override
  Widget build(BuildContext context) {
    final media = context.read<FlutterCallMedia>();
    final peer = state.peer;
    final isVideo = state.mode == CallMode.video;
    final showRemoteVideo =
        isVideo && state.phase == CallPhase.inProgress && state.remoteCameraOn;

    return ColoredBox(
      color: const Color(0xFF0A0A0A),
      child: SafeArea(
        child: Stack(
          children: [
            if (showRemoteVideo)
              Positioned.fill(child: CallVideoView(stream: media.remoteStream)),
            if (isVideo && state.cameraOn && state.phase != CallPhase.ended)
              Positioned(
                top: 12,
                right: 12,
                width: 110,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CallVideoView(
                    stream: media.localStream,
                    mirror: true,
                    cover: true,
                  ),
                ),
              ),
            Column(
              children: [
                const SizedBox(height: 24),
                if (!showRemoteVideo && peer != null)
                  ContactAvatar(
                    user: ContactUser(
                      id: 0,
                      username: peer.username,
                      fullName: peer.displayName,
                      avatarUrl: peer.avatarUrl,
                    ),
                    size: 96,
                    showPresence: false,
                  ),
                const SizedBox(height: 12),
                if (peer != null)
                  Text(
                    peer.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                _Status(state: state),
                const Spacer(),
                _Controls(state: state),
                const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Status extends StatefulWidget {
  const _Status({required this.state});

  final CallState state;

  @override
  State<_Status> createState() => _StatusState();
}

class _StatusState extends State<_Status> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(_Status oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  /// Ticks once a second while the call is connected, for the duration.
  void _syncTicker() {
    final connected = widget.state.phase == CallPhase.inProgress;
    if (connected && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!connected) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = widget.state;
    final text = switch (state.phase) {
      CallPhase.outgoing => l10n.t('calls.outgoing.waiting'),
      CallPhase.incoming => l10n.t('calls.badge.incoming'),
      CallPhase.connecting => l10n.t('calls.status.connecting'),
      CallPhase.inProgress => _duration(state.startedAt),
      CallPhase.ended => l10n.t(_endKey(state.endReason)),
      CallPhase.idle => '',
    };
    return Text(
      text,
      style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 15),
    );
  }

  static String _duration(DateTime? since) {
    if (since == null) return '';
    final elapsed = DateTime.now().difference(since);
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static String _endKey(String? reason) => switch (reason) {
    'rejected' => 'calls.status.rejected',
    'missed' => 'calls.status.missed',
    'failed' => 'calls.status.failed',
    'canceled' => 'calls.status.canceled',
    'answered-elsewhere' => 'calls.status.answeredElsewhere',
    _ => 'calls.status.ended',
  };
}

/// The buttons for the current phase: answer or decline when ringing, hang up
/// while ringing out, and mute, camera, speaker and end while connected.
class _Controls extends StatelessWidget {
  const _Controls({required this.state});

  final CallState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<CallCubit>();
    final media = context.read<FlutterCallMedia>();
    final isVideo = state.mode == CallMode.video;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: switch (state.phase) {
        CallPhase.incoming => [
          _ControlButton(
            key: const ValueKey('call-decline'),
            label: l10n.t('calls.actions.decline'),
            icon: LucideIcons.phoneOff,
            color: ShadTheme.of(context).colorScheme.destructive,
            onPressed: cubit.rejectCall,
          ),
          _ControlButton(
            key: const ValueKey('call-answer'),
            label: l10n.t('calls.actions.answer'),
            icon: LucideIcons.phone,
            color: AppColors.online,
            onPressed: cubit.acceptCall,
          ),
        ],
        CallPhase.outgoing => [
          _ControlButton(
            key: const ValueKey('call-cancel'),
            label: l10n.t('calls.actions.cancelCall'),
            icon: LucideIcons.phoneOff,
            color: ShadTheme.of(context).colorScheme.destructive,
            onPressed: cubit.cancelCall,
          ),
        ],
        CallPhase.connecting || CallPhase.inProgress => [
          _ControlButton(
            key: const ValueKey('call-mute'),
            label: l10n.t(
              state.micOn ? 'calls.actions.mute' : 'calls.actions.unmute',
            ),
            icon: state.micOn ? LucideIcons.mic : LucideIcons.micOff,
            active: !state.micOn,
            onPressed: cubit.toggleMic,
          ),
          if (isVideo)
            _ControlButton(
              key: const ValueKey('call-camera'),
              label: l10n.t(
                state.cameraOn
                    ? 'calls.actions.cameraOff'
                    : 'calls.actions.cameraOn',
              ),
              icon: state.cameraOn ? LucideIcons.video : LucideIcons.videoOff,
              active: !state.cameraOn,
              onPressed: cubit.toggleCamera,
            ),
          if (isVideo)
            _ControlButton(
              key: const ValueKey('call-switch-camera'),
              label: l10n.t('calls.actions.switchCamera'),
              icon: LucideIcons.switchCamera,
              onPressed: media.switchCamera,
            ),
          _ControlButton(
            key: const ValueKey('call-speaker'),
            label: l10n.t('calls.inProgress.speaker'),
            icon: LucideIcons.volume2,
            onPressed: () => media.setSpeakerOn(true),
          ),
          _ControlButton(
            key: const ValueKey('call-end'),
            label: l10n.t('calls.actions.endCall'),
            icon: LucideIcons.phoneOff,
            color: ShadTheme.of(context).colorScheme.destructive,
            onPressed: cubit.endCall,
          ),
        ],
        CallPhase.ended || CallPhase.idle => const <Widget>[],
      },
    );
  }
}

/// A round control with its label under it.
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
    this.active = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  /// True to show the control in its alternate state, such as muted.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final background =
        color ?? (active ? const Color(0xFFFFFFFF) : const Color(0x33FFFFFF));
    final foreground = color != null
        ? const Color(0xFFFFFFFF)
        : (active ? const Color(0xFF0A0A0A) : const Color(0xFFFFFFFF));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShadIconButton(
          width: 56,
          height: 56,
          padding: EdgeInsets.zero,
          decoration: const ShadDecoration(shape: BoxShape.circle),
          backgroundColor: background,
          foregroundColor: foreground,
          icon: Icon(icon, size: 22),
          onPressed: onPressed,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 88,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
