import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bigreminder/models/super_admin_models/business_create_reminder.dart';

import '../../../providers/business/business_provider.dart';

// ---------------------------------------------------------------------------
// UPDATE REMINDER PROVIDER  (place in business_provider.dart if preferred)
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
  // ── form state ────────────────────────────────────────────────────────────
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _targetGender = 'all';
  DateTime _scheduledDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _scheduledTime = TimeOfDay.now();
  bool _isEditing = false;
  int? _editingReminderId;
  bool _submitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  DateTime get _combinedDateTime => DateTime(
    _scheduledDate.year,
    _scheduledDate.month,
    _scheduledDate.day,
    _scheduledTime.hour,
    _scheduledTime.minute,
  );

  void _resetForm() {
    _messageController.clear();
    _targetGender = 'all';
    _scheduledDate = DateTime.now().add(const Duration(hours: 1));
    _scheduledTime = TimeOfDay.now();
    _isEditing = false;
    _editingReminderId = null;
    _submitting = false;
  }

  Future<void> _pickDate(StateSetter setBottomSheetState) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    setBottomSheetState(() => _scheduledDate = date);
  }

  Future<void> _pickTime(StateSetter setBottomSheetState) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    setBottomSheetState(() => _scheduledTime = time);
  }

  // ── bottom sheet ──────────────────────────────────────────────────────────

  void _openSheet({BusinessReminderModel? reminder}) {
    if (reminder != null) {
      _messageController.text = reminder.message;
      _targetGender = reminder.targetGender;
      _scheduledDate = reminder.scheduledAt;
      _scheduledTime = TimeOfDay.fromDateTime(reminder.scheduledAt);
      _isEditing = true;
      _editingReminderId = reminder.id;
    } else {
      _resetForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setBottomSheetState) {
          final primary = Theme.of(ctx).primaryColor;
          final cs = Theme.of(ctx).colorScheme;
          final tt = Theme.of(ctx).textTheme;

          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // title
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isEditing
                              ? Icons.edit_rounded
                              : Icons.add_alarm_rounded,
                          color: primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEditing ? 'Edit Reminder' : 'New Reminder',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          fontSize: 16
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // message field
                  TextFormField(
                    controller: _messageController,
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Message is required'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      hintText: 'What should customers be reminded about?',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: cs.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: cs.outline.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: cs.error, width: 1.5),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: cs.error, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // target gender
                  DropdownButtonFormField<String>(
                    value: _targetGender,
                    decoration: InputDecoration(
                      labelText: 'Target audience',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: cs.outline.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primary, width: 1.5),
                      ),
                      prefixIcon: Icon(Icons.people_alt_outlined,
                          color: primary, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Everyone')),
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(
                          value: 'female', child: Text('Female')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setBottomSheetState(() => _targetGender = v);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // date + time row
                  Row(
                    children: [
                      Expanded(
                        child: _DateTimeTile(
                          icon: Icons.calendar_today_rounded,
                          label: 'Date',
                          value: DateFormat('MMM dd, yyyy')
                              .format(_scheduledDate),
                          primary: primary,
                          cs: cs,
                          tt: tt,
                          onTap: () => _pickDate(setBottomSheetState),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateTimeTile(
                          icon: Icons.access_time_rounded,
                          label: 'Time',
                          value: _scheduledTime.format(ctx),
                          primary: primary,
                          cs: cs,
                          tt: tt,
                          onTap: () => _pickTime(setBottomSheetState),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: OutlinedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(
                                color: cs.outline.withOpacity(0.5)),
                            foregroundColor: cs.onSurface,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _submitting
                              ? null
                              : () => _submit(sheetContext, setBottomSheetState),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: primary.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _submitting
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            _isEditing ? 'Save changes' : 'Schedule reminder',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() => _resetForm());
  }

  Future<void> _submit(BuildContext sheetCtx, StateSetter setBottomSheetState) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Update BOTH parent state and sheet state so button reacts
    setState(() => _submitting = true);
    setBottomSheetState(() => _submitting = true);

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

      if (mounted) {
        Navigator.pop(sheetCtx);
        _showToast(
          _isEditing ? 'Reminder updated' : 'Reminder scheduled',
          isError: false,
        );
      }
    } catch (e) {
      setState(() => _submitting = false);
      setBottomSheetState(() => _submitting = false);
      if (mounted) {
        _showToast(_friendlyError(e.toString()), isError: true);
      }
    }
  }

  // ── delete ────────────────────────────────────────────────────────────────

  void _confirmDelete(BuildContext ctx, int reminderId) {
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;

    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete reminder?',
            style: tt.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        content: Text(
          'This action cannot be undone.',
          style:
          tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.6)),
        ),
        actionsPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            style:
            TextButton.styleFrom(foregroundColor: cs.onSurface),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dCtx);
              _deleteReminder(reminderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReminder(int reminderId) async {
    try {
      await ref
          .read(deleteReminderProvider.notifier)
          .deleteReminder(reminderId: reminderId);
      if (mounted) _showToast('Reminder deleted', isError: false);
    } catch (e) {
      if (mounted) _showToast(_friendlyError(e.toString()), isError: true);
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  void _showToast(String message, {required bool isError}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
          backgroundColor: isError ? cs.error : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  String _friendlyError(String raw) {
    if (raw.contains('Business ID')) return 'Business not found. Please re-login.';
    if (raw.contains('Token')) return 'Session expired. Please re-login.';
    if (raw.contains('SocketException') || raw.contains('Connection')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reminderAsync = ref.watch(reminderListProvider);
    final primary = Theme.of(context).primaryColor;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.9),
      appBar: AppBar(
        title: const Text(
          'Reminders',
          style: TextStyle(fontWeight: FontWeight.w700,fontSize: 17),
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(reminderListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSheet(),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('New reminder',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: reminderAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: primary),
        ),
        error: (error, _) => _ErrorView(
          message: _friendlyError(error.toString()),
          onRetry: () => ref.invalidate(reminderListProvider),
          primary: primary,
          cs: cs,
          tt: tt,
        ),
        data: (reminders) {
          if (reminders.isEmpty) {
            return _EmptyView(primary: primary, cs: cs, tt: tt);
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(reminderListProvider),
            color: primary,
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: reminders.length,
              itemBuilder: (ctx, i) => _ReminderCard(
                reminder: reminders[i],
                primary: primary,
                cs: cs,
                tt: tt,
                onEdit: () => _openSheet(reminder: reminders[i]),
                onDelete: () => _confirmDelete(ctx, reminders[i].id),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DATE / TIME TILE
// ---------------------------------------------------------------------------

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.primary,
    required this.cs,
    required this.tt,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color primary;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: tt.labelSmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.5))),
                  const SizedBox(height: 2),
                  Text(value,
                      style: tt.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      )),
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
// REMINDER CARD
// ---------------------------------------------------------------------------

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.primary,
    required this.cs,
    required this.tt,
    required this.onEdit,
    required this.onDelete,
  });

  final BusinessReminderModel reminder;
  final Color primary;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isSent = reminder.status == 'sent';
    final isPending = !isSent && reminder.scheduledAt.isBefore(DateTime.now());
    final hasError =
        reminder.lastError != null && reminder.lastError!.isNotEmpty;

    final statusColor = isSent
        ? Colors.green.shade600
        : isPending
        ? Colors.orange.shade700
        : primary;

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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── top row ────────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // status indicator
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 18),
                ),
                const SizedBox(width: 12),
                // message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.message,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                          decoration:
                          isSent ? TextDecoration.lineThrough : null,
                          decorationColor: cs.onSurface.withOpacity(0.4),
                        ),
                        maxLines: 20,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── meta row ───────────────────────────────────────────────────
            const SizedBox(height: 12),
            Row(
              children: [
                _MetaChip(
                  icon: Icons.calendar_today_rounded,
                  label: DateFormat('MMM dd, yyyy').format(reminder.scheduledAt),
                  cs: cs,
                  tt: tt,
                ),
                const SizedBox(width: 8),
                _MetaChip(
                  icon: Icons.access_time_rounded,
                  label: DateFormat('hh:mm a').format(reminder.scheduledAt.toLocal()),
                  cs: cs,
                  tt: tt,
                ),
                const SizedBox(width: 8),
                _MetaChip(
                  icon: Icons.people_alt_outlined,
                  label: _genderLabel(reminder.targetGender),
                  cs: cs,
                  tt: tt,
                ),
              ],
            ),

            // ── error banner ───────────────────────────────────────────────
            if (hasError) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.error.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.error.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 16, color: cs.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reminder.lastError!,
                        style: tt.bodySmall?.copyWith(color: cs.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── actions ────────────────────────────────────────────────────
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isSent) ...[
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: primary,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 4),
                ],
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: cs.error,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
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

// ---------------------------------------------------------------------------
// SMALL REUSABLE WIDGETS
// ---------------------------------------------------------------------------

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.cs,
    required this.tt,
  });

  final IconData icon;
  final String label;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cs.outline.withOpacity(.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: cs.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.labelMedium?.copyWith(
              color: cs.onSurface.withOpacity(.75),
              fontWeight: FontWeight.w600,
              letterSpacing: .1,
            ),
          ),
        ],
      ),
    );
  }
}
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label,
          style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EMPTY + ERROR VIEWS
// ---------------------------------------------------------------------------

class _EmptyView extends StatelessWidget {
  const _EmptyView(
      {required this.primary, required this.cs, required this.tt});
  final Color primary;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_none_rounded,
                  size: 40, color: primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              'No reminders yet',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "New reminder" to schedule\nyour first customer notification.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium
                  ?.copyWith(color: cs.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.primary,
    required this.cs,
    required this.tt,
  });
  final String message;
  final VoidCallback onRetry;
  final Color primary;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.error.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded,
                  size: 40, color: cs.error.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),
            Text(
              'Couldn\'t load reminders',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: tt.bodyMedium
                  ?.copyWith(color: cs.onSurface.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}