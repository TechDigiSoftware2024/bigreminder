import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bigreminder/models/super_admin_models/business_create_reminder.dart';
import 'package:bigreminder/widgets/custom_dialog.dart';
import 'package:bigreminder/widgets/custom_dropdown_textfield.dart';

import '../../../providers/business/business_provider.dart';

// ---------------------------------------------------------------------------
// UPDATE REMINDER PROVIDER
// ---------------------------------------------------------------------------

final updateReminderProvider =
    StateNotifierProvider<UpdateReminderNotifier, AsyncValue<void>>(
  (ref) => UpdateReminderNotifier(ref),
);

class UpdateReminderNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  UpdateReminderNotifier(this.ref) : super(const AsyncData(null));

  Future<void> updateReminder({
    required int reminderId,
    required String message,
    required DateTime scheduledAt,
    required String targetGender,
  }) async {
    state = const AsyncLoading();
    try {
      final token = ref.read(tokenProvider);
      final prefs = await SharedPreferences.getInstance();
      final businessId = prefs.getInt('businessId') ?? 0;

      await ref.read(reminderServiceProvider).updateReminder(
            reminderId: reminderId,
            message: message,
            scheduledAt: scheduledAt.toUtc(),
            targetGender: targetGender,
            businessId: businessId,
            token: token,
          );

      ref.invalidate(reminderListProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

// ---------------------------------------------------------------------------
// SCREEN
// ---------------------------------------------------------------------------

class BusinessRemindersScreen extends ConsumerStatefulWidget {
  const BusinessRemindersScreen({super.key});

  @override
  ConsumerState<BusinessRemindersScreen> createState() =>
      _BusinessRemindersScreenState();
}

class _BusinessRemindersScreenState
    extends ConsumerState<BusinessRemindersScreen> {
  final _messageController = TextEditingController();
  final _desktopFormKey = GlobalKey<FormState>();

  String _targetGender = 'all';
  DateTime _scheduledDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _scheduledTime = TimeOfDay.now();
  bool _isEditing = false;
  int? _editingReminderId;
  bool _submitting = false;
  bool _didChange = false;
  int? _deletingId;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  DateTime get _combinedDateTime => DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _scheduledTime.hour,
        _scheduledTime.minute,
      );

  String get _audienceLabel {
    switch (_targetGender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      default:
        return 'Everyone';
    }
  }

  void _resetForm() {
    _messageController.clear();
    _targetGender = 'all';
    _scheduledDate = DateTime.now().add(const Duration(hours: 1));
    _scheduledTime = TimeOfDay.now();
    _isEditing = false;
    _editingReminderId = null;
    _submitting = false;
  }

  void _fillForm(BusinessReminderModel reminder) {
    _messageController.text = reminder.message;
    _targetGender = reminder.targetGender;
    _scheduledDate = reminder.scheduledAt;
    _scheduledTime = TimeOfDay.fromDateTime(reminder.scheduledAt);
    _isEditing = true;
    _editingReminderId = reminder.id;
  }

  Future<void> _pickDate(VoidCallback refresh) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    setState(() => _scheduledDate = date);
    refresh();
  }

  Future<void> _pickTime(VoidCallback refresh) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (time == null || !mounted) return;
    setState(() => _scheduledTime = time);
    refresh();
  }

  Future<bool> _submit({
    required GlobalKey<FormState> formKey,
    VoidCallback? onLoadingChanged,
  }) async {
    if (_submitting) return false;
    if (!(formKey.currentState?.validate() ?? false)) return false;

    setState(() => _submitting = true);
    onLoadingChanged?.call();

    try {
      if (_isEditing) {
        await ref.read(updateReminderProvider.notifier).updateReminder(
              reminderId: _editingReminderId!,
              message: _messageController.text.trim(),
              scheduledAt: _combinedDateTime.toUtc(),
              targetGender: _targetGender,
            );
      } else {
        final prefs = await SharedPreferences.getInstance();
        final businessId = prefs.getInt('businessId') ?? 0;

        await ref.read(createReminderProvider.notifier).createReminder(
              message: _messageController.text.trim(),
              scheduledAt: _combinedDateTime.toUtc(),
              targetGender: _targetGender,
              businessId: businessId,
            );
      }

      if (!mounted) return false;

      final wasEdit = _isEditing;
      _resetForm();
      _didChange = true;
      setState(() {});

      CustomDialog.showSuccessSnack(
        context,
        wasEdit ? 'Reminder updated' : 'Reminder scheduled',
      );

      return true;
    } catch (e) {
      if (mounted) {
        CustomDialog.showErrorSnack(context, _friendlyError(e.toString()));
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
        onLoadingChanged?.call();
      }
    }
  }

  void _openForm({BusinessReminderModel? reminder}) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    if (isDesktop) {
      _resetForm();
      if (reminder != null) _fillForm(reminder);
      setState(() {});
      return;
    }

    _resetForm();
    if (reminder != null) _fillForm(reminder);
    setState(() {});

    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void refresh() => setDialogState(() {});

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: ReminderAddForm(
                      formKey: dialogFormKey,
                      messageController: _messageController,
                      audienceLabel: _audienceLabel,
                      scheduledDate: _scheduledDate,
                      scheduledTime: _scheduledTime,
                      loading: _submitting,
                      isEditing: _isEditing,
                      onAudienceChanged: (label) {
                        setState(() {
                          _targetGender = _genderValue(label);
                        });
                        refresh();
                      },
                      onPickDate: () => _pickDate(refresh),
                      onPickTime: () => _pickTime(refresh),
                      onClear: () {
                        setState(_resetForm);
                        refresh();
                      },
                      onSubmit: () async {
                        final success = await _submit(
                          formKey: dialogFormKey,
                          onLoadingChanged: refresh,
                        );
                        if (!dialogContext.mounted) return;
                        if (success) Navigator.of(dialogContext).pop();
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) setState(_resetForm);
    });
  }

  String _genderValue(String label) {
    switch (label) {
      case 'Male':
        return 'male';
      case 'Female':
        return 'female';
      default:
        return 'all';
    }
  }

  Future<void> _confirmDelete(BusinessReminderModel reminder) async {
    final primary = Theme.of(context).colorScheme.primary;
    final dialogWidth = MediaQuery.sizeOf(context).width >= 900
        ? 420.0
        : MediaQuery.sizeOf(context).width - 32;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: primary.withOpacity(0.1),
                    child: Icon(Icons.help, color: primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Delete Reminder?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This action cannot be undone.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, true),
                          child: const Text('Delete'),
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

    if (confirmed != true) return;

    setState(() => _deletingId = reminder.id);

    try {
      await ref
          .read(deleteReminderProvider.notifier)
          .deleteReminder(reminderId: reminder.id);

      if (!mounted) return;
      _didChange = true;
      CustomDialog.showSuccessSnack(context, 'Reminder deleted');
    } catch (e) {
      if (!mounted) return;
      CustomDialog.showErrorSnack(context, _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('Business ID')) {
      return 'Business not found. Please re-login.';
    }
    if (raw.contains('Token')) return 'Session expired. Please re-login.';
    if (raw.contains('SocketException') || raw.contains('Connection')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final reminderAsync = ref.watch(reminderListProvider);
    final cs = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_didChange);
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF5F7FB),
        appBar: AppBar(
          backgroundColor: cs.primary,
          elevation: 0,
          title: const Text(
            'Reminders',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Refresh',
              onPressed: () => ref.invalidate(reminderListProvider),
            ),
            const SizedBox(width: 4),
          ],
        ),
        floatingActionButton: !isDesktop
            ? FloatingActionButton(
                backgroundColor: cs.primary,
                onPressed: () => _openForm(),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        body: isDesktop
            ? _buildDesktop(reminderAsync, cs)
            : _buildMobile(reminderAsync, cs),
      ),
    );
  }

  Widget _buildDesktop(
    AsyncValue<List<BusinessReminderModel>> reminderAsync,
    ColorScheme cs,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: ReminderListPanel(
              reminderAsync: reminderAsync,
              deletingId: _deletingId,
              isDesktop: true,
              onRefresh: () async => ref.invalidate(reminderListProvider),
              onEdit: (reminder) => _openForm(reminder: reminder),
              onDelete: _confirmDelete,
              friendlyError: _friendlyError,
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: ReminderAddForm(
                formKey: _desktopFormKey,
                messageController: _messageController,
                audienceLabel: _audienceLabel,
                scheduledDate: _scheduledDate,
                scheduledTime: _scheduledTime,
                loading: _submitting,
                isEditing: _isEditing,
                onAudienceChanged: (label) {
                  setState(() => _targetGender = _genderValue(label));
                },
                onPickDate: () => _pickDate(() => setState(() {})),
                onPickTime: () => _pickTime(() => setState(() {})),
                onClear: () => setState(_resetForm),
                onSubmit: () async {
                  await _submit(formKey: _desktopFormKey);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(
    AsyncValue<List<BusinessReminderModel>> reminderAsync,
    ColorScheme cs,
  ) {
    return RefreshIndicator(
      color: cs.primary,
      onRefresh: () async => ref.invalidate(reminderListProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            ReminderListPanel(
              reminderAsync: reminderAsync,
              deletingId: _deletingId,
              isDesktop: false,
              onRefresh: () async => ref.invalidate(reminderListProvider),
              onEdit: (reminder) => _openForm(reminder: reminder),
              onDelete: _confirmDelete,
              friendlyError: _friendlyError,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ADD FORM
// ---------------------------------------------------------------------------

class ReminderAddForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController messageController;
  final String audienceLabel;
  final DateTime scheduledDate;
  final TimeOfDay scheduledTime;
  final bool loading;
  final bool isEditing;
  final ValueChanged<String> onAudienceChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  const ReminderAddForm({
    super.key,
    required this.formKey,
    required this.messageController,
    required this.audienceLabel,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.loading,
    required this.isEditing,
    required this.onAudienceChanged,
    required this.onPickDate,
    required this.onPickTime,
    required this.onClear,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Form(
        key: formKey,
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Update Reminder' : 'New Reminder',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEditing
                              ? 'Edit scheduled notification'
                              : 'Notify customers on time',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isEditing)
                    IconButton(
                      onPressed: onClear,
                      tooltip: 'Clear form',
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Message',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 5),
            TextFormField(
              controller: messageController,
              minLines: 3,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Message is required'
                  : null,
              decoration: InputDecoration(
                hintText: 'What should customers be reminded about?',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Icon(
                    Icons.message_outlined,
                    color: cs.primary,
                    size: 20,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xffFAFBFD),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: cs.onSurface.withOpacity(.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            CustomDropdownTextField(
              label: 'Target audience',
              hint: 'Everyone / Male / Female',
              icon: Icons.people_alt_outlined,
              value: audienceLabel,
              items: const ['Everyone', 'Male', 'Female'],
              onChanged: (value) {
                if (value != null) onAudienceChanged(value);
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DateTimeTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: DateFormat('MMM dd, yyyy').format(scheduledDate),
                    onTap: onPickDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateTimeTile(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: scheduledTime.format(context),
                    onTap: onPickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: loading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  disabledBackgroundColor: cs.primary.withOpacity(.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        height: 19,
                        width: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditing ? 'Save Changes' : 'Schedule Reminder',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTimeTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xffFAFBFD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withOpacity(.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LIST PANEL
// ---------------------------------------------------------------------------

class ReminderListPanel extends StatelessWidget {
  final AsyncValue<List<BusinessReminderModel>> reminderAsync;
  final int? deletingId;
  final bool isDesktop;
  final Future<void> Function() onRefresh;
  final ValueChanged<BusinessReminderModel> onEdit;
  final ValueChanged<BusinessReminderModel> onDelete;
  final String Function(String) friendlyError;

  const ReminderListPanel({
    super.key,
    required this.reminderAsync,
    required this.deletingId,
    required this.isDesktop,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    required this.friendlyError,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = reminderAsync.asData?.value ?? <BusinessReminderModel>[];
    final isInitialLoading =
        reminderAsync.isLoading && reminderAsync.asData == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Reminders',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isInitialLoading
                          ? 'Loading reminders...'
                          : '${items.length} reminder records',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDesktop)
                IconButton(
                  onPressed: isInitialLoading ? null : onRefresh,
                  icon: Icon(Icons.refresh_rounded, color: cs.primary),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (reminderAsync.hasError && items.isEmpty)
            _ErrorView(
              message: friendlyError(reminderAsync.error.toString()),
              onRetry: onRefresh,
            )
          else if (isDesktop)
            Expanded(child: _buildList(items, isInitialLoading))
          else
            _buildMobileList(items, isInitialLoading),
        ],
      ),
    );
  }

  Widget _buildList(List<BusinessReminderModel> items, bool loading) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) return const _EmptyReminders();

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final reminder = items[index];
        return ReminderCard(
          reminder: reminder,
          deleting: deletingId == reminder.id,
          onEdit: () => onEdit(reminder),
          onDelete: () => onDelete(reminder),
        );
      },
    );
  }

  Widget _buildMobileList(List<BusinessReminderModel> items, bool loading) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (items.isEmpty) return const _EmptyReminders();

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final reminder = items[index];
        return ReminderCard(
          reminder: reminder,
          deleting: deletingId == reminder.id,
          onEdit: () => onEdit(reminder),
          onDelete: () => onDelete(reminder),
        );
      },
    );
  }
}

class _EmptyReminders extends StatelessWidget {
  const _EmptyReminders();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No reminders yet',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Schedule your first customer notification',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: Colors.red),
          const SizedBox(height: 12),
          const Text(
            "Couldn't load reminders",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CARD
// ---------------------------------------------------------------------------

class ReminderCard extends StatefulWidget {
  final BusinessReminderModel reminder;
  final bool deleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.deleting,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<ReminderCard> {
  bool _expanded = false;

  String get _title {
    final msg = widget.reminder.message.trim();
    if (msg.isEmpty) return 'Reminder';

    final firstLine = msg.split(RegExp(r'\r?\n')).first.trim();
    if (firstLine.length <= 42) return firstLine;
    return '${firstLine.substring(0, 42).trimRight()}...';
  }

  bool get _canExpand {
    final msg = widget.reminder.message.trim();
    return msg.contains('\n') || msg.length > 42;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reminder = widget.reminder;
    final isSent = reminder.status == 'sent';
    final isPending = !isSent && reminder.scheduledAt.isBefore(DateTime.now());
    final hasError =
        reminder.lastError != null && reminder.lastError!.isNotEmpty;

    final statusColor = isSent
        ? Colors.green.shade600
        : isPending
            ? Colors.orange.shade700
            : cs.primary;

    final statusLabel = isSent
        ? 'Sent'
        : isPending
            ? 'Pending'
            : 'Scheduled';

    final statusIcon = isSent
        ? Icons.check_circle_rounded
        : isPending
            ? Icons.hourglass_bottom_rounded
            : Icons.schedule_rounded;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xffFAFBFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _canExpand
                      ? () => setState(() => _expanded = !_expanded)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                decoration:
                                    isSent ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          if (_canExpand) ...[
                            const SizedBox(width: 4),
                            Icon(
                              _expanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _StatusBadge(
                            label: statusLabel,
                            color: statusColor,
                          ),
                          _MetaBadge(
                            icon: Icons.people_alt_outlined,
                            label: _genderLabel(reminder.targetGender),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${DateFormat('MMM dd, yyyy').format(reminder.scheduledAt)} • ${DateFormat('hh:mm a').format(reminder.scheduledAt.toLocal())}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  if (!isSent) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.deleting ? null : widget.onEdit,
                        borderRadius: BorderRadius.circular(10),
                        child: Ink(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.deleting ? null : widget.onDelete,
                      borderRadius: BorderRadius.circular(10),
                      child: Ink(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: widget.deleting
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red,
                                ),
                              )
                            : Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: Colors.red.shade400,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message preview',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reminder.message.trim(),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: cs.onSurface,
                      decoration:
                          isSent ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (hasError) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(.2)),
              ),
              child: Text(
                reminder.lastError!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _genderLabel(String g) {
    switch (g) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      default:
        return 'Everyone';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
