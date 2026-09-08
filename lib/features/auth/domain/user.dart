class User {
  const User({
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
}
