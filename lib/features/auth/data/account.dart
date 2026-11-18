import 'package:amber_mobile_client/core/network/server_time.dart';

/// The signed-in user, as returned by `GET /account/v1/me`.
class Account {
  const Account({
    required this.id,
    required this.username,
    required this.verified,
    this.fullName,
    this.email,
    this.bio,
    this.avatarUrl,
    this.registeredAt,
    this.lastActiveAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as int,
    username: json['username'] as String,
    verified: json['verified'] == true,
    fullName: json['full_name'] as String?,
    email: json['email'] as String?,
    bio: json['bio'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    registeredAt: parseServerTime(json['registered_at']),
    lastActiveAt: parseServerTime(json['last_active_at']),
  );

  final int id;
  final String username;
  final bool verified;
  final String? fullName;
  final String? email;
  final String? bio;
  final String? avatarUrl;
  final DateTime? registeredAt;
  final DateTime? lastActiveAt;

  String get displayName {
    final name = fullName?.trim();
    return name == null || name.isEmpty ? username : name;
  }

  Account copyWith({bool? verified}) => Account(
    id: id,
    username: username,
    verified: verified ?? this.verified,
    fullName: fullName,
    email: email,
    bio: bio,
    avatarUrl: avatarUrl,
    registeredAt: registeredAt,
    lastActiveAt: lastActiveAt,
  );
}
