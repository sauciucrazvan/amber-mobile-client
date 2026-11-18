/// The signed-in user, as returned by `GET /account/v1/me`.
class Account {
  const Account({
    required this.id,
    required this.username,
    required this.verified,
    this.fullName,
    this.email,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as int,
    username: json['username'] as String,
    verified: json['verified'] == true,
    fullName: json['full_name'] as String?,
    email: json['email'] as String?,
  );

  final int id;
  final String username;
  final bool verified;
  final String? fullName;
  final String? email;

  Account copyWith({bool? verified}) => Account(
    id: id,
    username: username,
    verified: verified ?? this.verified,
    fullName: fullName,
    email: email,
  );
}
