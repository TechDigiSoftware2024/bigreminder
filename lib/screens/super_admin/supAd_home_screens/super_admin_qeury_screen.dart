import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/business_models/query_model.dart';
import '../../../providers/business/business_provider.dart';
import '../../../providers/super_admin/super_admin_provider.dart';
import '../../../theme/super_admin_colors.dart';
import '../../../widgets/custom_dialog.dart';

enum _QueryFilter { all, open, resolved }

class SuperAdminQueryScreen extends ConsumerStatefulWidget {
  const SuperAdminQueryScreen({super.key});

  @override
  ConsumerState<SuperAdminQueryScreen> createState() =>
      _SuperAdminQueryScreenState();
}

class _SuperAdminQueryScreenState extends ConsumerState<SuperAdminQueryScreen> {
  _QueryFilter _filter = _QueryFilter.all;
  int? _selectedId;

  List<QueryModel> _applyFilter(List<QueryModel> queries) {
    return queries.where((q) {
      final s = q.status.toLowerCase();
      switch (_filter) {
        case _QueryFilter.open:
          return s == 'open';
        case _QueryFilter.resolved:
          return s == 'resolved';
        case _QueryFilter.all:
          return true;
      }
    }).toList();
  }

  QueryModel? _resolveSelected(List<QueryModel> filtered) {
    if (filtered.isEmpty) return null;
    if (_selectedId != null) {
      for (final q in filtered) {
        if (q.id == _selectedId) return q;
      }
    }
    return filtered.first;
  }

