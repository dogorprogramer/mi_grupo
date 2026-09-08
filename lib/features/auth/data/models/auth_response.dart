import 'user_dto.dart';

class AuthResponse {
  const AuthResponse({required this.accessToken, required this.user});

  final String accessToken;
  final UserDto user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      user: UserDto.fromJson(json),
    );
  }
}
