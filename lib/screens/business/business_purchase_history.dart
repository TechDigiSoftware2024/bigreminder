import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/business_models/business_purchase_list_model.dart';
import '../../providers/business/business_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_dialog.dart';

class BusinessPurchaseHistoryScreen extends ConsumerStatefulWidget {
  const BusinessPurchaseHistoryScreen({super.key});

  @override
  ConsumerState<BusinessPurchaseHistoryScreen> createState() =>
      _BusinessPurchaseHistoryScreenState();
}

class _BusinessPurchaseHistoryScreenState
    extends ConsumerState<BusinessPurchaseHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();

  String _searchQuery = '';
  PurchaseModel? _selectedBill;
  bool _showPaymentField = false;
  bool _isPaying = false;
  bool _isRefreshing = false;
  String? _selectedPaymentMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ignore return; initial load is already watched in build.
      ref.invalidate(purchasesProvider(null));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  bool _matchesSearch(PurchaseModel purchase) {
    if (_searchQuery.trim().isEmpty) return true;

    final query = _searchQuery.trim().toLowerCase();
    final fields = <String>[
      purchase.customerName,
      purchase.customerPhone,
      purchase.billNumber,
      purchase.barcode,
      purchase.totalAmount,
      purchase.paid,
      purchase.pending,
      purchase.billDate,
      purchase.status,
      purchase.paymentMode,
    ];

    return fields.any((field) => field.toLowerCase().contains(query));
  }

  double _pendingOf(PurchaseModel purchase) {
    return double.tryParse(purchase.pending) ?? 0;
  }

  bool _isPaid(PurchaseModel purchase) => _pendingOf(purchase) <= 0;

  void _selectBill(PurchaseModel purchase) {
    setState(() {
      _selectedBill = purchase;
      _showPaymentField = false;
      _isPaying = false;
      _selectedPaymentMode = null;
      _paymentController.clear();
    });
  }

  Future<void> _refreshList() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _searchQuery = '';
      _searchController.clear();
    });

    try {
      final list = await ref.refresh(purchasesProvider(null).future);
      if (!mounted) return;

      // Re-sync selected bill with fresh list data
      if (_selectedBill != null) {
        PurchaseModel? updated;
        for (final p in list) {
          if (p.billId == _selectedBill!.billId) {
            updated = p;
            break;
          }
        }
        setState(() {
          _selectedBill = updated;
          if (updated == null || _isPaid(updated)) {
            _showPaymentField = false;
            _paymentController.clear();
          }
        });
      } else {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      CustomDialog.showErrorSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _submitPayment(PurchaseModel purchase) async {
    final pending = _pendingOf(purchase);
    final amount = double.tryParse(_paymentController.text.trim()) ?? 0;

    if (amount <= 0) {
      CustomDialog.showErrorSnack(context, "Please enter a valid amount");
      return;
    }

    if (amount > pending) {
      CustomDialog.showErrorSnack(
        context,
        "Amount can't exceed ₹${pending.formatPrice}",
      );
      return;
    }

    if (_selectedPaymentMode == null ||
        _selectedPaymentMode!.trim().isEmpty) {
      CustomDialog.showErrorSnack(context, "Select payment mode");
      return;
    }

    setState(() => _isPaying = true);

    try {
      final result =
          await ref.read(receivePaymentProvider.notifier).receivePayment(
                amount: amount,
                billId: purchase.billId,
                paymentMode: _selectedPaymentMode!,
              );

      if (!mounted) return;

      // Prefer refreshed list row; fall back to payment response amounts
      final list = ref.read(purchasesProvider(null)).asData?.value ?? [];
      PurchaseModel updated = purchase;
      var found = false;
      for (final p in list) {
        if (p.billId == purchase.billId) {
          updated = p;
          found = true;
          break;
        }
      }

      if (!found) {
        updated = PurchaseModel(
          billId: purchase.billId,
          businessId: purchase.businessId,
          billNumber: result.billNumber.isNotEmpty
              ? result.billNumber
              : purchase.billNumber,
          barcode: purchase.barcode,
          customerId: purchase.customerId,
          customerName: purchase.customerName,
          customerPhone: purchase.customerPhone,
          subtotal: purchase.subtotal,
          totalGst: purchase.totalGst,
          totalAmount: purchase.totalAmount,
          paid: result.paid,
          pending: result.pending,
          status: result.status.isNotEmpty ? result.status : purchase.status,
          paymentMode: _selectedPaymentMode ?? purchase.paymentMode,
          notes: purchase.notes,
          billDate: purchase.billDate,
          createdAt: purchase.createdAt,
          items: purchase.items,
        );
      }

      setState(() {
        _selectedBill = updated;
        _showPaymentField = false;
        _isPaying = false;
        _selectedPaymentMode = null;
        _paymentController.clear();
      });

      CustomDialog.showSuccessSnack(
        context,
        "Payment of ₹${amount.formatPrice} received",
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPaying = false);
      CustomDialog.showErrorSnack(
        context,
        e.toString().replaceFirst("Exception: ", ""),
      );
    }
  }

  void _openMobileDetail(PurchaseModel purchase) {
    _selectBill(purchase);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              minChildSize: 0.55,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xffF5F7FB),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                          child: BillDetailPanel(
                            purchase: _selectedBill ?? purchase,
                            paymentController: _paymentController,
                            showPaymentField: _showPaymentField,
                            isPaying: _isPaying,
                            selectedPaymentMode: _selectedPaymentMode,
                            onPaymentModeChanged: (value) {
                              setState(() => _selectedPaymentMode = value);
                              setSheetState(() {});
                            },
                            onTogglePayment: () {
                              setState(() {
                                _showPaymentField = !_showPaymentField;
                                if (!_showPaymentField) {
                                  _paymentController.clear();
                                  _selectedPaymentMode = null;
                                }
                              });
                              setSheetState(() {});
                            },
                            onCancelPayment: () {
                              setState(() {
                                _showPaymentField = false;
                                _paymentController.clear();
                                _selectedPaymentMode = null;
                              });
                              setSheetState(() {});
                            },
                            onSubmitPayment: () async {
                              await _submitPayment(_selectedBill ?? purchase);
                              setSheetState(() {});
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _showPaymentField = false;
          _selectedPaymentMode = null;
          _paymentController.clear();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final purchasesAsync = ref.watch(purchasesProvider(null));

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        title: const Text(
          'Bill History',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 17,
          ),
        ),
      ),
      body: purchasesAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: _refreshList,
        ),
        data: (purchases) {
          final filtered = purchases.where(_matchesSearch).toList();

          // Keep selected bill in sync with refreshed list values.
          if (_selectedBill != null) {
            final match = filtered
                .where((p) => p.billId == _selectedBill!.billId)
                .toList();
            if (match.isNotEmpty &&
                (match.first.paid != _selectedBill!.paid ||
                    match.first.pending != _selectedBill!.pending ||
                    match.first.totalAmount != _selectedBill!.totalAmount)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _selectedBill = match.first);
              });
            }
          }

          if (purchases.isEmpty) {
            return const _EmptyBills();
          }

          if (isDesktop) {
            return _buildDesktop(filtered, cs);
          }
          return _buildMobile(filtered, cs);
        },
      ),
    );
  }

  Widget _buildDesktop(List<PurchaseModel> filtered, ColorScheme cs) {
    // Auto-select first bill if none selected
    if (_selectedBill == null && filtered.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedBill == null) {
          _selectBill(filtered.first);
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 6,
            child: BillListPanel(
              searchController: _searchController,
              searchQuery: _searchQuery,
              bills: filtered,
              selectedBillId: _selectedBill?.billId,
              onSearchChanged: (value) {
                setState(() => _searchQuery = value);
              },
              onClearSearch: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              onRefresh: _refreshList,
              isRefreshing: _isRefreshing,
              onSelect: _selectBill,
              isDesktop: true,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 420,
            child: _selectedBill == null
                ? const _NoSelectionPanel()
                : SingleChildScrollView(
                    child: BillDetailPanel(
                      purchase: _selectedBill!,
                      paymentController: _paymentController,
                      showPaymentField: _showPaymentField,
                      isPaying: _isPaying,
                      selectedPaymentMode: _selectedPaymentMode,
                      onPaymentModeChanged: (value) {
                        setState(() => _selectedPaymentMode = value);
                      },
                      onTogglePayment: () {
                        setState(() {
                          _showPaymentField = !_showPaymentField;
                          if (!_showPaymentField) {
                            _paymentController.clear();
                            _selectedPaymentMode = null;
                          }
                        });
                      },
                      onCancelPayment: () {
                        setState(() {
                          _showPaymentField = false;
                          _paymentController.clear();
                          _selectedPaymentMode = null;
                        });
                      },
                      onSubmitPayment: () => _submitPayment(_selectedBill!),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(List<PurchaseModel> filtered, ColorScheme cs) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      child: BillListPanel(
        searchController: _searchController,
        searchQuery: _searchQuery,
        bills: filtered,
        selectedBillId: null,
        onSearchChanged: (value) {
          setState(() => _searchQuery = value);
        },
        onClearSearch: () {
          _searchController.clear();
          setState(() => _searchQuery = '');
        },
        onRefresh: _refreshList,
        isRefreshing: _isRefreshing,
        onSelect: _openMobileDetail,
        isDesktop: false,
      ),
    );
  }
}

// ============================================================================
// LIST PANEL
// ============================================================================

class BillListPanel extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final List<PurchaseModel> bills;
  final int? selectedBillId;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final Future<void> Function() onRefresh;
  final bool isRefreshing;
  final ValueChanged<PurchaseModel> onSelect;
  final bool isDesktop;

  const BillListPanel({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.bills,
    required this.selectedBillId,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onRefresh,
    required this.isRefreshing,
    required this.onSelect,
    required this.isDesktop,
  });

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
                      'All Bills',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${bills.length} invoice records',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: isRefreshing
                    ? null
                    : () {
                        onRefresh();
                      },
                icon: isRefreshing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: cs.primary,
                        ),
                      )
                    : Icon(Icons.refresh_rounded, color: cs.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search bill, customer, amount...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.grey.shade600,
                size: 20,
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: onClearSearch,
                    )
                  : null,
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
          if (bills.isEmpty)
            const _EmptySearch()
          else if (isDesktop)
            Expanded(
              child: ListView.separated(
                itemCount: bills.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  return BillListCard(
                    purchase: bill,
                    selected: selectedBillId == bill.billId,
                    onTap: () => onSelect(bill),
                  );
                },
              ),
            )
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: bills.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final bill = bills[index];
                return BillListCard(
                  purchase: bill,
                  selected: false,
                  onTap: () => onSelect(bill),
                );
              },
            ),
        ],
      ),
    );
  }
}

