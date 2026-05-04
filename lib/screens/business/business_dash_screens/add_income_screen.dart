import 'package:bigreminder/widgets/custom_dialog.dart';
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
  final sourceCtrl = TextEditingController();

  bool loading = false;

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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔵 HEADER CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "New Income",
                    style: TextStyle(color: Colors.white,fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Track your earnings easily",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 💳 INPUT CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [

                  /// 💰 AMOUNT
                  _inputField(
                    controller: amountCtrl,
                    label: "Amount",
                    hint: "Enter amount",
                    icon: Icons.currency_rupee,
                    keyboard: TextInputType.number,
                  ),

                  const SizedBox(height: 14),

                  /// 🏷 SOURCE
                  _inputField(
                    controller: sourceCtrl,
                    label: "Source",
                    hint: "e.g. UPI / Cash / Bank",
                    icon: Icons.account_balance_wallet,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 🚀 BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  "Add Income",
                  style: TextStyle(
                    fontSize: 16,
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

  /// 🔥 SUBMIT
  Future<void> _submit() async {
    try {
      setState(() => loading = true);

      final amount = double.tryParse(amountCtrl.text.trim());

      if (amount == null || amount <= 0) {
        throw "Enter valid amount";
      }

      final businessId = ref.read(businessIdProvider);

      final req = BusinessIncomeRequest(
        amount: double.parse(amount.toStringAsFixed(2)),
        source: sourceCtrl.text.trim(),
        businessId: businessId,
      );

      await ref.read(incomeServiceProvider).addIncome(req);

      _showSnack("Income added successfully");

      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.pop(context, true); // 🔥 RETURN TRUE
      });
      amountCtrl.clear();
      sourceCtrl.clear();
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// 💬 SNACK
  void _showSnack(String msg) {
    CustomDialog.showSuccessSnack(context, msg);
  }

  /// 🎨 INPUT FIELD
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
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: cs.primary),
            filled: true,
            fillColor: cs.onSurface.withOpacity(0.05),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}