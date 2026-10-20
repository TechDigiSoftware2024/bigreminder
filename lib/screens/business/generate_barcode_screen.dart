import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/business_models/add_product_model.dart';
import '../../providers/business/business_provider.dart';
import '../../services/business/add_product_service.dart';
import '../../utils/formatters.dart';
import '../../utils/product_barcode_sheet.dart';
import '../../widgets/custom_dialog.dart';

class GenerateBarcodeScreen extends ConsumerStatefulWidget {
  final List<ProductModel> productsWithoutBarcode;
  final Set<String> takenBarcodes;
  final ProductModel? seed;

  const GenerateBarcodeScreen({
    super.key,
    required this.productsWithoutBarcode,
    required this.takenBarcodes,
    this.seed,
  });

  @override
  ConsumerState<GenerateBarcodeScreen> createState() =>
      _GenerateBarcodeScreenState();
}

class _GenerateBarcodeScreenState extends ConsumerState<GenerateBarcodeScreen> {
  final _nameCtrl = TextEditingController();
  final _mrpCtrl = TextEditingController();
  final _sellCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _copiesCtrl = TextEditingController(text: '1');

  final _items = <_BatchItem>[];
  final _retired = <_BatchItem>[];
  late final List<ProductModel> _missing;
  late final Set<String> _taken;

  BarcodeLabelPreset _preset = BarcodeLabelPreset.options[1];
  late int _columns;
  late int _rows;

  String? _composerError;
  bool _saving = false;
  bool _printing = false;
  bool _forcePop = false;
  bool _leaveDialogOpen = false;

