import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Windows USB barcode scanners type like a keyboard and finish with Enter.
/// This dialog keeps a field focused so the scan is captured, then returns it.
Future<String?> showWindowsBarcodeScanner(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _WindowsBarcodeScannerDialog(),
  );
}

class _WindowsBarcodeScannerDialog extends StatefulWidget {
  const _WindowsBarcodeScannerDialog();

  @override
  State<_WindowsBarcodeScannerDialog> createState() =>
      _WindowsBarcodeScannerDialogState();
}

class _WindowsBarcodeScannerDialogState
    extends State<_WindowsBarcodeScannerDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _burstTimer;
  DateTime? _lastKeyAt;
  int _fastKeys = 0;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _focusNode.onKeyEvent = _onKey;
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _burstTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _clean(String raw) {
    return raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
  }

  void _accept() {
    if (_closed) return;
    final code = _clean(_controller.text);
    if (code.length < 3) return;
    _closed = true;
    Navigator.of(context).pop(code);
  }

  void _onChanged(String value) {
    final now = DateTime.now();
    if (_lastKeyAt != null &&
        now.difference(_lastKeyAt!).inMilliseconds < 45) {
      _fastKeys++;
    } else {
      _fastKeys = 0;
    }
    _lastKeyAt = now;

    _burstTimer?.cancel();
    _burstTimer = Timer(const Duration(milliseconds: 140), () {
      // A USB scanner types the whole code in one burst, often without Enter.
      if (_fastKeys >= 4) _accept();
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.tab ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _accept();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ready = _focusNode.hasFocus;
    final width = MediaQuery.sizeOf(context).width;
    final dialogWidth = width >= 720 ? 480.0 : width - 48;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.qr_code_scanner_rounded, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan barcode',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'USB scanner on this Windows PC',
                          style: TextStyle(fontSize: 12, color: Color(0xFF5C6778)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: ready
                      ? const Color(0xFFE7F2EB)
                      : const Color(0xFFFFF6E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      ready
                          ? Icons.check_circle_rounded
                          : Icons.touch_app_rounded,
                      size: 18,
                      color: ready
                          ? const Color(0xFF2F6B4A)
                          : const Color(0xFF9A6B12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ready
                            ? 'Scanner ready. Scan the product barcode now.'
                            : 'Click the box below, then scan.',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
                onChanged: _onChanged,
                onSubmitted: (_) => _accept(),
                onTap: () => _focusNode.requestFocus(),
                decoration: InputDecoration(
                  hintText: 'Barcode appears here',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                    color: Colors.grey.shade500,
                  ),
                  filled: true,
                  fillColor: const Color(0xffFAFBFD),
                  prefixIcon: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: cs.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: ready ? cs.primary : Colors.grey.shade300,
                      width: ready ? 1.6 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cs.primary, width: 1.8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Point the USB scanner at the code. You can also type a barcode and press Use barcode.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.35),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _accept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Use barcode'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
