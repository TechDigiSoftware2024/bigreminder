import 'package:flutter/material.dart';

class CustomDropdown extends FormField<String> {
  CustomDropdown({
    super.key,
    required List<String> roles,
    required Function(String) onChanged,
    String? selectedRole,
    String hint = "Select Role",
    String? Function(String?)? validator,
  }) : super(
          initialValue: selectedRole,
          validator: validator,
          builder: (FormFieldState<String> state) {
            return _DropdownBody(
              roles: roles,
              selectedRole: state.value,
              hint: hint,
              errorText: state.errorText,
              onChanged: (value) {
                state.didChange(value);
                onChanged(value);
              },
            );
          },
        );
}

class _DropdownBody extends StatefulWidget {
  final List<String> roles;
  final String? selectedRole;
  final Function(String) onChanged;
  final String hint;
  final String? errorText;

  const _DropdownBody({
    required this.roles,
    required this.onChanged,
    required this.selectedRole,
    required this.hint,
    this.errorText,
  });

  @override
  State<_DropdownBody> createState() => _DropdownBodyState();
}

class _DropdownBodyState extends State<_DropdownBody> {
  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => isOpen = !isOpen),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: hasError
                  ? Border.all(color: scheme.error, width: 1.2)
                  : isOpen
                      ? Border.all(color: scheme.primary, width: 1.2)
                      : Border.all(color: scheme.outline, width: 1.2),
            ),
            child: Row(
              children: [
                Icon(
                  widget.selectedRole != null
                      ? _roleIcon(widget.selectedRole!)
                      : Icons.category_outlined,
                  size: 20,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.selectedRole ?? widget.hint,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: widget.selectedRole == null
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
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
              style: TextStyle(
                color: scheme.error,
                fontSize: 12,
              ),
            ),
          ),
        if (isOpen)
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
                )
              ],
            ),
            child: Column(
              children: widget.roles.map((role) {
                final selected = widget.selectedRole == role;
                return InkWell(
                  onTap: () {
                    widget.onChanged(role);
                    setState(() => isOpen = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    color: selected
                        ? scheme.primary.withValues(alpha: 0.08)
                        : null,
                    child: Row(
                      children: [
                        Icon(
                          _roleIcon(role),
                          size: 18,
                          color: selected
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          role,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? scheme.primary
                                : scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  IconData _roleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'general store':
        return Icons.storefront;
      case 'gym':
        return Icons.fitness_center;
      case 'medical':
        return Icons.local_hospital;
      case 'salon':
        return Icons.content_cut;
      case 'restaurant':
        return Icons.restaurant;
      case 'repair shop':
        return Icons.build;
      case 'clothing':
        return Icons.checkroom;
      case 'electronics':
        return Icons.devices;
      case 'other':
        return Icons.more_horiz;
      default:
        return Icons.work_outline;
    }
  }
}
