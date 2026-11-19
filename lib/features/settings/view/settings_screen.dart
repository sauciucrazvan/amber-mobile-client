import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/theme/appearance_cubit.dart';
import 'package:amber_mobile_client/core/l10n/language_cubit.dart';
import 'package:amber_mobile_client/features/auth/view/legal_dialog.dart';
import 'package:amber_mobile_client/features/calls/bloc/call_devices_cubit.dart';
import 'package:amber_mobile_client/features/calls/data/call_devices.dart';
import 'package:amber_mobile_client/features/contacts/view/blocked_accounts_screen.dart';
import 'package:amber_mobile_client/features/settings/data/app_info.dart';
import 'package:amber_mobile_client/core/ui/amber_page_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Local settings: appearance, call devices, about and legal. Changes apply
/// at once and stay on this device. Account settings are elsewhere.
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Section(
                title: l10n.t('settings.tabs.appearance'),
                children: const [_ThemeRow(), _FontScaleRow()],
              ),
              _Section(
                title: l10n.t('settings.general.language.title'),
                children: const [_LanguageRow()],
              ),
              _Section(
                title: l10n.t('settings.tabs.devices'),
                children: const [
                  _CameraRow(),
                  _AudioOutputRow(),
                  _MicrophoneRow(),
                ],
              ),
              _Section(
                title: l10n.t('contacts.blocked.title'),
                children: const [_BlockedRow()],
              ),
              _Section(
                title: l10n.t('settings.tabs.about'),
                children: const [_VersionRow()],
              ),
              _Section(
                title: l10n.t('settings.legal.title'),
                children: const [_LegalRow()],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.large),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

/// A label and a short description, with the control on the right.
class _Row extends StatelessWidget {
  const _Row({required this.title, this.description, required this.control});

  final String title;
  final String? description;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.small),
                if (description != null)
                  Text(description!, style: theme.textTheme.muted),
              ],
            ),
          ),
          const SizedBox(width: 12),
          control,
        ],
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = context.select(
      (AppearanceCubit cubit) => cubit.state.themeMode == ThemeMode.dark,
    );
    return _Row(
      title: l10n.t('settings.appearance.theme.title'),
      description: l10n.t('settings.appearance.theme.description'),
      control: ShadSwitch(
        key: const ValueKey('dark-theme'),
        value: dark,
        onChanged: (value) => context.read<AppearanceCubit>().setThemeMode(
          value ? ThemeMode.dark : ThemeMode.light,
        ),
      ),
    );
  }
}

class _FontScaleRow extends StatelessWidget {
  const _FontScaleRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scale = context.select(
      (AppearanceCubit cubit) => cubit.state.fontScale,
    );
    return _Row(
      title: l10n.t('settings.appearance.scaling.title'),
      description: l10n.t('settings.appearance.scaling.description'),
      control: ShadSelect<double>(
        key: const ValueKey('font-scale'),
        initialValue: scale,
        options: [
          for (final option in fontScaleOptions)
            ShadOption(value: option, child: Text('${option}x')),
        ],
        selectedOptionBuilder: (_, value) => Text('${value}x'),
        onChanged: (value) {
          if (value != null) {
            context.read<AppearanceCubit>().setFontScale(value);
          }
        },
      ),
    );
  }
}

class _CameraRow extends StatelessWidget {
  const _CameraRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final camera = context.select(
      (CallDevicesCubit cubit) => cubit.state.camera,
    );
    return _Row(
      title: l10n.t('settings.general.devices.camera.title'),
      description: l10n.t('settings.general.devices.camera.description'),
      control: ShadSelect<CameraChoice>(
        key: const ValueKey('call-camera-choice'),
        initialValue: camera,
        options: [
          ShadOption(
            value: CameraChoice.front,
            child: Text(l10n.t('settings.devices.options.front')),
          ),
          ShadOption(
            value: CameraChoice.back,
            child: Text(l10n.t('settings.devices.options.back')),
          ),
        ],
        selectedOptionBuilder: (_, value) => Text(
          l10n.t(
            value == CameraChoice.back
                ? 'settings.devices.options.back'
                : 'settings.devices.options.front',
          ),
        ),
        onChanged: (value) {
          if (value != null) {
            context.read<CallDevicesCubit>().setCamera(value);
          }
        },
      ),
    );
  }
}

