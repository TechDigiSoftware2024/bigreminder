import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/business_models/business_purchase_list_model.dart';
import '../../providers/business/business_provider.dart';
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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.refresh(purchasesProvider(null));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(PurchaseModel purchase, {String? customerPhone}) {
    if (_searchQuery.isEmpty) return true;

    final query = _searchQuery.toLowerCase();

    final searchFields = <String>[
      purchase.customerName,
      purchase.billNumber,
      purchase.barcode,
      purchase.totalAmount.toString(),
      purchase.billDate,
      purchase.status,
    ];

    // Add customer phone if available
    if (customerPhone?.isNotEmpty == true) {
      searchFields.add(customerPhone!);
    }

    return searchFields.any((field) => field.toLowerCase().contains(query));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final purchasesAsync = ref.watch(purchasesProvider(null));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Purchase History',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white,fontSize: 17,),
        ),
        backgroundColor: primary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(purchasesProvider(null));
          await ref.read(purchasesProvider(null).future);
        },
        child: purchasesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (purchases) {
            if (purchases.isEmpty) {
              return const Center(
                child: Text('No Purchases Found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              );
            }

            // Watch all customer details for search functionality
            // This is reactive and will update when customer data loads
            final filteredPurchases = purchases.where((purchase) {
              final customerAsync = ref.watch(customerDetailProvider(purchase.customerId));
              final customerPhone = customerAsync.when(
                data: (customer) => customer.phone,
                loading: () => null,
                error: (_, __) => null,
              );

              return _matchesSearch(purchase, customerPhone: customerPhone);
            }).toList();

            return Column(
              children: [
                _buildSearchBar(context),
                Expanded(
                  child: filteredPurchases.isEmpty
                      ? _buildEmptySearch()
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredPurchases.length,
                    itemBuilder: (_, index) => _PurchaseCard(
                      purchase: filteredPurchases[index],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Material(
        elevation: 0.5,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: "Search bill, customer, amount, date...",
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).primaryColor),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            "No matching purchase found",
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PurchaseCard extends ConsumerStatefulWidget {
  final PurchaseModel purchase;
  const _PurchaseCard({required this.purchase});

  @override
  ConsumerState<_PurchaseCard> createState() => _PurchaseCardState();
}

class _PurchaseCardState extends ConsumerState<_PurchaseCard> {
  bool _showPaymentField = false;
  bool _isLoading = false;
  bool _hasExpandedOnce = false;
  final TextEditingController _paymentController = TextEditingController();

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  double get _pendingAmount {
    final pending = double.tryParse(widget.purchase.pending);
    return pending ?? 0;
  }

  bool get _isFullyPaid => _pendingAmount <= 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final purchasesAsync = ref.watch(purchasesProvider(null));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onExpansionChanged: (expanded) {
            if (expanded && !_hasExpandedOnce) {
              setState(() => _hasExpandedOnce = true);
            }
          },
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: primary,
            child: Text(
              widget.purchase.customerName.isNotEmpty
                  ? widget.purchase.customerName[0].toUpperCase()
                  : "?",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
          title: Text(
            widget.purchase.customerName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: _buildSubtitle(context),
          trailing: _buildStatusBadge(context),
          childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: _buildExpandedContent(context),
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final customerAsync = ref.watch(customerDetailProvider(widget.purchase.customerId));

    return Row(
      children: [
        Flexible(
          child: customerAsync.when(
            loading: () => Text(
              widget.purchase.billDate,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            error: (_, __) => Text(
              widget.purchase.billDate,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            data: (customer) {
              if (customer.phone?.isNotEmpty == true) {
                return Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        customer.phone!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.purchase.billDate,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                );
              }
              return Text(
                widget.purchase.billDate,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    if (_isFullyPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "Paid",
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "₹${_pendingAmount.formatPrice}",
        style: TextStyle(
          color: Colors.red.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  List<Widget> _buildExpandedContent(BuildContext context) {
    return [
      _buildAmountSummary(context),
      const SizedBox(height: 12),
      if (_hasExpandedOnce) _buildDetailSection(context),
      if (!_isFullyPaid) ...[
        const SizedBox(height: 16),
        _buildPaymentSection(context),
      ],
    ];
  }

  Widget _buildAmountSummary(BuildContext context) {
    return Row(
      children: [
        _AmountChip(
          label: "Total",
          value: "₹${widget.purchase.totalAmount}",
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        _AmountChip(
          label: "Paid",
          value: "₹${widget.purchase.paid}",
          color: Colors.green.shade700,
        ),
        const SizedBox(width: 8),
        _AmountChip(
          label: "Pending",
          value: _isFullyPaid ? "₹0" : "₹${widget.purchase.pending}",
          color: _isFullyPaid ? Colors.grey.shade600 : Colors.red.shade700,
        ),
      ],
    );
  }

  Widget _buildDetailSection(BuildContext context) {
    final detailAsync = ref.watch(billDetailProvider(widget.purchase.billId));

    return detailAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => _buildErrorWidget(context),
      data: (detail) {
        final merged = widget.purchase.mergeWithDetail(detail);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerInfo(context, merged),
            if (merged.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildNotesSection(context, merged.notes),
            ],
            const SizedBox(height: 16),
            _buildProductsList(context, merged.items),
          ],
        );
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
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
          const Text("Couldn't load bill details",
              style: TextStyle(fontSize: 13)),
          const Spacer(),
          TextButton(
            onPressed: () => ref.invalidate(billDetailProvider(widget.purchase.billId)),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(BuildContext context, PurchaseModel merged) {
    final primary = Theme.of(context).primaryColor;
    final customerAsync = ref.watch(customerDetailProvider(merged.customerId));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: primary),
              const SizedBox(width: 6),
              Text("Customer",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: primary,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(label: "ID", value: merged.customerId.toString()),
          customerAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text("Loading...", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            error: (_, __) => const SizedBox(height: 4),
            data: (customer) {
              return Column(
                children: [
                  if (customer.phone?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    _InfoRow(label: "Phone", value: customer.phone!),
                  ],
                  if (customer.gender?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    _InfoRow(label: "Gender", value: customer.gender!.capitalize),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _InfoRow(label: "Bill No", value: merged.billNumber),
          if (merged.paymentMode.isNotEmpty) ...[
            const SizedBox(height: 4),
            _InfoRow(label: "Payment Mode", value: merged.paymentMode.toUpperCase()),
          ],
          const SizedBox(height: 4),
          _InfoRow(label: "Status", value: merged.status.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, String notes) {
    return Container(
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
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(BuildContext context, List<dynamic> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text("No items", style: TextStyle(color: Colors.grey.shade600)),
        ),
      );
    }

    final primary = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shopping_bag_outlined, size: 16, color: primary),
            const SizedBox(width: 6),
            Text("Products (${items.length})",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: primary,
                )),
          ],
        ),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((entry) => _buildProductItem(context, entry.key, entry.value)),
      ],
    );
  }

  Widget _buildProductItem(BuildContext context, int index, dynamic item) {
    final primary = Theme.of(context).primaryColor;
    final totalAmount = _parseTotal(item.total);
    final price = _parseTotal(item.price);
    final quantity = item.quantity?.toString() ?? "0";

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text(
            "${index + 1}",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name ?? "Unknown",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "₹${price.formatPrice} × $quantity",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "₹${totalAmount.formatPrice}",
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  double _parseTotal(dynamic total) {
    if (total == null) return 0.0;
    if (total is double) return total;
    if (total is int) return total.toDouble();
    if (total is String) {
      return double.tryParse(total) ?? 0.0;
    }
    return 0.0;
  }

  Widget _buildPaymentSection(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final pending = _pendingAmount;

    if (!_showPaymentField) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => setState(() => _showPaymentField = true),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.payments_outlined, size: 18),
          label: const Text("Receive Payment",
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildPendingAmountChip(context, pending),
          const SizedBox(height: 12),
          _buildPaymentInput(context, primary),
          const SizedBox(height: 12),
          _buildPaymentActions(context, primary, pending),
        ],
      ),
    );
  }

  Widget _buildPendingAmountChip(BuildContext context, double pending) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 8),
          Text(
            "Pending: ₹${pending.formatPrice}",
            style: TextStyle(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInput(BuildContext context, Color primary) {
    return TextField(
      controller: _paymentController,
      keyboardType: TextInputType.number,
      autofocus: true,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        hintText: "Enter received amount",
        prefixIcon: Icon(Icons.currency_rupee, color: primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPaymentActions(BuildContext context, Color primary, double pending) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() => _showPaymentField = false);
              _paymentController.clear();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Cancel"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () => _submitPayment(context, pending),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isLoading
                ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.check_circle_outline, size: 18),
            label: Text(
              _isLoading ? "Processing..." : "Submit",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitPayment(BuildContext context, double pending) async {
    final amount = double.tryParse(_paymentController.text) ?? 0;

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

    setState(() => _isLoading = true);

    await ref.read(receivePaymentProvider.notifier).receivePayment(
      amount: amount,
      purchaseId: widget.purchase.billId,
    );

    ref.invalidate(billDetailProvider(widget.purchase.billId));

    if (mounted) {
      setState(() {
        _showPaymentField = false;
        _isLoading = false;
      });
      _paymentController.clear();
      CustomDialog.showSuccessSnack(
        context,
        "Payment of ₹${amount.formatPrice} received",
      );
    }
  }
}

// Reusable Widgets
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
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

// Extensions
extension PriceFormatter on double {
  String get formatPrice {
    if (this == toInt()) {
      return toInt().toString();
    }
    return toStringAsFixed(2);
  }
}

extension StringExtension on String {
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}