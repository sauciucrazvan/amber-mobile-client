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
    this.avatarUrl,
  });

  /// Reads a peer from `from` (ringing) or `peer` (call summaries).
  factory CallPeer.fromJson(Map<String, dynamic> json) {
    final username = json['username'] as String;
    return CallPeer(
      username: username,
      displayName: (json['display_name'] as String?) ?? username,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  final String username;
  final String displayName;
  final String? avatarUrl;
}
