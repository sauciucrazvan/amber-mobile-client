import 'package:amber_mobile_client/core/network/server_time.dart';

/// The other user in a contact, request or block.
class ContactUser {
  const ContactUser({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.online = false,
    this.lastActiveAt,
  });

  factory ContactUser.fromJson(Map<String, dynamic> json) => ContactUser(
    id: json['id'] as int,
    username: json['username'] as String,
    fullName: json['full_name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    online: json['online'] == true,
    lastActiveAt: parseServerTime(json['last_active_at']),
  );

  final int id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final bool online;
  final DateTime? lastActiveAt;

  String get displayName {
    final name = fullName?.trim();
    return name == null || name.isEmpty ? username : name;
  }

  ContactUser copyWith({
    String? fullName,
    String? avatarUrl,
    bool? online,
    DateTime? lastActiveAt,
  }) {
    return ContactUser(
      id: id,
      username: username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      online: online ?? this.online,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}

/// Preview of the latest direct message with a contact.
class LastMessage {
  const LastMessage({
    required this.senderId,
    required this.type,
    this.content = const {},
    this.createdAt,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    final content = json['content'];
    return LastMessage(
      senderId: json['sender_id'] as int,
      type: json['type'] as String? ?? 'text',
      content: content is Map ? Map<String, dynamic>.from(content) : const {},
      createdAt: parseServerTime(json['created_at']),
    );
  }

  final int senderId;

  /// `text`, `file` or `log` (system entries such as call logs).
  final String type;

  /// The message body as stored by the backend (JSON), for example
  /// `{"text": "hi"}`, `{"filename": "a.png"}` or `{"event": "call.missed"}`.
  final Map<String, dynamic> content;
  final DateTime? createdAt;

  String? get text => content['text'] as String?;
}

/// An entry of `GET /contacts/v1/list`.
class Contact {
  const Contact({
    required this.user,
    this.createdAt,
    this.lastActionAt,
    this.notifications = 0,
    this.lastMessage,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    final lastMessage = json['last_message'];
    return Contact(
      user: ContactUser.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: parseServerTime(json['created_at']),
      lastActionAt: parseServerTime(json['last_action_at']),
      notifications: (json['notifications'] as int?) ?? 0,
      lastMessage: lastMessage is Map<String, dynamic>
          ? LastMessage.fromJson(lastMessage)
          : null,
    );
  }

  final ContactUser user;
  final DateTime? createdAt;
  final DateTime? lastActionAt;

  /// Unseen messages in the direct conversation.
  final int notifications;
  final LastMessage? lastMessage;

  Contact copyWith({
    ContactUser? user,
    DateTime? lastActionAt,
    LastMessage? lastMessage,
    bool clearLastMessage = false,
  }) {
    return Contact(
      user: user ?? this.user,
      createdAt: createdAt,
      lastActionAt: lastActionAt ?? this.lastActionAt,
      notifications: notifications,
      lastMessage: clearLastMessage ? null : lastMessage ?? this.lastMessage,
    );
  }
}

/// An incoming friend request from `GET /contacts/v1/requests`.
class ContactRequest {
  const ContactRequest({required this.user, this.createdAt});

  factory ContactRequest.fromJson(Map<String, dynamic> json) => ContactRequest(
    user: ContactUser.fromJson(json['user'] as Map<String, dynamic>),
    createdAt: parseServerTime(json['created_at']),
  );

  final ContactUser user;
  final DateTime? createdAt;
}

/// An entry of `GET /contacts/v1/blocked`.
class BlockedUser {
  const BlockedUser({required this.id, required this.username, this.createdAt});

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return BlockedUser(
      id: user['id'] as int,
      username: user['username'] as String,
      createdAt: parseServerTime(json['created_at']),
    );
  }

  final int id;
  final String username;
  final DateTime? createdAt;
}

/// `GET /contacts/v1/profile/{username}`.
class ContactProfile {
  const ContactProfile({
    required this.user,
    this.bio,
    this.registeredAt,
    this.verified = false,
  });

  factory ContactProfile.fromJson(Map<String, dynamic> json) => ContactProfile(
    user: ContactUser.fromJson(json),
    bio: json['bio'] as String?,
    registeredAt: parseServerTime(json['registered_at']),
    verified: json['verified'] == true,
  );

  final ContactUser user;
  final String? bio;
  final DateTime? registeredAt;
  final bool verified;
}
