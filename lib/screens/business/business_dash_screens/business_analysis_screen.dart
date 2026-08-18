import 'package:bigreminder/screens/business/business_purchase_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/business/business_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../utils/enum_classes.dart';

const int kMaxAnalysisMonths = 36;

class BusinessAnalysisScreen extends ConsumerStatefulWidget {
  const BusinessAnalysisScreen({super.key});

  @override
  ConsumerState<BusinessAnalysisScreen> createState() =>
      _BusinessAnalysisScreenState();
}

class _BusinessAnalysisScreenState
    extends ConsumerState<BusinessAnalysisScreen> {
  late final TextEditingController _monthController;

  @override
  void initState() {
    super.initState();
    _monthController = TextEditingController();
  }

  @override
  void dispose() {
    _monthController.dispose();
    super.dispose();
  }

  void _applyManualMonths() {
    final raw = _monthController.text.trim();
    if (raw.isEmpty) return;

    int? value = int.tryParse(raw);
    if (value == null) return;

    if (value < 1) value = 1;
    if (value > kMaxAnalysisMonths) value = kMaxAnalysisMonths;

    ref.read(analysisMonthsProvider.notifier).state = value;
    _monthController.text = value.toString();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final accent = theme.colorScheme.primary;

    final analysis = ref.watch(businessAnalysisProvider);
    final selectedMonths = ref.watch(analysisMonthsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: accent,
        elevation: 0,
        title: const Text(
          "Business Analysis",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17
          ),
        ),
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: analysis.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: accent),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      e.toString(),
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            data: (data) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _FilterPanel(
                    theme: theme,
                    selectedMonths: selectedMonths,
                    monthController: _monthController,
                    onQuickSelect: (v) {
                      ref.read(analysisMonthsProvider.notifier).state = v;
                      _monthController.clear();
                    },
                    onManualApply: _applyManualMonths,
                  ),
                  const SizedBox(height: 10),
                  if (data.monthlyRevenue.isEmpty)
                    _buildEmptyState(theme)
                  else
                    for (int i = 0; i < data.monthlyRevenue.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AnalysisCard(
                          month: data.monthlyRevenue[i].month,
                          revenue: data.monthlyRevenue[i].value,
                          purchase: data.monthlyPurchaseRevenue[i].value,
                          expense: data.monthlyExpense[i].value,
                          profit: data.monthlyProfit[i].value,
                          theme: theme,
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final accent = theme.colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bar_chart_rounded, size: 56, color: accent),
            ),
            const SizedBox(height: 20),
            Text(
              "No Data Available",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No analysis data for the selected period.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- Filter Panel ----------------

class _FilterPanel extends StatelessWidget {
  final ThemeData theme;
  final int selectedMonths;
  final TextEditingController monthController;
  final ValueChanged<int> onQuickSelect;
  final VoidCallback onManualApply;

  const _FilterPanel({
    required this.theme,
    required this.selectedMonths,
    required this.monthController,
    required this.onQuickSelect,
    required this.onManualApply,
  });

  static const _quickOptions = [1, 3, 6, 12];

  @override
  Widget build(BuildContext context) {
    final accent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                "PERIOD",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _quickOptions)
                _MonthChip(
                  label: m == 1 ? "1 Month" : "$m Months",
                  selected: selectedMonths == m,
                  theme: theme,
                  onTap: () => onQuickSelect(m),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: monthController,
                    keyboardType: TextInputType.number,
                    style: theme.textTheme.bodyMedium,
                    onSubmitted: (_) => onManualApply(),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                      _MonthRangeFormatter(maxMonths: kMaxAnalysisMonths),
                    ],
                    decoration: InputDecoration(
                      hintText: "Custom (1–$kMaxAnalysisMonths months)",
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 14
                      ),
                      isDense: true,
                      prefixIcon: Icon(
                        Icons.edit_calendar_outlined,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        size: 20,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 14,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: accent, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: accent,
                borderRadius: BorderRadius.circular(14),
                elevation: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onManualApply,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    child: Icon(Icons.check_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
          if (selectedMonths > 12) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 15, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Showing last $selectedMonths months (max $kMaxAnalysisMonths)",
                      style: TextStyle(
                        color: accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
/// Custom formatter to restrict month input to valid range
class _MonthRangeFormatter extends TextInputFormatter {
  final int maxMonths;

  _MonthRangeFormatter({required this.maxMonths});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // If empty, allow it
    if (newValue.text.isEmpty) return newValue;

    // Parse the new value
    final int? value = int.tryParse(newValue.text);

    // If not a valid number, return old value
    if (value == null) return oldValue;

    // Clamp between 1 and maxMonths
    if (value < 1 || value > maxMonths) {
      // If typing more than 2 digits or invalid number, prevent input
      if (newValue.text.length > 2) {
        return oldValue;
      }

      // Auto-correct to nearest valid value
      if (value > maxMonths) {
        return TextEditingValue(
          text: maxMonths.toString(),
          selection: TextSelection.collapsed(offset: maxMonths.toString().length),
        );
      }
      return oldValue;
    }

    return newValue;
  }
}
class _MonthChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _MonthChip({
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = theme.colorScheme.primary;

    return Material(
      color: selected ? accent.withOpacity(0.12) : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : Colors.grey.shade200,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: selected ? accent : theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------- Analysis Card ----------------

class AnalysisCard extends StatelessWidget {
  final String month;
  final double revenue;
  final double purchase;
  final double expense;
  final double profit;
  final ThemeData theme;

  const AnalysisCard({
    super.key,
    required this.month,
    required this.revenue,
    required this.purchase,
    required this.expense,
    required this.profit,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isProfit = profit >= 0;
    final profitColor = isProfit ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    month,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: profitColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: profitColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 15,
                      color: profitColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isProfit ? "PROFIT" : "LOSS",
                      style: TextStyle(
                        color: profitColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MetricRow(
            icon: Icons.trending_up_rounded,
            label: "Revenue",
            value: revenue,
            color: Colors.green,
            theme: theme,
          ),
          const SizedBox(height: 6),
          _MetricRow(
            icon: Icons.shopping_bag_outlined,
            label: "Purchase",
            value: purchase,
            color: Colors.blue,
            theme: theme,
          ),
          const SizedBox(height: 6),
          _MetricRow(
            icon: Icons.receipt_long_outlined,
            label: "Expense",
            value: expense,
            color: Colors.red,
            theme: theme,
          ),
          Divider(color: theme.dividerColor.withOpacity(0.1),thickness: 2,),
          _MetricRow(
            icon: Icons.account_balance_wallet_outlined,
            label: "Net Profit",
            value: profit,
            color: profitColor,
            theme: theme,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final ThemeData theme;
  final bool emphasized;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: emphasized ? 14 : 13.5,
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          "₹${value.toStringAsFixed(2)}",
          style: TextStyle(
            color: emphasized ? color : theme.colorScheme.onSurface,
            fontSize: emphasized ? 17 : 14,
            fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}