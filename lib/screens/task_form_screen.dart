// PASTE THIS ENTIRE FILE INTO:
// lib/screens/task_form_screen.dart
// (Select all with Ctrl+A, delete, paste this)

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TaskStatus _status = TaskStatus.todo;
  String? _blockedById;
  RecurringType _recurringType = RecurringType.none;
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TaskProvider>();

    if (_isEditing) {
      final t = widget.task!;
      _titleCtrl = TextEditingController(text: t.title);
      _descCtrl = TextEditingController(text: t.description);
      _dueDate = t.dueDate;
      _status = t.status;
      _recurringType = t.recurringType;
      // Only set blockedById if blocker actually exists in task list
      final blockerExists = provider.allTasks
          .any((t2) => t2.id == t.blockedById && t2.id != widget.task!.id);
      _blockedById = blockerExists ? t.blockedById : null;
    } else {
      _titleCtrl = TextEditingController(text: provider.draftTitle);
      _descCtrl = TextEditingController(text: provider.draftDescription);
      _titleCtrl.addListener(_autosaveDraft);
      _descCtrl.addListener(_autosaveDraft);
    }
  }

  void _autosaveDraft() {
    context.read<TaskProvider>().saveDraft(_titleCtrl.text, _descCtrl.text);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.surfaceElevated,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final provider = context.read<TaskProvider>();

      if (_isEditing) {
        final updated = widget.task!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          dueDate: _dueDate,
          status: _status,
          blockedById: _blockedById,
          clearBlockedBy: _blockedById == null,
          recurringType: _recurringType,
        );
        await provider.updateTask(updated);
      } else {
        await provider.createTask(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          dueDate: _dueDate,
          status: _status,
          blockedById: _blockedById,
          recurringType: _recurringType,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing ? '✓ Task updated' : '✓ Task created'),
          backgroundColor: AppColors.statusDone.withOpacity(0.9),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger.withOpacity(0.9),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.danger),
                  tooltip: 'Delete Task',
                  onPressed: _isSaving ? null : _confirmDelete,
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionLabel('Task Title', Icons.title_rounded),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              enabled: !_isSaving,
              textCapitalization: TextCapitalization.sentences,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'What needs to be done?',
                prefixIcon: Icon(Icons.edit_rounded,
                    color: AppColors.textSecondary, size: 20),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),
            _buildSectionLabel('Description', Icons.notes_rounded),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              enabled: !_isSaving,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Add details (optional)',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.subject_rounded,
                    color: AppColors.textSecondary, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionLabel('Due Date', Icons.calendar_today_rounded),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isSaving ? null : _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: AppColors.accent, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_dueDate),
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionLabel('Status', Icons.flag_rounded),
            const SizedBox(height: 8),
            _buildStatusSelector(),
            const SizedBox(height: 20),
            _buildSectionLabel(
                'Blocked By (Optional)', Icons.lock_outline_rounded),
            const SizedBox(height: 4),
            Text(
              'This task cannot start until the selected task is Done',
              style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 11),
            ),
            const SizedBox(height: 8),
            _buildBlockedByDropdown(),
            const SizedBox(height: 20),
            _buildSectionLabel('Repeat', Icons.repeat_rounded),
            const SizedBox(height: 8),
            _buildRecurringSelector(),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                child: AnimatedSwitcher(
                  duration: 200.ms,
                  child: _isSaving
                      ? Row(
                          key: const ValueKey('saving'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.background,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isEditing ? 'Updating…' : 'Creating…',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ],
                        )
                      : Row(
                          key: const ValueKey('idle'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_isEditing
                                ? Icons.save_rounded
                                : Icons.add_rounded),
                            const SizedBox(width: 8),
                            Text(
                              _isEditing ? 'Update Task' : 'Create Task',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.accent),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelector() {
    return Row(
      children: TaskStatus.values.map((s) {
        final selected = _status == s;
        return Expanded(
          child: GestureDetector(
            onTap: _isSaving ? null : () => setState(() => _status = s),
            child: AnimatedContainer(
              duration: 180.ms,
              margin: EdgeInsets.only(right: s != TaskStatus.done ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? s.color.withOpacity(0.18)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? s.color : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(s.icon,
                      color: selected ? s.color : AppColors.textSecondary,
                      size: 20),
                  const SizedBox(height: 4),
                  Text(
                    s.label,
                    style: TextStyle(
                      color: selected ? s.color : AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBlockedByDropdown() {
    return Consumer<TaskProvider>(
      builder: (_, provider, __) {
        final otherTasks =
            provider.allTasks.where((t) => t.id != widget.task?.id).toList();

        // Reset if selected task no longer exists
        if (_blockedById != null &&
            !otherTasks.any((t) => t.id == _blockedById)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _blockedById = null);
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _blockedById != null
                  ? AppColors.danger.withOpacity(0.4)
                  : AppColors.border,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _blockedById ?? '__none__',
              isExpanded: true,
              dropdownColor: AppColors.surfaceElevated,
              icon: const Icon(Icons.expand_more_rounded,
                  color: AppColors.textSecondary),
              items: [
                DropdownMenuItem<String>(
                  value: '__none__',
                  child: Row(children: const [
                    Icon(Icons.lock_open_rounded,
                        color: AppColors.textSecondary, size: 18),
                    SizedBox(width: 10),
                    Text('Not blocked',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14)),
                  ]),
                ),
                ...otherTasks.map((t) => DropdownMenuItem<String>(
                      value: t.id,
                      child: Row(children: [
                        const Icon(Icons.lock_outline_rounded,
                            color: AppColors.danger, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 14),
                          ),
                        ),
                      ]),
                    )),
              ],
              onChanged: _isSaving
                  ? null
                  : (v) => setState(
                      () => _blockedById = (v == '__none__') ? null : v),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecurringSelector() {
    return Row(
      children: RecurringType.values.map((r) {
        final selected = _recurringType == r;
        final color = r == RecurringType.none
            ? AppColors.textSecondary
            : AppColors.statusTodo;
        return Expanded(
          child: GestureDetector(
            onTap: _isSaving ? null : () => setState(() => _recurringType = r),
            child: AnimatedContainer(
              duration: 180.ms,
              margin: EdgeInsets.only(right: r != RecurringType.weekly ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? color.withOpacity(0.15)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? color : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    r == RecurringType.none
                        ? Icons.block_rounded
                        : Icons.repeat_rounded,
                    color: selected ? color : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r == RecurringType.none ? 'Once' : r.label,
                    style: TextStyle(
                      color: selected ? color : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Task',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Delete "${widget.task!.title}"?\nThis cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<TaskProvider>().deleteTask(widget.task!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}
