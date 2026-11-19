import 'package:amber_mobile_client/core/theme/app_theme.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Avatar with the user's initials as fallback and an optional presence dot.
class ContactAvatar extends StatelessWidget {
  const ContactAvatar({
    super.key,
    required this.user,
    this.size = 44,
    this.showPresence = true,
  });

  final ContactUser user;
  final double size;
  final bool showPresence;

  String get _initials {
    final parts = user.displayName.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
    return letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final dotSize = size * 0.28;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          ShadAvatar(
            user.avatarUrl,
            size: Size.square(size),
            placeholder: Text(_initials),
          ),
          // Green when online, red when offline, as on the desktop.
          if (showPresence)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                key: ValueKey(
                  user.online ? 'presence-online' : 'presence-offline',
                ),
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: user.online ? AppColors.online : AppColors.offline,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.background,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
