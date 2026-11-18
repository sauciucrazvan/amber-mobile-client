import 'package:material_ui/material_ui.dart';

/// Root widget. Feature screens are added here as they are built.
class AmberApp extends StatelessWidget {
  const AmberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amber',
      home: const Scaffold(body: Center(child: Text('Amber'))),
    );
  }
}
