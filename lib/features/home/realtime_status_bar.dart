import 'dart:async';

import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/realtime/realtime_client.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A thin progress bar while the live connection is being set up, and one
/// error toast when it fails, as on the desktop.
class RealtimeStatusBar extends StatefulWidget {
  const RealtimeStatusBar({super.key, required this.states});

  final Stream<RealtimeConnectionState> states;

  @override
  State<RealtimeStatusBar> createState() => _RealtimeStatusBarState();
}

class _RealtimeStatusBarState extends State<RealtimeStatusBar> {
  late final StreamSubscription<RealtimeConnectionState> _subscription;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.states.listen(_onState);
  }

  void _onState(RealtimeConnectionState state) {
    if (!mounted) return;
    if (state == RealtimeConnectionState.failed) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            AppLocalizations.of(context).t('common.connection.failed'),
          ),
        ),
      );
    }
    setState(() => _connecting = state == RealtimeConnectionState.connecting);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: _connecting ? const LinearProgressIndicator(minHeight: 2) : null,
    );
  }
}
