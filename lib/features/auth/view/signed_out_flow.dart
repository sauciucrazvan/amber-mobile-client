import 'package:amber_mobile_client/features/auth/view/login_screen.dart';
import 'package:amber_mobile_client/features/auth/view/register_screen.dart';
import 'package:material_ui/material_ui.dart';

enum _SignedOutPage { login, register }

/// Switches between the signed-out screens in place, so nothing is left on
/// the navigator stack once the gate moves to the signed-in screen.
class SignedOutFlow extends StatefulWidget {
  const SignedOutFlow({super.key});

  @override
  State<SignedOutFlow> createState() => _SignedOutFlowState();
}

class _SignedOutFlowState extends State<SignedOutFlow> {
  _SignedOutPage _page = _SignedOutPage.login;

  void _show(_SignedOutPage page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    return switch (_page) {
      _SignedOutPage.login => LoginScreen(
        onRegister: () => _show(_SignedOutPage.register),
      ),
      _SignedOutPage.register => RegisterScreen(
        onLogin: () => _show(_SignedOutPage.login),
      ),
    };
  }
}
