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
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Main Field
        GestureDetector(
          onTap: () {
            setState(() => isOpen = !isOpen);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: hasError
                  ? Border.all(color: Colors.red, width: 1.2)
                  : isOpen
                  ? Border.all(color: Colors.blueGrey, width: 1.2)
                  : null,
            ),
            child: Row(
              children: [
                const Icon(Icons.business, size: 20, color: Color(0xFF6B7280)),
                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    widget.selectedRole ?? widget.hint,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: widget.selectedRole == null
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF1F2937),
                    ),
                  ),
                ),

                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down,
                      color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ),

        /// Error Text
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),

        /// Dropdown List
        if (isOpen)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: widget.roles.map((role) {
                return InkWell(
                  onTap: () {
                    widget.onChanged(role);
                    setState(() => isOpen = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        _getRoleIcon(role),
                        const SizedBox(width: 10),
                        Text(
                          role,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2937),
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
  Widget _getRoleIcon(String role) {
    switch (role.toLowerCase()) {

      case 'general store':
        return const Icon(Icons.storefront, size: 18);

      case 'gym':
        return const Icon(Icons.fitness_center, size: 18);

      case 'medical':
        return const Icon(Icons.local_hospital, size: 18);

      case 'salon':
        return const Icon(Icons.content_cut, size: 18);

      case 'restaurant':
        return const Icon(Icons.restaurant, size: 18);

      case 'repair shop':
        return const Icon(Icons.build, size: 18);

      case 'clothing':
        return const Icon(Icons.checkroom, size: 18);

      case 'electronics':
        return const Icon(Icons.devices, size: 18);

      case 'other':
        return const Icon(Icons.more_horiz, size: 18);

      default:
        return const Icon(Icons.work_outline, size: 18);
    }
  }
}