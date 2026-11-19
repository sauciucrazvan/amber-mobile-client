import 'package:material_ui/material_ui.dart';

/// Shows the child at [index] and fades between children when it changes.
/// Every child stays mounted, so each keeps its scroll position and state, like
/// an `IndexedStack`. Hidden children ignore touches.
class FadeStack extends StatelessWidget {
  const FadeStack({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: i != index,
            child: AnimatedOpacity(
              opacity: i == index ? 1 : 0,
              duration: _duration,
              curve: Curves.easeOut,
              child: children[i],
            ),
          ),
      ],
    );
  }
}
