import 'package:material_ui/material_ui.dart';

/// Keeps a page alive inside a `PageView`, so swiping away from it does not
/// reset its scroll position or state.
class PageKeepAlive extends StatefulWidget {
  const PageKeepAlive({super.key, required this.child});

  final Widget child;

  @override
  State<PageKeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<PageKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
