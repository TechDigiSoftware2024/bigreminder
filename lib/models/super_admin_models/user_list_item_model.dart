class UserListItemModel {
  final int id;
  final String name;
  final String phone;
  final String role;

  UserListItemModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
  });

  factory UserListItemModel.fromJson(Map<String, dynamic> json) {
    return UserListItemModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
    );
  }
}