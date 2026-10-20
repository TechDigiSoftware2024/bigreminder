import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/category_model.dart';
import '../../../services/category_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../widgets/custom_dialog.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryService _service = CategoryService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<CategoryModel> _categories = const [];
  bool _loading = true;
  String? _error;
  bool? _activeFilter;

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

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please sign in again.');
    }
    return token;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _token();
      final result = await _service.fetchAdmin(
        token: token,
        search: _searchController.text,
        isActive: _activeFilter,
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

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  Future<void> _openEditor({CategoryModel? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    var isActive = existing?.isActive ?? true;
    var saving = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add category' : 'Edit category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Gym',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    subtitle: const Text(
                      'Inactive categories are hidden from sign up',
                    ),
                    value: isActive,
                    onChanged: saving
                        ? null
                        : (value) => setDialogState(() => isActive = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            CustomDialog.showErrorSnack(
                              dialogContext,
                              'Enter a category name',
                            );
                            return;
                          }
                          setDialogState(() => saving = true);
                          try {
                            final token = await _token();
                            if (existing == null) {
                              await _service.create(
                                token: token,
                                name: name,
                                isActive: isActive,
                              );
                            } else {
                              await _service.update(
                                token: token,
                                id: existing.id,
                                name: name,
                                isActive: isActive,
                              );
                            }
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            if (!dialogContext.mounted) return;
                            setDialogState(() => saving = false);
                            CustomDialog.showErrorSnack(
                              dialogContext,
                              e.toString().replaceFirst('Exception: ', ''),
                            );
                          }
                        },
                  child: Text(saving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    if (saved == true && mounted) {
      CustomDialog.showSuccessSnack(
        context,
        existing == null ? 'Category added' : 'Category updated',
      );
      await _load();
    }
  }

  Future<void> _setActive(CategoryModel category, bool active) async {
    try {
      final token = await _token();
      if (active) {
        await _service.update(
          token: token,
          id: category.id,
          name: category.name,
          isActive: true,
        );
      } else {
        await _service.delete(token: token, id: category.id);
      }
      if (!mounted) return;
      CustomDialog.showSuccessSnack(
        context,
        active ? 'Category activated' : 'Category deactivated',
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      CustomDialog.showErrorSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _deletePermanent(CategoryModel category) async {
    final confirmed = await CustomDialog.showConfirm(
      context: context,
      title: 'Delete ${category.name}?',
      message:
          'This removes the category permanently. The delete is rejected if any business still uses it.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;

    try {
      final token = await _token();
      await _service.delete(token: token, id: category.id, hard: true);
      if (!mounted) return;
      CustomDialog.showSuccessSnack(context, 'Category deleted');
      await _load();
    } catch (e) {
      if (!mounted) return;
      CustomDialog.showErrorSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.appBarBg,
        foregroundColor: AppColors.appBarText,
        surfaceTintColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: AppColors.appBarBorder),
        ),
        title: const Text(
          'Categories',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.appBarText,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.appBarIcon),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search categories',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.input,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.input,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _filterChip('All', null),
                const SizedBox(width: 8),
                _filterChip('Active', true),
                const SizedBox(width: 8),
                _filterChip('Inactive', false),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool? value) {
    final selected = _activeFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _activeFilter = value);
        _load();
      },
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryDark : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }

  Widget _body() {
    if (_loading && _categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_categories.isEmpty) {
      return const Center(
        child: Text(
          'No categories yet',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final businessCount = category.businesses.length;
          return Material(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.card,
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                title: Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  businessCount == 0
                      ? (category.isActive ? 'Active' : 'Inactive')
                      : '${category.isActive ? 'Active' : 'Inactive'} · $businessCount businesses',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: category.isActive
                            ? AppColors.creditBg
                            : AppColors.surfaceMuted,
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        category.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: category.isActive
                              ? AppColors.credit
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        switch (action) {
                          case 'edit':
                            _openEditor(existing: category);
                          case 'toggle':
                            _setActive(category, !category.isActive);
                          case 'delete':
                            _deletePermanent(category);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(
                            category.isActive ? 'Deactivate' : 'Activate',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete permanently'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
