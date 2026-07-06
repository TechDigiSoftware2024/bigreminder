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

  String selectedType = "info";

  List<String> sendVia = ["push"];

  bool isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final Map<String, IconData> _typeIcons = {
    "info": Icons.info_outline_rounded,

    "promo": Icons.local_offer_rounded,

    "alert": Icons.warning_amber_rounded,
  };

  Map<String, Color> _typeColors(ColorScheme cs) => {
    "info": cs.primary,

    "promo": cs.tertiary,

    "alert": cs.error,
  };

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,

      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();

    titleController.dispose();

    messageController.dispose();

    customerIdController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,

      extendBodyBehindAppBar: true,

      appBar: _buildAppBar(cs),

      body: Stack(
        children: [
          _buildBackground(cs),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,

              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    /// 🔥 HEADER
                    _buildHeader(cs),

                    const SizedBox(height: 8),

                    /// 🔥 TYPE
                    _buildTypeSelector(cs),

                    const SizedBox(height: 8),

                    /// 🔥 COMPOSE
                    _buildInputCard(cs),

                    const SizedBox(height: 8),

                    // /// 🔥 CHANNELS
                    // _buildChannelToggle(cs),

                    const SizedBox(height: 10),

                    /// 🔥 ACTIONS
                    _buildActions(cs),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =====================================================
  /// APP BAR
  /// =====================================================

  PreferredSizeWidget _buildAppBar(ColorScheme cs) {
    return AppBar(
      elevation: 0,

      backgroundColor: cs.primary,

      systemOverlayStyle: SystemUiOverlayStyle.light,

      title: const Text(
        "Notifications",

        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),

      actions: [
        Container(
          margin: const EdgeInsets.all(10),

          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),

            borderRadius: BorderRadius.circular(12),
          ),

          child: IconButton(
            onPressed: _showHistoryDialog,

            icon: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),

        const SizedBox(width: 6),
      ],
    );
  }

  /// =====================================================
  /// BACKGROUND
  /// =====================================================

  Widget _buildBackground(ColorScheme cs) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -60,

            child: Container(
              width: 220,
              height: 220,

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                gradient: RadialGradient(
                  colors: [cs.primary.withOpacity(0.16), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =====================================================
  /// HEADER
  /// =====================================================

  Widget _buildHeader(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          "Reach your customers instantly",

          style: TextStyle(
            color: cs.onSurface,

            fontSize: 16,

            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// =====================================================
  /// TYPE SELECTOR
  /// =====================================================

  Widget _buildTypeSelector(ColorScheme cs) {
    final typeColors = _typeColors(cs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        _sectionLabel("Notification Type", cs),

        const SizedBox(height: 8),

        Row(
          children: ["info", "promo", "alert"].map((type) {
            final isSelected = selectedType == type;

            final color = typeColors[type]!;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedType = type;
                  });
                },

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),

                  margin: const EdgeInsets.only(right: 8),

                  padding: const EdgeInsets.symmetric(vertical: 7),

                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.14)
                        : cs.onSurface.withOpacity(0.04),

                    borderRadius: BorderRadius.circular(14),

                    border: Border.all(
                      color: isSelected
                          ? color.withOpacity(0.55)
                          : cs.onSurface.withOpacity(0.07),
                    ),
                  ),

                  child: Column(
                    children: [
                      Icon(
                        _typeIcons[type],

                        size: 17,

                        color: isSelected
                            ? color
                            : cs.onSurface.withOpacity(0.35),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        type.toUpperCase(),

                        style: TextStyle(
                          color: isSelected
                              ? color
                              : cs.onSurface.withOpacity(0.35),

                          fontSize: 8,

                          fontWeight: FontWeight.w700,

                          letterSpacing: 1,
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

  /// =====================================================
  /// COMPOSE CARD
  /// =====================================================

  Widget _buildInputCard(ColorScheme cs) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),

      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),

        child: Container(
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color: cs.onSurface.withOpacity(0.05),

            borderRadius: BorderRadius.circular(18),

            border: Border.all(color: cs.onSurface.withOpacity(0.08)),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              _sectionLabel("Compose", cs),

              const SizedBox(height: 10),

              _customerField(cs),

              const SizedBox(height: 8),

              _glassTextField("Title", titleController, cs),

              const SizedBox(height: 8),

              _glassTextField("Message", messageController, cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customerField(ColorScheme cs) {
    return GestureDetector(
      onTap: _openCustomerDialog,

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.06),

          borderRadius: BorderRadius.circular(14),

          border: Border.all(color: cs.onSurface.withOpacity(0.07)),
        ),

        child: Row(
          children: [
            Icon(Icons.search, size: 17, color: cs.onSurface.withOpacity(0.5)),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                selectedCustomerId == null
                    ? "Search customer"
                    : selectedCustomerName ?? "Selected",

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  color: selectedCustomerId == null
                      ? cs.onSurface.withOpacity(0.4)
                      : cs.onSurface,

                  fontSize: 13,
                ),
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,

              size: 13,

              color: cs.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  /// =====================================================
  /// CHANNELS
  /// =====================================================

  // Widget _buildChannelToggle(ColorScheme cs) {
  //   final channels = [
  //     {"id": "push", "label": "WhatsApp", "icon": Icons.notifications_rounded},
  //     //
  //     // {"id": "email", "label": "Email", "icon": Icons.email_rounded},
  //     //
  //     // {"id": "sms", "label": "SMS", "icon": Icons.sms_rounded},
  //   ];
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //
  //     children: [
  //       _sectionLabel("Channel", cs),
  //
  //       const SizedBox(height: 8),
  //
  //       Row(
  //         children: channels.map((ch) {
  //           final id = ch["id"] as String;
  //
  //           final isOn = sendVia.contains(id);
  //
  //           return GestureDetector(
  //             onTap: () {
  //               setState(() {
  //                 if (isOn) {
  //                   if (sendVia.length > 1) {
  //                     sendVia.remove(id);
  //                   }
  //                 } else {
  //                   sendVia.add(id);
  //                 }
  //               });
  //             },
  //
  //             child: AnimatedContainer(
  //               duration: const Duration(milliseconds: 180),
  //
  //               padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 6),
  //
  //               decoration: BoxDecoration(
  //                 color: isOn
  //                     ? cs.primary.withOpacity(0.14)
  //                     : cs.onSurface.withOpacity(0.04),
  //
  //                 borderRadius: BorderRadius.circular(14),
  //
  //                 border: Border.all(
  //                   color: isOn
  //                       ? cs.primary.withOpacity(0.45)
  //                       : cs.onSurface.withOpacity(0.07),
  //                 ),
  //               ),
  //
  //               child: Column(
  //                 children: [
  //                   Icon(
  //                     ch["icon"] as IconData,
  //
  //                     size: 15,
  //
  //                     color: isOn
  //                         ? cs.primary
  //                         : cs.onSurface.withOpacity(0.25),
  //                   ),
  //
  //                   const SizedBox(height: 5),
  //
  //                   Text(
  //                     ch["label"] as String,
  //
  //                     style: TextStyle(
  //                       color: isOn
  //                           ? cs.primary
  //                           : cs.onSurface.withOpacity(0.3),
  //
  //                       fontSize: 9,
  //
  //                       fontWeight: FontWeight.w600,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         }).toList(),
  //       ),
  //     ],
  //   );
  // }

  /// =====================================================
  /// ACTIONS
  /// =====================================================
  Widget _buildActions(ColorScheme cs) {
    final service = ref.read(notificationServiceProvider);

    final actions = [
      {
        "title": "Send Now",

        "subtitle": "Instant delivery",

        "icon": Icons.bolt_rounded,

        "fn": () => service.sendNow(_buildRequest()),
      },

      {
        "title": "Send to Customer",

        "subtitle": "Send to selected customer",

        "icon": Icons.schedule_send_rounded,

        "fn": () => service.send(_buildRequest()),
      },

      {
        "title": "Send Broadcast",

        "subtitle": "All customers",

        "icon": Icons.cell_tower_rounded,

        "fn": () => service.broadcast(_buildRequest()),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        _sectionLabel("Send", cs),

        const SizedBox(height: 8),

        ...actions.map((a) {
          return GestureDetector(
            onTap: isLoading
                ? null
                : () => _showConfirmDialog(
                    context,
                    title: a["title"] as String,
                    subtitle: a["subtitle"] as String,
                    icon: a["icon"] as IconData,
                    cs: cs,
                    onConfirm: () {
                      _handleAction(a["fn"] as Future<void> Function());
                    },
                  ),

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),

              margin: const EdgeInsets.only(bottom: 8),

              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),

              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.05),

                borderRadius: BorderRadius.circular(16),

                border: Border.all(color: cs.onSurface.withOpacity(0.08)),
              ),

              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,

                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.12),

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Icon(
                      a["icon"] as IconData,

                      size: 18,

                      color: cs.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          a["title"] as String,

                          style: TextStyle(
                            color: cs.onSurface,

                            fontWeight: FontWeight.w700,

                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          a["subtitle"] as String,
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(0.38),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.arrow_forward_ios_rounded,

                    size: 13,

                    color: cs.onSurface.withOpacity(0.24),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// =====================================================
  /// REQUEST
  /// =====================================================

  NotificationRequest _buildRequest() {
    return NotificationRequest(
      customerId: selectedCustomerId,

      title: titleController.text,

      message: messageController.text,

      type: selectedType,

      sendVia: sendVia,

      businessId: ref.read(businessIdProvider),
    );
  }

  /// =====================================================
  /// INPUT
  /// =====================================================

  Widget _glassTextField(
    String label,

    TextEditingController controller,

    ColorScheme cs, {

    int minLines = 2,
  }) {
    return TextField(
      controller: controller,

      minLines: minLines,

      maxLines: null, // 🔥 auto expand

      keyboardType: TextInputType.multiline,

      style: TextStyle(color: cs.onSurface, fontSize: 13),

      decoration: InputDecoration(
        labelText: label,

        alignLabelWithHint: true,

        labelStyle: TextStyle(
          color: cs.onSurface.withOpacity(0.4),

          fontSize: 12,
        ),

        filled: true,

        fillColor: cs.onSurface.withOpacity(0.06),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: BorderSide(color: cs.onSurface.withOpacity(0.07)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: BorderSide(
            color: cs.primary.withOpacity(0.5),

            width: 1.4,
          ),
        ),
      ),
    );
  }

  /// =====================================================
  /// SECTION LABEL
  /// =====================================================

  Widget _sectionLabel(String text, ColorScheme cs) {
    return Text(
      text.toUpperCase(),

      style: TextStyle(
        color: cs.onSurface.withOpacity(0.35),

        fontSize: 9,

        fontWeight: FontWeight.w700,

        letterSpacing: 1.6,
      ),
    );
  }

  /// =====================================================
  /// CUSTOMER DIALOG
  /// =====================================================

  void _openCustomerDialog() async {
    showDialog(
      context: context,

      barrierDismissible: false,

      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await ref.read(customerProvider.future);

    Navigator.pop(context);

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
          height: MediaQuery.of(context).size.height * 0.65,

          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: cs.surface,

            borderRadius: BorderRadius.circular(20),
          ),

          child: Column(
            children: [
              TextField(
                onChanged: (v) {
                  setLocalState(() {
                    localSearch = v;
                  });
                },

                decoration: InputDecoration(
                  hintText: "Search customer",

                  filled: true,

                  fillColor: cs.onSurface.withOpacity(0.05),

                  prefixIcon: Icon(
                    Icons.search,

                    color: cs.onSurface.withOpacity(0.5),
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),

                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

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

                              selectedCustomerName = "${c.name}";
                            });

                            Navigator.pop(context);
                          },

                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),

                            padding: const EdgeInsets.all(12),

                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primary.withOpacity(0.14)
                                  : cs.onSurface.withOpacity(0.04),

                              borderRadius: BorderRadius.circular(14),

                              border: Border.all(
                                color: isSelected
                                    ? cs.primary.withOpacity(0.5)
                                    : cs.onSurface.withOpacity(0.07),
                              ),
                            ),

                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,

                                  backgroundColor: cs.primary.withOpacity(0.12),

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

                                          fontSize: 13,
                                        ),
                                      ),

                                      Text(
                                        c.phone ?? "",

                                        style: TextStyle(
                                          color: cs.onSurface.withOpacity(0.5),

                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (isSelected)
                                  Icon(Icons.check_circle, color: cs.primary),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },

                  loading: () =>
                      const Center(child: CircularProgressIndicator()),

                  error: (e, _) =>
                      const Center(child: Text("Error loading customers")),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// =====================================================
  /// ACTION HANDLER
  /// =====================================================

  Future<void> _handleAction(Future<void> Function() action) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      await action();

      if (mounted) {
        _showSuccessToast();
      }
    } catch (e) {
      if (mounted) {
        _showErrorToast(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// =====================================================
  /// CONFIRM DIALOG
  /// =====================================================

  void _showConfirmDialog(
    BuildContext context, {

    required String title,

    required String subtitle,

    required IconData icon,

    required ColorScheme cs,

    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,

      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        title: Row(
          children: [
            Icon(icon, color: cs.primary),

            const SizedBox(width: 10),

            Text(title),
          ],
        ),

        content: Text(subtitle),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },

            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              onConfirm();
            },

            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  /// =====================================================
  /// HISTORY
  /// =====================================================

  void _showHistoryDialog() {
    showDialog(
      context: context,

      builder: (_) => AlertDialog(
        title: const Text("Recent Notifications"),

        content: const Text("History feature coming soon."),
      ),
    );
  }

  /// =====================================================
  /// TOASTS
  /// =====================================================

  void _showSuccessToast() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Notification sent 🚀")));
  }

  void _showErrorToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
