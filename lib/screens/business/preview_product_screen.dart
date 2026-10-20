import 'package:flutter/material.dart';

import '../../models/business_models/add_product_model.dart';
import '../../utils/formatters.dart';

class PreviewProductsScreen extends StatefulWidget {
  final List<ProductModel> products;
  final Future<void> Function(List<ProductModel> products) onUpload;

  const PreviewProductsScreen({
    super.key,
    required this.products,
    required this.onUpload,
  });

  @override
  State<PreviewProductsScreen> createState() => _PreviewProductsScreenState();
}

class _PreviewProductsScreenState extends State<PreviewProductsScreen> {
  late List<ProductModel> _products;
  ProductModel? _selected;
  int? _selectedIndex;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _products = List<ProductModel>.from(widget.products);
    if (_products.isNotEmpty) {
      _selected = _products.first;
      _selectedIndex = 0;
    }
  }

  Future<void> _handleUpload() async {
    if (_isUploading || _products.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      await widget.onUpload(List<ProductModel>.from(_products));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _select(int index) {
    setState(() {
      _selectedIndex = index;
      _selected = _products[index];
    });
  }

  void _removeAt(int index) {
    setState(() {
      _products.removeAt(index);
      if (_products.isEmpty) {
        _selected = null;
        _selectedIndex = null;
      } else {
        final next = index.clamp(0, _products.length - 1);
        _selectedIndex = next;
        _selected = _products[next];
      }
    });
  }

  double get _totalValue =>
      _products.fold<double>(0, (sum, p) => sum + (p.price * p.stock));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        title: const Text(
          'Preview Products',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      body: _products.isEmpty
          ? const _EmptyPreview()
          : isDesktop
              ? _buildDesktop(cs)
              : _buildMobile(cs),
      bottomNavigationBar: (!isDesktop && _products.isNotEmpty)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _UploadButton(
                  count: _products.length,
                  loading: _isUploading,
                  onPressed: _handleUpload,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDesktop(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: _PreviewListPanel(
              products: _products,
              selectedIndex: _selectedIndex,
              onSelect: _select,
              onRemove: _removeAt,
              isDesktop: true,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 380,
            child: _PreviewSidePanel(
              selected: _selected,
              selectedIndex: _selectedIndex,
              totalCount: _products.length,
              totalValue: _totalValue,
              loading: _isUploading,
              onUpload: _handleUpload,
              onRemoveSelected: _selectedIndex == null
                  ? null
                  : () => _removeAt(_selectedIndex!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(ColorScheme cs) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: _SummaryBanner(
            count: _products.length,
            totalValue: _totalValue,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: _PreviewListPanel(
              products: _products,
              selectedIndex: _selectedIndex,
              onSelect: (index) {
                _select(index);
                _openMobileDetail(index);
              },
              onRemove: _removeAt,
              isDesktop: false,
            ),
          ),
        ),
      ],
    );
  }

  void _openMobileDetail(int index) {
    final product = _products[index];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: _ProductDetailCard(
                    product: product,
                    index: index,
                    onRemove: () {
                      Navigator.pop(sheetContext);
                      _removeAt(index);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// LIST
// ============================================================================

class _PreviewListPanel extends StatelessWidget {
  final List<ProductModel> products;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onRemove;
  final bool isDesktop;

  const _PreviewListPanel({
    required this.products,
    required this.selectedIndex,
    required this.onSelect,
    required this.onRemove,
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
          Text(
            'Import Preview',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${products.length} products ready to upload',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _PreviewProductCard(
                  product: products[index],
                  index: index,
                  selected: selectedIndex == index,
                  onTap: () => onSelect(index),
                  onRemove: () => onRemove(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewProductCard extends StatelessWidget {
  final ProductModel product;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PreviewProductCard({
    required this.product,
    required this.index,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasBarcode =
        product.barcode != null && product.barcode!.trim().isNotEmpty;
    final priceLabel = AppFormatters.currency(product.price);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withOpacity(.06)
                : const Color(0xffFAFBFD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? cs.primary.withOpacity(.35)
                  : Colors.grey.shade200,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasBarcode ? product.barcode! : 'No barcode',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniChip(
                          label: 'Stock ${product.stock}',
                          color: Colors.orange,
                        ),
                        if ((product.gst_percent ?? 0) > 0)
                          _MiniChip(
                            label: '${product.gst_percent}% GST',
                            color: Colors.blue,
                          ),
                      ],
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
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      priceLabel,
                      style: const TextStyle(
                        color: Color(0xFF1B8A3E),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onRemove,
                      borderRadius: BorderRadius.circular(10),
                      child: Ink(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.red.shade400,
                        ),
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
// RIGHT SIDE / DETAIL
// ============================================================================

class _PreviewSidePanel extends StatelessWidget {
  final ProductModel? selected;
  final int? selectedIndex;
  final int totalCount;
  final double totalValue;
  final bool loading;
  final VoidCallback onUpload;
  final VoidCallback? onRemoveSelected;

  const _PreviewSidePanel({
    required this.selected,
    required this.selectedIndex,
    required this.totalCount,
    required this.totalValue,
    required this.loading,
    required this.onUpload,
    required this.onRemoveSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _ImportSummaryCard(
            count: totalCount,
            totalValue: totalValue,
            loading: loading,
            onUpload: onUpload,
          ),
          const SizedBox(height: 14),
          if (selected != null && selectedIndex != null)
            _ProductDetailCard(
              product: selected!,
              index: selectedIndex!,
              onRemove: onRemoveSelected,
            )
          else
            const _NoSelectionCard(),
        ],
      ),
    );
  }
}

class _ImportSummaryCard extends StatelessWidget {
  final int count;
  final double totalValue;
  final bool loading;
  final VoidCallback onUpload;

  const _ImportSummaryCard({
    required this.count,
    required this.totalValue,
    required this.loading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final valueLabel = AppFormatters.currency(totalValue);

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
                  'CSV Import',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Review before uploading',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Products',
                  value: '$count',
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'Stock Value',
                  value: valueLabel,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _UploadButton(
            count: count,
            loading: loading,
            onPressed: onUpload,
          ),
        ],
      ),
    );
  }
}

class _ProductDetailCard extends StatelessWidget {
  final ProductModel product;
  final int index;
  final VoidCallback? onRemove;

  const _ProductDetailCard({
    required this.product,
    required this.index,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasBarcode =
        product.barcode != null && product.barcode!.trim().isNotEmpty;
    final priceLabel = AppFormatters.currency(product.price);

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
              Text(
                'Product #${index + 1}',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (onRemove != null)
                TextButton.icon(
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: Colors.red.shade400,
                  ),
                  label: Text(
                    'Remove',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'Barcode',
            value: hasBarcode ? product.barcode! : '—',
          ),
          const SizedBox(height: 8),
          _DetailRow(label: 'Price', value: priceLabel),
          const SizedBox(height: 8),
          _DetailRow(label: 'Stock', value: '${product.stock}'),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'GST',
            value: (product.gst_percent ?? 0) > 0
                ? '${product.gst_percent}%'
                : '—',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SMALL UI
// ============================================================================

class _SummaryBanner extends StatelessWidget {
  final int count;
  final double totalValue;

  const _SummaryBanner({
    required this.count,
    required this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final valueLabel = AppFormatters.currency(totalValue);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Products',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Stock value $valueLabel',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.9),
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
}

class _UploadButton extends StatelessWidget {
  final int count;
  final bool loading;
  final VoidCallback onPressed;

  const _UploadButton({
    required this.count,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: cs.primary,
          disabledBackgroundColor: cs.primary.withOpacity(.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: (loading || count == 0) ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.cloud_upload_rounded,
                color: Colors.white,
                size: 20,
              ),
        label: Text(
          loading ? 'Uploading...' : 'Upload $count Products',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 14,
            ),
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
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xffF7F8FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
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
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NoSelectionCard extends StatelessWidget {
  const _NoSelectionCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.touch_app_outlined, size: 28, color: cs.primary),
          const SizedBox(height: 10),
          const Text(
            'Select a product',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap an item on the left to review details',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 34,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No Products Found',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Import a CSV file to preview products.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
