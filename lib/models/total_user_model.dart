import 'package:bigreminder/models/user_list_item_model.dart';

class TotalUserModel {
  final List<UserListItemModel> users;
  final int totalUsers;
  final int totalSuperAdmins;
  final int totalBusinessOwners;

  TotalUserModel({
    required this.users,
    required this.totalUsers,
    required this.totalSuperAdmins,
    required this.totalBusinessOwners,
  });
  factory TotalUserModel.fromJson(List<dynamic> jsonList) {
    final users = jsonList
        .map((e) {
      if (e is Map<String, dynamic>) {
        return UserListItemModel.fromJson(e);
      } else {
        return UserListItemModel(
          id: 0,
          name: '',
          phone: '',
          role: '',
        );
      }
    })
        .toList();

    final totalUsers = users.length;

    final totalSuperAdmins =
        users.where((u) => u.role.toLowerCase() == "super_admin").length;

    final totalBusinessOwners =
        users.where((u) => u.role.toLowerCase() == "business_owner").length;

    return TotalUserModel(
      users: users,
      totalUsers: totalUsers,
      totalSuperAdmins: totalSuperAdmins,
      totalBusinessOwners: totalBusinessOwners,
    );
  }
}