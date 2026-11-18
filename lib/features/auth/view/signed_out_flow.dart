import 'package:amber_mobile_client/features/auth/view/login_screen.dart';
import 'package:amber_mobile_client/features/auth/view/recovery_screen.dart';
import 'package:amber_mobile_client/features/auth/view/register_screen.dart';
import 'package:material_ui/material_ui.dart';

enum _SignedOutPage { login, register, recovery }

/// Switches between the signed-out screens in place, so nothing is left on
/// the navigator stack once the gate moves to the signed-in screen.
class SignedOutFlow extends StatefulWidget {
  const SignedOutFlow({super.key});

  @override
  State<SignedOutFlow> createState() => _SignedOutFlowState();
}

class _SignedOutFlowState extends State<SignedOutFlow> {
  _SignedOutPage _page = _SignedOutPage.login;
  String? _loginInfoKey;

  void _show(_SignedOutPage page, {String? loginInfoKey}) {
    setState(() {
      _page = page;
      _loginInfoKey = loginInfoKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_page) {
      _SignedOutPage.login => LoginScreen(
        infoKey: _loginInfoKey,
        onRegister: () => _show(_SignedOutPage.register),
        onForgotPassword: () => _show(_SignedOutPage.recovery),
      ),
      _SignedOutPage.register => RegisterScreen(
        onLogin: () => _show(_SignedOutPage.login),
      ),
      _SignedOutPage.recovery => RecoveryScreen(
        onCancel: () => _show(_SignedOutPage.login),
        onReset: () =>
            _show(_SignedOutPage.login, loginInfoKey: 'login.recovery.success'),
      ),
    };
  }
}
