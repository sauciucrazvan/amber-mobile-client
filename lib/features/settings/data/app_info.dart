import 'package:package_info_plus/package_info_plus.dart';

/// The version and build number, as shown in About: `1.0.0 (1)`.
Future<String> appVersionLabel() async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
}
