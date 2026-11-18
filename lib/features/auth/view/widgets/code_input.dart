import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Six-digit code input, used for account verification and password recovery.
class CodeInput extends StatelessWidget {
  const CodeInput({super.key, required this.onChanged, this.enabled = true});

  static const length = 6;

  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ShadInputOTP(
        maxLength: length,
        enabled: enabled,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        children: const [
          ShadInputOTPGroup(
            children: [
              ShadInputOTPSlot(),
              ShadInputOTPSlot(),
              ShadInputOTPSlot(),
            ],
          ),
          SizedBox(width: 12),
          ShadInputOTPGroup(
            children: [
              ShadInputOTPSlot(),
              ShadInputOTPSlot(),
              ShadInputOTPSlot(),
            ],
          ),
        ],
      ),
    );
  }
}
