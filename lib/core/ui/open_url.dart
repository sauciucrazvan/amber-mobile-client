import 'package:url_launcher/url_launcher.dart';

/// Opens a file's URL in the device's browser or app, which downloads it.
/// Returns false when nothing can open it.
Future<bool> openFileUrl(String url) {
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
