import 'package:amber_mobile_client/core/ui/open_url.dart';
import 'package:amber_mobile_client/core/ui/amber_page_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Opens a full-screen, pinch-to-zoom view of an image attachment.
Future<void> showImagePreview(
  BuildContext context, {
  required String url,
  required String filename,
}) {
  return Navigator.of(context).push(
    AmberPageRoute<void>(
      builder: (_) => ImagePreviewScreen(url: url, filename: filename),
    ),
  );
}

class ImagePreviewScreen extends StatelessWidget {
  const ImagePreviewScreen({
    super.key,
    required this.url,
    required this.filename,
  });

  final String url;
  final String filename;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(filename, overflow: TextOverflow.ellipsis),
        actions: [
          // Download, like the desktop's image preview.
          ShadIconButton.ghost(
            key: const ValueKey('download-image'),
            icon: const Icon(LucideIcons.download, color: Colors.white),
            onPressed: () => openFileUrl(url),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}
