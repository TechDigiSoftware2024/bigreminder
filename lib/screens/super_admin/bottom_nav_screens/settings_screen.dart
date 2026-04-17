import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/custom_list_toggle.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool maintenanceMode = false;
  bool allowSignup = true;
  bool guestAccess = false;
  bool enable2FA = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg,
        title: const Text(
          "Admin Settings",
          style: TextStyle(fontWeight: FontWeight.w600,color: AppColors.appBarText),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 APP CONTROL
            _sectionTitle("App Control"),
            _card(
              child: Column(
                children: [
                  CustomListToggle(
                    title: "Maintenance Mode",
                    subtitle: "Disable app for all users",
                    value: maintenanceMode,
                    onChanged: (val) => setState(() => maintenanceMode = val),
                    onColor: AppColors.primaryDark,
                    offColor: AppColors.primary
                  ),
                  _divider(),
                  CustomListToggle(

                    title: "Allow New Registrations",
                    value: allowSignup,
                    onChanged: (val) =>
                        setState(() => allowSignup = val),
                      onColor: AppColors.primaryDark,
                      offColor: AppColors.primary
                  ),
                  _divider(),
                  CustomListToggle(
                    title: "Allow Guest Access",
                    value: guestAccess,
                    onChanged: (val) =>
                        setState(() => guestAccess = val),
                      onColor: AppColors.primaryDark,
                      offColor: AppColors.primary
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 🔹 USER MANAGEMENT
            _sectionTitle("User Management"),
            _card(
              child: Column(
                children: [
                  _tile(
                    title: "View All Users",
                    icon: Icons.people,
                    onTap: () {},
                  ),
                  _divider(),
                  _tile(
                    title: "Block / Unblock Users",
                    icon: Icons.block,
                    onTap: () {},
                  ),
                  _divider(),
                  _tile(
                    title: "User Activity Logs",
                    icon: Icons.history,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 🔹 NOTIFICATIONS
            _sectionTitle("Notifications"),
            _card(
              child: Column(
                children: [
                  CustomListToggle(
                    title: "Enable Push Notifications",
                    value: notificationsEnabled,
                    onChanged: (val) =>
                        setState(() => notificationsEnabled = val),
                      onColor: AppColors.primaryDark,
                      offColor: AppColors.primary
                  ),
                  _divider(),
                  _tile(
                    title: "Notification History",
                    icon: Icons.notifications,
                    onTap: () {},
                  ),
                  _divider(),
                  _tile(
                    title: "Set Daily Limit",
                    icon: Icons.timer,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 🔹 DATA MANAGEMENT
            _sectionTitle("Data Management"),
            _card(
              child: Column(
                children: [
                  _tile(
                    title: "Backup Data",
                    icon: Icons.cloud_upload,
                    onTap: () {},
                  ),
                  _divider(),
                  _tile(
                    title: "Restore Backup",
                    icon: Icons.cloud_download,
                    onTap: () {},
                  ),
                  _divider(),
                  _tile(
                    title: "Clear Cache",
                    icon: Icons.cleaning_services,
                    onTap: () {},
                  ),
                  _divider(),
                  _tile(
                    title: "Reset App Data",
                    icon: Icons.delete_forever,
                    isDanger: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 🔹 SECURITY
            _sectionTitle("Security"),
            _card(
              child: Column(
                children: [
                  _tile(
                    title: "Change Admin Password",
                    icon: Icons.lock_outline,
                    onTap: () {},
                  ),
                  _divider(),
                  CustomListToggle(
                    title: "Enable 2FA",
                    value: enable2FA,
                    onChanged: (val) =>
                        setState(() => enable2FA = val),
                      onColor: AppColors.primaryDark,
                      offColor: AppColors.primary
                  ),
                  _divider(),
                  _tile(
                    title: "Logout",
                    icon: Icons.logout,
                    isDanger: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 🔹 SYSTEM INFO
            _sectionTitle("System Info"),
            _card(
              child: Column(
                children: const [
                  ListTile(
                    title: Text("App Version"),
                    subtitle: Text("v1.0.0"),
                  ),
                  ListTile(
                    title: Text("Build Number"),
                    subtitle: Text("102"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// ================= REUSABLE =================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }



  Widget _tile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isDanger ? Colors.red : AppColors.primaryDark,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? Colors.red : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _divider() {
    return Divider(color: Colors.grey.shade200);
  }
}