/// Upload rules from `app/api/features/chats/files.py`. The app checks them on
/// the device first, so the user gets a clear message before a large upload.
abstract final class ChatFileRules {
  static const maxBytes = 15 * 1024 * 1024;

  /// Accepted extensions, each with the content type the backend expects.
  static const contentTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'heic': 'image/heic',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'webm': 'video/webm',
    'mp3': 'audio/mpeg',
    'ogg': 'audio/ogg',
    'aac': 'audio/aac',
    'm4a': 'audio/m4a',
    'pdf': 'application/pdf',
    'txt': 'text/plain',
    'csv': 'text/csv',
    'zip': 'application/zip',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  };

  /// For the file picker's extension filter.
  static List<String> get extensions => contentTypes.keys.toList();

  /// The content type for [extension], or null when it isn't accepted.
  static String? contentTypeFor(String? extension) =>
      contentTypes[extension?.toLowerCase()];

  static bool isImage(String contentType) => contentType.startsWith('image/');

  /// The translation key for the first rule [extension] and [size] break,
  /// or null when the file can be sent.
  static String? problemFor({required String? extension, required int size}) {
    if (contentTypeFor(extension) == null) {
      return 'conversations.files.type_not_accepted';
    }
    if (size == 0) return 'conversations.files.empty';
    if (size > maxBytes) return 'conversations.files.too_big';
    return null;
  }
}
