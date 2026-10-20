import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bigreminder/widgets/custom_dialog.dart';
import 'package:bigreminder/widgets/custom_dropdown_textfield.dart';
import '../../../models/business_models/business_income_req_model.dart';
import '../../../utils/formatters.dart';
import '../../../providers/business/business_provider.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();

}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen>
{
  final amountCtrl = TextEditingController();
  final remarkCtrl = TextEditingController();
  final GlobalKey<_IncomeListPanelState> incomeListKey =
  GlobalKey<_IncomeListPanelState>();
  String? selectedSource;
  bool loading = false;

  @override
  void dispose() {
    amountCtrl.dispose();
    remarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        title: const Text(
          "Income",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ============================================================
      // MOBILE FAB
      // ============================================================
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
        backgroundColor: cs.primary,
        onPressed: _showMobileAddIncomeDialog,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      )
          : null,
      body: isDesktop
          ? _buildDesktopLayout()
          : _buildMobileLayout(),
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
          // ----------------------------------------------------------
          // LEFT PANEL - INCOME LIST
          // ----------------------------------------------------------

          Expanded(
            flex: 7,
            child: IncomeListPanel(
              key: incomeListKey,
              isDesktop: true,
            ),
          ),

          const SizedBox(width: 20),

          // ----------------------------------------------------------
          // RIGHT PANEL - ADD INCOME
          // ----------------------------------------------------------

          SizedBox(
            width: 380,
            child: IncomeAddForm(
              amountController: amountCtrl,
              remarkController: remarkCtrl,
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
        await incomeListKey.currentState?._loadIncomes(
          isRefresh: true,
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            IncomeListPanel(
              key: incomeListKey,
              isDesktop: false,
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
  void _showMobileAddIncomeDialog() {
    // Reset old form values before opening.
    amountCtrl.clear();
    remarkCtrl.clear();

    setState(() {
      selectedSource = null;
      loading = false;
    });

    showDialog(
      context: context,
      builder: (dialogContext) {
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
              child: IncomeAddForm(
                amountController: amountCtrl,
                remarkController: remarkCtrl,
                selectedSource: selectedSource,
                loading: loading,
                onSourceChanged: (value) {
                  setState(() {
                    selectedSource = value;
                  });
                },
                onSubmit: () async {
                  final success = await _submit();

                  if (!mounted) return;

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
  }
  // ================================================================
  // MOBILE SCROLL
  // ================================================================

  // ================================================================
  // SUBMIT
  // ================================================================

  Future<bool> _submit() async {
    if (loading) return false;

    try {
      setState(() {
        loading = true;
      });

      // ============================================================
      // AMOUNT
      // ============================================================

      final amount = double.tryParse(
        amountCtrl.text.trim(),
      );

      if (amount == null || amount <= 0) {
        _showSnack(
          "Enter a valid amount",
          isSuccess: false,
        );

        return false;
      }

      // ============================================================
      // SOURCE
      // ============================================================

      if (selectedSource == null ||
          selectedSource!.trim().isEmpty) {
        _showSnack(
          "Select income source",
          isSuccess: false,
        );

        return false;
      }

      // ============================================================
      // REMARK
      // ============================================================

      if (remarkCtrl.text.trim().isEmpty) {
        _showSnack(
          "Enter income remarks",
          isSuccess: false,
        );

        return false;
      }

      // ============================================================
      // BUSINESS ID
      // ============================================================

      final businessId = ref.read(
        businessIdProvider,
      );

      // ============================================================
      // REQUEST
      // ============================================================

      final req = BusinessIncomeRequest(
        amount: double.parse(
          amount.toStringAsFixed(2),
        ),
        source: selectedSource!
            .trim()
            .toLowerCase(),
        remark: remarkCtrl.text
            .trim()
            .toLowerCase(),
        businessId: businessId,
      );

      // ============================================================
      // API
      // ============================================================

      await ref
          .read(incomeServiceProvider)
          .addIncome(req);

      // ============================================================
      // SUCCESS
      // ============================================================

      amountCtrl.clear();
      remarkCtrl.clear();

      if (mounted) {
        setState(() {
          selectedSource = null;
        });

        CustomDialog.showSuccessSnack(
          context,
          "Income added successfully",
        );
      }

      return true;
    } catch (e) {
      if (mounted) {
        _showSnack(
          parseApiError(e),
          isSuccess: false,
        );
      }

      return false;
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }
  // ================================================================
  // ERROR PARSER
  // ================================================================

  String parseApiError(dynamic error) {
    final cleaned = error
        .toString()
        .replaceFirst(
      'Exception: ',
      '',
    );

    final match = RegExp(
      r'msg:\s*(.+?)\s*,\s*input:',
    ).firstMatch(cleaned);

    if (match != null) {
      return match
          .group(1)!
          .replaceAll("'", "")
          .trim();
    }

    return cleaned
        .replaceAll("'", "")
        .trim();
  }

  // ================================================================
  // SNACK
  // ================================================================

  void _showSnack(
      String msg, {
        required bool isSuccess,
      }) {
    if (!mounted) return;

    if (isSuccess) {
      CustomDialog.showSuccessSnack(
        context,
        msg,
      );
    } else {
      CustomDialog.showErrorSnack(
        context,
        msg,
      );
    }
  }

}

class IncomeAddForm extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController remarkController;

  final String? selectedSource;

  final bool loading;

  final ValueChanged<String?> onSourceChanged;

  final VoidCallback onSubmit;

  const IncomeAddForm({
    super.key,
    required this.amountController,
    required this.remarkController,
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
          // ==========================================================
          // HEADER
          // ==========================================================

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
                  "New Income",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Track your earnings easily",
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

          // ==========================================================
          // AMOUNT
          // ==========================================================

          IncomeInputField(
            controller: amountController,
            label: "Amount",
            hint: "Enter amount",
            icon: Icons.currency_rupee,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 10),

          // ==========================================================
          // SOURCE
          // ==========================================================

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

          // ==========================================================
          // REMARK
          // ==========================================================

          IncomeInputField(
            controller: remarkController,
            label: "Income Remarks",
            hint: "e.g. Fees / Product sold",
            icon: Icons.description_outlined,
            maxLines: 3,
          ),

          const SizedBox(height: 18),

          // ==========================================================
          // SUBMIT
          // ==========================================================

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                disabledBackgroundColor:
                cs.primary.withOpacity(.5),
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
                "Add Income",
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

class IncomeInputField extends StatelessWidget {
  final TextEditingController controller;

  final String label;
  final String hint;
  final IconData icon;

  final TextInputType keyboardType;

  final int maxLines;

  const IncomeInputField({
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
        // ==========================================================
        // LABEL
        // ==========================================================

        Text(
          label,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 5),

        // ==========================================================
        // TEXT FIELD
        // ==========================================================

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

class IncomeCard extends StatefulWidget {
  final dynamic income;
  final VoidCallback? onDelete;
  final bool deleting;

  const IncomeCard({
    super.key,
    required this.income,
    this.onDelete,
    this.deleting = false,
  });

  @override
  State<IncomeCard> createState() => _IncomeCardState();
}

class _IncomeCardState extends State<IncomeCard> {
  bool _expanded = false;

  String _shortTitle(String text) {
    final first = text.split(RegExp(r'\r?\n')).first.trim();
    if (first.isEmpty) return 'Income';
    if (first.length <= 28) return first;
    return '${first.substring(0, 28).trimRight()}…';
  }

  @override
  Widget build(BuildContext context) {
    final amount = AppFormatters.currency(widget.income.amount);
    final source = widget.income.source?.toString() ?? "Other";
    final remark = widget.income.remark?.toString().trim().isNotEmpty == true
        ? widget.income.remark.toString()
        : "No remarks";
    final title = _shortTitle(remark);
    final date = widget.income.recordedAt != null
        ? _formatDate(widget.income.recordedAt!)
        : "";
    final shortDate = widget.income.recordedAt != null
        ? _formatShortDate(widget.income.recordedAt!)
        : "";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _expanded
              ? const Color(0xFF22C55E).withValues(alpha: 0.35)
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 3.5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
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
                                  color: const Color(0xFF22C55E)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                  Icons.south_west_rounded,
                                  color: Color(0xFF16A34A),
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
                                  style: const TextStyle(
                                    color: Color(0xFF15803D),
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
                                _IncomeDetailChip(
                                  icon: Icons.payments_outlined,
                                  label: source.toUpperCase(),
                                  color: const Color(0xFF2563EB),
                                ),
                                if (date.isNotEmpty)
                                  _IncomeDetailChip(
                                    icon: Icons.schedule_rounded,
                                    label: date,
                                    color: const Color(0xFF64748B),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              remark,
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
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
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

class _IncomeDetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _IncomeDetailChip({
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

// ====================================================================
// SOURCE BADGE
// ====================================================================

class IncomeListPanel extends ConsumerStatefulWidget {
  final bool isDesktop;

  const IncomeListPanel({
    super.key,
    required this.isDesktop,
  });

  @override
  ConsumerState<IncomeListPanel> createState() =>
      _IncomeListPanelState();
}

class _IncomeListPanelState
    extends ConsumerState<IncomeListPanel> {
  bool loading = true;
  bool refreshing = false;
  List<dynamic> incomes = [];

  String search = '';
  int? deletingId;

  @override
  void initState() {
    super.initState();

    Future.microtask(
      _loadIncomes,
    );
  }

  // ================================================================
  // FETCH
  // ================================================================

  Future<void> _loadIncomes({
    bool isRefresh = false,
  }) async {
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

      final response = await ref
          .read(incomeServiceProvider)
          .getIncomes();

      if (!mounted) return;

      setState(() {
        incomes = response;
      });
    } catch (e) {
      debugPrint(
        "Income loading error: $e",
      );

      if (!mounted) return;

      if (!isRefresh) {
        setState(() {
          incomes = [];
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
  // ================================================================
  // FILTER
  // ================================================================

  List<dynamic> get filteredIncomes {
    final list = search.trim().isEmpty
        ? List<dynamic>.from(incomes)
        : incomes.where((income) {
            final query = search.trim().toLowerCase();
            final remark =
                income.remark?.toString().toLowerCase() ?? '';
            final source =
                income.source?.toString().toLowerCase() ?? '';
            return remark.contains(query) || source.contains(query);
          }).toList();

    list.sort((a, b) {
      final da = a.recordedAt as DateTime?;
      final db = b.recordedAt as DateTime?;
      if (da == null && db == null) {
        return (b.id as int).compareTo(a.id as int);
      }
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return list;
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ==========================================================
          // HEADER
          // ==========================================================

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      "All Incomes",
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 17,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "${incomes.length} income records",
                      style: TextStyle(
                        color:
                        Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isDesktop)
              IconButton(
                onPressed:
                loading
                    ? null
                    : _loadIncomes,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: cs.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ==========================================================
          // SEARCH
          // ==========================================================

          TextField(
            onChanged: (value) {
              setState(() {
                search = value;
              });
            },
            decoration:
            InputDecoration(
              hintText:
              "Search income...",
              hintStyle:
              TextStyle(
                fontSize: 13,
                color:
                Colors.grey.shade500,
              ),
              prefixIcon:
              Icon(
                Icons.search_rounded,
                color:
                Colors.grey.shade600,
                size: 20,
              ),
              filled: true,
              fillColor:
              const Color(
                0xffF7F8FA,
              ),
              contentPadding:
              const EdgeInsets
                  .symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
                borderSide:
                BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ==========================================================
          // LIST
          // ==========================================================

          if (widget.isDesktop)
            Expanded(
              child: _buildList(),
            )
          else
            _buildMobileList(),
        ],
      ),
    );
  }

  // ================================================================
  // DESKTOP LIST
  // ================================================================
  Widget _buildList() {
    if (loading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (filteredIncomes.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      physics:
      const AlwaysScrollableScrollPhysics(),
      itemCount:
      filteredIncomes.length,
      separatorBuilder:
          (_, __) =>
      const SizedBox(
        height: 6,
      ),
      itemBuilder:
          (context, index) {
        return IncomeCard(
          income: filteredIncomes[index],
          deleting: deletingId ==
              filteredIncomes[index].id,
          onDelete: () {
            _deleteIncome(
              filteredIncomes[index],
            );
          },
        );
      },
    );
  }
  Future<void> _deleteIncome(dynamic income) async {
    final confirmed = await _showDeleteConfirmation();

    if (confirmed != true) {
      return;
    }

    try {
      setState(() {
        deletingId = income.id;
      });

      await ref
          .read(incomeServiceProvider)
          .deleteIncome(income.id);

      if (!mounted) return;

      setState(() {
        incomes.removeWhere(
              (item) => item.id == income.id,
        );
      });

      CustomDialog.showSuccessSnack(
        context,
        "Income deleted successfully",
      );
    } catch (e) {
      if (!mounted) return;

      CustomDialog.showErrorSnack(
        context,
        e.toString().replaceFirst(
          "Exception: ",
          "",
        ),
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
    final primary =
        Theme.of(context).colorScheme.primary;

    final dialogWidth =
    MediaQuery.sizeOf(context).width >= 900
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
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
            ),

            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor:
                    primary.withOpacity(0.1),
                    child: Icon(
                      Icons.help,
                      color: primary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Delete Income?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Are you sure you want to delete this income record?",
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                              false,
                            );
                          },
                          child: const Text(
                            "Cancel",
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          },
                          child: const Text(
                            "Delete",
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
  // ================================================================
  // MOBILE LIST
  // ================================================================

  Widget _buildMobileList() {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (filteredIncomes.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: filteredIncomes.length,
      separatorBuilder: (_, __) {
        return const SizedBox(height: 6);
      },
      itemBuilder: (context, index) {
        final income = filteredIncomes[index];

        return IncomeCard(
          income: income,
          deleting: deletingId == income.id,
          onDelete: () {
            _deleteIncome(income);
          },
        );
      },
    );
  }
  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget _buildEmptyState() {
    final cs =
        Theme.of(context)
            .colorScheme;

    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 40,
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding:
              const EdgeInsets.all(
                16,
              ),
              decoration:
              BoxDecoration(
                color: cs.primary
                    .withOpacity(.08),
                shape:
                BoxShape.circle,
              ),
              child: Icon(
                Icons
                    .account_balance_wallet_outlined,
                size: 32,
                color:
                cs.primary,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              "No incomes found",
              style:
              TextStyle(
                fontWeight:
                FontWeight.w600,
                fontSize: 15,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              search.isNotEmpty
                  ? "Try a different search"
                  : "Your income records will appear here",
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                color:
                Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