class _AudioOutputRow extends StatelessWidget {
  const _AudioOutputRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final output = context.select(
      (CallDevicesCubit cubit) => cubit.state.audioOutput,
    );
    String label(AudioOutput value) => l10n.t(
      value == AudioOutput.speaker
          ? 'settings.devices.options.speaker'
          : 'settings.devices.options.earpiece',
    );
    return _Row(
      title: l10n.t('settings.general.devices.speaker.title'),
      description: l10n.t('settings.general.devices.speaker.description'),
      control: ShadSelect<AudioOutput>(
        key: const ValueKey('call-audio-output'),
        initialValue: output,
        options: [
          for (final value in AudioOutput.values)
            ShadOption(value: value, child: Text(label(value))),
        ],
        selectedOptionBuilder: (_, value) => Text(label(value)),
        onChanged: (value) {
          if (value != null) {
            context.read<CallDevicesCubit>().setAudioOutput(value);
          }
        },
      ),
    );
  }
}

/// Phones use their own microphone, so the choice the desktop offers is not
/// available here. The row says so, rather than leaving it out.
class _MicrophoneRow extends StatelessWidget {
  const _MicrophoneRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Row(
      title: l10n.t('settings.general.devices.microphone.title'),
      description: l10n.t('settings.devices.microphoneDefault'),
      control: const SizedBox.shrink(),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<String>(
      future: appVersionLabel(),
      builder: (context, snapshot) => _Row(
        title: l10n.t('settings.about.version'),
        control: Text(snapshot.data ?? ''),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final code = context.select(
      (LanguageCubit cubit) => cubit.state.localeCode,
    );
    return _Row(
      title: l10n.t('settings.general.language.title'),
      description: l10n.t('settings.general.language.description'),
      control: ShadSelect<String>(
        key: const ValueKey('language'),
        initialValue: code,
        options: [
          for (final entry in languageNames.entries)
            ShadOption(value: entry.key, child: Text(entry.value)),
        ],
        selectedOptionBuilder: (_, value) =>
            Text(languageNames[value] ?? value),
        onChanged: (value) {
          if (value != null) {
            context.read<LanguageCubit>().setLanguage(value);
          }
        },
      ),
    );
  }
}

/// The blocked-accounts list, which used to sit in the chats header.
class _BlockedRow extends StatelessWidget {
  const _BlockedRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Row(
      title: l10n.t('contacts.blocked.title'),
      description: l10n.t('contacts.blocked.description'),
      control: ShadButton.outline(
        key: const ValueKey('open-blocked'),
        size: ShadButtonSize.sm,
        onPressed: () => Navigator.of(context).push(
          AmberPageRoute<void>(builder: (_) => const BlockedAccountsScreen()),
        ),
        child: Text(l10n.t('contacts.blocked.trigger')),
      ),
    );
  }
}

class _LegalRow extends StatelessWidget {
  const _LegalRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      children: [
        ShadButton.outline(
          key: const ValueKey('open-terms'),
          size: ShadButtonSize.sm,
          onPressed: () => showLegalDialog(context, LegalDocument.terms),
          child: Text(l10n.t('legal.terms.title')),
        ),
        ShadButton.outline(
          key: const ValueKey('open-privacy'),
          size: ShadButtonSize.sm,
          onPressed: () => showLegalDialog(context, LegalDocument.privacy),
          child: Text(l10n.t('legal.privacy.title')),
        ),
      ],
    );
  }
}
