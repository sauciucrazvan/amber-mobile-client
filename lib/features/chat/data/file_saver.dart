import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

/// Downloads a chat file, then asks the user where to save it. The desktop's
/// "Save as" does the same. Returns false when the user cancels the dialog.
/// Throws when the download fails.
Future<bool> saveChatFile({
  required String url,
  required String filename,
  required String contentType,
  Dio? dio,
}) async {
  final response = await (dio ?? Dio()).get<List<int>>(
    url,
    options: Options(responseType: ResponseType.bytes),
  );
  final bytes = Uint8List.fromList(response.data ?? const []);
  final saved = await FilePicker.saveFile(
    fileName: filename,
    bytes: bytes,
    mimeType: contentType,
  );
  return saved != null;
}
