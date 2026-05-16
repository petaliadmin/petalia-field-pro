class AppUser {
  final String id;
  final String name;
  final String phone;
  final String role;
  final String? avatar;

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.avatar,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'role': role,
        'avatar': avatar,
      };

  factory AppUser.fromJson(Map json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: (json['phone'] ?? json['identifier'] ?? '') as String,
        role: json['role'] as String,
        avatar: json['avatar'] as String?,
      );
}

class AuthState {
  final bool isAuthenticated;
  final AppUser? user;
  const AuthState({this.isAuthenticated = false, this.user});
}
