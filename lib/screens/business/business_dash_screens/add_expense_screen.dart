import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bigreminder/widgets/custom_dialog.dart';
import 'package:bigreminder/widgets/custom_dropdown_textfield.dart';
import '../../../models/business_models/business_create_expense_model.dart';
import '../../../utils/formatters.dart';
import '../../../providers/business/business_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final amountCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final GlobalKey<_ExpenseListPanelState> expenseListKey =
      GlobalKey<_ExpenseListPanelState>();

  String? selectedSource;
  bool loading = false;
  bool _didChange = false;

  @override
  void dispose() {
    amountCtrl.dispose();
    categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_didChange);
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF5F7FB),
        appBar: AppBar(
          backgroundColor: cs.primary,
          elevation: 0,
          title: const Text(
            "Expense",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        floatingActionButton: !isDesktop
            ? FloatingActionButton(
                backgroundColor: cs.primary,
                onPressed: _showMobileAddExpenseDialog,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              )
            : null,
        body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  // ================================================================
  // DESKTOP
  // ================================================================

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: ExpenseListPanel(
              key: expenseListKey,
              isDesktop: true,
              onChanged: () => _didChange = true,
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 380,
            child: ExpenseAddForm(
              amountController: amountCtrl,
              categoryController: categoryCtrl,
              selectedSource: selectedSource,
              loading: loading,
              onSourceChanged: (value) {
                setState(() {
                  selectedSource = value;
                });
              },
              onSubmit: _submit,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // MOBILE
  // ================================================================

  Widget _buildMobileLayout() {
    return RefreshIndicator(
      onRefresh: () async {
        await expenseListKey.currentState?._loadExpenses(isRefresh: true);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            ExpenseListPanel(
              key: expenseListKey,
              isDesktop: false,
              onChanged: () => _didChange = true,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showMobileAddExpenseDialog() {
    amountCtrl.clear();
    categoryCtrl.clear();

    setState(() {
      selectedSource = null;
      loading = false;
    });

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ExpenseAddForm(
                    amountController: amountCtrl,
                    categoryController: categoryCtrl,
                    selectedSource: selectedSource,
                    loading: loading,
                    onSourceChanged: (value) {
                      setState(() {
                        selectedSource = value;
                      });
                      setDialogState(() {});
                    },
                    onSubmit: () async {
                      final success = await _submit(
                        onLoadingChanged: () => setDialogState(() {}),
                      );

                      if (!dialogContext.mounted) return;

                      if (success) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================================================================
  // SUBMIT
  // ================================================================

  Future<bool> _submit({VoidCallback? onLoadingChanged}) async {
    if (loading) return false;

    try {
      setState(() {
        loading = true;
      });
      onLoadingChanged?.call();

      final amount = double.tryParse(amountCtrl.text.trim());

      if (amount == null || amount <= 0) {
        _showSnack("Enter a valid amount", isSuccess: false);
        return false;
      }

      if (selectedSource == null || selectedSource!.trim().isEmpty) {
        _showSnack("Select expense source", isSuccess: false);
        return false;
      }

      if (categoryCtrl.text.trim().isEmpty) {
        _showSnack("Enter reason for expense", isSuccess: false);
        return false;
      }

      final businessId = ref.read(businessIdProvider);

      final expense = BusinessExpenseModel(
        amount: amount.toInt(),
        category: categoryCtrl.text.trim().toLowerCase(),
        source: selectedSource!.trim().toLowerCase(),
        businessId: businessId,
      );

      await ref.read(expenseServiceProvider).addExpense(expense);

      amountCtrl.clear();
      categoryCtrl.clear();

      if (mounted) {
        setState(() {
          selectedSource = null;
          _didChange = true;
        });

        CustomDialog.showSuccessSnack(
          context,
          "Expense added successfully",
        );
      }

      await expenseListKey.currentState?._loadExpenses(isRefresh: true);

      return true;
    } catch (e) {
      if (mounted) {
        _showSnack(parseApiError(e), isSuccess: false);
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
        onLoadingChanged?.call();
      }
    }
  }

  String parseApiError(dynamic error) {
    final cleaned = error.toString().replaceFirst('Exception: ', '');

    final match = RegExp(r'msg:\s*(.+?)\s*,\s*input:').firstMatch(cleaned);

    if (match != null) {
      return match.group(1)!.replaceAll("'", "").trim();
    }

    return cleaned.replaceAll("'", "").trim();
  }

  void _showSnack(String msg, {required bool isSuccess}) {
    if (!mounted) return;

    if (isSuccess) {
      CustomDialog.showSuccessSnack(context, msg);
    } else {
      CustomDialog.showErrorSnack(context, msg);
    }
  }
}

class ExpenseAddForm extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController categoryController;
  final String? selectedSource;
  final bool loading;
  final ValueChanged<String?> onSourceChanged;
  final VoidCallback onSubmit;

  const ExpenseAddForm({
    super.key,
    required this.amountController,
    required this.categoryController,
    required this.selectedSource,
    required this.loading,
    required this.onSourceChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "New Expense",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Track your spending smartly",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ExpenseInputField(
            controller: amountController,
            label: "Amount",
            hint: "Enter amount",
            icon: Icons.currency_rupee,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          CustomDropdownTextField(
            label: "Source",
            hint: "e.g. Cash / UPI",
            icon: Icons.account_balance_wallet,
            value: selectedSource,
            items: const [
              "Cash",
              "UPI",
              "Card",
              "Other",
            ],
            onChanged: onSourceChanged,
          ),
          const SizedBox(height: 10),
          ExpenseInputField(
            controller: categoryController,
            label: "Reason for Expense",
            hint: "e.g. Rent / Water Bill",
            icon: Icons.description_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                disabledBackgroundColor: cs.primary.withOpacity(.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      height: 19,
                      width: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Add Expense",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpenseInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;

  const ExpenseInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              icon,
              color: cs.primary,
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xffFAFBFD),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: cs.onSurface.withOpacity(.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: cs.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ExpenseCard extends StatefulWidget {
  final BusinessExpense expense;
  final VoidCallback? onDelete;
  final bool deleting;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onDelete,
    this.deleting = false,
  });

  @override
  State<ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<ExpenseCard> {
  bool _expanded = false;

  String _shortTitle(String text) {
    final first = text.split(RegExp(r'\r?\n')).first.trim();
    if (first.isEmpty) return 'Expense';
    if (first.length <= 28) return first;
    return '${first.substring(0, 28).trimRight()}…';
  }

  @override
  Widget build(BuildContext context) {
    final amount = AppFormatters.currency(widget.expense.amount);
    final source =
        widget.expense.source.isNotEmpty ? widget.expense.source : "Other";
    final category = widget.expense.category.isNotEmpty
        ? widget.expense.category
        : "No reason";
    final title = _shortTitle(category);
    final date = widget.expense.recordedAt != null
        ? _formatDate(widget.expense.recordedAt!)
        : "";
    final shortDate = widget.expense.recordedAt != null
        ? _formatShortDate(widget.expense.recordedAt!)
        : "";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _expanded
              ? const Color(0xFFEF4444).withValues(alpha: 0.35)
              : const Color(0xFFE8EDF2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _expanded ? 0.06 : 0.03),
            blurRadius: _expanded ? 10 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3.5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 34,
                              width: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.north_east_rounded,
                                color: Color(0xFFDC2626),
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    shortDate.isNotEmpty
                                        ? '$source · $shortDate'
                                        : source,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade500,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 140),
                              child: Text(
                                amount,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            AnimatedRotation(
                              turns: _expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 22,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        if (_expanded) ...[
                          const SizedBox(height: 12),
                          Divider(height: 1, color: Colors.grey.shade200),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _ExpenseDetailChip(
                                icon: Icons.payments_outlined,
                                label: source.toUpperCase(),
                                color: const Color(0xFF2563EB),
                              ),
                              if (date.isNotEmpty)
                                _ExpenseDetailChip(
                                  icon: Icons.schedule_rounded,
                                  label: date,
                                  color: const Color(0xFF64748B),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed:
                                  widget.deleting ? null : widget.onDelete,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red.shade600,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: widget.deleting
                                  ? SizedBox(
                                      height: 14,
                                      width: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.red.shade600,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                    ),
                              label: Text(
                                widget.deleting ? 'Deleting…' : 'Delete',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    final local = date.toLocal();
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    return "${local.day} ${months[local.month - 1]}";
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? "PM" : "AM";
    return "$day ${months[local.month - 1]} ${local.year} · "
        "${hour.toString().padLeft(2, '0')}:$minute $period";
  }
}

class _ExpenseDetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ExpenseDetailChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ExpenseListPanel extends ConsumerStatefulWidget {
  final bool isDesktop;
  final VoidCallback? onChanged;

  const ExpenseListPanel({
    super.key,
    required this.isDesktop,
    this.onChanged,
  });

  @override
  ConsumerState<ExpenseListPanel> createState() => _ExpenseListPanelState();
}

class _ExpenseListPanelState extends ConsumerState<ExpenseListPanel> {
  bool loading = true;
  bool refreshing = false;
  List<BusinessExpense> expenses = [];
  String search = '';
  int? deletingId;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadExpenses);
  }

  Future<void> _loadExpenses({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        setState(() {
          refreshing = true;
        });
      } else {
        setState(() {
          loading = true;
        });
      }

      final response = await ref.read(expenseServiceProvider).getExpenses();

      if (!mounted) return;

      setState(() {
        expenses = response;
      });
    } catch (e) {
      debugPrint("Expense loading error: $e");

      if (!mounted) return;

      if (!isRefresh) {
        setState(() {
          expenses = [];
        });
      }
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
        refreshing = false;
      });
    }
  }

  List<BusinessExpense> get filteredExpenses {
    final list = search.trim().isEmpty
        ? List<BusinessExpense>.from(expenses)
        : expenses.where((expense) {
            final query = search.trim().toLowerCase();
            final category = expense.category.toLowerCase();
            final source = expense.source.toLowerCase();
            return category.contains(query) || source.contains(query);
          }).toList();

    list.sort((a, b) {
      final da = a.recordedAt;
      final db = b.recordedAt;
      if (da == null && db == null) return b.id.compareTo(a.id);
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "All Expenses",
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "${expenses.length} expense records",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isDesktop)
                IconButton(
                  onPressed: loading ? null : _loadExpenses,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: cs.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) {
              setState(() {
                search = value;
              });
            },
            decoration: InputDecoration(
              hintText: "Search expense...",
              hintStyle: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.grey.shade600,
                size: 20,
              ),
              filled: true,
              fillColor: const Color(0xffF7F8FA),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (widget.isDesktop)
            Expanded(child: _buildList())
          else
            _buildMobileList(),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredExpenses.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: filteredExpenses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final expense = filteredExpenses[index];
        return ExpenseCard(
          expense: expense,
          deleting: deletingId == expense.id,
          onDelete: () => _deleteExpense(expense),
        );
      },
    );
  }

  Widget _buildMobileList() {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (filteredExpenses.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: filteredExpenses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final expense = filteredExpenses[index];
        return ExpenseCard(
          expense: expense,
          deleting: deletingId == expense.id,
          onDelete: () => _deleteExpense(expense),
        );
      },
    );
  }

  Future<void> _deleteExpense(BusinessExpense expense) async {
    final confirmed = await _showDeleteConfirmation();

    if (confirmed != true) return;

    try {
      setState(() {
        deletingId = expense.id;
      });

      await ref.read(expenseServiceProvider).deleteExpense(expense.id);

      if (!mounted) return;

      setState(() {
        expenses.removeWhere((item) => item.id == expense.id);
      });

      widget.onChanged?.call();

      CustomDialog.showSuccessSnack(
        context,
        "Expense deleted successfully",
      );
    } catch (e) {
      if (!mounted) return;

      CustomDialog.showErrorSnack(
        context,
        e.toString().replaceFirst("Exception: ", ""),
      );
    } finally {
      if (mounted) {
        setState(() {
          deletingId = null;
        });
      }
    }
  }

  Future<bool?> _showDeleteConfirmation() {
    final primary = Theme.of(context).colorScheme.primary;
    final dialogWidth = MediaQuery.sizeOf(context).width >= 900
        ? 420.0
        : MediaQuery.sizeOf(context).width - 32;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: primary.withOpacity(0.1),
                    child: Icon(Icons.help, color: primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Delete Expense?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Are you sure you want to delete this expense record?",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext, false);
                          },
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext, true);
                          },
                          child: const Text("Delete"),
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

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 32,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "No expenses found",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              search.isNotEmpty
                  ? "Try a different search"
                  : "Your expense records will appear here",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
