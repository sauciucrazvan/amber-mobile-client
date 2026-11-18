import 'package:material_ui/material_ui.dart';

/// The Amber logo, from the same image the desktop uses.
class AmberLogo extends StatelessWidget {
  const AmberLogo({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/amber_logo.png',
      width: size,
      height: size,
      semanticLabel: 'Amber logo',
      filterQuality: FilterQuality.medium,
    );
  }
}
