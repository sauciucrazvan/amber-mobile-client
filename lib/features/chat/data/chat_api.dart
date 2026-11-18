import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/features/chat/data/chat_models.dart';
import 'package:dio/dio.dart';

/// Calls the `/chats/v1/*` endpoints. Every method throws [ApiFailure].
///
/// The paths and bodies follow the backend router. Where the backend differs
/// from `plan/03-chat.md`, the backend wins: edit and delete take the message
/// id in the body rather than the path, and reactions send the emoji as JSON.
class ChatApi {
  ChatApi(this._client);

  final ApiClient _client;

  /// Opens the direct conversation with a contact, creating it if needed.
  Future<Conversation> openDirect(int otherUserId) async {
    final response = await _guard(
      () => _client.request<Map<String, dynamic>>(
        '/chats/v1/direct/$otherUserId',
        method: 'POST',
      ),
    );
    return Conversation.fromJson(response.data!);
  }

  /// One page of messages, oldest first. Pass [before] (the created time of
  /// the oldest loaded message) to load older pages.
  ///
  /// The first page also marks the conversation as read on the server.
  Future<List<ChatMessage>> messages(
    String conversationId, {
    int limit = 20,
    DateTime? before,
  }) async {
    final query = Uri(
      queryParameters: {
        'limit': '$limit',
        if (before != null) 'before': before.toUtc().toIso8601String(),
      },
    ).query;
    final response = await _guard(
      () => _client.request<List<dynamic>>(
        '/chats/v1/$conversationId/messages?$query',
      ),
    );
    return [
      for (final item in response.data ?? const [])
        ChatMessage.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<ChatMessage> sendText(String conversationId, String text) {
    return _sendForm(
      '/chats/v1/$conversationId/messages',
      fields: {'text': text},
    );
  }

  /// Sends a file, with an optional caption. The backend checks the type and
  /// size (see `ChatFileRules`).
  Future<ChatMessage> sendFile(
    String conversationId, {
    required ChatUpload file,
    String? text,
  }) {
    return _sendForm(
      '/chats/v1/$conversationId/messages',
      fields: {'text': ?text},
      file: file,
    );
  }

  /// Replies to [messageId] with text, a file, or both.
  Future<ChatMessage> reply(
    String conversationId, {
    required String messageId,
    String? text,
    ChatUpload? file,
  }) {
    return _sendForm(
      '/chats/v1/$conversationId/reply',
      fields: {'message_id': messageId, 'text': ?text},
      file: file,
    );
  }

  /// Edits the text of one of the current user's messages.
  Future<ChatMessage> edit(
    String conversationId, {
    required String messageId,
    required String text,
  }) async {
    final response = await _guard(
      () => _client.request<Map<String, dynamic>>(
        '/chats/v1/$conversationId/messages',
        method: 'PATCH',
        data: {'text': text, 'message_id': messageId},
      ),
    );
    return ChatMessage.fromJson(response.data!);
  }

  Future<void> delete(String conversationId, {required String messageId}) {
    return _guard(
      () => _client.request<void>(
        '/chats/v1/$conversationId/messages',
        method: 'DELETE',
        data: {'message_id': messageId},
      ),
    );
  }

  /// Adds the current user's [emoji] to a message and returns the updated
  /// message.
  Future<ChatMessage> addReaction(
    String conversationId, {
    required String messageId,
    required String emoji,
  }) {
    return _reaction('POST', conversationId, messageId, emoji);
  }

  Future<ChatMessage> removeReaction(
    String conversationId, {
    required String messageId,
    required String emoji,
  }) {
    return _reaction('DELETE', conversationId, messageId, emoji);
  }

  /// Marks messages up to [uptoSeq] as read.
  Future<ReadCursor> markRead(
    String conversationId, {
    required int uptoSeq,
  }) async {
    final response = await _guard(
      () => _client.request<Map<String, dynamic>>(
        '/chats/v1/$conversationId/read-cursor',
        method: 'POST',
        data: {'upto_seq': uptoSeq},
      ),
    );
    return ReadCursor.fromJson(response.data!);
  }

  Future<ChatMessage> _reaction(
    String method,
    String conversationId,
    String messageId,
    String emoji,
  ) async {
    final response = await _guard(
      () => _client.request<Map<String, dynamic>>(
        '/chats/v1/$conversationId/messages/$messageId/reactions',
        method: method,
        data: {'emoji': emoji},
      ),
    );
    return ChatMessage.fromJson(response.data!);
  }

  Future<ChatMessage> _sendForm(
    String path, {
    required Map<String, String> fields,
    ChatUpload? file,
  }) async {
    final form = FormData.fromMap({
      ...fields,
      if (file != null)
        'file': MultipartFile.fromBytes(
          file.bytes,
          filename: file.filename,
          contentType: DioMediaType.parse(file.contentType),
        ),
    });
    final response = await _guard(
      () => _client.request<Map<String, dynamic>>(
        path,
        method: 'POST',
        data: form,
      ),
    );
    return ChatMessage.fromJson(response.data!);
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}

/// A file picked on the device, ready to upload.
class ChatUpload {
  const ChatUpload({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final List<int> bytes;
  final String filename;

  /// Must be one of the types in [ChatFileRules.contentTypes].
  final String contentType;
}
