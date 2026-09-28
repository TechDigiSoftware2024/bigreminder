import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/super_admin_models/business_list_model.dart';
import '../../../providers/business/business_provider.dart';
import '../../../services/business/business_service.dart';
import '../../../theme/super_admin_colors.dart';
import '../../../widgets/custom_dialog.dart';
import 'business_list_details.dart';

class BusinessListPage extends ConsumerStatefulWidget {
  const BusinessListPage({super.key});

  @override
  ConsumerState<BusinessListPage> createState() => _BusinessListPageState();
}

class _BusinessListPageState extends ConsumerState<BusinessListPage> {
  late Future<List<Business>> _future;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Business> _all = [];
  List<Business> _filtered = [];
  String _query = '';
  Business? _selected;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _future = BusinessService.fetchBusinesses();
    });

    try {
      final list = await _future;
      if (!mounted) return;
      setState(() {
        _all = list;
        _applyFilter();
        _loading = false;
        // Keep selection if still present; otherwise pick first on desktop.
        if (_selected != null) {
          final match = _all.where((b) => b.id == _selected!.id);
          _selected = match.isEmpty ? null : match.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      _filtered = List.of(_all);
      return;
    }
    _filtered = _all.where((b) {
      return b.name.toLowerCase().contains(_query) ||
          b.category.toLowerCase().contains(_query) ||
          b.phone.toLowerCase().contains(_query) ||
          b.id.toString().contains(_query);
    }).toList();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      setState(() {
        _query = value.trim().toLowerCase();
        _applyFilter();
      });
    });
  }

  void _select(Business business, {required bool isDesktop}) {
    if (isDesktop) {
      setState(() => _selected = business);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessDetailPage(business: business),
      ),
    );
  }

  Future<void> _confirmDelete(Business business) async {
    final ok = await CustomDialog.showConfirm(
      context: context,
      title: 'Delete Business',
      message: 'Delete "${business.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (!ok || !mounted) return;

    try {
      await ref
          .read(businessControllerProvider.notifier)
          .deleteBusinessById(business.id);
      if (!mounted) return;

      final err = ref.read(businessControllerProvider).error;
      if (err != null && err.isNotEmpty) {
        CustomDialog.showErrorSnack(context, 'Delete failed');
        return;
      }

      CustomDialog.showSuccessSnack(context, 'Business deleted');
      if (_selected?.id == business.id) {
        setState(() => _selected = null);
      }
      await _load();
    } catch (_) {
      if (!mounted) return;
      CustomDialog.showErrorSnack(context, 'Delete failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final canPop = Navigator.of(context).canPop();

    return Theme(
      data: SuperAdminTheme.theme,
      child: Scaffold(
        backgroundColor: const Color(0xffF5F7FB),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: SuperAdminColors.primaryDark,
          leading: canPop
              ? IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                )
              : null,
          title: const Text(
            'Businesses',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: Colors.white,
            ),
          ),
          // actions: [
          //   IconButton(
          //     tooltip: 'Refresh',
          //     onPressed: _loading ? null : _load,
          //     icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          //   ),
          //   const SizedBox(width: 4),
          // ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorView(error: _error!, onRetry: _load)
                : isDesktop
                    ? _desktopBody()
                    : _mobileBody(),
      ),
    );
  }

  Widget _desktopBody() {
    // Auto-select first item when nothing selected.
    if (_selected == null && _filtered.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _selected != null) return;
        setState(() => _selected = _filtered.first);
      });
    }

    return Row(
      children: [
        _BusinessListSidebar(
          businesses: _filtered,
          totalCount: _all.length,
          selectedId: _selected?.id,
          searchController: _searchController,
          query: _query,
          onSearchChanged: _onSearchChanged,
          onClearSearch: () {
            setState(() {
              _searchController.clear();
              _query = '';
              _applyFilter();
            });
          },
          onRefresh: _load,
          onSelect: (b) => _select(b, isDesktop: true),
          onDelete: _confirmDelete,
        ),
        Expanded(
          child: ColoredBox(
            color: SuperAdminColors.background,
            child: _selected == null
                ? _EmptyDetail()
                : BusinessDetailPanel(
                    key: ValueKey(_selected!.id),
                    business: _selected!,
                    showInlineHeader: true,
                    onRefreshList: _load,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _mobileBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _SearchField(
            controller: _searchController,
            query: _query,
            onChanged: _onSearchChanged,
            onClear: () {
              setState(() {
                _searchController.clear();
                _query = '';
                _applyFilter();
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_filtered.length} of ${_all.length} businesses',
              style: const TextStyle(
                color: SuperAdminColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No businesses found',
                    style: TextStyle(color: SuperAdminColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final b = _filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _BusinessListTile(
                        business: b,
                        selected: false,
                        compact: false,
                        onTap: () => _select(b, isDesktop: false),
                        onDelete: () => _confirmDelete(b),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEFT SIDEBAR (permanent on desktop)
// ─────────────────────────────────────────────────────────────────────────────

class _BusinessListSidebar extends StatelessWidget {
  final List<Business> businesses;
  final int totalCount;
  final int? selectedId;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;
  final ValueChanged<Business> onSelect;
  final ValueChanged<Business> onDelete;

  const _BusinessListSidebar({
    required this.businesses,
    required this.totalCount,
    required this.selectedId,
    required this.searchController,
    required this.query,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onRefresh,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: SuperAdminColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
            decoration: BoxDecoration(
              color: SuperAdminColors.primary.withValues(alpha: 0.04),
              border: const Border(
                bottom: BorderSide(color: SuperAdminColors.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: SuperAdminColors.primary,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Businesses',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: SuperAdminColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Select to view details',
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
                const SizedBox(height: 14),
                _SearchField(
                  controller: searchController,
                  query: query,
                  onChanged: onSearchChanged,
                  onClear: onClearSearch,
                ),
                const SizedBox(height: 10),
                Text(
                  '${businesses.length} of $totalCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SuperAdminColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: businesses.isEmpty
                ? Center(
                    child: Text(
                      query.isEmpty ? 'No businesses yet' : 'No matches',
                      style: const TextStyle(
                        color: SuperAdminColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                    itemCount: businesses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final b = businesses[index];
                      return _BusinessListTile(
                        business: b,
                        selected: b.id == selectedId,
                        compact: true,
                        onTap: () => onSelect(b),
                        onDelete: () => onDelete(b),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      cursorColor: SuperAdminColors.primary,
      decoration: InputDecoration(
        hintText: 'Search name, phone, id…',
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                onPressed: onClear,
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
          borderSide: const BorderSide(color: SuperAdminColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: SuperAdminColors.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _BusinessListTile extends StatelessWidget {
  final Business business;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BusinessListTile({
    required this.business,
    required this.selected,
    required this.compact,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = business.isActive;

    return Material(
      color: selected
          ? SuperAdminColors.primary.withValues(alpha: 0.08)
          : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? SuperAdminColors.primary.withValues(alpha: 0.45)
                  : SuperAdminColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: compact ? 38 : 42,
                width: compact ? 38 : 42,
                decoration: BoxDecoration(
                  color: isActive
                      ? SuperAdminColors.primary.withValues(alpha: 0.12)
                      : SuperAdminColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  size: 20,
                  color: isActive
                      ? SuperAdminColors.primaryDark
                      : SuperAdminColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 13.5 : 14,
                        color: SuperAdminColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${business.category} · #${business.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SuperAdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? SuperAdminColors.success.withValues(alpha: 0.12)
                          : SuperAdminColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Off',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? SuperAdminColors.success
                            : SuperAdminColors.error,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 28,
                    ),
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: SuperAdminColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              size: 34,
              color: SuperAdminColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a business',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: SuperAdminColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pick one from the list to view details\nand manage access controls.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SuperAdminColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
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
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: SuperAdminColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: SuperAdminColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
