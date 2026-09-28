import 'package:bigreminder/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../theme/super_admin_colors.dart';
import '../../../widgets/custom_dialog.dart';
import '../../../widgets/custom_list_toggle.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool notificationsEnabled = true;
  bool maintenanceMode = false;
  bool allowSignup = true;
  bool guestAccess = false;
  bool enable2FA = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: SuperAdminColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: SuperAdminColors.primaryDark,
        foregroundColor: Colors.white,
        title: const Text(
          'Admin Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 20 : 14,
          16,
          isDesktop ? 20 : 14,
          28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroBanner(),
            const SizedBox(height: 18),

            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _sectionBlock(
                          title: 'App Control',
                          subtitle: 'Platform availability & access',
                          icon: Icons.tune_rounded,
                          child: Column(
                            children: [
                              CustomListToggle(
                                title: 'Maintenance Mode',
                                subtitle: 'Disable app for all users',
                                value: maintenanceMode,
                                onChanged: (val) =>
                                    setState(() => maintenanceMode = val),
                                onColor: SuperAdminColors.primaryDark,
                                offColor: SuperAdminColors.primary,
                              ),
                              CustomListToggle(
                                title: 'Allow New Registrations',
                                subtitle: 'New businesses can sign up',
                                value: allowSignup,
                                onChanged: (val) =>
                                    setState(() => allowSignup = val),
                                onColor: SuperAdminColors.primaryDark,
                                offColor: SuperAdminColors.primary,
                              ),
                              CustomListToggle(
                                title: 'Allow Guest Access',
                                subtitle: 'Browse without full login',
                                value: guestAccess,
                                onChanged: (val) =>
                                    setState(() => guestAccess = val),
                                onColor: SuperAdminColors.primaryDark,
                                offColor: SuperAdminColors.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _sectionBlock(
                          title: 'Notifications',
                          subtitle: 'Push delivery preferences',
                          icon: Icons.notifications_active_outlined,
                          child: Column(
                            children: [
                              CustomListToggle(
                                title: 'Enable Push Notifications',
                                subtitle: 'System-wide push delivery',
                                value: notificationsEnabled,
                                onChanged: (val) => setState(
                                  () => notificationsEnabled = val,
                                ),
                                onColor: SuperAdminColors.primaryDark,
                                offColor: SuperAdminColors.primary,
                              ),
                              _tile(
                                title: 'Notification History',
                                subtitle: 'View past broadcasts',
                                icon: Icons.history_rounded,
                                onTap: () {},
                              ),
                              _tile(
                                title: 'Set Daily Limit',
                                subtitle: 'Cap notifications per day',
                                icon: Icons.timer_outlined,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        _sectionBlock(
                          title: 'User Management',
                          subtitle: 'Accounts & activity',
                          icon: Icons.people_alt_outlined,
                          child: Column(
                            children: [
                              _tile(
                                title: 'View All Users',
                                subtitle: 'Browse registered accounts',
                                icon: Icons.people_outline_rounded,
                                onTap: () {},
                              ),
                              _tile(
                                title: 'Block / Unblock Users',
                                subtitle: 'Manage access restrictions',
                                icon: Icons.block_flipped,
                                onTap: () {},
                              ),
                              _tile(
                                title: 'User Activity Logs',
                                subtitle: 'Audit recent actions',
                                icon: Icons.manage_history_rounded,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _sectionBlock(
                          title: 'Data Management',
                          subtitle: 'Backup and maintenance',
                          icon: Icons.storage_rounded,
                          child: Column(
                            children: [
                              _tile(
                                title: 'Backup Data',
                                subtitle: 'Create a platform backup',
                                icon: Icons.cloud_upload_outlined,
                                onTap: () {},
                              ),
                              _tile(
                                title: 'Restore Backup',
                                subtitle: 'Restore from a saved copy',
                                icon: Icons.cloud_download_outlined,
                                onTap: () {},
                              ),
                              _tile(
                                title: 'Clear Cache',
                                subtitle: 'Free temporary storage',
                                icon: Icons.cleaning_services_outlined,
                                onTap: () {},
                              ),
                              _tile(
                                title: 'Reset App Data',
                                subtitle: 'Dangerous — wipe app data',
                                icon: Icons.delete_forever_outlined,
                                isDanger: true,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _sectionBlock(
                          title: 'Security',
                          subtitle: 'Account protection',
                          icon: Icons.shield_outlined,
                          child: Column(
                            children: [
                              _tile(
                                title: 'Change Admin Password',
                                subtitle: 'Update your credentials',
                                icon: Icons.lock_outline_rounded,
                                onTap: () {},
                              ),
                              CustomListToggle(
                                title: 'Enable 2FA',
                                subtitle: 'Extra login verification',
                                value: enable2FA,
                                onChanged: (val) =>
                                    setState(() => enable2FA = val),
                                onColor: SuperAdminColors.primaryDark,
                                offColor: SuperAdminColors.primary,
                              ),
                              _tile(
                                title: 'Logout',
                                subtitle: 'Sign out of super admin',
                                icon: Icons.logout_rounded,
                                isDanger: true,
                                onTap: _showLogoutDialog,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _systemInfoCard(),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              _sectionBlock(
                title: 'App Control',
                subtitle: 'Platform availability & access',
                icon: Icons.tune_rounded,
                child: Column(
                  children: [
                    CustomListToggle(
                      title: 'Maintenance Mode',
                      subtitle: 'Disable app for all users',
                      value: maintenanceMode,
                      onChanged: (val) =>
                          setState(() => maintenanceMode = val),
                      onColor: SuperAdminColors.primaryDark,
                      offColor: SuperAdminColors.primary,
                    ),
                    CustomListToggle(
                      title: 'Allow New Registrations',
                      subtitle: 'New businesses can sign up',
                      value: allowSignup,
                      onChanged: (val) => setState(() => allowSignup = val),
                      onColor: SuperAdminColors.primaryDark,
                      offColor: SuperAdminColors.primary,
                    ),
                    CustomListToggle(
                      title: 'Allow Guest Access',
                      subtitle: 'Browse without full login',
                      value: guestAccess,
                      onChanged: (val) => setState(() => guestAccess = val),
                      onColor: SuperAdminColors.primaryDark,
                      offColor: SuperAdminColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionBlock(
                title: 'User Management',
                subtitle: 'Accounts & activity',
                icon: Icons.people_alt_outlined,
                child: Column(
                  children: [
                    _tile(
                      title: 'View All Users',
                      subtitle: 'Browse registered accounts',
                      icon: Icons.people_outline_rounded,
                      onTap: () {},
                    ),
                    _tile(
                      title: 'Block / Unblock Users',
                      subtitle: 'Manage access restrictions',
                      icon: Icons.block_flipped,
                      onTap: () {},
                    ),
                    _tile(
                      title: 'User Activity Logs',
                      subtitle: 'Audit recent actions',
                      icon: Icons.manage_history_rounded,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionBlock(
                title: 'Notifications',
                subtitle: 'Push delivery preferences',
                icon: Icons.notifications_active_outlined,
                child: Column(
                  children: [
                    CustomListToggle(
                      title: 'Enable Push Notifications',
                      subtitle: 'System-wide push delivery',
                      value: notificationsEnabled,
                      onChanged: (val) =>
                          setState(() => notificationsEnabled = val),
                      onColor: SuperAdminColors.primaryDark,
                      offColor: SuperAdminColors.primary,
                    ),
                    _tile(
                      title: 'Notification History',
                      subtitle: 'View past broadcasts',
                      icon: Icons.history_rounded,
                      onTap: () {},
                    ),
                    _tile(
                      title: 'Set Daily Limit',
                      subtitle: 'Cap notifications per day',
                      icon: Icons.timer_outlined,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionBlock(
                title: 'Data Management',
                subtitle: 'Backup and maintenance',
                icon: Icons.storage_rounded,
                child: Column(
                  children: [
                    _tile(
                      title: 'Backup Data',
                      subtitle: 'Create a platform backup',
                      icon: Icons.cloud_upload_outlined,
                      onTap: () {},
                    ),
                    _tile(
                      title: 'Restore Backup',
                      subtitle: 'Restore from a saved copy',
                      icon: Icons.cloud_download_outlined,
                      onTap: () {},
                    ),
                    _tile(
                      title: 'Clear Cache',
                      subtitle: 'Free temporary storage',
                      icon: Icons.cleaning_services_outlined,
                      onTap: () {},
                    ),
                    _tile(
                      title: 'Reset App Data',
                      subtitle: 'Dangerous — wipe app data',
                      icon: Icons.delete_forever_outlined,
                      isDanger: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionBlock(
                title: 'Security',
                subtitle: 'Account protection',
                icon: Icons.shield_outlined,
                child: Column(
                  children: [
                    _tile(
                      title: 'Change Admin Password',
                      subtitle: 'Update your credentials',
                      icon: Icons.lock_outline_rounded,
                      onTap: () {},
                    ),
                    CustomListToggle(
                      title: 'Enable 2FA',
                      subtitle: 'Extra login verification',
                      value: enable2FA,
                      onChanged: (val) => setState(() => enable2FA = val),
                      onColor: SuperAdminColors.primaryDark,
                      offColor: SuperAdminColors.primary,
                    ),
                    _tile(
                      title: 'Logout',
                      subtitle: 'Sign out of super admin',
                      icon: Icons.logout_rounded,
                      isDanger: true,
                      onTap: _showLogoutDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _systemInfoCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _heroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SuperAdminColors.primaryDark,
            SuperAdminColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: SuperAdminColors.primaryDark.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Platform Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Control access, security, and system preferences',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionBlock({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: SuperAdminColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: SuperAdminColors.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _tile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final color = isDanger ? SuperAdminColors.error : SuperAdminColors.primaryDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDanger
                          ? SuperAdminColors.error
                          : SuperAdminColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _systemInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _infoCell('App Version', 'v1.0.0'),
          ),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          Expanded(
            child: _infoCell('Build', '102'),
          ),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          Expanded(
            child: _infoCell('Theme', 'Admin'),
          ),
        ],
      ),
    );
  }

  Widget _infoCell(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: SuperAdminColors.primaryDark,
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) {
        final width = CustomDialog.dialogWidth(
          dialogContext,
          desktop: CustomDialog.confirmWidth,
        );
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: SuperAdminColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: SuperAdminColors.error,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Logout?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to logout from your admin account?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: SuperAdminColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            await ref
                                .read(authControllerProvider.notifier)
                                .logout();
                            if (!mounted) return;
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          child: const Text(
                            'Logout',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
