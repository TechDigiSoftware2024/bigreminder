import 'dart:async';

import 'package:bigreminder/theme/super_admin_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/super_admin_models/total_user_model.dart';
import '../../../models/super_admin_models/user_list_item_model.dart';
import '../../../services/super_admin/user_list_service.dart';
import '../../../widgets/custom_dialog.dart';

enum _UserFilter { all, admins, owners }

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserService _service = UserService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  TotalUserModel? data;
  bool isLoading = true;
  String? error;
  String _query = '';
  _UserFilter _filter = _UserFilter.all;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadUsers() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        throw Exception('Token not found');
      }

      final result = await _service.fetchUsers(token: token);
      if (!mounted) return;
      setState(() {
        data = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  List<UserListItemModel> get _filtered {
    final users = data?.users ?? [];
    return users.where((u) {
      final role = u.role.toLowerCase();
      switch (_filter) {
        case _UserFilter.admins:
          if (role != 'super_admin') return false;
          break;
        case _UserFilter.owners:
          if (role != 'business_owner') return false;
          break;
        case _UserFilter.all:
          break;
      }

      if (_query.isEmpty) return true;
      return u.name.toLowerCase().contains(_query) ||
          u.phone.toLowerCase().contains(_query) ||
          u.role.toLowerCase().contains(_query) ||
          u.id.toString().contains(_query);
    }).toList();
  }

  UserListItemModel? _resolveSelected(List<UserListItemModel> filtered) {
    if (filtered.isEmpty) return null;
    if (_selectedId != null) {
      for (final u in filtered) {
        if (u.id == _selectedId) return u;
      }
    }
    return filtered.first;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      setState(() => _query = value.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final canPop = Navigator.of(context).canPop();
    final showingMobileDetail = !isDesktop && _selectedId != null;

    return Theme(
      data: SuperAdminTheme.theme,
      child: Scaffold(
        backgroundColor: const Color(0xffF5F7FB),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: SuperAdminColors.primaryDark,
          leading: showingMobileDetail
              ? IconButton(
                  onPressed: () => setState(() => _selectedId = null),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                )
              : canPop
                  ? IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    )
                  : null,
          title: const Text(
            'Total Users',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: isLoading ? null : loadUsers,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? _ErrorView(error: error!, onRetry: loadUsers)
                : _buildBody(isDesktop),
      ),
    );
  }

  Widget _buildBody(bool isDesktop) {
    final filtered = _filtered;
    final selected = _resolveSelected(filtered);
    final total = data?.totalUsers ?? 0;
    final admins = data?.totalSuperAdmins ?? 0;
    final owners = data?.totalBusinessOwners ?? 0;

    if (!isDesktop) {
      if (_selectedId != null && selected != null) {
        return _UserDetailPane(
          total: total,
          admins: admins,
          owners: owners,
          selected: selected,
        );
      }

      return _UserListPane(
        users: filtered,
        totalCount: total,
        filter: _filter,
        selectedId: null,
        searchController: _searchController,
        query: _query,
        onSearchChanged: _onSearchChanged,
        onClearSearch: () {
          setState(() {
            _searchController.clear();
            _query = '';
          });
        },
        onFilter: (f) => setState(() {
          _filter = f;
          _selectedId = null;
        }),
        onSelect: (u) => setState(() => _selectedId = u.id),
        onRefresh: loadUsers,
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _UserListPane(
            users: filtered,
            totalCount: total,
            filter: _filter,
            selectedId: selected?.id,
            searchController: _searchController,
            query: _query,
            onSearchChanged: _onSearchChanged,
            onClearSearch: () {
              setState(() {
                _searchController.clear();
                _query = '';
              });
            },
            onFilter: (f) => setState(() {
              _filter = f;
              _selectedId = null;
            }),
            onSelect: (u) => setState(() => _selectedId = u.id),
            onRefresh: loadUsers,
          ),
        ),
        SizedBox(
          width: 420,
          child: _UserDetailPane(
            total: total,
            admins: admins,
            owners: owners,
            selected: selected,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEFT — wider user list
// ─────────────────────────────────────────────────────────────────────────────

class _UserListPane extends StatelessWidget {
  final List<UserListItemModel> users;
  final int totalCount;
  final _UserFilter filter;
  final int? selectedId;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<_UserFilter> onFilter;
  final ValueChanged<UserListItemModel> onSelect;
  final VoidCallback onRefresh;

  const _UserListPane({
    required this.users,
    required this.totalCount,
    required this.filter,
    required this.selectedId,
    required this.searchController,
    required this.query,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilter,
    required this.onSelect,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Users',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: SuperAdminColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${users.length}/$totalCount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SuperAdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  cursorColor: SuperAdminColors.primary,
                  decoration: InputDecoration(
                    hintText: 'Search name, phone, role…',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey.shade500,
                    ),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            onPressed: onClearSearch,
                            icon: const Icon(Icons.close_rounded, size: 18),
                          )
                        : null,
                    filled: true,
                    fillColor: SuperAdminColors.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: SuperAdminColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: SuperAdminColors.primary,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: filter == _UserFilter.all,
                      color: SuperAdminColors.primary,
                      onTap: () => onFilter(_UserFilter.all),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: 'Admins',
                      selected: filter == _UserFilter.admins,
                      color: SuperAdminColors.error,
                      onTap: () => onFilter(_UserFilter.admins),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: 'Owners',
                      selected: filter == _UserFilter.owners,
                      color: SuperAdminColors.primaryDark,
                      onTap: () => onFilter(_UserFilter.owners),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: SuperAdminColors.border),
          Expanded(
            child: users.isEmpty
                ? const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: SuperAdminColors.textSecondary),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => onRefresh(),
                    color: SuperAdminColors.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _UserListTile(
                          user: user,
                          selected: user.id == selectedId,
                          onTap: () => onSelect(user),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  final UserListItemModel user;
  final bool selected;
  final VoidCallback onTap;

  const _UserListTile({
    required this.user,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(user.role);

    return Material(
      color: selected
          ? roleColor.withValues(alpha: 0.08)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? roleColor.withValues(alpha: 0.45)
                  : SuperAdminColors.border,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: roleColor.withValues(alpha: 0.14),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isEmpty ? 'Unknown' : user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.phone.isEmpty ? '—' : user.phone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SuperAdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _RoleBadge(role: user.role),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT — header stats + user detail
// ─────────────────────────────────────────────────────────────────────────────

class _UserDetailPane extends StatelessWidget {
  final int total;
  final int admins;
  final int owners;
  final UserListItemModel? selected;

  const _UserDetailPane({
    required this.total,
    required this.admins,
    required this.owners,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xffF5F7FB),
        border: Border(
          left: BorderSide(color: SuperAdminColors.border),
        ),
      ),
      child: Column(
        children: [
          // Header lives on the right
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: SuperAdminColors.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    _HeaderIcon(),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User directory',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: SuperAdminColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Accounts & roles overview',
                            style: TextStyle(
                              fontSize: 12,
                              color: SuperAdminColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Total',
                        value: '$total',
                        color: SuperAdminColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStat(
                        label: 'Admins',
                        value: '$admins',
                        color: SuperAdminColors.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStat(
                        label: 'Owners',
                        value: '$owners',
                        color: SuperAdminColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: selected == null
                ? const Center(
                    child: Text(
                      'Select a user',
                      style: TextStyle(
                        color: SuperAdminColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : _SelectedUserDetail(user: selected!),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: SuperAdminColors.primary,
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.people_alt_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedUserDetail extends StatelessWidget {
  final UserListItemModel user;

  const _SelectedUserDetail({required this.user});

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(user.role);
    final initial =
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SuperAdminColors.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: roleColor.withValues(alpha: 0.14),
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name.isEmpty ? 'Unknown' : user.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: SuperAdminColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _RoleBadge(role: user.role),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SuperAdminColors.border),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.tag_rounded,
                  label: 'User ID',
                  value: '#${user.id}',
                  copyValue: '${user.id}',
                ),
                const Divider(height: 18, color: SuperAdminColors.border),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: user.phone.isEmpty ? '—' : user.phone,
                  copyValue: user.phone,
                ),
                const Divider(height: 18, color: SuperAdminColors.border),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: _prettyRole(user.role),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? copyValue;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.copyValue,
  });

  @override
  Widget build(BuildContext context) {
    final canCopy = copyValue != null && copyValue!.trim().isNotEmpty;

    return Row(
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: SuperAdminColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: SuperAdminColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: SuperAdminColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: SuperAdminColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (canCopy)
          IconButton(
            tooltip: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: copyValue!));
              CustomDialog.showSuccessSnack(context, 'Copied');
            },
            icon: Icon(
              Icons.copy_rounded,
              size: 16,
              color: Colors.grey.shade500,
            ),
          ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        _prettyRole(role),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? color.withValues(alpha: 0.12)
          : SuperAdminColors.surfaceMuted,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.45)
                  : SuperAdminColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? color : SuperAdminColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Failed to load users',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SuperAdminColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

Color _roleColor(String role) {
  switch (role.toLowerCase()) {
    case 'super_admin':
      return SuperAdminColors.error;
    case 'business_owner':
      return SuperAdminColors.primaryDark;
    default:
      return SuperAdminColors.primary;
  }
}

String _prettyRole(String role) {
  if (role.isEmpty) return 'Unknown';
  return role.replaceAll('_', ' ').toUpperCase();
}
