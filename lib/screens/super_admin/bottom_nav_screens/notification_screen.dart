import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/business/business_provider.dart';
import '../../../theme/super_admin_colors.dart';
import '../../../widgets/custom_dialog.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();
  String selectedAudience = 'All Users';
  bool isSending = false;

  static const _audiences = <({String value, String label, IconData icon})>[
    (value: 'All Users', label: 'All Users', icon: Icons.groups_rounded),
    (value: 'Active Users', label: 'Active', icon: Icons.bolt_rounded),
    (
      value: 'Premium Users',
      label: 'Premium',
      icon: Icons.workspace_premium_outlined
    ),
  ];

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  Future<void> sendNotification() async {
    final title = titleController.text.trim();
    final body = bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      CustomDialog.showErrorSnack(
        context,
        'Please enter both title and message',
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => isSending = true);

    try {
      const int businessId = 1;

      await ref.read(createReminderProvider.notifier).createReminder(
            message: body,
            scheduledAt: DateTime.now(),
            targetGender: 'all',
            businessId: businessId,
          );

      if (!mounted) return;
      titleController.clear();
      bodyController.clear();
      setState(() {});
      CustomDialog.showSuccessSnack(context, 'Notification sent successfully');
    } catch (e) {
      if (!mounted) return;
      CustomDialog.showErrorSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: Icon(icon, size: 20, color: SuperAdminColors.primaryDark),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: maxLines > 1 ? 14 : 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: SuperAdminColors.primaryDark,
          width: 1.5,
        ),
      ),
    );
  }

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
          'Broadcast Notification',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
      ),
      body: isDesktop
          ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 6, child: _composePanel()),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _previewPanel(expanded: true)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
              child: Column(
                children: [
                  _composePanel(),
                  const SizedBox(height: 14),
                  _previewPanel(expanded: false),
                ],
              ),
            ),
    );
  }

  Widget _composePanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: SuperAdminColors.primaryDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compose broadcast',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Send updates to your audience instantly',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Title',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: titleController,
            enabled: !isSending,
            onChanged: (_) => setState(() {}),
            decoration: _fieldDecoration(
              hint: 'e.g. New feature launched',
              icon: Icons.title_rounded,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Message',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: bodyController,
            enabled: !isSending,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            decoration: _fieldDecoration(
              hint: 'Write your notification message…',
              icon: Icons.notes_rounded,
              maxLines: 4,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Audience',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _audiences.map((a) {
              final active = selectedAudience == a.value;
              return InkWell(
                onTap: isSending
                    ? null
                    : () => setState(() => selectedAudience = a.value),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? SuperAdminColors.primaryLight
                        : SuperAdminColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                          ? SuperAdminColors.primaryDark
                          : Colors.grey.shade300,
                      width: active ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        a.icon,
                        size: 15,
                        color: active
                            ? SuperAdminColors.primaryDark
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        a.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? SuperAdminColors.primaryDark
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: isSending ? null : sendNotification,
              icon: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                isSending ? 'Sending…' : 'Send Notification',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: SuperAdminColors.primaryDark,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    SuperAdminColors.primaryDark.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SuperAdminColors.primaryLight.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SuperAdminColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: SuperAdminColors.primaryDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Delivered instantly to $selectedAudience. Avoid sending too frequently.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewPanel({required bool expanded}) {
    final title = titleController.text.trim();
    final body = bodyController.text.trim();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live preview',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          'How it may appear on devices',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
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
                color: SuperAdminColors.primaryDark.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Biz Reminder',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    'now',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title.isEmpty ? 'Notification Title' : title,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: title.isEmpty ? 0.55 : 1,
                  ),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: expanded ? 400 : 72,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    body.isEmpty ? 'Your message will appear here' : body,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: body.isEmpty ? 0.5 : 0.9,
                      ),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  selectedAudience,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (expanded) ...[
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SuperAdminColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Tip: Keep titles short and messages clear for higher open rates.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration,
      child: expanded ? content : content,
    );
  }

  BoxDecoration get _panelDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}
