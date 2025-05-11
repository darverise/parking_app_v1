class AuthUserModel {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final String token;
  final String refreshToken;

  AuthUserModel({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    required this.token,
    required this.refreshToken,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
    id: json['id'] ?? '',
    username: json['username'] ?? '',
    email: json['email'] ?? '',
    avatarUrl: json['avatarUrl'],
    token: json['token'] ?? '',
    refreshToken: json['refreshToken'] ?? '',
  );
}

class SignInRequest {
  final String username;
  final String password;

  SignInRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class UpdateUserRequest {
  final String username;
  final String? email;
  final String? avatarUrl;

  UpdateUserRequest({required this.username, this.email, this.avatarUrl});

  Map<String, dynamic> toJson() => {
    'username': username,
    if (email != null) 'email': email,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
  };
}

class ChangePasswordRequest {
  final String oldPassword;
  final String newPassword;

  ChangePasswordRequest({required this.oldPassword, required this.newPassword});

  Map<String, dynamic> toJson() => {
    'oldPassword': oldPassword,
    'newPassword': newPassword,
  };
}
