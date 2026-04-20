class UserModel {
  final String name;
  final String role;
  final String email;

  const UserModel({
    required this.name,
    required this.role,
    required this.email,
  });

  UserModel copyWith({
    String? name,
    String? role,
    String? email,
  }) {
    return UserModel(
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
    );
  }
}