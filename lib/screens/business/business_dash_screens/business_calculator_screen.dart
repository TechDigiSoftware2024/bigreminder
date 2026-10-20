import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme/app_colors.dart';

class BusinessCalculatorScreen extends StatefulWidget {
  const BusinessCalculatorScreen({super.key});

  @override
  State<BusinessCalculatorScreen> createState() =>
      _BusinessCalculatorScreenState();
}

class _BusinessCalculatorScreenState extends State<BusinessCalculatorScreen>
    with TickerProviderStateMixin {
  String _input = "";
  String _result = "0";
  bool _justEvaluated = false;
  final List<Map<String, dynamic>> _history = [];

  late AnimationController _resultAnimController;
  late Animation<double> _resultScaleAnim;

  static const _historyKey = "calc_history";

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _history.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(_historyKey, data);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_historyKey) ?? [];

    final now = DateTime.now().millisecondsSinceEpoch;

    _history.clear();

    for (var item in data) {
      final decoded = jsonDecode(item);
      final time = decoded['time'];

      // Keep only last 2 days
      if (now - time <= 2 * 24 * 60 * 60 * 1000) {
        _history.add(Map<String, dynamic>.from(decoded));
      }
    }

    if (mounted) setState(() {});
    await _saveHistory();
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _resultScaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _resultAnimController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _resultAnimController.dispose();
    super.dispose();
  }

  // ─── BUTTON HANDLER ───────────────────────────────────────────────────────

  void _onTap(String value) {
    HapticFeedback.lightImpact();

    setState(() {
      switch (value) {
        case "C":
          _input = "";
          _result = "0";
          _justEvaluated = false;
          break;

        case "⌫":
          if (_input.isNotEmpty) {
            _input = _input.substring(0, _input.length - 1);
            _justEvaluated = false;
            _liveCalculate();
          }
          break;

        case "=":
          _calculate(finalEval: true);
          break;

        case "+/-":
          if (_input.isNotEmpty && _input != "0") {
            if (_input.startsWith("-")) {
              _input = _input.substring(1);
            } else {
              _input = "-$_input";
            }
            _liveCalculate();
          }
          break;

        case "00":
          if (_input.isNotEmpty) {
            _input += "00";
            _liveCalculate();
          }
          break;

        default:
          if (_isOperator(value) &&
              _input.isNotEmpty &&
              _isOperator(_input[_input.length - 1])) {
            _input = _input.substring(0, _input.length - 1);
          }

          if (_justEvaluated) {
            if (_isOperator(value)) {
              _input = _result.replaceAll(",", "") + value;
            } else {
              _input = value;
            }
            _justEvaluated = false;
          } else {
            if (value == ".") {
              final parts = _input.split(RegExp(r'[+\-×÷]'));
              if (parts.last.contains(".")) return;
            }
            _input += value;
          }
          _liveCalculate();
      }
    });
  }

  bool _isOperator(String ch) => ["+", "-", "×", "÷", "%"].contains(ch);

  void _liveCalculate() {
    if (_input.isEmpty) {
      _result = "0";
      return;
    }
    try {
      final res = _parseAndEvaluate(_input);
      if (res != null) _result = res;
    } catch (_) {}
  }

  void _calculate({bool finalEval = false}) {
    if (_input.isEmpty) return;
    try {
      final res = _parseAndEvaluate(_input);
      if (res == null) return;

      if (finalEval) {
        _history.insert(0, {
          "exp": _input,
          "res": res,
          "time": DateTime.now().millisecondsSinceEpoch,
        });
        // Cap stored history for snappy UI
        if (_history.length > 40) {
          _history.removeRange(40, _history.length);
        }
        _saveHistory();
        _resultAnimController.forward(from: 0);
        _justEvaluated = true;
        HapticFeedback.mediumImpact();
      }

      _result = res;
      if (finalEval) _input = res;
    } catch (_) {
      _result = "Error";
    }
  }

  String? _parseAndEvaluate(String expr) {
    try {
      String cleaned = expr
          .replaceAll("×", "*")
          .replaceAll("÷", "/")
          .replaceAll(",", "");

      cleaned = cleaned.replaceAllMapped(
        RegExp(r'(\d+(\.\d+)?)%'),
        (m) => "(${m[1]}/100)",
      );

      if (_isOperator(cleaned[cleaned.length - 1])) return null;

      final p = Parser();
      final exp = p.parse(cleaned);
      final cm = ContextModel();
      final val = exp.evaluate(EvaluationType.REAL, cm) as double;

      return _formatResult(val);
    } catch (_) {
      return null;
    }
  }

  String _formatResult(double val) {
    if (val.isNaN || val.isInfinite) return "Error";

    if (val % 1 == 0 && val.abs() < 1e15) {
      return _addCommas(val.toInt().toString());
    }

    String fixed = val.toStringAsFixed(2);

    if (fixed.endsWith(".00")) {
      return _addCommas(val.toInt().toString());
    }

    final parts = fixed.split(".");
    final intPart = _addCommas(parts[0]);
    final decimalPart = parts.length > 1 ? parts[1] : "";

    return "$intPart.$decimalPart";
  }

  String _addCommas(String number) {
    final isNeg = number.startsWith('-');
    final digits = isNeg ? number.substring(1) : number;
    if (digits.length <= 3) return number;

    final head = digits.substring(0, digits.length - 3);
    final tail = digits.substring(digits.length - 3);
    final groups = <String>[];
    var rest = head;
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    groups.add(tail);
    final formatted = groups.join(',');
    return isNeg ? '-$formatted' : formatted;
  }

  void _clearAll() {
    HapticFeedback.heavyImpact();
    setState(() {
      _input = "";
      _result = "0";
      _justEvaluated = false;
    });
  }

  void _clearHistory() {
    HapticFeedback.lightImpact();
    setState(() => _history.clear());
    _saveHistory();
  }

  void _deleteHistoryAt(int index) {
    HapticFeedback.selectionClick();
    setState(() => _history.removeAt(index));
    _saveHistory();
  }

  void _useHistoryItem(Map<String, dynamic> item, {bool useResult = true}) {
    HapticFeedback.selectionClick();
    setState(() {
      if (useResult) {
        _input = item['res'].toString();
        _result = item['res'].toString();
        _justEvaluated = true;
      } else {
        _input = item['exp'].toString();
        _justEvaluated = false;
        _liveCalculate();
      }
    });
  }

  String _relativeTime(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays == 1) return "Yesterday";
    return "${diff.inDays}d ago";
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mq = MediaQuery.of(context);
    final isDesktop = mq.size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isDesktop ? _buildDesktop(cs, mq) : _buildMobile(cs, mq),
      ),
    );
  }

  Widget _buildMobile(ColorScheme cs, MediaQueryData mq) {
    return Column(
      children: [
        _buildHeader(cs, showHistoryButton: true),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              children: [
                _buildDisplay(cs),
                const SizedBox(height: 12),
                if (_history.isNotEmpty) ...[
                  _buildRecentStrip(cs),
                  const SizedBox(height: 10),
                ],
                const Spacer(flex: 1),
                Expanded(
                  flex: 7,
                  child: _buildKeypad(cs, fill: true),
                ),
                SizedBox(height: mq.padding.bottom > 0 ? 6 : 10),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktop(ColorScheme cs, MediaQueryData mq) {
    return Column(
      children: [
        _buildHeader(cs, showHistoryButton: false),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _buildDisplay(cs, tall: true),
                      const SizedBox(height: 16),
                      Expanded(child: _buildKeypad(cs, fill: true)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 340,
                  child: _buildHistoryPanel(cs, embedded: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme cs, {required bool showHistoryButton}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: cs.onSurface,
              size: 24,
            ),
            tooltip: "Back",
          ),
          const SizedBox(width: 4),
          Text(
            "Calculator",
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          if (showHistoryButton)
            _HeaderAction(
              icon: Icons.history_rounded,
              label: _history.isEmpty ? null : "${_history.length}",
              tooltip: "History",
              color: cs.primary,
              onTap: _openHistorySheet,
            ),
        ],
      ),
    );
  }

  void _openHistorySheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _HistorySheet(
              history: _history,
              colorScheme: Theme.of(context).colorScheme,
              relativeTime: _relativeTime,
              onUseResult: (item) {
                Navigator.pop(ctx);
                _useHistoryItem(item, useResult: true);
              },
              onUseExpression: (item) {
                Navigator.pop(ctx);
                _useHistoryItem(item, useResult: false);
              },
              onDelete: (index) {
                _deleteHistoryAt(index);
                setSheetState(() {});
                if (_history.isEmpty && ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              onClearAll: () {
                _clearHistory();
                setSheetState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }

  // ─── DISPLAY ──────────────────────────────────────────────────────────────

  Widget _buildDisplay(ColorScheme cs, {bool tall = false}) {
    final resultLen = _result.replaceAll(",", "").length;
    final resultSize = resultLen > 14
        ? 28.0
        : resultLen > 10
            ? 34.0
            : 42.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, tall ? 28 : 20, 20, tall ? 28 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Live",
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              _MiniIconButton(
                icon: Icons.backspace_outlined,
                tooltip: "Backspace · hold to clear",
                color: cs.primary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (_input.isNotEmpty) {
                      _input = _input.substring(0, _input.length - 1);
                      _justEvaluated = false;
                      _liveCalculate();
                    }
                  });
                },
                onLongPress: _clearAll,
              ),
            ],
          ),
          SizedBox(height: tall ? 28 : 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              _input.isEmpty ? "0" : _input,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.45),
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ScaleTransition(
            scale: _resultScaleAnim,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(
                _result,
                style: TextStyle(
                  color: _result == "Error" ? cs.error : cs.onSurface,
                  fontSize: resultSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── RECENT STRIP (mobile quick access) ───────────────────────────────────

  Widget _buildRecentStrip(ColorScheme cs) {
    final recent = _history.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Text(
                "Recent",
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _openHistorySheet,
                child: Text(
                  "See all",
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final item = recent[i];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _useHistoryItem(item, useResult: true),
                  onLongPress: () => _useHistoryItem(item, useResult: false),
                  child: Ink(
                    width: 132,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['exp'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(0.45),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "= ${item['res']}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── HISTORY PANEL (desktop) ──────────────────────────────────────────────

  Widget _buildHistoryPanel(ColorScheme cs, {bool embedded = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 8),
            child: Row(
              children: [
                Icon(Icons.history_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "History",
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_history.isNotEmpty)
                  TextButton(
                    onPressed: _clearHistory,
                    style: TextButton.styleFrom(
                      foregroundColor: cs.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      "Clear",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Text(
              _history.isEmpty
                  ? "Your calculations will appear here"
                  : "${_history.length} recent · tap to reuse",
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.45),
                fontSize: 12,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _history.isEmpty
                ? _EmptyHistory(cs: cs)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      return _HistoryCard(
                        expression: _history[i]['exp'].toString(),
                        result: _history[i]['res'].toString(),
                        timeLabel: _relativeTime(_history[i]['time'] as int),
                        colorScheme: cs,
                        onTap: () =>
                            _useHistoryItem(_history[i], useResult: true),
                        onLongPress: () =>
                            _useHistoryItem(_history[i], useResult: false),
                        onDelete: () => _deleteHistoryAt(i),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ─── KEYPAD ───────────────────────────────────────────────────────────────

  Widget _buildKeypad(ColorScheme cs, {bool compact = false, bool fill = false}) {
    final rows = [
      ["C", "+/-", "%", "÷"],
      ["7", "8", "9", "×"],
      ["4", "5", "6", "-"],
      ["1", "2", "3", "+"],
      ["00", "0", ".", "="],
    ];

    // Small gap on all sides between buttons
    const gap = 5.0;

    final pad = Column(
      children: rows.asMap().entries.map((rowEntry) {
        final row = rowEntry.value;
        final isLastRow = rowEntry.key == rows.length - 1;

        final rowWidget = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: row.asMap().entries.map((entry) {
            final btn = entry.value;
            final isLastCol = entry.key == row.length - 1;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: isLastCol ? 0 : gap,
                ),
                child: _CalcButton(
                  label: btn,
                  type: _buttonType(btn),
                  height: fill ? null : (compact ? 68 : 90),
                  onTap: () => _onTap(btn),
                  onLongPress: btn == "C" ? _clearAll : null,
                ),
              ),
            );
          }).toList(),
        );

        if (fill) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLastRow ? 0 : gap),
              child: rowWidget,
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: isLastRow ? 0 : gap),
          child: SizedBox(
            height: compact ? 68 : 90,
            child: rowWidget,
          ),
        );
      }).toList(),
    );

    return pad;
  }

  _ButtonType _buttonType(String btn) {
    if (btn == "=") return _ButtonType.equals;
    if (["÷", "×", "-", "+"].contains(btn)) return _ButtonType.operator;
    if (["C", "+/-", "%"].contains(btn)) return _ButtonType.function;
    return _ButtonType.digit;
  }
}

// ─── SMALL UI PIECES ──────────────────────────────────────────────────────────

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: color),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _MiniIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            width: 40,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color.withOpacity(0.85), size: 18),
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final ColorScheme cs;

  const _EmptyHistory({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calculate_outlined,
                size: 28,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "No history yet",
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Press = to save calculations here\nfor quick reuse",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.5),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String expression;
  final String result;
  final String timeLabel;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.expression,
    required this.result,
    required this.timeLabel,
    required this.colorScheme,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: const Color(0xffF7F8FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expression,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "= $result",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.35),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(10),
                  child: Ink(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
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
        ),
      ),
    );
  }
}

class _HistorySheet extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final ColorScheme colorScheme;
  final String Function(int) relativeTime;
  final ValueChanged<Map<String, dynamic>> onUseResult;
  final ValueChanged<Map<String, dynamic>> onUseExpression;
  final ValueChanged<int> onDelete;
  final VoidCallback onClearAll;

  const _HistorySheet({
    required this.history,
    required this.colorScheme,
    required this.relativeTime,
    required this.onUseResult,
    required this.onUseExpression,
    required this.onDelete,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Icon(Icons.history_rounded, color: cs.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "History",
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        history.isEmpty
                            ? "Nothing here yet"
                            : "Tap result · long-press expression",
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.45),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (history.isNotEmpty)
                  TextButton(
                    onPressed: onClearAll,
                    style: TextButton.styleFrom(foregroundColor: cs.error),
                    child: const Text(
                      "Clear all",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: history.isEmpty
                ? _EmptyHistory(cs: cs)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      return _HistoryCard(
                        expression: history[i]['exp'].toString(),
                        result: history[i]['res'].toString(),
                        timeLabel: relativeTime(history[i]['time'] as int),
                        colorScheme: cs,
                        onTap: () => onUseResult(history[i]),
                        onLongPress: () => onUseExpression(history[i]),
                        onDelete: () => onDelete(i),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── BUTTON TYPES ─────────────────────────────────────────────────────────────

enum _ButtonType { digit, operator, function, equals }

// ─── CALC BUTTON WIDGET ───────────────────────────────────────────────────────

class _CalcButton extends StatefulWidget {
  final String label;
  final _ButtonType type;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double? height;

  const _CalcButton({
    required this.label,
    required this.type,
    required this.onTap,
    this.onLongPress,
    this.height,
  });

  @override
  State<_CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<_CalcButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _getBgColor(ColorScheme cs) {
    switch (widget.type) {
      case _ButtonType.equals:
        return cs.primary;
      case _ButtonType.operator:
        return cs.primaryContainer;
      case _ButtonType.function:
        return const Color(0xffEEF1F6);
      case _ButtonType.digit:
        return Colors.white;
    }
  }

  Color _getTextColor(ColorScheme cs) {
    switch (widget.type) {
      case _ButtonType.equals:
        return cs.onPrimary;
      case _ButtonType.operator:
        return cs.onPrimaryContainer;
      case _ButtonType.function:
        return cs.primary;
      case _ButtonType.digit:
        return cs.onSurface;
    }
  }

  FontWeight get _fontWeight {
    switch (widget.type) {
      case _ButtonType.digit:
        return FontWeight.w600;
      case _ButtonType.function:
        return FontWeight.w600;
      case _ButtonType.operator:
        return FontWeight.w700;
      case _ButtonType.equals:
        return FontWeight.w700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = _getBgColor(cs);
    final textColor = _getTextColor(cs);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: SizedBox(
          width: double.infinity,
          height: widget.height ?? double.infinity,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
              border: widget.type == _ButtonType.digit
                  ? Border.all(color: cs.outlineVariant.withOpacity(0.28))
                  : null,
              boxShadow: [
                BoxShadow(
                  color: widget.type == _ButtonType.equals
                      ? cs.primary.withOpacity(0.28)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: widget.type == _ButtonType.equals ? 14 : 6,
                  offset: Offset(0, widget.type == _ButtonType.equals ? 4 : 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: widget.label.length > 2 ? 16 : 22,
                  fontWeight: _fontWeight,
                  letterSpacing: widget.type == _ButtonType.operator ? 0.5 : 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