  @override
  Widget build(BuildContext context) {
    final queryState = ref.watch(adminQueryProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final canPop = Navigator.of(context).canPop();
    final showingMobileDetail =
        !isDesktop && _selectedId != null;

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
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
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
            'Support Center',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => ref.invalidate(adminQueryProvider),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: queryState.when(
          data: (queries) {
            final total = queries.length;
            final open = queries
                .where((e) => e.status.toLowerCase() == 'open')
                .length;
            final resolved = queries
                .where((e) => e.status.toLowerCase() == 'resolved')
                .length;
            final filtered = _applyFilter(queries);
            final selected = _resolveSelected(filtered);

            if (!isDesktop) {
              return _mobileBody(
                filtered: filtered,
                total: total,
                open: open,
                resolved: resolved,
                selected: selected,
              );
            }

            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _QueryListPane(
                    filtered: filtered,
                    totalCount: total,
                    filter: _filter,
                    selectedId: selected?.id,
                    onRefresh: () => ref.invalidate(adminQueryProvider),
                    onFilter: (f) => setState(() {
                      _filter = f;
                      _selectedId = null;
                    }),
                    onSelect: (q) => setState(() => _selectedId = q.id),
                    onDelete: (id) => _showDeleteDialog(context, id),
                  ),
                ),
                SizedBox(
                  width: 420,
                  child: _QueryDetailPane(
                    total: total,
                    open: open,
                    resolved: resolved,
                    selected: selected,
                    onReply: (q) => _showReplyDialog(context, ref, q),
                    onDelete: (id) => _showDeleteDialog(context, id),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: SuperAdminColors.primary),
          ),
          error: (e, _) => _ErrorView(
            error: e.toString(),
            onRetry: () => ref.invalidate(adminQueryProvider),
          ),
        ),
      ),
    );
  }

  Widget _mobileBody({
    required List<QueryModel> filtered,
    required int total,
    required int open,
    required int resolved,
    required QueryModel? selected,
  }) {
    final showingDetail = _selectedId != null && selected != null;

    if (showingDetail) {
      return _QueryDetailPane(
        total: total,
        open: open,
        resolved: resolved,
        selected: selected,
        onReply: (q) => _showReplyDialog(context, ref, q),
        onDelete: (id) => _showDeleteDialog(context, id),
      );
    }

    return _QueryListPane(
      filtered: filtered,
      totalCount: total,
      filter: _filter,
      selectedId: null,
      onRefresh: () => ref.invalidate(adminQueryProvider),
      onFilter: (f) => setState(() => _filter = f),
      onSelect: (q) => setState(() => _selectedId = q.id),
      onDelete: (id) => _showDeleteDialog(context, id),
    );
  }

  void _showReplyDialog(
    BuildContext context,
    WidgetRef ref,
    QueryModel query,
  ) {
    final replyController = TextEditingController(
      text: query.adminResponse.isNotEmpty ? query.adminResponse : '',
    );
    var selectedStatus =
        query.status.isNotEmpty ? query.status.toLowerCase() : 'open';
    if (selectedStatus != 'open' && selectedStatus != 'resolved') {
      selectedStatus = 'open';
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final replyState = ref.watch(replyToQueryProvider);

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return Dialog(
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: SizedBox(
                    width: CustomDialog.dialogWidth(
                      context,
                      desktop: CustomDialog.formWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Reply to query',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          Text(
                            'Business #${query.businessId}',
                            style: const TextStyle(
                              color: SuperAdminColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            key: ValueKey(selectedStatus),
                            initialValue: selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              filled: true,
                              fillColor: SuperAdminColors.surfaceMuted,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: SuperAdminColors.primary,
                                  width: 1.4,
                                ),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'open',
                                child: Text('Open'),
                              ),
                              DropdownMenuItem(
                                value: 'resolved',
                                child: Text('Resolved'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() => selectedStatus = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: replyController,
                            minLines: 4,
                            maxLines: 6,
                            cursorColor: SuperAdminColors.primary,
                            decoration: InputDecoration(
                              hintText: 'Write your response…',
                              filled: true,
                              fillColor: SuperAdminColors.surfaceMuted,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        SuperAdminColors.textPrimary,
                                    side: const BorderSide(
                                      color: SuperAdminColors.border,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: replyState.isLoading
                                      ? null
                                      : () async {
                                          final response =
                                              replyController.text.trim();
                                          if (response.isEmpty) {
                                            CustomDialog.showErrorSnack(
                                              context,
                                              'Please enter a response',
                                            );
                                            return;
                                          }
                                          try {
                                            await ref
                                                .read(queryServiceProvider)
                                                .updateQuery(
                                                  queryId: query.id,
                                                  status: selectedStatus,
                                                  adminResponse: response,
                                                  token:
                                                      ref.read(tokenProvider),
                                                );
                                            ref.invalidate(
                                              adminQueryProvider,
                                            );
                                            if (!context.mounted) return;
                                            Navigator.pop(dialogContext);
                                            CustomDialog.showSuccessSnack(
                                              context,
                                              'Query updated successfully',
                                            );
                                          } catch (e) {
                                            CustomDialog.showErrorSnack(
                                              context,
                                              e.toString(),
                                            );
                                          }
                                        },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: SuperAdminColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: replyState.isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Send reply'),
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
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEFT LIST (wider)
// ─────────────────────────────────────────────────────────────────────────────

const Color _kOpen = SuperAdminColors.warning;
const Color _kResolved = SuperAdminColors.success;

class _QueryListPane extends StatelessWidget {
  final List<QueryModel> filtered;
  final int totalCount;
  final _QueryFilter filter;
  final int? selectedId;
  final VoidCallback onRefresh;
  final ValueChanged<_QueryFilter> onFilter;
  final ValueChanged<QueryModel> onSelect;
  final ValueChanged<int> onDelete;

  const _QueryListPane({
    required this.filtered,
    required this.totalCount,
    required this.filter,
    required this.selectedId,
    required this.onRefresh,
    required this.onFilter,
    required this.onSelect,
    required this.onDelete,
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
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Queries',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: SuperAdminColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${filtered.length}/$totalCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SuperAdminColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: filter == _QueryFilter.all,
                  color: SuperAdminColors.primary,
                  onTap: () => onFilter(_QueryFilter.all),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Open',
                  selected: filter == _QueryFilter.open,
                  color: _kOpen,
                  onTap: () => onFilter(_QueryFilter.open),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Resolved',
                  selected: filter == _QueryFilter.resolved,
                  color: _kResolved,
                  onTap: () => onFilter(_QueryFilter.resolved),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: SuperAdminColors.border),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No queries found',
                      style: TextStyle(color: SuperAdminColors.textSecondary),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => onRefresh(),
                    color: SuperAdminColors.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final q = filtered[index];
                        return _QueryListTile(
                          query: q,
                          selected: q.id == selectedId,
                          onTap: () => onSelect(q),
                          onDelete: () => onDelete(q.id),
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

class _QueryListTile extends StatelessWidget {
  final QueryModel query;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _QueryListTile({
    required this.query,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = query.status.toLowerCase() == 'open';
    final statusColor = isOpen ? _kOpen : _kResolved;

    return Material(
      color: selected
          ? statusColor.withValues(alpha: 0.08)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? statusColor.withValues(alpha: 0.55)
                  : SuperAdminColors.border,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isOpen
                      ? Icons.schedule_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 17,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Business #${query.businessId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        _StatusBadge(
                          label: isOpen ? 'Open' : 'Resolved',
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      query.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: SuperAdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT DETAIL (medium)
// ─────────────────────────────────────────────────────────────────────────────

class _QueryDetailPane extends StatelessWidget {
  final int total;
  final int open;
  final int resolved;
  final QueryModel? selected;
  final ValueChanged<QueryModel> onReply;
  final ValueChanged<int> onDelete;

  const _QueryDetailPane({
    required this.total,
    required this.open,
    required this.resolved,
    required this.selected,
    required this.onReply,
    required this.onDelete,
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: SuperAdminColors.border),
              ),
            ),
            child: Row(
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
                    label: 'Open',
                    value: '$open',
                    color: _kOpen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: 'Resolved',
                    value: '$resolved',
                    color: _kResolved,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: selected == null
                ? const Center(
                    child: Text(
                      'Select a query',
                      style: TextStyle(
                        color: SuperAdminColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : _SelectedQueryDetail(
                    query: selected!,
                    onReply: () => onReply(selected!),
                    onDelete: () => onDelete(selected!.id),
                  ),
          ),
        ],
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

class _SelectedQueryDetail extends StatelessWidget {
  final QueryModel query;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  const _SelectedQueryDetail({
    required this.query,
    required this.onReply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = query.status.toLowerCase() == 'open';
    final statusColor = isOpen ? _kOpen : _kResolved;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SuperAdminColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Business #${query.businessId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _StatusBadge(
                      label: isOpen ? 'Open' : 'Resolved',
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'MESSAGE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: SuperAdminColors.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  query.message,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: SuperAdminColors.textPrimary,
                  ),
                ),
                if (query.adminResponse.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: SuperAdminColors.border),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: SuperAdminColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: const Border(
                        left: BorderSide(
                          color: SuperAdminColors.primary,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ADMIN REPLY',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: SuperAdminColors.primary,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          query.adminResponse,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: SuperAdminColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SuperAdminColors.textPrimary,
                    side: const BorderSide(color: SuperAdminColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: onReply,
                  icon: Icon(
                    isOpen ? Icons.reply_rounded : Icons.edit_outlined,
                    size: 18,
                  ),
                  label: Text(isOpen ? 'Reply' : 'Update'),
                  style: FilledButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: isOpen ? Colors.white : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
      color: selected ? color.withValues(alpha: 0.12) : SuperAdminColors.surfaceMuted,
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
              'Failed to load queries',
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
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

void _showDeleteDialog(BuildContext context, int queryId) {
  CustomDialog.showConfirmDialog(
    context: context,
    title: 'Delete Query',
    message:
        'Are you sure you want to delete this query? This action cannot be undone.',
    confirmLabel: 'Delete',
    isDestructive: true,
    icon: Icons.delete_outline_rounded,
    onConfirm: () async {
      try {
        final container = ProviderScope.containerOf(context);
        final token = container.read(tokenProvider);

        await container
            .read(queryServiceProvider)
            .deleteQuery(queryId: queryId, token: token);

        container.invalidate(adminQueryProvider);

        if (!context.mounted) return;
        CustomDialog.showSuccessSnack(context, 'Query deleted successfully');
      } catch (e) {
        if (!context.mounted) return;
        CustomDialog.showErrorSnack(context, e.toString());
      }
    },
  );
}
