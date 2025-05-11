// lib/core/models/auth_signin_model.dart
class AuthUserModel {
  final String id;
  final String login_id;
  final String username;
  final String email;
  final String phone_number;
  final String? avatar_url;
  final String token;
  final String refresh_token;
  final bool is_owner;

  AuthUserModel({
    required this.id,
    required this.login_id,
    required this.username,
    required this.email,
    required this.phone_number,
    this.avatar_url,
    required this.token,
    required this.refresh_token,
    required this.is_owner,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] ?? '',
      login_id: json['login_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone_number: json['phone_number'] ?? '',
      avatar_url: json['avatar_url'],
      token: json['token'] ?? '',
      refresh_token: json['refresh_token'] ?? '',
      is_owner: json['is_owner'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'login_id': login_id,
    'username': username,
    'email': email,
    'phone_number': phone_number,
    'avatar_url': avatar_url,
    'token': token,
    'refresh_token': refresh_token,
    'is_owner': is_owner,
  };
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
  final String? avatar_url;

  UpdateUserRequest({required this.username, this.email, this.avatar_url});

  Map<String, dynamic> toJson() => {
    'username': username,
    if (email != null) 'email': email,
    if (avatar_url != null) 'avatar_url': avatar_url,
  };
}

class ChangePasswordRequest {
  final String oldPassword;
  final String newPassword;

  ChangePasswordRequest({required this.oldPassword, required this.newPassword});

  Map<String, dynamic> toJson() => {
    'old_password': oldPassword,
    'new_password': newPassword,
  };
}
