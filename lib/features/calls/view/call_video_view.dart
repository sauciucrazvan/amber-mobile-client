import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:material_ui/material_ui.dart';

/// Shows a WebRTC stream. Follows [stream], so it updates when the peer's
/// stream arrives or the local camera restarts.
class CallVideoView extends StatefulWidget {
  const CallVideoView({
    super.key,
    required this.stream,
    this.mirror = false,
    this.cover = true,
  });

  final ValueListenable<MediaStream?> stream;

  /// True for the local preview, so it looks like a mirror.
  final bool mirror;

  /// True to fill the area and crop, false to fit the whole picture.
  final bool cover;

  @override
  State<CallVideoView> createState() => _CallVideoViewState();
}

class _CallVideoViewState extends State<CallVideoView> {
  final _renderer = RTCVideoRenderer();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    widget.stream.addListener(_sync);
    _renderer.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _sync();
    });
  }

  @override
  void didUpdateWidget(CallVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      oldWidget.stream.removeListener(_sync);
      widget.stream.addListener(_sync);
      _sync();
    }
  }

  /// The renderer cannot take a stream until it is initialised.
  void _sync() {
    if (!_ready) return;
    _renderer.srcObject = widget.stream.value;
  }

  @override
  void dispose() {
    widget.stream.removeListener(_sync);
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    return RTCVideoView(
      _renderer,
      mirror: widget.mirror,
      objectFit: widget.cover
          ? RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
          : RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    );
  }
}
