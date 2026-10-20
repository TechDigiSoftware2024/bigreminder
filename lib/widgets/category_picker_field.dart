import 'dart:async';

import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../services/category_service.dart';

/// Searchable category field. Loads active categories before login.
class CategoryPickerField extends FormField<CategoryModel> {
  CategoryPickerField({
    super.key,
    CategoryModel? selected,
    required ValueChanged<CategoryModel> onChanged,
    String hint = 'Select business category',
    super.validator,
  }) : super(
          initialValue: selected,
          builder: (state) {
            return _CategoryPickerBody(
              selected: state.value,
              hint: hint,
              errorText: state.errorText,
              onChanged: (category) {
                state.didChange(category);
                onChanged(category);
              },
            );
          },
        );
}

class _CategoryPickerBody extends StatefulWidget {
  final CategoryModel? selected;
  final String hint;
  final String? errorText;
  final ValueChanged<CategoryModel> onChanged;

  const _CategoryPickerBody({
    required this.selected,
    required this.hint,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<_CategoryPickerBody> createState() => _CategoryPickerBodyState();
}

class _CategoryPickerBodyState extends State<_CategoryPickerBody> {
  final CategoryService _service = CategoryService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  bool _open = false;
  bool _loading = false;
  String? _error;
  List<CategoryModel> _categories = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load([String search = '']) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.fetchPublic(
        search: search.trim().isEmpty ? null : search.trim(),
      );
      if (!mounted) return;
      setState(() {
        _categories = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _load(value);
    });
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _searchController.clear();
      _load();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasError = widget.errorText != null;
    final selected = widget.selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? scheme.error
                    : _open
                        ? scheme.primary
                        : scheme.outline,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.category_outlined, size: 20, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selected?.name ?? widget.hint,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: selected == null
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              widget.errorText!,
              style: TextStyle(color: scheme.error, fontSize: 12),
            ),
          ),
        if (_open)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search categories',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: Column(
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.error, fontSize: 12),
                        ),
                        TextButton(
                          onPressed: () => _load(_searchController.text),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (_categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    child: Text(
                      'No categories found',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 6),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = selected?.id == category.id;
                        return InkWell(
                          onTap: () {
                            widget.onChanged(category);
                            setState(() => _open = false);
                          },
                          child: Container(
                            color: isSelected
                                ? scheme.primary.withValues(alpha: 0.08)
                                : null,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.work_outline,
                                  size: 18,
                                  color: isSelected
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    category.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? scheme.primary
                                          : scheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (category.businesses.isNotEmpty)
                                  Text(
                                    '${category.businesses.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
