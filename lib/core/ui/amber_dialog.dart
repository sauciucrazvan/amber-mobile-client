import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A shadcn dialog with the app's rounded corners and left-aligned text.
/// Takes the same title, description, actions and child as [ShadDialog].
class AmberDialog extends StatelessWidget {
  const AmberDialog({
    super.key,
    this.title,
    this.description,
    this.actions,
    this.child,
  });

  final Widget? title;
  final Widget? description;
  final List<Widget>? actions;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // The inset keeps the dialog off the screen edges on a phone.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ShadDialog(
        title: title,
        description: description,
        actions: actions ?? const [],
        radius: BorderRadius.circular(8),
        removeBorderRadiusWhenTiny: false,
        titleTextAlign: TextAlign.start,
        descriptionTextAlign: TextAlign.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        gap: 16,
        actionsGap: 8,
        child: child,
      ),
    );
  }
}
