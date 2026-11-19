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
    return ShadDialog(
      title: title,
      description: description,
      actions: actions ?? const [],
      radius: BorderRadius.circular(8),
      titleTextAlign: TextAlign.start,
      descriptionTextAlign: TextAlign.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      child: child,
    );
  }
}
