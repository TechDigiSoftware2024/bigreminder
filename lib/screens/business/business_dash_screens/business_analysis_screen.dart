import 'package:bigreminder/screens/business/business_purchase_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/business/business_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/enum_classes.dart';
import '../../../utils/formatters.dart';

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

    if (value < 1) {
      value = 1;
    }

    if (value > kMaxAnalysisMonths) {
      value = kMaxAnalysisMonths;
    }

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

    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: accent,
        elevation: 0,
        title: const Text(
          "Business Analysis",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),

      body: SafeArea(
        child: analysis.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: accent)),

          error: (e, _) => _AnalysisError(error: e.toString(), theme: theme),

          data: (data) {
            if (isDesktop) {
              return _DesktopAnalysisLayout(
                data: data,
                theme: theme,
                selectedMonths: selectedMonths,
                monthController: _monthController,
                onQuickSelect: (value) {
                  ref.read(analysisMonthsProvider.notifier).state = value;

                  _monthController.clear();
                },
                onManualApply: _applyManualMonths,
              );
            }

            return _MobileAnalysisLayout(
              data: data,
              theme: theme,
              selectedMonths: selectedMonths,
              monthController: _monthController,
              onQuickSelect: (value) {
                ref.read(analysisMonthsProvider.notifier).state = value;

                _monthController.clear();
              },
              onManualApply: _applyManualMonths,
            );
          },
        ),
      ),
    );
  }
}

class _MobileAnalysisLayout extends StatelessWidget {
  final dynamic data;
  final ThemeData theme;

  final int selectedMonths;
  final TextEditingController monthController;

  final ValueChanged<int> onQuickSelect;
  final VoidCallback onManualApply;

  const _MobileAnalysisLayout({
    required this.data,
    required this.theme,
    required this.selectedMonths,
    required this.monthController,
    required this.onQuickSelect,
    required this.onManualApply,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // ================= PERIOD =================
        _FilterPanel(
          theme: theme,
          selectedMonths: selectedMonths,
          monthController: monthController,
          onQuickSelect: onQuickSelect,
          onManualApply: onManualApply,
          desktop: false,
        ),

        const SizedBox(height: 10),

        // ================= ANALYSIS =================
        if (data.monthlyRevenue.isEmpty)
          _AnalysisEmptyState(theme: theme)
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
  }
}

class _DesktopAnalysisLayout extends StatelessWidget {
  final dynamic data;
  final ThemeData theme;

  final int selectedMonths;
  final TextEditingController monthController;

  final ValueChanged<int> onQuickSelect;
  final VoidCallback onManualApply;

  const _DesktopAnalysisLayout({
    required this.data,
    required this.theme,
    required this.selectedMonths,
    required this.monthController,
    required this.onQuickSelect,
    required this.onManualApply,
  });

