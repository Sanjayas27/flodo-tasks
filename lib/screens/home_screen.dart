// screens/home_screen.dart
// The main screen. Contains:
//   • App header with task count summary
//   • Status filter chips
//   • Debounced search bar (300ms)
//   • Drag-to-reorder task list with animated cards
//   • FAB to open the create screen

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _searchVisible = false;

  @override
  void initState() {
    super.initState();
    // Load tasks from backend when the screen first opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ── Search debounce ─────────────────────────────────────────────────────────
  // Cancel the previous timer on every keystroke, start a new 300ms timer.
  // The provider is only notified after the user stops typing for 300ms.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) context.read<TaskProvider>().setSearchQuery(value);
    });
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  Future<void> _openCreate() async {
    // Pre-load draft text before navigating
    await context.read<TaskProvider>().loadDraft();
    if (!mounted) return;
    _push(const TaskFormScreen());
  }

  void _openEdit(Task task) => _push(TaskFormScreen(task: task));

  void _push(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => screen,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildFilterChips(),
            AnimatedSize(
              duration: 250.ms,
              curve: Curves.easeOut,
              child: _searchVisible ? _buildSearchBar() : const SizedBox.shrink(),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        tooltip: 'New Task',
        child: const Icon(Icons.add_rounded, size: 28),
      ).animate().scale(delay: 400.ms, duration: 300.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Flodo Tasks',
                    style: Theme.of(context).textTheme.displayMedium)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.08),
                const SizedBox(height: 4),
                Consumer<TaskProvider>(
                  builder: (_, p, __) {
                    final done = p.allTasks
                        .where((t) => t.status == TaskStatus.done)
                        .length;
                    return Text(
                      '${p.allTasks.length} tasks · $done done',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ).animate().fadeIn(delay: 100.ms);
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: 200.ms,
              child: Icon(
                _searchVisible
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
                key: ValueKey(_searchVisible),
                color: _searchVisible
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
            ),
            onPressed: () {
              setState(() => _searchVisible = !_searchVisible);
              if (!_searchVisible) {
                _searchController.clear();
                context.read<TaskProvider>().setSearchQuery('');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => context.read<TaskProvider>().loadTasks(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<TaskProvider>(
      builder: (_, provider, __) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: provider.filterStatus == null,
                color: AppColors.textSecondary,
                onTap: () => provider.setFilterStatus(null),
              ),
              const SizedBox(width: 8),
              for (final status in TaskStatus.values) ...[
                _FilterChip(
                  label: status.label,
                  selected: provider.filterStatus == status,
                  color: status.color,
                  onTap: () => provider.setFilterStatus(
                      provider.filterStatus == status ? null : status),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        autofocus: true,
        style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search tasks by title…',
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textSecondary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    context.read<TaskProvider>().setSearchQuery('');
                  },
                )
              : null,
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildBody() {
    return Consumer<TaskProvider>(
      builder: (_, provider, __) {
        // Show error banner if connection failed
        if (provider.loadingState == LoadingState.error) {
          return _buildErrorState(provider);
        }

        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppColors.accent, strokeWidth: 2.5),
          );
        }

        final tasks = provider.filteredTasks;

        if (tasks.isEmpty) {
          return _buildEmptyState(provider);
        }

        // ReorderableListView provides built-in drag-to-reorder
        return ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount: tasks.length,
          proxyDecorator: _proxyDecorator,
          onReorder: (oldIdx, newIdx) {
            // Map filtered index → full list index before reordering
            final all = provider.allTasks.toList();
            final oldTask = tasks[oldIdx];
            final newTask = tasks[newIdx > oldIdx ? newIdx - 1 : newIdx];
            provider.reorderTasks(
                all.indexOf(oldTask), all.indexOf(newTask));
          },
          itemBuilder: (_, idx) {
            final task = tasks[idx];
            return TaskCard(
              key: ValueKey(task.id),
              task: task,
              searchQuery: provider.searchQuery,
              index: idx,
              onTap: () => _openEdit(task),
              onDelete: () => _confirmDelete(task),
            );
          },
        );
      },
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> anim) {
    return AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (_, child) => Transform.scale(
        scale: 1.03,
        child: Material(
          color: Colors.transparent,
          elevation: 10,
          shadowColor: AppColors.accent.withOpacity(0.25),
          child: child,
        ),
      ),
    );
  }

  Widget _buildEmptyState(TaskProvider provider) {
    final isFiltered =
        provider.filterStatus != null || provider.searchQuery.isNotEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFiltered ? Icons.search_off_rounded : Icons.task_alt_rounded,
            size: 60,
            color: AppColors.border,
          ),
          const SizedBox(height: 14),
          Text(
            isFiltered ? 'No tasks match your criteria' : 'No tasks yet',
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          if (!isFiltered) ...[
            const SizedBox(height: 6),
            const Text('Tap + to create your first task',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.92, 0.92));
  }

  Widget _buildErrorState(TaskProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.danger, size: 52),
            const SizedBox(height: 16),
            const Text(
              'Could not connect to backend',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? '',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                provider.clearError();
                provider.loadTasks();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Task',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Delete "${task.title}"?\nThis cannot be undone.',
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<TaskProvider>().deleteTask(task.id);
    }
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 180.ms,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.14)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
