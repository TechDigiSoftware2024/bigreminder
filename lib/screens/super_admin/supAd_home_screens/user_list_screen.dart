import 'package:bigreminder/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/total_user_model.dart';
import '../../../services/super_admin/user_list_service.dart';


class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserService _service = UserService();

  TotalUserModel? data;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  // ================= LOAD USERS =================
  Future<void> loadUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token'); // 🔑 yaha se token lo

      if (token == null) {
        throw Exception("Token not found");
      }

      final result = await _service.fetchUsers(token: token);

      setState(() {
        data = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor:  AppColors.appBarBg,
        title: const Text(
          "Total Users",
          style: TextStyle(fontWeight: FontWeight.w600,color: AppColors.appBarText),
        ),
        centerTitle: false,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildSummary(),
          const SizedBox(height: 8),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }
  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _statCard("Total", data?.totalUsers ?? 0, Colors.black),
          const SizedBox(width: 8),
          _statCard("Admins", data?.totalSuperAdmins ?? 0, Colors.red),
          const SizedBox(width: 8),
          _statCard("Owners", data?.totalBusinessOwners ?? 0, AppColors.primaryDark),
        ],
      ),
    );
  }

  Widget _statCard(String title, int value, Color color) {
    return Expanded(
      child: Container(
        height: 90,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withOpacity(0.5),
            width: 0.4
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔢 Value
            Text(
              "$value",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 6),

            // 🏷 Title
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ================= USER LIST =================
  Widget _buildUserList() {
    final users = data?.users ?? [];

    if (users.isEmpty) {
      return const Center(child: Text("No Users Found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (_, i) {
        final user = users[i];
        final isAdmin = user.role == "super_admin";

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // 🔥 Gradient Avatar
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isAdmin
                        ? [Colors.red.shade500, Colors.red.shade600]
                        : [AppColors.primaryDark,AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : "?",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 📄 Info Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.phone,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // 🏷 Modern Role Badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? Colors.red.withOpacity(0.1)
                      : AppColors.primaryDark.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  user.role.replaceAll("_", " ").toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isAdmin ? Colors.red : AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}