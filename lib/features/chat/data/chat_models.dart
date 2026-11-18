import 'package:amber_mobile_client/core/network/server_time.dart';

/// A direct conversation returned by `POST /chats/v1/direct/{userId}`.
class Conversation {
  const Conversation({
    required this.id,
    required this.type,
    required this.createdAt,
    this.notifications = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    type: json['type'] as String? ?? 'direct',
    createdAt: parseServerTime(json['created_at']),
    notifications: (json['notifications'] as int?) ?? 0,
  );

  final String id;
  final String type;
  final DateTime? createdAt;

  /// Unseen messages for the current user.
  final int notifications;
}

/// Emoji reaction on a message, with the user ids that added it.
class MessageReaction {
  const MessageReaction({
    required this.emoji,
    required this.count,
    this.userIds = const [],
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) =>
      MessageReaction(
        emoji: json['emoji'] as String,
        count: (json['count'] as int?) ?? 0,
        userIds: [
          for (final id in (json['user_ids'] as List<dynamic>?) ?? const [])
            id as int,
        ],
      );

  final String emoji;
  final int count;
  final List<int> userIds;

  bool isReactedBy(int userId) => userIds.contains(userId);
}

/// The message a reply points to, as stored in `content.reply_to`.
class ReplyTo {
  const ReplyTo({
    required this.id,
    required this.senderId,
    required this.type,
    this.text,
  });

  factory ReplyTo.fromJson(Map<String, dynamic> json) {
    final content = json['content'];
    return ReplyTo(
      id: json['id'] as String,
      senderId: json['sender_id'] as int,
      type: json['type'] as String? ?? 'text',
      text: content is Map ? content['text'] as String? : null,
    );
  }

  final String id;
  final int senderId;
  final String type;
  final String? text;
}

/// An uploaded file, from a `file` message's content.
class ChatFile {
  const ChatFile({
    required this.url,
    required this.filename,
    required this.contentType,
    required this.size,
    this.width,
    this.height,
  });

  final String url;
  final String filename;
  final String contentType;
  final int size;
  final int? width;
  final int? height;

  bool get isImage => contentType.startsWith('image/');
}

/// A chat message as returned by the messages endpoints and `message.*` events.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.seq,
    required this.type,
    required this.content,
    this.reactions = const [],
    this.createdAt,
    this.editedAt,
    this.seen = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final content = json['content'];
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as int,
      seq: json['seq'] as int,
      type: json['type'] as String? ?? 'text',
      content: content is Map ? Map<String, dynamic>.from(content) : const {},
      reactions: [
        for (final r
            in (json['reaction_details'] as List<dynamic>?) ?? const [])
          MessageReaction.fromJson(r as Map<String, dynamic>),
      ],
      createdAt: parseServerTime(json['created_at']),
      editedAt: parseServerTime(json['edited_at']),
      seen: json['seen'] == true,
    );
  }

  final String id;
  final String conversationId;
  final int senderId;

  /// Position in the conversation. Read cursors are expressed in seq.
  final int seq;

  /// `text`, `file`, or `log` for system entries such as call logs.
  final String type;
  final Map<String, dynamic> content;
  final List<MessageReaction> reactions;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final bool seen;

  String? get text => content['text'] as String?;

  bool get isEdited => editedAt != null;

  bool isMine(int userId) => senderId == userId;

  ReplyTo? get replyTo {
    final reply = content['reply_to'];
    return reply is Map<String, dynamic> ? ReplyTo.fromJson(reply) : null;
  }

  ChatFile? get file {
    if (type != 'file') return null;
    return ChatFile(
      url: content['url'] as String,
      filename: content['filename'] as String? ?? 'file',
      contentType:
          content['content_type'] as String? ?? 'application/octet-stream',
      size: (content['size'] as int?) ?? 0,
      width: content['width'] as int?,
      height: content['height'] as int?,
    );
  }

  ChatMessage copyWith({
    List<MessageReaction>? reactions,
    DateTime? editedAt,
    Map<String, dynamic>? content,
    bool? seen,
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      seq: seq,
      type: type,
      content: content ?? this.content,
      reactions: reactions ?? this.reactions,
      createdAt: createdAt,
      editedAt: editedAt ?? this.editedAt,
      seen: seen ?? this.seen,
    );
  }
}

/// Result of `POST /chats/v1/{id}/read-cursor`.
class ReadCursor {
  const ReadCursor({required this.lastSeenSeq, required this.updated});

  factory ReadCursor.fromJson(Map<String, dynamic> json) => ReadCursor(
    lastSeenSeq: json['last_seen_seq'] as int,
    updated: (json['updated'] as int?) ?? 0,
  );

  final int lastSeenSeq;

  /// How many messages this call newly marked as read.
  final int updated;
}
