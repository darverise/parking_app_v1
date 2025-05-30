// lib/core/models/auth_signin_model.dart
class AuthUserModel {
  final String id;
  final String email;
  final String? name;
  final String? phoneNumber;
  final String? avatarUrl;
  final String token;
  final String refreshToken;
  final bool isEmailVerified;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AuthUserModel({
    required this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    this.avatarUrl,
    required this.token,
    required this.refreshToken,
    required this.isEmailVerified,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  // Add getters for snake_case property access
  String? get phone_number => phoneNumber;
  String? get avatar_url => avatarUrl;
  bool get is_email_verified => isEmailVerified;
  String get refresh_token => refreshToken;
  DateTime? get created_at => createdAt;
  DateTime? get updated_at => updatedAt;

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      phoneNumber: json['phone_number'] ?? json['phoneNumber'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      token: json['token'] ?? '',
      refreshToken: json['refresh_token'] ?? json['refreshToken'] ?? '',
      isEmailVerified:
          json['is_email_verified'] ?? json['isEmailVerified'] ?? false,
      role: json['role'] ?? 'user',
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : (json['createdAt'] != null
                  ? DateTime.parse(json['createdAt'])
                  : null),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : (json['updatedAt'] != null
                  ? DateTime.parse(json['updatedAt'])
                  : null),
    );
  }

  get is_owner => null;
}

/// Model for signin request that matches the Rust backend expectations
class SignInRequest {
  final String email;
  final String password;

  SignInRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

/// Model for update user request
class UpdateUserRequest {
  final String? name;
  final String? phoneNumber;
  final String? avatarUrl;

  UpdateUserRequest({this.name, this.phoneNumber, this.avatarUrl});

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
  };
}

/// Model for change password request
class ChangePasswordRequest {
  final String oldPassword;
  final String newPassword;

  ChangePasswordRequest({required this.oldPassword, required this.newPassword});

  Map<String, dynamic> toJson() => {
    'old_password': oldPassword,
    'new_password': newPassword,
  };
}

/// Model for refresh token request
class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refresh_token': refreshToken};
}
