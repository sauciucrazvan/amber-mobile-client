import 'package:material_ui/material_ui.dart';

/// Opens a screen by sliding it in from the right while it fades in. Used for
/// every screen the app pushes, so they all move the same way.
class AmberPageRoute<T> extends PageRouteBuilder<T> {
  AmberPageRoute({required WidgetBuilder builder})
    : super(
        pageBuilder: (context, _, _) => builder(context),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.12, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
}
