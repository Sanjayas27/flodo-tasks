// providers/task_provider.dart
// The single source of truth for all task state.
// The UI never calls ApiService directly — it only talks to this provider.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/api_service.dart';

/// Describes what the provider is currently doing.
enum LoadingState { idle, loading, saving, error }

class TaskProvider extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  List<Task> _tasks = [];
  LoadingState _loadingState = LoadingState.idle;
  String? _errorMessage;

  // Search & filter
  String _searchQuery = '';
  TaskStatus? _filterStatus;

  // Drafts (create screen only)
  String _draftTitle = '';
  String _draftDescription = '';

  // ── Public getters ─────────────────────────────────────────────────────────

  List<Task> get allTasks => List.unmodifiable(_tasks);
  LoadingState get loadingState => _loadingState;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get isSaving => _loadingState == LoadingState.saving;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  TaskStatus? get filterStatus => _filterStatus;
  String get draftTitle => _draftTitle;
  String get draftDescription => _draftDescription;

  /// The list of tasks after applying search and status filter.
  List<Task> get filteredTasks {
    var result = List<Task>.from(_tasks);

    if (_filterStatus != null) {
      result = result.where((t) => t.status == _filterStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((t) => t.title.toLowerCase().contains(q)).toList();
    }

    return result;
  }

  /// Returns true if [task] is currently blocked (its blocker is not Done).
  bool isBlocked(Task task) {
    if (task.blockedById == null) return false;
    final blocker = _tasks.firstWhere(
      (t) => t.id == task.blockedById,
      orElse: () => Task(
        id: '',
        title: '',
        description: '',
        dueDate: DateTime.now(),
        status: TaskStatus.done, // default to not-blocking if not found
        createdAt: DateTime.now(),
      ),
    );
    return blocker.status != TaskStatus.done;
  }

  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> loadTasks() async {
    _setState(LoadingState.loading);
    try {
      _tasks = await ApiService.getTasks(
        status: _filterStatus?.label,
        // Don't pass search here — filtering is done client-side for instant feedback
      );
      _setState(LoadingState.idle);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<void> createTask({
    required String title,
    required String description,
    required DateTime dueDate,
    TaskStatus status = TaskStatus.todo,
    String? blockedById,
    RecurringType recurringType = RecurringType.none,
  }) async {
    _setState(LoadingState.saving);
    try {
      final draft = Task(
        id: 'temp', // backend will assign real ID
        title: title,
        description: description,
        dueDate: dueDate,
        status: status,
        blockedById: blockedById,
        recurringType: recurringType,
        sortOrder: _tasks.length,
        createdAt: DateTime.now(),
      );

      final created = await ApiService.createTask(draft);
      _tasks.add(created);
      await clearDraft();
      _setState(LoadingState.idle);
    } catch (e) {
      _setError(e.toString());
      rethrow; // let the form screen show the error too
    }
  }

  Future<void> updateTask(Task task) async {
    _setState(LoadingState.saving);
    try {
      final updated = await ApiService.updateTask(task);
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        _tasks[idx] = updated;
        // If a new recurring task was spawned server-side, refresh the list
        if (updated.status == TaskStatus.done && updated.isRecurring) {
          _tasks = await ApiService.getTasks(status: _filterStatus?.label);
        }
      }
      _setState(LoadingState.idle);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    // Optimistic removal — remove immediately, re-add if server fails
    final removed = _tasks.firstWhere((t) => t.id == id);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();

    try {
      await ApiService.deleteTask(id);
    } catch (e) {
      _tasks.add(removed); // Restore on failure
      _setError(e.toString());
    }
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final task = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, task);
    notifyListeners(); // Update UI immediately

    try {
      await ApiService.reorderTasks(_tasks.map((t) => t.id).toList());
    } catch (_) {
      // Non-critical; ignore reorder errors silently
    }
  }

  // ── Search & Filter ────────────────────────────────────────────────────────

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Future<void> setFilterStatus(TaskStatus? status) async {
    _filterStatus = status;
    notifyListeners();
    await loadTasks(); // Re-fetch from backend with new filter
  }

  // ── Draft management ───────────────────────────────────────────────────────

  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    _draftTitle = prefs.getString('draft_title') ?? '';
    _draftDescription = prefs.getString('draft_description') ?? '';
    notifyListeners();
  }

  Future<void> saveDraft(String title, String description) async {
    _draftTitle = title;
    _draftDescription = description;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_title', title);
    await prefs.setString('draft_description', description);
  }

  Future<void> clearDraft() async {
    _draftTitle = '';
    _draftDescription = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_title');
    await prefs.remove('draft_description');
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setState(LoadingState state) {
    _loadingState = state;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _loadingState = LoadingState.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _loadingState = LoadingState.idle;
    notifyListeners();
  }
}
