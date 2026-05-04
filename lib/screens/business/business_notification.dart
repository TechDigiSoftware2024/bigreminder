import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/business_models/notification_req_model.dart';
import '../../providers/business/business_provider.dart';

class BusinessNotificationScreen extends ConsumerStatefulWidget {
  const BusinessNotificationScreen({super.key});

  @override
  ConsumerState<BusinessNotificationScreen> createState() =>
      _BusinessNotificationScreenState();
}

class _BusinessNotificationScreenState
    extends ConsumerState<BusinessNotificationScreen>
    with TickerProviderStateMixin {
  final titleController = TextEditingController();
  final messageController = TextEditingController();
  final customerIdController = TextEditingController();

  int? selectedCustomerId;
  String? selectedCustomerName;
  String searchQuery = "";

  String selectedType = "info";
  List<String> sendVia = ["push"];
  bool isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  final Map<String, IconData> _typeIcons = {
    "info": Icons.info_outline_rounded,
    "promo": Icons.local_offer_rounded,
    "alert": Icons.warning_amber_rounded,
  };

  /// Returns per-type accent colors derived entirely from the theme.
  Map<String, Color> _typeColors(ColorScheme cs) => {
    "info": cs.primary,
    "promo": cs.tertiary,
    "alert": cs.error,
  };
  Widget _customerField(ColorScheme cs) {
    return GestureDetector(
      onTap: _openCustomerDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.onSurface.withOpacity(0.07),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: cs.onSurface.withOpacity(0.5), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedCustomerId == null
                    ? "Search customer (name / number)"
                    : selectedCustomerName ?? "Selected",
                style: TextStyle(
                  color: selectedCustomerId == null
                      ? cs.onSurface.withOpacity(0.4)
                      : cs.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: cs.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    titleController.dispose();
    messageController.dispose();
    customerIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final business = ref.watch(businessIdProvider);
    return Scaffold(
      backgroundColor: cs.surface,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, cs),
      body: Stack(
        children: [
          _buildBackground(cs),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(cs),
                    const SizedBox(height: 28),
                    _buildTypeSelector(cs),
                    const SizedBox(height: 20),
                    _buildInputCard(context, cs),
                    const SizedBox(height: 20),
                    _buildChannelToggle(cs),
                    const SizedBox(height: 28),
                    _buildActions(context, cs),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── APP BAR ────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context, ColorScheme cs) {
    return AppBar(
      backgroundColor: cs.primary,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: BackButton(color: Colors.white),
      title: Text(
        "Notifications",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: IconButton(
            onPressed: _showHistoryDialog,
            icon: Icon(Icons.history_rounded, size: 18, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ),
        SizedBox(width: 10,)
      ],
    );
  }

  // ── BACKGROUND GLOWS ──────────────────────────────────────────

  Widget _buildBackground(ColorScheme cs) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [cs.primary.withOpacity(0.18), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [cs.primary.withOpacity(0.10), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "BROADCAST CENTER",
              style: TextStyle(
                color: cs.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Push the\nright message.",
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  // ── TYPE SELECTOR ─────────────────────────────────────────────

  Widget _buildTypeSelector(ColorScheme cs) {
    final typeColors = _typeColors(cs);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Notification Type", cs),
        const SizedBox(height: 10),
        Row(
          children: ["info", "promo", "alert"].map((type) {
            final isSelected = selectedType == type;
            final color = typeColors[type]!;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.15)
                        : cs.onSurface.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? color.withOpacity(0.6)
                          : cs.onSurface.withOpacity(0.08),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _typeIcons[type],
                        color: isSelected
                            ? color
                            : cs.onSurface.withOpacity(0.38),
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? color
                              : cs.onSurface.withOpacity(0.38),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── INPUT CARD ────────────────────────────────────────────────

  Widget _buildInputCard(BuildContext context, ColorScheme cs) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.onSurface.withOpacity(0.09)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel("Compose", cs),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                      child: _customerField(cs)),
                ],
              ),
              const SizedBox(height: 10),
              _glassTextField("Title", titleController, cs),
              const SizedBox(height: 10),
              _glassTextField("Message", messageController, cs, maxLines: 3),
            ],
          ),
        ),
      ),
    );
  }
  void _openCustomerDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await ref.read(customerProvider.future);

    Navigator.pop(context); // remove loader

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: _customerDialogContent(),
      ),
    );
  }
  Widget _customerDialogContent() {
    final cs = Theme.of(context).colorScheme;
    final customersAsync = ref.watch(customerProvider);

    String localSearch = "";

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [

              /// 🔍 SEARCH BAR (same glass style)
              TextField(
                onChanged: (val) {
                  setLocalState(() => localSearch = val);
                },
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: "Search customer",
                  hintStyle: TextStyle(
                      color: cs.onSurface.withOpacity(0.4)),
                  filled: true,
                  fillColor: cs.onSurface.withOpacity(0.06),
                  prefixIcon: Icon(Icons.search,
                      color: cs.onSurface.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// 📋 LIST
              Expanded(
                child: customersAsync.when(
                  data: (customers) {
                    final filtered = customers.where((c) {
                      final name = (c.name ?? "").toLowerCase();
                      final phone = (c.phone ?? "").toLowerCase();
                      return name.contains(localSearch.toLowerCase()) ||
                          phone.contains(localSearch.toLowerCase());
                    }).toList();

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final isSelected = selectedCustomerId == c.id;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCustomerId = c.id;
                              selectedCustomerName =
                              "${c.name ?? ""} (${c.phone ?? ""})";
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primary.withOpacity(0.15)
                                  : cs.onSurface.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? cs.primary.withOpacity(0.6)
                                    : cs.onSurface.withOpacity(0.07),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                  cs.primary.withOpacity(0.1),
                                  child: Text(
                                    (c.name ?? "C")[0].toUpperCase(),
                                    style: TextStyle(color: cs.primary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.name ?? "Customer",
                                        style: TextStyle(
                                          color: cs.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        c.phone ?? "",
                                        style: TextStyle(
                                          color: cs.onSurface
                                              .withOpacity(0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle,
                                      color: cs.primary),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                  const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const Text("Error loading customers"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  // ── CHANNEL TOGGLE ────────────────────────────────────────────

  Widget _buildChannelToggle(ColorScheme cs) {
    final channels = [
      {"id": "push", "label": "Push", "icon": Icons.notifications_rounded},
      {"id": "email", "label": "Email", "icon": Icons.email_rounded},
      {"id": "sms", "label": "SMS", "icon": Icons.sms_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Channels", cs),
        const SizedBox(height: 10),
        Row(
          children: channels.map((ch) {
            final id = ch["id"] as String;
            final isOn = sendVia.contains(id);
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isOn) {
                      if (sendVia.length > 1) sendVia.remove(id);
                    } else {
                      sendVia.add(id);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isOn
                        ? cs.primary.withOpacity(0.15)
                        : cs.onSurface.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isOn
                          ? cs.primary.withOpacity(0.5)
                          : cs.onSurface.withOpacity(0.07),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        ch["icon"] as IconData,
                        color: isOn
                            ? cs.primary
                            : cs.onSurface.withOpacity(0.24),
                        size: 18,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        ch["label"] as String,
                        style: TextStyle(
                          color: isOn
                              ? cs.primary
                              : cs.onSurface.withOpacity(0.30),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── ACTIONS ───────────────────────────────────────────────────

  Widget _buildActions(BuildContext context, ColorScheme cs) {
    final service = ref.read(notificationServiceProvider);

    final actions = [
      {
        "title": "Send Now",
        "subtitle": "Instant delivery",
        "icon": Icons.bolt_rounded,
        "fn": () => service.sendNow(_buildRequest()),
        "isPrimary": true,
      },
      {
        "title": "Send Custom",
        "subtitle": "With scheduling",
        "icon": Icons.schedule_send_rounded,
        "fn": () => service.send(_buildRequest()),
        "isPrimary": false,
      },
      {
        "title": "Broadcast",
        "subtitle": "All customers",
        "icon": Icons.cell_tower_rounded,
        "fn": () => service.broadcast(_buildRequest()),
        "isPrimary": false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Send", cs),
        const SizedBox(height: 12),
        ...actions.map((a) {
          final isPrimary = a["isPrimary"] as bool;
          return GestureDetector(
            onTap: isLoading
                ? null
                : () => _showConfirmDialog(
              context,
              title: a["title"] as String,
              subtitle: a["subtitle"] as String,
              icon: a["icon"] as IconData,
              cs: cs,
              onConfirm: () =>
                  _handleAction(a["fn"] as Future<void> Function()),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 10),
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: isPrimary
                    ? LinearGradient(
                  colors: [cs.primary, cs.primary.withOpacity(0.7)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
                    : null,
                color: isPrimary ? null : cs.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isPrimary
                      ? Colors.transparent
                      : cs.onSurface.withOpacity(0.08),
                ),
                boxShadow: isPrimary
                    ? [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isPrimary
                          ? cs.onPrimary.withOpacity(0.2)
                          : cs.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      a["icon"] as IconData,
                      color: isPrimary ? cs.onPrimary : cs.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a["title"] as String,
                          style: TextStyle(
                            color: isPrimary ? cs.onPrimary : cs.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          a["subtitle"] as String,
                          style: TextStyle(
                            color: isPrimary
                                ? cs.onPrimary.withOpacity(0.6)
                                : cs.onSurface.withOpacity(0.38),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLoading && isPrimary)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.onPrimary),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isPrimary
                          ? cs.onPrimary.withOpacity(0.5)
                          : cs.onSurface.withOpacity(0.24),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── DIALOGS ───────────────────────────────────────────────────

  void _showConfirmDialog(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required ColorScheme cs,
        required VoidCallback onConfirm,
      }) {
    final typeColors = _typeColors(cs);
    showDialog(
      context: context,
      barrierColor: cs.shadow.withOpacity(0.7),
      builder: (ctx) => _ConfirmDialog(
        title: title,
        subtitle: subtitle,
        icon: icon,
        cs: cs,
        type: selectedType,
        typeColor: typeColors[selectedType]!,
        titleText: titleController.text,
        messageText: messageController.text,
        onConfirm: () {
          Navigator.pop(ctx);
          onConfirm();
        },
      ),
    );
  }

  void _showHistoryDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierColor: cs.shadow.withOpacity(0.7),
      builder: (ctx) => _HistoryDialog(cs: cs),
    );
  }

  // ── TOAST ─────────────────────────────────────────────────────

  Future<void> _handleAction(Future<void> Function() action) async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      await action();
      if (mounted) _showSuccessToast();
    } catch (e) {
      if (mounted) _showErrorToast(e.toString());
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _showSuccessToast() {
    final cs = Theme.of(context).colorScheme;
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: "Notification sent 🚀",
        accentColor: cs.primary,
        surfaceColor: cs.surfaceContainerHighest,
        onSurfaceColor: cs.onSurface,
        isSuccess: true,
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), entry.remove);
  }

  void _showErrorToast(String msg) {
    final cs = Theme.of(context).colorScheme;
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: msg,
        accentColor: cs.error,
        surfaceColor: cs.surfaceContainerHighest,
        onSurfaceColor: cs.onSurface,
        isSuccess: false,
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), entry.remove);
  }

  // ── HELPERS ───────────────────────────────────────────────────

  NotificationRequest _buildRequest() {
    return NotificationRequest(
      customerId: customerIdController.text.isEmpty
          ? null
          : int.tryParse(customerIdController.text),
      title: titleController.text,
      message: messageController.text,
      type: selectedType,
      sendVia: sendVia,
      businessId: ref.read(businessIdProvider),
    );
  }

  Widget _glassTextField(
      String label,
      TextEditingController controller,
      ColorScheme cs, {
        int maxLines = 1,
        bool isNumber = false,
        bool isOptional = false,
      }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: cs.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: isOptional ? "$label (Optional)" : label,
        labelStyle:
        TextStyle(color: cs.onSurface.withOpacity(0.38), fontSize: 13),
        filled: true,
        fillColor: cs.onSurface.withOpacity(0.06),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          BorderSide(color: cs.onSurface.withOpacity(0.07), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          BorderSide(color: cs.primary.withOpacity(0.5), width: 1.5),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, ColorScheme cs) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: cs.onSurface.withOpacity(0.35),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
/// CONFIRM DIALOG
// ════════════════════════════════════════════════════════════════
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ColorScheme cs;
  final String type;
  final Color typeColor;
  final String titleText;
  final String messageText;
  final VoidCallback onConfirm;

  const _ConfirmDialog({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.cs,
    required this.type,
    required this.typeColor,
    required this.titleText,
    required this.messageText,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.95),
              borderRadius: BorderRadius.circular(28),
              border:
              Border.all(color: cs.onSurface.withOpacity(0.10), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withOpacity(0.3),
                        cs.primary.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: cs.primary.withOpacity(0.4), width: 1.5),
                  ),
                  child: Icon(icon, color: cs.primary, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.4),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                // Preview card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: cs.onSurface.withOpacity(0.07), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border:
                          Border.all(color: typeColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          type.toUpperCase(),
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        titleText.isEmpty ? "No title" : titleText,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        messageText.isEmpty ? "No message" : messageText,
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.45),
                          fontSize: 12,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: cs.onSurface.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: cs.onSurface.withOpacity(0.08)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(0.54),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: onConfirm,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cs.primary,
                                cs.primary.withOpacity(0.7)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Confirm",
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
/// HISTORY DIALOG
// ════════════════════════════════════════════════════════════════
class _HistoryDialog extends StatelessWidget {
  final ColorScheme cs;
  const _HistoryDialog({required this.cs});

  Color _colorForType(String type) {
    switch (type) {
      case "promo":
        return cs.tertiary;
      case "alert":
        return cs.error;
      default:
        return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {"title": "Summer Sale 🔥", "time": "2m ago", "type": "promo"},
      {"title": "System Maintenance", "time": "1h ago", "type": "alert"},
      {"title": "New Feature Update", "time": "3h ago", "type": "info"},
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.95),
              borderRadius: BorderRadius.circular(28),
              border:
              Border.all(color: cs.onSurface.withOpacity(0.10), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recent Sent",
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 16,
                            color: cs.onSurface.withOpacity(0.54)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...items.map((item) {
                  final color = _colorForType(item["type"]!);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: cs.onSurface.withOpacity(0.07), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.check_rounded,
                              color: color, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["title"]!,
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "${item["type"]!.toUpperCase()} · ${item["time"]}",
                                style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.35),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
/// TOAST WIDGET
// ════════════════════════════════════════════════════════════════
class _ToastWidget extends StatefulWidget {
  final String message;
  final Color accentColor;
  final Color surfaceColor;
  final Color onSurfaceColor;
  final bool isSuccess;

  const _ToastWidget({
    required this.message,
    required this.accentColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
    required this.isSuccess,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slide =
        Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.surfaceColor.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: widget.accentColor.withOpacity(0.4), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          widget.isSuccess
                              ? Icons.check_rounded
                              : Icons.error_outline_rounded,
                          color: widget.accentColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: widget.onSurfaceColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}