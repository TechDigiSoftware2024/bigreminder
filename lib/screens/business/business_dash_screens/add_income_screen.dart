import 'package:bigreminder/widgets/custom_dialog.dart';
import 'package:bigreminder/widgets/custom_dropdown.dart';
import 'package:bigreminder/widgets/custom_dropdown_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/business_models/business_income_req_model.dart';
import '../../../providers/business/business_provider.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  final amountCtrl = TextEditingController();
  final remarkCtrl = TextEditingController();

  bool loading = false;
  String? selectedSource;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        title: const Text(
          "Add Income",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            /// HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
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

            const SizedBox(height: 16),

            /// INPUT CARD
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _inputField(
                    controller: amountCtrl,
                    label: "Amount",
                    hint: "Enter amount",
                    icon: Icons.currency_rupee,
                    keyboard: TextInputType.number,
                  ),

                  const SizedBox(height: 6),

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
                    onChanged: (value) {
                      setState(() {
                        selectedSource = value;
                      });
                    },
                  ),

                  const SizedBox(height: 6),

                  _inputField(
                    controller: remarkCtrl,
                    label: "Income Remarks",
                    hint: "e.g. Fees / Product sold",
                    icon: Icons.description_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                  height: 18,
                  width: 18,
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// SUBMIT
  Future<void> _submit() async {
    try {
      setState(() => loading = true);

      final amount = double.tryParse(amountCtrl.text.trim());

      if (amount == null || amount <= 0) {
        return _showSnack(
          "Enter valid amount",
          isSuccess: false,
        );
      }

      final businessId = ref.read(businessIdProvider);

      final req = BusinessIncomeRequest(
        amount: double.parse(amount.toStringAsFixed(2)),
        source: selectedSource.toString().toLowerCase(),
        remark: remarkCtrl.toString().toLowerCase(),
        businessId: businessId,
      );

      await ref.read(incomeServiceProvider).addIncome(req);

      _showSnack(
        "Income added successfully",
        isSuccess: true,
      );

      Future.delayed(
        const Duration(milliseconds: 300),
            () {
          Navigator.pop(context, true);
        },
      );

      amountCtrl.clear();
    } catch (e) {
      _showSnack(
        parseApiError(e),
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
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
  /// SNACK
  void _showSnack(
      String msg, {
        required bool isSuccess,
      }) {
    if (isSuccess) {
      CustomDialog.showSuccessSnack(context, msg);
    } else {
      CustomDialog.showErrorSnack(context, msg);
    }
  }

  /// INPUT FIELD
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
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

        const SizedBox(height: 4),

        TextField(
          controller: controller,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(
              icon,
              color: cs.primary,
              size: 20,
            ),
            filled: true,
            fillColor: cs.onSurface.withOpacity(0.01),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: cs.onSurface.withOpacity(.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: cs.primary.withOpacity(0.90,),
                width: 1.7
              ),
            ),
          ),
        ),
      ],
    );
  }
}