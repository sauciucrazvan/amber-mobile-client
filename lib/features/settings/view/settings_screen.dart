import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/ui/amber_page_route.dart';
import 'package:amber_mobile_client/features/account/view/account_settings.dart';
import 'package:amber_mobile_client/features/settings/view/settings_pages.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The Settings tab: one button per category, as on the desktop. Each opens
/// its own page with the settings grouped inside it.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 425),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CategoryButton(
                key: const ValueKey('settings-general'),
                icon: LucideIcons.slidersHorizontal,
                label: l10n.t('settings.tabs.general'),
                page: const GeneralPage(),
              ),
              _CategoryButton(
                key: const ValueKey('settings-account'),
                icon: LucideIcons.user,
                label: l10n.t('settings.tabs.account'),
                page: const AccountPage(),
              ),
              _CategoryButton(
                key: const ValueKey('settings-devices'),
                icon: LucideIcons.phone,
                label: l10n.t('settings.tabs.devices'),
                page: const DevicesPage(),
              ),
              _CategoryButton(
                key: const ValueKey('settings-about'),
                icon: LucideIcons.info,
                label: l10n.t('settings.tabs.about'),
                page: const AboutPage(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card that opens a settings page: an icon tile, the category name, and a
/// chevron, so each category reads as a destination.
class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.page,
  });

  final IconData icon;
  final String label;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            Navigator.of(context)
                .push(AmberPageRoute<void>(builder: (_) => page)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.card,
            border: Border.all(color: theme.colorScheme.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.secondaryForeground,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.large.copyWith(fontSize: 16),
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: theme.colorScheme.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
