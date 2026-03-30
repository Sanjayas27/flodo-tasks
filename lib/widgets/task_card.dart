// widgets/task_card.dart
// The main list item. Communicates blocked state, status, due date, and
// search-match highlighting all at a glance.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'highlighted_text.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final String searchQuery;
  final int index; // Used for staggered entrance animation
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.searchQuery,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TaskProvider>();
    final blocked = provider.isBlocked(task);
    final blocker = task.blockedById != null
        ? provider.getTaskById(task.blockedById!)
        : null;

    return Animate(
      effects: [
        FadeEffect(duration: 280.ms, delay: (index * 45).ms),
        SlideEffect(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
          duration: 280.ms,
          delay: (index * 45).ms,
          curve: Curves.easeOut,
        ),
      ],
      child: Dismissible(
        key: ValueKey(task.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          onDelete();
          return false; // We handle deletion ourselves via dialog
        },
        background: _DismissBackground(),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedOpacity(
            opacity: blocked ? 0.48 : 1.0,
            duration: 220.ms,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: blocked
                      ? AppColors.border
                      : task.status.color.withOpacity(0.22),
                  width: 1.2,
                ),
                boxShadow: blocked
                    ? []
                    : [
                        BoxShadow(
                          color: task.status.color.withOpacity(0.07),
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Coloured accent line at the top — changes with status
                    AnimatedContainer(
                      duration: 300.ms,
                      height: 3,
                      color: blocked ? AppColors.border : task.status.color,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title row
                          Row(
                            children: [
                              Icon(
                                task.status.icon,
                                color: blocked
                                    ? AppColors.textSecondary
                                    : task.status.color,
                                size: 17,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: HighlightedText(
                                  text: task.title,
                                  highlight: searchQuery,
                                  baseStyle: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: blocked
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                    decoration: task.status == TaskStatus.done
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusChip(task: task, blocked: blocked),
                            ],
                          ),

                          // Description (if any)
                          if (task.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              task.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: blocked
                                    ? AppColors.textSecondary.withOpacity(0.55)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Bottom metadata row
                          Row(
                            children: [
                              Flexible(
                                child: _DueDateChip(task: task),
                              ),
                              if (task.isRecurring) ...[
                                const SizedBox(width: 6),
                                _RecurringChip(task: task),
                              ],
                              if (blocked && blocker != null) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: _BlockedByChip(blocker: blocker),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.danger.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_outline_rounded,
              color: AppColors.danger, size: 22),
          const SizedBox(height: 4),
          const Text('Delete',
              style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Task task;
  final bool blocked;
  const _StatusChip({required this.task, required this.blocked});

  @override
  Widget build(BuildContext context) {
    final color = blocked ? AppColors.textSecondary : task.status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: blocked ? AppColors.border : task.status.color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        task.status.label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _DueDateChip extends StatelessWidget {
  final Task task;
  const _DueDateChip({required this.task});

  @override
  Widget build(BuildContext context) {
    final overdue =
        task.dueDate.isBefore(DateTime.now()) && task.status != TaskStatus.done;
    final color = overdue ? AppColors.danger : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          overdue ? Icons.warning_amber_rounded : Icons.calendar_today_rounded,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          DateFormat('MMM d, yyyy').format(task.dueDate),
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: overdue ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _RecurringChip extends StatelessWidget {
  final Task task;
  const _RecurringChip({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.statusTodo.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat_rounded,
              size: 11, color: AppColors.statusTodo),
          const SizedBox(width: 3),
          Text(
            task.recurringType.label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.statusTodo,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedByChip extends StatelessWidget {
  final Task blocker;
  const _BlockedByChip({required this.blocker});

  @override
  Widget build(BuildContext context) {
    final name = blocker.title.length > 8
        ? '${blocker.title.substring(0, 8)}…'
        : blocker.title;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.09),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.danger.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 11, color: AppColors.danger),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Blocked by "$name"',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.danger,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
