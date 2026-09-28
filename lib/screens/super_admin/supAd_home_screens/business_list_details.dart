import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/business_models/business_access_model.dart';
import '../../../models/super_admin_models/business_list_model.dart';
import '../../../services/business/business_access_service.dart';
import '../../../theme/super_admin_colors.dart';
import '../../../widgets/custom_dialog.dart';

/// Full-page details (mobile / deep link).
class BusinessDetailPage extends StatelessWidget {
  final Business business;

  const BusinessDetailPage({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: SuperAdminTheme.theme,
      child: Scaffold(
        backgroundColor: SuperAdminColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: SuperAdminColors.primaryDark,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          titleSpacing: 0,
          title: Text(
            business.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
        ),
        body: BusinessDetailPanel(business: business),
      ),
    );
  }
}

/// Embeddable detail body — compact modern layout for desktop split view.
class BusinessDetailPanel extends StatefulWidget {
  final Business business;
  final bool showInlineHeader;
  final VoidCallback? onRefreshList;

  const BusinessDetailPanel({
    super.key,
    required this.business,
    this.showInlineHeader = false,
    this.onRefreshList,
  });

  @override
  State<BusinessDetailPanel> createState() => _BusinessDetailPanelState();
}

class _BusinessDetailPanelState extends State<BusinessDetailPanel> {
  BusinessAccess? access;
  bool loadingAccess = true;
  bool saving = false;
  final TextEditingController maxCustomerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAccess();
  }

  @override
  void didUpdateWidget(covariant BusinessDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.business.id != widget.business.id) {
      setState(() {
        loadingAccess = true;
        access = null;
        maxCustomerController.clear();
      });
      _fetchAccess();
    }
  }

  Future<void> _fetchAccess() async {
    try {
      final result = await BusinessAccessService.fetchAccess(
        widget.business.id,
      );
      if (!mounted) return;
      setState(() {
        access = result;
        maxCustomerController.text = result.maxCustomers.toString();
        loadingAccess = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingAccess = false);
    }
  }

  @override
  void dispose() {
    maxCustomerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    final isActive = b.isActive;
    final wide = MediaQuery.sizeOf(context).width >= 1100;

    return Column(
      children: [
        if (widget.showInlineHeader) _inlineHeader(b, isActive),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  wide ? 24 : 16,
                  14,
                  wide ? 24 : 16,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!widget.showInlineHeader) ...[
                      _compactHero(b, isActive),
                      const SizedBox(height: 12),
                    ],
                    _infoGrid(b),
                    const SizedBox(height: 12),
                    _sectionTitle('Access control'),
                    const SizedBox(height: 8),
                    if (loadingAccess)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        ),
                      )
                    else if (access == null)
                      _emptyAccess()
                    else
                      _accessCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _inlineHeader(Business b, bool isActive) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: SuperAdminColors.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: isActive
                  ? SuperAdminColors.primary.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.storefront_rounded,
              size: 22,
              color: isActive ? SuperAdminColors.primary : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: SuperAdminColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${b.category}  ·  #${b.id}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: SuperAdminColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _statusChip(isActive),
          if (widget.onRefreshList != null)
            IconButton(
              tooltip: 'Refresh',
              onPressed: widget.onRefreshList,
              icon: const Icon(
                Icons.refresh_rounded,
                color: SuperAdminColors.primaryDark,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _compactHero(Business b, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SuperAdminColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: SuperAdminColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: SuperAdminColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  b.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: SuperAdminColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _statusChip(isActive),
        ],
      ),
    );
  }

  Widget _statusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? SuperAdminColors.success.withValues(alpha: 0.12)
            : SuperAdminColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? SuperAdminColors.success : SuperAdminColors.error,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade600,
        letterSpacing: 0.55,
      ),
    );
  }

  Widget _infoGrid(Business b) {
    final items = <({String label, String value, IconData icon, bool copy})>[
      (
        label: 'Business ID',
        value: b.id.toString(),
        icon: Icons.tag_rounded,
        copy: true,
      ),
      (
        label: 'Phone',
        value: b.phone.isEmpty ? '—' : b.phone,
        icon: Icons.phone_outlined,
        copy: b.phone.isNotEmpty,
      ),
      (
        label: 'Gov ID',
        value: b.doc?.isNotEmpty == true ? b.doc! : 'Not provided',
        icon: Icons.badge_outlined,
        copy: b.doc?.isNotEmpty == true,
      ),
      (
        label: 'Category',
        value: b.category,
        icon: Icons.category_outlined,
        copy: false,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SuperAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Business info'),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoCol = constraints.maxWidth >= 520;
              final cellW = twoCol
                  ? (constraints.maxWidth - 10) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: cellW,
                        child: _infoCell(
                          item.label,
                          item.value,
                          item.icon,
                          copy: item.copy,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 10),
          _infoCell(
            'Address',
            b.address.isEmpty ? '—' : b.address,
            Icons.location_on_outlined,
          ),
        ],
      ),
    );
  }

  Widget _infoCell(
    String label,
    String value,
    IconData icon, {
    bool copy = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: SuperAdminColors.surfaceMuted,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: SuperAdminColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SuperAdminColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (copy)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                CustomDialog.showSuccessSnack(context, 'Copied');
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyAccess() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SuperAdminColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Could not load access settings',
              style: TextStyle(color: SuperAdminColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => loadingAccess = true);
              _fetchAccess();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _accessCard() {
    final toggles = <({String title, bool value, IconData icon, ValueChanged<bool> onChanged})>[
      (
        title: 'Reminder',
        value: access!.reminderEnabled,
        icon: Icons.notifications_active_outlined,
        onChanged: (v) => setState(() => access!.reminderEnabled = v),
      ),
      (
        title: 'Income',
        value: access!.incomeEnabled,
        icon: Icons.trending_up_rounded,
        onChanged: (v) => setState(() => access!.incomeEnabled = v),
      ),
      (
        title: 'Expense',
        value: access!.expenseEnabled,
        icon: Icons.trending_down_rounded,
        onChanged: (v) => setState(() => access!.expenseEnabled = v),
      ),
      (
        title: 'Customers',
        value: access!.customersEnabled,
        icon: Icons.people_outline_rounded,
        onChanged: (v) => setState(() => access!.customersEnabled = v),
      ),
      (
        title: 'Support',
        value: access!.supportQueriesEnabled,
        icon: Icons.support_agent_rounded,
        onChanged: (v) => setState(() => access!.supportQueriesEnabled = v),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SuperAdminColors.border),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final twoCol = constraints.maxWidth >= 520;
              final cellW = twoCol
                  ? (constraints.maxWidth - 8) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: toggles
                    .map(
                      (t) => SizedBox(
                        width: cellW,
                        child: _compactSwitch(
                          t.title,
                          t.value,
                          t.onChanged,
                          t.icon,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: maxCustomerController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  cursorColor: SuperAdminColors.primary,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Max customers',
                    labelStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                    floatingLabelStyle: const TextStyle(
                      color: SuperAdminColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: SuperAdminColors.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide:
                          const BorderSide(color: SuperAdminColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: SuperAdminColors.primary,
                        width: 1.4,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    access!.maxCustomers = int.tryParse(val) ?? 0;
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 36,
                child: FilledButton(
                  onPressed: saving ? null : _saveAccess,
                  style: FilledButton.styleFrom(
                    backgroundColor: SuperAdminColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactSwitch(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Material(
      color: value
          ? SuperAdminColors.primary.withValues(alpha: 0.07)
          : SuperAdminColors.grey100,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: value
                  ? SuperAdminColors.primary.withValues(alpha: 0.28)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: SuperAdminColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(
                height: 28,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeThumbColor: Colors.white,
                  activeTrackColor: SuperAdminColors.primary,
                  inactiveThumbColor: SuperAdminColors.primaryDark,
                  trackOutlineColor: WidgetStatePropertyAll(
                    SuperAdminColors.primaryDark.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAccess() async {
    final text = maxCustomerController.text.trim();
    if (text.isEmpty) {
      CustomDialog.showErrorSnack(context, 'Please enter max customers');
      return;
    }


    final parsed = int.tryParse(text);
    if (parsed == null || parsed <= 0) {
      CustomDialog.showErrorSnack(
        context,
        'Enter a valid number greater than 0',
      );
      return;
    }

    access!.maxCustomers = parsed;
    setState(() => saving = true);
    try {
      await BusinessAccessService.updateAccess(access!);
      if (!mounted) return;
      CustomDialog.showSuccessSnack(context, 'Changes saved successfully');
    } catch (_) {
      if (!mounted) return;
      CustomDialog.showErrorSnack(context, 'Update failed. Try again.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
