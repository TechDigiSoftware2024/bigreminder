import 'package:bigreminder/providers/theme_provider.dart';
import 'package:bigreminder/utils/enum_classes.dart';
import 'package:bigreminder/widgets/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/business_models/customer_list_model.dart';
import '../../models/business_models/notification_history_model.dart';
import '../../models/business_models/notification_req_model.dart';
import '../../providers/business/business_provider.dart';
import '../../services/notification_service.dart';

class BusinessNotificationScreen extends ConsumerStatefulWidget {
  const BusinessNotificationScreen({super.key});

  @override
  ConsumerState<BusinessNotificationScreen> createState() =>
      _BusinessNotificationScreenState();
}

class _BusinessNotificationScreenState
    extends ConsumerState<BusinessNotificationScreen> {
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  int? selectedCustomerId;
  String? selectedCustomerName;
  String selectedType = 'info';
  final List<String> sendVia = ['push'];
  bool isLoading = false;

  final Map<String, IconData> _typeIcons = {
    'info': Icons.info_outline_rounded,
    'promo': Icons.local_offer_outlined,
    'alert': Icons.warning_amber_rounded,
  };

  Map<String, Color> _typeColors(ColorScheme cs) => {
        'info': cs.primary,
        'promo': const Color(0xFFE67E22),
        'alert': const Color(0xFFD64545),
      };

  @override
  void initState() {
    super.initState();
    titleController.addListener(_onComposeChanged);
    messageController.addListener(_onComposeChanged);
  }

  void _onComposeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    titleController.removeListener(_onComposeChanged);
    messageController.removeListener(_onComposeChanged);
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  NotificationRequest _buildRequest() {
    return NotificationRequest(
      customerId: selectedCustomerId,
      title: titleController.text.trim(),
      message: messageController.text.trim(),
      type: selectedType,
      sendVia: sendVia,
      businessId: ref.read(businessIdProvider),
    );
  }

  bool _validate({bool requireCustomer = false}) {
    if (titleController.text.trim().isEmpty) {
      CustomDialog.showErrorSnack(context, 'Enter a title');
      return false;
    }
    if (messageController.text.trim().isEmpty) {
      CustomDialog.showErrorSnack(context, 'Enter a message');
      return false;
    }
    if (requireCustomer && selectedCustomerId == null) {
      CustomDialog.showErrorSnack(context, 'Select a customer first');
      return false;
    }
    return true;
  }

  Future<void> _handleAction(
    Future<void> Function() action, {
    bool requireCustomer = false,
  }) async {
    if (isLoading) return;
    if (!_validate(requireCustomer: requireCustomer)) return;

    setState(() => isLoading = true);

    try {
      await action();
      if (!mounted) return;
      CustomDialog.showSuccessSnack(context, 'Notification sent');
      setState(() {
        titleController.clear();
        messageController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      CustomDialog.showErrorSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _confirmAndSend({
    required String title,
    required String subtitle,
    required IconData icon,
    required Future<void> Function() action,
    bool requireCustomer = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: cs.primary.withValues(alpha: 0.1),
                    child: Icon(icon, color: cs.primary),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _handleAction(
                              action,
                              requireCustomer: requireCustomer,
                            );
                          },
                          child: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: const _NotificationHistorySheet(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final type = ref.watch(appTypeProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final service = ref.read(notificationServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'History',
            onPressed: _showHistoryDialog,
            icon: const Icon(Icons.history_rounded, color: Colors.white),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: isDesktop
          ? _buildDesktop(cs, type, service)
          : _buildMobile(cs, type, service),
    );
  }

  Widget _buildDesktop(
    ColorScheme cs,
    AppType type,
    dynamic service,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: SingleChildScrollView(
              child: _ComposePanel(
                typeLabel: DashboardText.customer(type),
                searchHint: DashboardText.searchBarTitle(type),
                selectedType: selectedType,
                typeIcons: _typeIcons,
                typeColors: _typeColors(cs),
                selectedCustomerName: selectedCustomerName,
                selectedCustomerId: selectedCustomerId,
                titleController: titleController,
                messageController: messageController,
                onCustomerSelected: (id, name) {
                  setState(() {
                    selectedCustomerId = id;
                    selectedCustomerName = name;
                  });
                },
                onClearCustomer: () {
                  setState(() {
                    selectedCustomerId = null;
                    selectedCustomerName = null;
                  });
                },
                onTypeChanged: (value) {
                  setState(() => selectedType = value);
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: _SendPanel(
                isLoading: isLoading,
                previewTitle: titleController.text.trim().isEmpty
                    ? 'Notification title'
                    : titleController.text.trim(),
                previewMessage: messageController.text.trim().isEmpty
                    ? 'Your message preview will appear here'
                    : messageController.text.trim(),
                selectedType: selectedType,
                typeColor: _typeColors(cs)[selectedType]!,
                onSendNow: () => _confirmAndSend(
                  title: 'Send Now',
                  subtitle: 'Send this notification instantly.',
                  icon: Icons.bolt_rounded,
                  action: () => service.sendNow(_buildRequest()),
                ),
                onSendCustomer: () => _confirmAndSend(
                  title: 'Send to Customer',
                  subtitle: 'Send only to the selected customer.',
                  icon: Icons.send_rounded,
                  requireCustomer: true,
                  action: () => service.send(_buildRequest()),
                ),
                onBroadcast: () => _confirmAndSend(
                  title: 'Send Broadcast',
                  subtitle: 'Send to all customers.',
                  icon: Icons.cell_tower_rounded,
                  action: () => service.broadcast(_buildRequest()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(
    ColorScheme cs,
    AppType type,
    dynamic service,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _ComposePanel(
            typeLabel: DashboardText.customer(type),
            searchHint: DashboardText.searchBarTitle(type),
            selectedType: selectedType,
            typeIcons: _typeIcons,
            typeColors: _typeColors(cs),
            selectedCustomerName: selectedCustomerName,
            selectedCustomerId: selectedCustomerId,
            titleController: titleController,
            messageController: messageController,
            onCustomerSelected: (id, name) {
              setState(() {
                selectedCustomerId = id;
                selectedCustomerName = name;
              });
            },
            onClearCustomer: () {
              setState(() {
                selectedCustomerId = null;
                selectedCustomerName = null;
              });
            },
            onTypeChanged: (value) {
              setState(() => selectedType = value);
            },
          ),
          const SizedBox(height: 14),
          _SendPanel(
            isLoading: isLoading,
            previewTitle: titleController.text.trim().isEmpty
                ? 'Notification title'
                : titleController.text.trim(),
            previewMessage: messageController.text.trim().isEmpty
                ? 'Your message preview will appear here'
                : messageController.text.trim(),
            selectedType: selectedType,
            typeColor: _typeColors(cs)[selectedType]!,
            onSendNow: () => _confirmAndSend(
              title: 'Send Now',
              subtitle: 'Send this notification instantly.',
              icon: Icons.bolt_rounded,
              action: () => service.sendNow(_buildRequest()),
            ),
            onSendCustomer: () => _confirmAndSend(
              title: 'Send to Customer',
              subtitle: 'Send only to the selected customer.',
              icon: Icons.send_rounded,
              requireCustomer: true,
              action: () => service.send(_buildRequest()),
            ),
            onBroadcast: () => _confirmAndSend(
              title: 'Send Broadcast',
              subtitle: 'Send to all customers.',
              icon: Icons.cell_tower_rounded,
              action: () => service.broadcast(_buildRequest()),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ============================================================================
// COMPOSE
// ============================================================================

class _ComposePanel extends ConsumerStatefulWidget {
  final String typeLabel;
  final String searchHint;
  final String selectedType;
  final Map<String, IconData> typeIcons;
  final Map<String, Color> typeColors;
  final String? selectedCustomerName;
  final int? selectedCustomerId;
  final TextEditingController titleController;
  final TextEditingController messageController;
  final void Function(int id, String name) onCustomerSelected;
  final VoidCallback onClearCustomer;
  final ValueChanged<String> onTypeChanged;

  const _ComposePanel({
    required this.typeLabel,
    required this.searchHint,
    required this.selectedType,
    required this.typeIcons,
    required this.typeColors,
    required this.selectedCustomerName,
    required this.selectedCustomerId,
    required this.titleController,
    required this.messageController,
    required this.onCustomerSelected,
    required this.onClearCustomer,
    required this.onTypeChanged,
  });

  @override
  ConsumerState<_ComposePanel> createState() => _ComposePanelState();
}

class _ComposePanelState extends ConsumerState<_ComposePanel> {
  final customerSearchController = TextEditingController();
  final customerFocusNode = FocusNode();
  bool listExpanded = false;

  @override
  void initState() {
    super.initState();
    customerFocusNode.addListener(_onFocusChange);
    if (widget.selectedCustomerName != null) {
      customerSearchController.text = widget.selectedCustomerName!;
    }
  }

  @override
  void didUpdateWidget(covariant _ComposePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCustomerId == null &&
        oldWidget.selectedCustomerId != null) {
      customerSearchController.clear();
      setState(() => listExpanded = false);
    } else if (widget.selectedCustomerName != null &&
        widget.selectedCustomerName != oldWidget.selectedCustomerName) {
      customerSearchController.text = widget.selectedCustomerName!;
    }
  }

  void _onFocusChange() {
    if (customerFocusNode.hasFocus) {
      setState(() => listExpanded = true);
      // Warm customers cache without blocking UI
      ref.read(customerProvider);
    }
    // Do not auto-collapse on blur — list item taps would miss selection.
  }

  @override
  void dispose() {
    customerFocusNode.removeListener(_onFocusChange);
    customerFocusNode.dispose();
    customerSearchController.dispose();
    super.dispose();
  }

  List<CustomerResponseModel> _filter(
    List<CustomerResponseModel> customers,
  ) {
    final q = customerSearchController.text.trim().toLowerCase();
    if (q.isEmpty) return customers;
    return customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customersAsync = ref.watch(customerProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Compose Notification',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reach your ${widget.typeLabel} instantly',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Notification Type',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['info', 'promo', 'alert'].map((type) {
              final selected = widget.selectedType == type;
              final color = widget.typeColors[type]!;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: type == 'alert' ? 0 : 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onTypeChanged(type),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withValues(alpha: 0.16)
                              : color.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? color
                                : color.withValues(alpha: 0.28),
                            width: selected ? 1.6 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              widget.typeIcons[type],
                              size: 20,
                              color: color,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'Customer (optional)',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: customerSearchController,
            focusNode: customerFocusNode,
            onTap: () => setState(() => listExpanded = true),
            onChanged: (_) {
              if (widget.selectedCustomerId != null) {
                widget.onClearCustomer();
              }
              setState(() => listExpanded = true);
            },
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
            decoration: InputDecoration(
              hintText: widget.searchHint,
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.person_search_outlined,
                color: cs.primary,
                size: 22,
              ),
              suffixIcon: widget.selectedCustomerId != null ||
                      customerSearchController.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear',
                      onPressed: () {
                        customerSearchController.clear();
                        widget.onClearCustomer();
                        setState(() => listExpanded = false);
                        customerFocusNode.unfocus();
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                    )
                  : IconButton(
                      tooltip: listExpanded ? 'Hide' : 'Show',
                      onPressed: () {
                        setState(() => listExpanded = !listExpanded);
                        if (listExpanded) {
                          customerFocusNode.requestFocus();
                          ref.read(customerProvider);
                        } else {
                          customerFocusNode.unfocus();
                        }
                      },
                      icon: Icon(
                        listExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey.shade500,
                      ),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.selectedCustomerId != null
                      ? cs.primary.withValues(alpha: 0.45)
                      : Colors.grey.shade300,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary, width: 1.6),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: listExpanded && widget.selectedCustomerId == null
                ? _CustomerExpandList(
                    customersAsync: customersAsync,
                    filter: _filter,
                    onSelect: (c) {
                      customerSearchController.text = c.name;
                      widget.onCustomerSelected(c.id, c.name);
                      setState(() => listExpanded = false);
                      customerFocusNode.unfocus();
                    },
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'Title',
            child: TextField(
              controller: widget.titleController,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
              decoration: _inputDecoration(
                context,
                hint: 'Enter notification title',
                icon: Icons.title_rounded,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'Message',
            child: TextField(
              controller: widget.messageController,
              minLines: 3,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
                height: 1.4,
              ),
              decoration: _inputDecoration(
                context,
                hint: 'Write your message...',
                icon: Icons.message_outlined,
                alignTop: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
    bool alignTop = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: alignTop
          ? Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Icon(icon, color: cs.primary, size: 20),
            )
          : Icon(icon, color: cs.primary, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.6),
      ),
    );
  }
}

class _CustomerExpandList extends StatelessWidget {
  final AsyncValue<List<CustomerResponseModel>> customersAsync;
  final List<CustomerResponseModel> Function(List<CustomerResponseModel>)
      filter;
  final void Function(CustomerResponseModel) onSelect;

  const _CustomerExpandList({
    required this.customersAsync,
    required this.filter,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 220),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: customersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Could not load customers',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          data: (customers) {
            final filtered = filter(customers);
            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No customers found',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6),
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Colors.grey.shade100,
              ),
              itemBuilder: (_, i) {
                final c = filtered[i];
                return InkWell(
                  onTapDown: (_) => onSelect(c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: cs.primary.withValues(alpha: 0.12),
                          child: Text(
                            (c.name.isNotEmpty ? c.name[0] : 'C')
                                .toUpperCase(),
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name.isEmpty ? 'Customer' : c.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (c.phone.isNotEmpty)
                                Text(
                                  c.phone,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ============================================================================
// SEND PANEL
// ============================================================================

class _SendPanel extends StatelessWidget {
  final bool isLoading;
  final String previewTitle;
  final String previewMessage;
  final String selectedType;
  final Color typeColor;
  final VoidCallback onSendNow;
  final VoidCallback onSendCustomer;
  final VoidCallback onBroadcast;

  const _SendPanel({
    required this.isLoading,
    required this.previewTitle,
    required this.previewMessage,
    required this.selectedType,
    required this.typeColor,
    required this.onSendNow,
    required this.onSendCustomer,
    required this.onBroadcast,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview & Send',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: typeColor.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    selectedType.toUpperCase(),
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  previewTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  previewMessage,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else ...[
            _SendActionTile(
              icon: Icons.bolt_rounded,
              title: 'Send Now',
              subtitle: 'Instant delivery',
              onTap: onSendNow,
            ),
            const SizedBox(height: 8),
            _SendActionTile(
              icon: Icons.send_rounded,
              title: 'Send to Customer',
              subtitle: 'Selected customer only',
              onTap: onSendCustomer,
            ),
            const SizedBox(height: 8),
            _SendActionTile(
              icon: Icons.cell_tower_rounded,
              title: 'Send Broadcast',
              subtitle: 'All customers',
              onTap: onBroadcast,
            ),
          ],
        ],
      ),
    );
  }
}

class _SendActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SendActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xffFAFBFD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cs.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// NOTIFICATION HISTORY
// ============================================================================

class _NotificationHistorySheet extends ConsumerStatefulWidget {
  const _NotificationHistorySheet();

  @override
  ConsumerState<_NotificationHistorySheet> createState() =>
      _NotificationHistorySheetState();
}

class _NotificationHistorySheetState
    extends ConsumerState<_NotificationHistorySheet> {
  static const int _pageSize = 50;

  String? filterType;
  String? filterStatus;
  DateTime? fromDate;
  DateTime? toDate;

  List<NotificationHistoryItem> items = [];
  bool loading = true;
  bool loadingMore = false;
  String? error;
  int offset = 0;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  String? _fmtDate(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _fmtDateTime(DateTime? d) {
    if (d == null) return '';
    final local = d.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year  $hour:$min';
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        loading = true;
        error = null;
        offset = 0;
        hasMore = true;
        items = [];
      });
    } else {
      if (!hasMore || loadingMore) return;
      setState(() => loadingMore = true);
    }

    try {
      final businessId = ref.read(businessIdProvider);
      final service = ref.read(notificationServiceProvider);
      final result = await service.fetchHistory(
        businessId: businessId,
        type: filterType,
        status: filterStatus,
        fromDate: _fmtDate(fromDate),
        toDate: _fmtDate(toDate),
        limit: _pageSize,
        offset: reset ? 0 : offset,
      );

      if (!mounted) return;
      setState(() {
        if (reset) {
          items = result;
          offset = result.length;
        } else {
          items = [...items, ...result];
          offset += result.length;
        }
        hasMore = result.length >= _pageSize;
        loading = false;
        loadingMore = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        loadingMore = false;
        error = e is AppError ? e.message : e.toString();
      });
    }
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: toDate ?? DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => fromDate = picked);
    _load(reset: true);
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: fromDate ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => toDate = picked);
    _load(reset: true);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return const Color(0xFF2E9E6A);
      case 'failed':
        return const Color(0xFFD64545);
      case 'partial':
        return const Color(0xFFE67E22);
      default:
        return Colors.grey;
    }
  }

  Color _typeColor(String type, ColorScheme cs) {
    switch (type.toLowerCase()) {
      case 'promo':
        return const Color(0xFFE67E22);
      case 'alert':
        return const Color(0xFFD64545);
      default:
        return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification History',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'Sent, failed & partial deliveries',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: loading ? null : () => _load(reset: true),
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _FilterChipField(
                      label: filterType?.toUpperCase() ?? 'All types',
                      icon: Icons.category_outlined,
                      onTap: () async {
                        final value = await showModalBottomSheet<String?>(
                          context: context,
                          builder: (ctx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('All types'),
                                  onTap: () => Navigator.pop(ctx, ''),
                                ),
                                for (final t in ['info', 'promo', 'alert'])
                                  ListTile(
                                    title: Text(t.toUpperCase()),
                                    onTap: () => Navigator.pop(ctx, t),
                                  ),
                              ],
                            ),
                          ),
                        );
                        if (value == null) return;
                        setState(() {
                          filterType = value.isEmpty ? null : value;
                        });
                        _load(reset: true);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterChipField(
                      label: filterStatus?.toUpperCase() ?? 'All status',
                      icon: Icons.flag_outlined,
                      onTap: () async {
                        final value = await showModalBottomSheet<String?>(
                          context: context,
                          builder: (ctx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('All status'),
                                  onTap: () => Navigator.pop(ctx, ''),
                                ),
                                for (final s in ['sent', 'failed', 'partial'])
                                  ListTile(
                                    title: Text(s.toUpperCase()),
                                    onTap: () => Navigator.pop(ctx, s),
                                  ),
                              ],
                            ),
                          ),
                        );
                        if (value == null) return;
                        setState(() {
                          filterStatus = value.isEmpty ? null : value;
                        });
                        _load(reset: true);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _FilterChipField(
                      label: fromDate == null
                          ? 'From date'
                          : _fmtDate(fromDate)!,
                      icon: Icons.calendar_today_outlined,
                      onTap: _pickFromDate,
                      onClear: fromDate == null
                          ? null
                          : () {
                              setState(() => fromDate = null);
                              _load(reset: true);
                            },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterChipField(
                      label:
                          toDate == null ? 'To date' : _fmtDate(toDate)!,
                      icon: Icons.event_outlined,
                      onTap: _pickToDate,
                      onClear: toDate == null
                          ? null
                          : () {
                              setState(() => toDate = null);
                              _load(reset: true);
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                )
              : error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => _load(reset: true),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : items.isEmpty
                      ? Center(
                          child: Text(
                            'No notifications found',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _load(reset: true),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (n) {
                              if (n.metrics.pixels >=
                                      n.metrics.maxScrollExtent - 80 &&
                                  hasMore &&
                                  !loadingMore) {
                                _load();
                              }
                              return false;
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              itemCount: items.length + (loadingMore ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                if (i >= items.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final item = items[i];
                                final typeColor = _typeColor(item.type, cs);
                                final statusColor = _statusColor(item.status);

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffFAFBFD),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: typeColor.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.type.toUpperCase(),
                                              style: TextStyle(
                                                color: typeColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.status.toUpperCase(),
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (item.channel != null &&
                                              item.channel!.isNotEmpty)
                                            Text(
                                              item.channel!,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 11,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.message,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 12,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule_rounded,
                                            size: 13,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _fmtDateTime(item.sentAt),
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (item.customerId != null) ...[
                                            const SizedBox(width: 10),
                                            Icon(
                                              Icons.person_outline_rounded,
                                              size: 13,
                                              color: Colors.grey.shade500,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '#${item.customerId}',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _FilterChipField extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterChipField({
    required this.label,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xffF7F8FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (onClear != null)
                GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
