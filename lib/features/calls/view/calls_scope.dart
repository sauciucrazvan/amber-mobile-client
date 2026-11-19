import 'package:amber_mobile_client/core/app_services.dart';
import 'package:amber_mobile_client/features/calls/bloc/call_cubit.dart';
import 'package:amber_mobile_client/features/calls/data/call_signaling.dart';
import 'package:amber_mobile_client/features/calls/data/flutter_call_media.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Owns the one call the app can have at a time. It sits above the navigator,
/// so a call stays on screen when the user goes to another page.
class CallsScope extends StatefulWidget {
  const CallsScope({super.key, required this.child});

  final Widget child;

  @override
  State<CallsScope> createState() => _CallsScopeState();
}

class _CallsScopeState extends State<CallsScope> {
  late final FlutterCallMedia _media = FlutterCallMedia();
  late final CallCubit _cubit;

  @override
  void initState() {
    super.initState();
    final services = context.read<AppServices>();
    _cubit = CallCubit(
      signaling: CallSignaling(
        send: services.sendRealtime,
        incoming: services.realtimeEvents,
      ),
      media: _media,
    );
  }

  @override
  void dispose() {
    _cubit.close();
    _media.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<FlutterCallMedia>.value(
      value: _media,
      child: BlocProvider<CallCubit>.value(value: _cubit, child: widget.child),
    );
  }
}
