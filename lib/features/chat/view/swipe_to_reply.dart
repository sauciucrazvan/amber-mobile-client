import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Drag a message sideways, either way, to reply to it. Past [threshold] the
/// message calls [onReply]. The message springs back to its place either way.
class SwipeToReply extends StatefulWidget {
  const SwipeToReply({super.key, required this.onReply, required this.child});

  final VoidCallback onReply;
  final Widget child;

  /// How far a drag must go before it counts as a reply.
  static const threshold = 56.0;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  // A drag can go further than the threshold, but not much further.
  static const _maxDrag = 80.0;

  late final AnimationController _springBack = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  )..addListener(_onSpring);

  /// The drag offset: follows the finger, then eases back to zero.
  double _dx = 0;
  double _releasedAt = 0;

  @override
  void dispose() {
    _springBack.dispose();
    super.dispose();
  }

  void _onSpring() {
    setState(() {
      _dx = _releasedAt * (1 - Curves.easeOut.transform(_springBack.value));
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _springBack.stop();
    setState(() {
      _dx = (_dx + details.delta.dx).clamp(-_maxDrag, _maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dx.abs() >= SwipeToReply.threshold) widget.onReply();
    _releasedAt = _dx;
    _springBack.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final dx = _dx;
    final theme = ShadTheme.of(context);
    final progress = (dx.abs() / SwipeToReply.threshold).clamp(0.0, 1.0);

    return Stack(
      children: [
        // The reply hint, on the side the message is dragged towards.
        Positioned.fill(
          child: Align(
            alignment: dx >= 0
                ? AlignmentDirectional.centerStart
                : AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Opacity(
                opacity: progress,
                child: Icon(
                  LucideIcons.reply,
                  size: 18,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