class BillListCard extends StatelessWidget {
  final PurchaseModel purchase;
  final bool selected;
  final VoidCallback onTap;

  const BillListCard({
    super.key,
    required this.purchase,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pending = double.tryParse(purchase.pending) ?? 0;
    final isPaid = pending <= 0;
    final total = double.tryParse(purchase.totalAmount) ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withOpacity(.06)
                : const Color(0xffFAFBFD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? cs.primary.withOpacity(.35) : Colors.grey.shade200,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.primary.withOpacity(.12),
                child: Text(
                  purchase.customerName.isNotEmpty
                      ? purchase.customerName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.customerName.isEmpty
                          ? 'Unknown customer'
                          : purchase.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (purchase.billNumber.isNotEmpty)
                          '#${purchase.billNumber}',
                        purchase.billDate,
                      ].where((e) => e.toString().isNotEmpty).join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (purchase.customerPhone.isNotEmpty &&
                        purchase.customerPhone != '0') ...[
                      const SizedBox(height: 3),
                      Text(
                        purchase.customerPhone,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₹${total.formatPrice}',
                      style: const TextStyle(
                        color: Color(0xFF1B8A3E),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? Colors.green.withOpacity(.08)
                          : Colors.red.withOpacity(.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isPaid ? 'PAID' : '₹${pending.formatPrice} DUE',
                      style: TextStyle(
                        color: isPaid ? Colors.green.shade700 : Colors.red.shade700,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
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
  }
}

// ============================================================================
// DETAIL PANEL (RIGHT / MOBILE SHEET)
// ============================================================================

class BillDetailPanel extends ConsumerWidget {
  final PurchaseModel purchase;
  final TextEditingController paymentController;
  final bool showPaymentField;
  final bool isPaying;
  final String? selectedPaymentMode;
  final ValueChanged<String?> onPaymentModeChanged;
  final VoidCallback onTogglePayment;
  final VoidCallback onCancelPayment;
  final Future<void> Function() onSubmitPayment;

  const BillDetailPanel({
    super.key,
    required this.purchase,
    required this.paymentController,
    required this.showPaymentField,
    required this.isPaying,
    required this.selectedPaymentMode,
    required this.onPaymentModeChanged,
    required this.onTogglePayment,
    required this.onCancelPayment,
    required this.onSubmitPayment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final pending = double.tryParse(purchase.pending) ?? 0;
    final isPaid = pending <= 0;
    final detailAsync = ref.watch(billDetailProvider(purchase.billId));

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bill Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  purchase.customerName.isEmpty
                      ? 'Customer bill'
                      : purchase.customerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (purchase.billNumber.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Bill #${purchase.billNumber}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _AmountChip(
                label: 'Total',
                value: AppFormatters.currencyOf(purchase.totalAmount),
                color: cs.primary,
              ),
              const SizedBox(width: 8),
              _AmountChip(
                label: 'Paid',
                value: AppFormatters.currencyOf(purchase.paid),
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              _AmountChip(
                label: 'Pending',
                value: isPaid
                    ? AppFormatters.currency(0)
                    : AppFormatters.currencyOf(purchase.pending),
                color: isPaid ? Colors.grey.shade600 : Colors.red.shade700,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoCard(
            children: [
              _InfoRow(label: 'Date', value: purchase.billDate),
              if (purchase.customerPhone.isNotEmpty &&
                  purchase.customerPhone != '0')
                _InfoRow(label: 'Phone', value: purchase.customerPhone),
              if (purchase.paymentMode.isNotEmpty)
                _InfoRow(
                  label: 'Payment Mode',
                  value: purchase.paymentMode.toUpperCase(),
                ),
              _InfoRow(
                label: 'Status',
                value: purchase.status.toUpperCase(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          detailAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => _DetailError(
              onRetry: () =>
                  ref.invalidate(billDetailProvider(purchase.billId)),
            ),
            data: (detail) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (detail.notes.isNotEmpty) ...[
                    _NotesBanner(notes: detail.notes),
                    const SizedBox(height: 12),
                  ],
                  _ProductsSection(items: detail.items),
                ],
              );
            },
          ),
          if (!isPaid) ...[
            const SizedBox(height: 16),
            if (!showPaymentField)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: onTogglePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text(
                    'Receive Payment',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else
              _PaymentForm(
                controller: paymentController,
                isPaying: isPaying,
                selectedPaymentMode: selectedPaymentMode,
                onPaymentModeChanged: onPaymentModeChanged,
                onCancel: onCancelPayment,
                onSubmit: onSubmitPayment,
              ),
          ],
        ],
      ),
    );
  }
}

class _PaymentForm extends StatelessWidget {
  final TextEditingController controller;
  final bool isPaying;
  final String? selectedPaymentMode;
  final ValueChanged<String?> onPaymentModeChanged;
  final VoidCallback onCancel;
  final Future<void> Function() onSubmit;

  const _PaymentForm({
    required this.controller,
    required this.isPaying,
    required this.selectedPaymentMode,
    required this.onPaymentModeChanged,
    required this.onCancel,
    required this.onSubmit,
  });

  static const _modes = ['Cash', 'UPI', 'Card', 'Bank Transfer', 'Other'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            enabled: !isPaying,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Enter received amount',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              prefixIcon: Icon(
                Icons.currency_rupee,
                color: cs.primary,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey(selectedPaymentMode ?? 'none'),
            initialValue: selectedPaymentMode,
            isExpanded: true,
            onChanged: isPaying ? null : onPaymentModeChanged,
            decoration: InputDecoration(
              hintText: 'Select payment mode',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              prefixIcon: Icon(
                Icons.account_balance_wallet_outlined,
                color: cs.primary,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
            items: _modes
                .map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(
                      m,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Colors.grey,
                      width: 0.6,
                    ),
                  ),
                  onPressed: isPaying ? null : onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isPaying ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    disabledBackgroundColor: cs.primary.withOpacity(.5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: isPaying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(fontWeight: FontWeight.w600),
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

class _ProductsSection extends StatelessWidget {
  final List<PurchaseItem> items;

  const _ProductsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shopping_bag_outlined, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              'Products (${items.length})',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: cs.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xffF7F8FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No items on this bill',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          )
        else
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final price = double.tryParse(item.price) ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xffFAFBFD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${price.formatPrice}${item.gstPercent > 0 ? ' + ${item.gstPercent}% GST' : ''} × ${item.quantity}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${item.total.formatPrice}',
                          style: const TextStyle(
                            color: Color(0xFF1B8A3E),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (item.gstAmount > 0) ...[
                        const SizedBox(height: 3),
                        Text(
                          'GST ₹${item.gstAmount.formatPrice}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _AmountChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AmountChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2))
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesBanner extends StatelessWidget {
  final String notes;

  const _NotesBanner({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.note_alt_outlined, size: 16, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notes,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  final VoidCallback onRetry;

  const _DetailError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Couldn't load bill details",
              style: TextStyle(fontSize: 13),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _NoSelectionPanel extends StatelessWidget {
  const _NoSelectionPanel();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      alignment: Alignment.center,
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
        mainAxisAlignment: MainAxisAlignment.center,
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
            'Select a bill',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'View products, amounts and receive payment',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyBills extends StatelessWidget {
  const _EmptyBills();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 36,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No Bills Yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Your generated bills will appear here.\nCreate your first bill to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'No matching bills found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 42, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              message.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

extension PriceFormatter on double {
  String get formatPrice => AppFormatters.plain(this);
}
