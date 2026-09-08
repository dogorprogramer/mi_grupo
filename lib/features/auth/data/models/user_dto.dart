import '../../domain/user.dart';

class UserDto {
  const UserDto({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.image,
  });

  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String? image;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as int,
      username: json['username'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      image: json['image'] as String?,
    );
  }

  User toDomain() {
    return User(
      id: id,
      username: username,
      firstName: firstName,
      lastName: lastName,
      email: email,
      image: image,
    );
  }
}