  @override
  void initState() {
    super.initState();
    final fit = _preset.fitOnA4();
    _columns = fit.columns;
    _rows = fit.rows;
    _taken = {...widget.takenBarcodes};
    _missing = widget.productsWithoutBarcode
        .where((product) => product.id == null || product.id != widget.seed?.id)
        .toList();
    final seed = widget.seed;
    if (seed != null) {
      _items.add(_BatchItem.fromProduct(seed));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mrpCtrl.dispose();
    _sellCtrl.dispose();
    _gstCtrl.dispose();
    _stockCtrl.dispose();
    _copiesCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    for (final item in _retired) {
      item.dispose();
    }
    super.dispose();
  }

  bool get _hasUnsavedBarcodes =>
      _items.any((item) => item.barcode != null && !item.saved);

  bool get _allHaveBarcodes =>
      _items.isNotEmpty && _items.every((item) => item.barcode != null);

  int get _labelCount {
    var total = 0;
    for (final item in _items) {
      final copies = int.tryParse(item.copiesCtrl.text.trim()) ?? 0;
      if (copies > 0) total += copies;
    }
    return total;
  }

  void _applyPreset(BarcodeLabelPreset preset) {
    final fit = preset.fitOnA4();
    setState(() {
      _preset = preset;
      _columns = fit.columns;
      _rows = fit.rows;
    });
  }

  void _addFromComposer() {
    final draft = _BatchItem()
      ..nameCtrl.text = _nameCtrl.text
      ..mrpCtrl.text = _mrpCtrl.text
      ..sellCtrl.text = _sellCtrl.text
      ..gstCtrl.text = _gstCtrl.text
      ..stockCtrl.text = _stockCtrl.text
      ..copiesCtrl.text = _copiesCtrl.text;
    final error = _validateItem(draft);
    if (error != null) {
      draft.dispose();
      setState(() => _composerError = error);
      return;
    }

    setState(() {
      _composerError = null;
      _items.add(draft);
      _nameCtrl.clear();
      _mrpCtrl.clear();
      _sellCtrl.clear();
      _gstCtrl.clear();
      _stockCtrl.text = '0';
      _copiesCtrl.text = '1';
    });
  }

  void _addExisting(ProductModel product) {
    setState(() {
      _missing.removeWhere((item) => item.id == product.id);
      _items.add(_BatchItem.fromProduct(product));
    });
  }

  void _remove(_BatchItem item) {
    setState(() {
      _items.remove(item);
      _retired.add(item);
      final existing = item.existing;
      if (existing != null && !item.saved) {
        final already = _missing.any((product) => product.id == existing.id);
        if (!already) _missing.insert(0, existing);
      }
    });
  }

  Future<void> _generate() async {
    if (_items.isEmpty || _saving) return;

    var firstErrorItem = -1;
    for (var i = 0; i < _items.length; i++) {
      final error = _validateItem(_items[i]);
      _items[i].error = error;
      if (error != null && firstErrorItem == -1) firstErrorItem = i;
    }
    if (firstErrorItem != -1) {
      setState(() {});
      CustomDialog.showErrorSnack(
        context,
        _items[firstErrorItem].error ?? 'Check the product details',
      );
      return;
    }

    setState(() {
      for (final item in _items) {
        item.error = null;
        if (item.barcode == null) {
          item.barcode = generateStoreBarcode(_taken);
        }
      }
    });

    CustomDialog.showSuccessSnack(
      context,
      'Barcodes are ready. Choose a size, then print.',
    );
  }

  Future<void> _print() async {
    if (!_allHaveBarcodes || _printing || _saving) return;

    for (final item in _items) {
      final error = _validateItem(item);
      item.error = error;
      if (error != null) {
        setState(() {});
        CustomDialog.showErrorSnack(context, error);
        return;
      }
    }

    final labels = _items
        .map(
          (item) => PrintableProductLabel(
            name: item.nameCtrl.text.trim(),
            barcode: item.barcode!,
            mrp: double.parse(item.mrpCtrl.text.trim()),
            sellingPrice: double.parse(item.sellCtrl.text.trim()),
            copies: int.parse(item.copiesCtrl.text.trim()),
          ),
        )
        .toList();

    setState(() => _printing = true);
    try {
      await printProductBarcodeSheet(
        labels: labels,
        preset: _preset,
        columns: _columns,
        rows: _rows,
      );
    } catch (error) {
      if (!mounted) return;
      CustomDialog.showErrorSnack(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _save() async {
    if (!_allHaveBarcodes || _saving || _printing) return;

    for (final item in _items) {
      final error = _validateItem(item);
      item.error = error;
      if (error != null) {
        setState(() {});
        CustomDialog.showErrorSnack(context, error);
        return;
      }
    }

    final token = ref.read(tokenProvider);
    final businessId = ref.read(businessIdProvider);
    final service = ProductService();
    var saved = 0;
    var failed = 0;

    setState(() => _saving = true);
    try {
      for (final item in _items) {
        if (item.saved) continue;
        final gstText = item.gstCtrl.text.trim();
        final product = ProductModel(
          id: item.existing?.id,
          businessId: businessId,
          barcode: item.barcode,
          name: item.nameCtrl.text.trim(),
          gst_percent: gstText.isEmpty ? null : int.tryParse(gstText),
          price: double.parse(item.sellCtrl.text.trim()),
          stock: int.parse(item.stockCtrl.text.trim()),
        );

        try {
          final existingId = item.existing?.id;
          if (existingId != null) {
            await service.updateProduct(
              token: token,
              productId: existingId,
              product: product,
            );
          } else {
            await service.createProduct(token: token, product: product);
          }
          if (!mounted) return;
          setState(() {
            item.saved = true;
            item.error = null;
          });
          saved++;
        } catch (error) {
          failed++;
          if (!mounted) return;
          setState(() {
            item.error = error.toString().replaceFirst('Exception: ', '');
          });
        }
      }

      if (saved > 0) {
        await ref.read(productProvider.notifier).loadProducts(
              token,
              businessId.toString(),
              keepPrevious: true,
            );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (!mounted) return;
    if (failed == 0 && saved > 0) {
      CustomDialog.showSuccessSnack(
        context,
        saved == 1
            ? 'Product saved to inventory'
            : '$saved products saved to inventory',
      );
      Navigator.of(context).pop();
      return;
    }
    if (saved > 0) {
      CustomDialog.showErrorSnack(
        context,
        '$saved saved, $failed could not be saved. Check the marked rows.',
      );
    } else {
      CustomDialog.showErrorSnack(
        context,
        'Could not save these products to inventory.',
      );
    }
  }

  Future<void> _maybeLeave() async {
    if (_forcePop || !_hasUnsavedBarcodes) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (_leaveDialogOpen) return;
    _leaveDialogOpen = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Leave without saving?'),
          content: const Text(
            'Barcodes are generated but not saved to inventory yet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
    _leaveDialogOpen = false;
    if (leave == true && mounted) {
      setState(() => _forcePop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 980;

    return PopScope(
      canPop: _forcePop || !_hasUnsavedBarcodes,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _maybeLeave();
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF5F7FB),
        appBar: AppBar(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Generate barcodes',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _maybeLeave,
          ),
        ),
        body: wide
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 400, child: _buildComposerColumn()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildBatchColumn(shrinkWrap: false)),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildComposerCard(),
                  const SizedBox(height: 14),
                  _buildMissingCard(),
                  const SizedBox(height: 14),
                  _buildBatchColumn(shrinkWrap: true),
                ],
              ),
      ),
    );
  }

  Widget _buildComposerColumn() {
    return ListView(
      children: [
        _buildComposerCard(),
        const SizedBox(height: 14),
        _buildMissingCard(),
      ],
    );
  }

  Widget _buildComposerCard() {
    final cs = Theme.of(context).colorScheme;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New product label',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add one or more products. Each one gets its own barcode. MRP and selling price are printed on the label.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 14),
          _LabeledField(
            controller: _nameCtrl,
            label: 'Product name',
            hint: 'e.g. Soap',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  controller: _mrpCtrl,
                  label: 'MRP',
                  hint: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LabeledField(
                  controller: _sellCtrl,
                  label: 'Selling price',
                  hint: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  controller: _gstCtrl,
                  label: 'GST %',
                  hint: 'Optional',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LabeledField(
                  controller: _stockCtrl,
                  label: 'Stock',
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _LabeledField(
            controller: _copiesCtrl,
            label: 'Labels to print',
            hint: '1',
            keyboardType: TextInputType.number,
            helper: 'How many copies of this barcode go on the sheet.',
          ),
          if (_composerError != null) ...[
            const SizedBox(height: 8),
            Text(
              _composerError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _addFromComposer,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Add to batch',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingCard() {
    final cs = Theme.of(context).colorScheme;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Products without a barcode',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _missing.isEmpty
                ? 'Every product in inventory already has a barcode.'
                : 'Add these to the batch, generate a barcode, then save. The existing product is updated.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.35),
          ),
          if (_missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _missing.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final product = _missing[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xffFAFBFD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${AppFormatters.currency(product.price)} · Stock ${product.stock}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _addExisting(product),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBatchColumn({required bool shrinkWrap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (!shrinkWrap)
          Expanded(child: _buildBatchList(shrinkWrap: false))
        else
          _buildBatchList(shrinkWrap: true),
        const SizedBox(height: 14),
        _buildPrintBar(),
      ],
    );
  }

  Widget _buildBatchList({required bool shrinkWrap}) {
    final cs = Theme.of(context).colorScheme;
    return _Panel(
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
                      'Barcode batch',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _items.isEmpty
                          ? 'No products in this batch yet'
                          : '${_items.length} product${_items.length == 1 ? '' : 's'} · $_labelCount label${_labelCount == 1 ? '' : 's'}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'Add a product, generate its barcode, then print the labels.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            )
          else if (shrinkWrap)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _BatchCard(
                item: _items[index],
                index: index,
                onRemove: () => _remove(_items[index]),
                onChanged: () => setState(() {}),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _BatchCard(
                  item: _items[index],
                  index: index,
                  onRemove: () => _remove(_items[index]),
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrintBar() {
    final cs = Theme.of(context).colorScheme;
    final perSheet = _columns * _rows;
    final pages = _labelCount == 0 ? 0 : (_labelCount / perSheet).ceil();
    final fit = _preset.fitOnA4();
    final canGenerate = _items.isNotEmpty && !_saving && !_printing;
    final canPrint = _allHaveBarcodes && !_saving && !_printing;
    final canSave = _allHaveBarcodes && _items.any((item) => !item.saved) && !_saving && !_printing;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1  Generate    2  Choose size and print    3  Save to inventory',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'Label size',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in BarcodeLabelPreset.options)
                ChoiceChip(
                  label: Text('${option.name}  ${option.sizeLabel}'),
                  selected: option.id == _preset.id,
                  onSelected: _printing || _saving
                      ? null
                      : (_) => _applyPreset(option),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CountStepper(
                  label: 'Across',
                  value: _columns,
                  min: 1,
                  max: fit.columns,
                  onChanged: (value) => setState(() => _columns = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CountStepper(
                  label: 'Down',
                  value: _rows,
                  min: 1,
                  max: fit.rows,
                  onChanged: (value) => setState(() => _rows = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$perSheet barcodes on one A4 sheet ($_columns × $_rows). '
            '${pages == 0 ? 'Add labels to see the page count.' : '$pages sheet${pages == 1 ? '' : 's'} for $_labelCount label${_labelCount == 1 ? '' : 's'}.'}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: canGenerate ? _generate : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: cs.primary.withValues(alpha: 0.35),
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                label: const Text('Generate barcodes'),
              ),
              OutlinedButton.icon(
                onPressed: canPrint ? _print : null,
                icon: _printing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print_outlined, size: 18),
                label: const Text('Print labels'),
              ),
              ElevatedButton.icon(
                onPressed: canSave ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F6B4A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF2F6B4A).withValues(alpha: 0.35),
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.inventory_2_outlined, size: 18),
                label: const Text('Save to inventory'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatchItem {
  _BatchItem();

  static int _nextKey = 0;
  final int keyId = _nextKey++;

  ProductModel? existing;
  final nameCtrl = TextEditingController();
  final mrpCtrl = TextEditingController();
  final sellCtrl = TextEditingController();
  final gstCtrl = TextEditingController();
  final stockCtrl = TextEditingController(text: '0');
  final copiesCtrl = TextEditingController(text: '1');
  String? barcode;
  bool saved = false;
  String? error;

  factory _BatchItem.fromProduct(ProductModel product) {
    final item = _BatchItem()..existing = product;
    item.nameCtrl.text = product.name;
    item.sellCtrl.text = _trimNumber(product.price);
    item.stockCtrl.text = product.stock.toString();
    if (product.gst_percent != null && product.gst_percent! > 0) {
      item.gstCtrl.text = product.gst_percent.toString();
    }
    return item;
  }

  void dispose() {
    nameCtrl.dispose();
    mrpCtrl.dispose();
    sellCtrl.dispose();
    gstCtrl.dispose();
    stockCtrl.dispose();
    copiesCtrl.dispose();
  }
}

String? _validateItem(_BatchItem item) {
  if (item.nameCtrl.text.trim().isEmpty) return 'Product name is required';
  final mrp = double.tryParse(item.mrpCtrl.text.trim());
  if (mrp == null || mrp < 0) return 'Enter a valid MRP';
  final selling = double.tryParse(item.sellCtrl.text.trim());
  if (selling == null || selling < 0) return 'Enter a valid selling price';
  final stock = int.tryParse(item.stockCtrl.text.trim());
  if (stock == null || stock < 0) return 'Enter a valid stock quantity';
  final copies = int.tryParse(item.copiesCtrl.text.trim());
  if (copies == null || copies < 1 || copies > 500) {
    return 'Labels to print must be between 1 and 500';
  }
  final gst = item.gstCtrl.text.trim();
  if (gst.isNotEmpty && int.tryParse(gst) == null) {
    return 'GST must be a whole number';
  }
  return null;
}

String _trimNumber(num value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString();
}

class _BatchCard extends StatelessWidget {
  final _BatchItem item;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _BatchCard({
    required this.item,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locked = item.saved;
    final mrp = double.tryParse(item.mrpCtrl.text.trim());
    final selling = double.tryParse(item.sellCtrl.text.trim());
    final priceWarning = mrp != null && selling != null && selling > mrp;

    return Container(
      key: ValueKey(item.keyId),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffFAFBFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.error != null
              ? Colors.red.shade300
              : item.saved
                  ? const Color(0xFF2F6B4A)
                  : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Barcode ${index + 1}',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              if (item.existing != null) ...[
                const SizedBox(width: 8),
                Text(
                  'Already in inventory',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
              const Spacer(),
              if (item.saved)
                const Icon(Icons.check_circle, color: Color(0xFF2F6B4A), size: 18)
              else
                IconButton(
                  tooltip: 'Remove',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (item.barcode != null) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 58,
                    child: BarcodeWidget(
                      barcode: Barcode.ean13(),
                      data: item.barcode!,
                      drawText: false,
                      errorBuilder: (context, error) =>
                          Text(item.barcode!, textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.barcode!,
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (mrp != null && selling != null)
                    Text(
                      'MRP ${AppFormatters.currency(mrp)}    Sell ${AppFormatters.currency(selling)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                ],
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Barcode will be created when you generate.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          const SizedBox(height: 8),
          _LabeledField(
            controller: item.nameCtrl,
            label: 'Product name',
            enabled: !locked,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  controller: item.mrpCtrl,
                  label: 'MRP',
                  enabled: !locked,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LabeledField(
                  controller: item.sellCtrl,
                  label: 'Selling price',
                  enabled: !locked,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          if (priceWarning)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Selling price is higher than MRP.',
                style: TextStyle(color: Color(0xFF9A6B12), fontSize: 11),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  controller: item.gstCtrl,
                  label: 'GST %',
                  enabled: !locked,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LabeledField(
                  controller: item.stockCtrl,
                  label: 'Stock',
                  enabled: !locked,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LabeledField(
                  controller: item.copiesCtrl,
                  label: 'Labels',
                  enabled: !locked,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          if (item.saved)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Saved to inventory',
                style: TextStyle(
                  color: Color(0xFF2F6B4A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (item.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                item.error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LabeledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const _LabeledField({
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.onChanged,
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
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperMaxLines: 2,
            isDense: true,
            filled: true,
            fillColor: enabled ? const Color(0xffFAFBFD) : const Color(0xffF3F4F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.12)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _CountStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _CountStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const Spacer(),
        IconButton(
          onPressed: value <= min ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline),
          visualDensity: VisualDensity.compact,
        ),
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        IconButton(
          onPressed: value >= max ? null : () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