  @override
  Widget build(BuildContext context) {
    final accent = theme.colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =====================================================
        // LEFT SIDE
        // MONTHLY ANALYSIS
        // =====================================================
        Expanded(
          flex: 7,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(36, 28, 20, 32),
            children: [
              // ================= HEADER =================
              Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      color: accent,
                      fontWeight: FontWeight.bold,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Business Analysis",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        "Monthly financial performance",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(.55),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ================= LIST =================
              if (data.monthlyRevenue.isEmpty)
                _AnalysisEmptyState(theme: theme)
              else
                for (int i = 0; i < data.monthlyRevenue.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
          ),
        ),

        // =====================================================
        // VERTICAL DIVIDER
        // =====================================================
        Container(width: 1, color: theme.dividerColor.withOpacity(.12)),

        // =====================================================
        // RIGHT SIDE
        // PERIOD
        // =====================================================
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 36, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= TITLE =================
                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.timeline_rounded,
                        color: accent,
                        size: 21,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Period",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          "Select analysis period",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(.55),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ================= BIG PERIOD PANEL =================
                _FilterPanel(
                  theme: theme,
                  selectedMonths: selectedMonths,
                  monthController: monthController,
                  onQuickSelect: onQuickSelect,
                  onManualApply: onManualApply,
                  desktop: true,
                ),
              ],
            ),
          ),
        ),
      ],
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

  final bool desktop;

  const _FilterPanel({
    required this.theme,
    required this.selectedMonths,
    required this.monthController,
    required this.onQuickSelect,
    required this.onManualApply,
    this.desktop = false,
  });

  static const _quickOptions = [1, 3, 6, 12];

  @override
  Widget build(BuildContext context) {
    final accent = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(desktop ? 22 : 18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(desktop ? 20 : 18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===================================================
          // PERIOD LABEL
          // ===================================================
          Row(
            children: [
              Icon(
                Icons.timeline_rounded,
                size: desktop ? 19 : 16,
                color: accent,
              ),

              const SizedBox(width: 8),

              Text(
                "PERIOD",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  fontSize: desktop ? 11 : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ===================================================
          // DESKTOP = VERTICAL
          // MOBILE = WRAP
          // ===================================================
          if (desktop)
            Column(
              children: [
                for (int i = 0; i < _quickOptions.length; i++) ...[
                  _DesktopMonthOption(
                    months: _quickOptions[i],
                    selected: selectedMonths == _quickOptions[i],
                    theme: theme,
                    onTap: () => onQuickSelect(_quickOptions[i]),
                  ),

                  if (i != _quickOptions.length - 1) const SizedBox(height: 10),
                ],
              ],
            )
          else
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

          const SizedBox(height: 16),

          // ===================================================
          // CUSTOM MONTHS
          // ===================================================
          Text(
            "Custom period",
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(.65),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: desktop ? 46 : 40,
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
                      hintText: "1–$kMaxAnalysisMonths months",
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(.4),
                      ),
                      prefixIcon: Icon(
                        Icons.edit_calendar_outlined,
                        color: theme.colorScheme.onSurface.withOpacity(.4),
                        size: desktop ? 21 : 20,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
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

              const SizedBox(width: 10),

              Material(
                color: accent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onManualApply,
                  child: SizedBox(
                    height: desktop ? 46 : 40,
                    width: desktop ? 52 : 44,
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ===================================================
          // INFO
          // ===================================================
          if (selectedMonths > 12) ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: accent.withOpacity(.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 15, color: accent),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      "Showing last "
                      "$selectedMonths months "
                      "(max "
                      "$kMaxAnalysisMonths)",
                      style: TextStyle(
                        color: accent,
                        fontSize: desktop ? 12 : 11.5,
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

class _DesktopMonthOption extends StatelessWidget {
  final int months;
  final bool selected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _DesktopMonthOption({
    required this.months,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = theme.colorScheme.primary;

    final label = months == 1 ? "1 Month" : "$months Months";

    return Material(
      color: selected ? accent.withOpacity(.10) : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent : Colors.grey.shade200,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withOpacity(.12)
                      : theme.colorScheme.onSurface.withOpacity(.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: selected
                      ? accent
                      : theme.colorScheme.onSurface.withOpacity(.55),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? accent : theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),

              if (selected)
                Icon(Icons.check_circle_rounded, color: accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisError extends StatelessWidget {
  final String error;
  final ThemeData theme;

  const _AnalysisError({required this.error, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),

            const SizedBox(height: 16),

            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisEmptyState extends StatelessWidget {
  final ThemeData theme;

  const _AnalysisEmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    final accent = theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accent.withOpacity(.1),
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
                color: theme.colorScheme.onSurface.withOpacity(.6),
              ),
            ),
          ],
        ),
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
          selection: TextSelection.collapsed(
            offset: maxMonths.toString().length,
          ),
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
              color: selected
                  ? accent
                  : theme.colorScheme.onSurface.withOpacity(0.6),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: profitColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: profitColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfit
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
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
          Divider(color: theme.dividerColor.withOpacity(0.1), thickness: 2),
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
          AppFormatters.currency(value),
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
