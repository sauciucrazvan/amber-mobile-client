/// Audio or video, as the caller picks it.
enum CallMode {
  audio,
  video;

  /// Parses the `mode` or `call_mode` value. Anything else is a video call,
  /// as on the backend.
  static CallMode parse(Object? value) {
    return value == 'audio' ? CallMode.audio : CallMode.video;
  }
}

/// The other person in a call.
class CallPeer {
  const CallPeer({
    required this.username,
    required this.displayName,
    this.id,
    this.avatarUrl,
  });

  /// Reads a peer from `from` (ringing) or `peer` (call summaries).
  factory CallPeer.fromJson(Map<String, dynamic> json) {
    final username = json['username'] as String;
    return CallPeer(
      username: username,
      displayName: (json['display_name'] as String?) ?? username,
      id: json['id'] as int?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  final String username;
  final String displayName;

  /// The user's id, when the server sent it. Needed to open their chat.
  final int? id;
  final String? avatarUrl;
}
