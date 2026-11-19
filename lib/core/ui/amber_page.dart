import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A full-screen page with a back button, used for profiles. The content is
/// the same as the dialog it replaces, left-aligned and centred on the screen.
/// [footer] stays pinned to the bottom, under the scrolling content.
class AmberPage extends StatelessWidget {
  const AmberPage({super.key, this.title, required this.child, this.footer});

  /// Shown next to the back button, so the page says where it is.
  final String? title;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  ShadIconButton.ghost(
                    key: const ValueKey('back'),
                    icon: const Icon(LucideIcons.arrowLeft),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: ShadTheme.of(context).textTheme.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 425),
                    child: child,
                  ),
                ),
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 425),
                    child: footer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
