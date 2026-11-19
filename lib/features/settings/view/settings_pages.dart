import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/l10n/language_cubit.dart';
import 'package:amber_mobile_client/core/theme/appearance_cubit.dart';
import 'package:amber_mobile_client/core/ui/amber_page.dart';
import 'package:amber_mobile_client/features/auth/view/legal_dialog.dart';
import 'package:amber_mobile_client/features/calls/bloc/call_devices_cubit.dart';
import 'package:amber_mobile_client/features/calls/data/call_devices.dart';
import 'package:amber_mobile_client/features/settings/data/app_info.dart';
import 'package:amber_mobile_client/features/settings/view/settings_layout.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// General: how the app looks and the language it speaks.
class GeneralPage extends StatelessWidget {
  const GeneralPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AmberPage(
      title: l10n.t('settings.tabs.general'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSection(
            title: l10n.t('settings.tabs.appearance'),
            children: const [_ThemeRow(), _FontScaleRow()],
          ),
          SettingsSection(
            title: l10n.t('settings.general.language.title'),
            children: const [_LanguageRow()],
          ),
        ],
      ),
    );
  }
}

/// Devices: the camera and speaker a call starts with.
class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AmberPage(
      title: l10n.t('settings.tabs.devices'),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_CameraRow(), _AudioOutputRow(), _MicrophoneRow()],
      ),
    );
  }
}

/// About: the version, and the legal documents.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AmberPage(
      title: l10n.t('settings.tabs.about'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _VersionRow(),
          SettingsSection(
            title: l10n.t('settings.legal.title'),
            children: const [_LegalRow()],
          ),
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
    return SettingsRow(
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
    return SettingsRow(
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

class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final code = context.select(
      (LanguageCubit cubit) => cubit.state.localeCode,
    );
    return SettingsRow(
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

class _CameraRow extends StatelessWidget {
  const _CameraRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final camera = context.select(
      (CallDevicesCubit cubit) => cubit.state.camera,
    );
    return SettingsRow(
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
    return SettingsRow(
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

class _MicrophoneRow extends StatelessWidget {
  const _MicrophoneRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsRow(
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
      builder: (context, snapshot) => SettingsRow(
        title: l10n.t('settings.about.version'),
        control: Text(snapshot.data ?? ''),
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
