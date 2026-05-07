import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

      // ✅ keep only last 2 days
      if (now - time <= 2 * 24 * 60 * 60 * 1000) {
        _history.add(decoded);
      }
    }

    setState(() {});
    await _saveHistory(); // clean expired from storage
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
        // Prevent double operators
          if (_isOperator(value) &&
              _input.isNotEmpty &&
              _isOperator(_input[_input.length - 1])) {
            _input = _input.substring(0, _input.length - 1);
          }

          // After evaluation, pressing operator continues, pressing digit resets
          if (_justEvaluated) {
            if (_isOperator(value)) {
              _input = _result + value;
            } else {
              _input = value;
            }
            _justEvaluated = false;
          } else {
            // Prevent multiple decimals in same number segment
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

    // ✅ Whole number
    if (val % 1 == 0 && val.abs() < 1e15) {
      return _addCommas(val.toInt().toString());
    }

    // ✅ Limit to 2 decimal places
    String fixed = val.toStringAsFixed(2);

    // ✅ Remove trailing .00 (premium UX)
    if (fixed.endsWith(".00")) {
      return _addCommas(val.toInt().toString());
    }

    // ✅ Handle decimal part with commas in integer part
    final parts = fixed.split(".");
    final intPart = _addCommas(parts[0]);
    final decimalPart = parts.length > 1 ? parts[1] : "";

    return "$intPart.$decimalPart";
  }
  String _addCommas(String number) {
    final isNeg = number.startsWith('-');
    final digits = isNeg ? number.substring(1) : number;
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return isNeg ? '-${buffer.toString()}' : buffer.toString();
  }

  void _clearAll() {
    HapticFeedback.heavyImpact();
    setState(() {
      _input = "";
      _result = "0";
      _justEvaluated = false;
    });
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cs),
            _buildDisplay(cs),
            if (_history.isNotEmpty) _buildHistory(cs),
            const Spacer(),
            _buildKeypad(cs, mq),
            SizedBox(height: mq.padding.bottom > 0 ? 8 : 16),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // ✅ Android-style back button (not iOS chevron)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            "Calculator",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          if (_history.isNotEmpty)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _history.clear());
                _saveHistory();
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Clear History",
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── DISPLAY ──────────────────────────────────────────────────────────────

  Widget _buildDisplay(ColorScheme cs) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ✅ Input row with inline backspace X button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    _input.isEmpty ? "0" : _input,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // ✅ Inline delete (X) button — deletes one digit
              GestureDetector(
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
                child: Container(
                  width: 40,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.backspace_outlined,
                    color: Colors.white54,
                    size: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ✅ Result in distinct amber/gold — never same as primary
          ScaleTransition(
            scale: _resultScaleAnim,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(
                _result,
                style: TextStyle(
                  color: _result == "Error"
                      ? const Color(0xFFFF5B5B)
                      : const Color(0xFFF5C518),
                  fontSize: _result.length > 12 ? 28 : 42,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HISTORY ──────────────────────────────────────────────────────────────

  Widget _buildHistory(ColorScheme cs) {
    return Container(
      height: 150, // ✅ Fixed height 150
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(
              "HISTORY",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _history.length,
              itemBuilder: (_, i) {
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _input = _history[i]['exp'];
                      _result = _history[i]['res'];
                      _justEvaluated = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                        "${_history[i]['exp']} = ${_history[i]['res']}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── KEYPAD ───────────────────────────────────────────────────────────────

  Widget _buildKeypad(ColorScheme cs, MediaQueryData mq) {
    final rows = [
      ["C", "+/-", "%", "÷"],
      ["7", "8", "9", "×"],
      ["4", "5", "6", "-"],
      ["1", "2", "3", "+"],
      ["00", "0", ".", "="],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: row.asMap().entries.map((entry) {
                final btn = entry.value;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: entry.key == 0 ? 0 : 5,
                      right: entry.key == row.length - 1 ? 0 : 5,
                    ),
                    child: _CalcButton(
                      label: btn,
                      type: _buttonType(btn),
                      onTap: () => _onTap(btn),
                      onLongPress: btn == "C" ? _clearAll : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  _ButtonType _buttonType(String btn) {
    if (btn == "=") return _ButtonType.equals;
    if (["÷", "×", "-", "+"].contains(btn)) return _ButtonType.operator;
    if (["C", "+/-", "%"].contains(btn)) return _ButtonType.function;
    return _ButtonType.digit; // 0-9, 00, .
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

  const _CalcButton({
    required this.label,
    required this.type,
    required this.onTap,
    this.onLongPress,
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
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.91).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.type) {
      case _ButtonType.equals:
        return const Color(0xFFF5C518);
      case _ButtonType.operator:
        return const Color(0xFF2A2A2A);
      case _ButtonType.function:
        return const Color(0xFF2D2D2D);
      case _ButtonType.digit:
        return const Color(0xFF1E1E1E);
    }
  }

  Color get _textColor {
    switch (widget.type) {
      case _ButtonType.equals:
        return const Color(0xFF0F0F0F);
      case _ButtonType.operator:
        return const Color(0xFFF5C518);
      case _ButtonType.function:
        return const Color(0xFFCCCCCC);
      case _ButtonType.digit:
        return Colors.white;
    }
  }

  // ✅ digits + function buttons (0-9, +/-, %, C) → w600
  // ✅ operators (÷ × - +) + equals → w700
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
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(18),
            border: widget.type == _ButtonType.digit
                ? Border.all(color: Colors.white.withOpacity(0.04))
                : null,
            boxShadow: widget.type == _ButtonType.equals
                ? [
              BoxShadow(
                color: const Color(0xFFF5C518).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: _textColor,
                fontSize: widget.label.length > 2 ? 16 : 22,
                fontWeight: _fontWeight,
                letterSpacing: widget.type == _ButtonType.operator ? 0.5 : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}