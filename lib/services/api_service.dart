// services/api_service.dart
// Centralises every HTTP call to the FastAPI backend.
// Change [baseUrl] to your machine's IP when running on a physical device.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  // ⚠️ Use 10.0.2.2 for Android emulator (maps to host machine's localhost).
  // For a real device on the same Wi-Fi, replace with your machine's local IP,
  // e.g. 'http://192.168.1.5:8000'
  static const String baseUrl = 'http://192.168.1.100:8000';

  static final _headers = {'Content-Type': 'application/json'};

  // ── GET /tasks ──────────────────────────────────────────────────────────────

  /// Fetch all tasks. Optionally filter by [status] and/or [search] query.
  static Future<List<Task>> getTasks({
    String? status,
    String? search,
  }) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('$baseUrl/tasks').replace(queryParameters: params);
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    _checkStatus(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((j) => Task.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ── POST /tasks ─────────────────────────────────────────────────────────────

  /// Create a new task. The backend adds a 2-second delay.
  static Future<Task> createTask(Task task) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/tasks'),
          headers: _headers,
          body: jsonEncode(task.toJson()),
        )
        .timeout(const Duration(seconds: 15));

    _checkStatus(response);
    return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ── PUT /tasks/:id ───────────────────────────────────────────────────────────

  /// Update an existing task. The backend adds a 2-second delay.
  static Future<Task> updateTask(Task task) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/tasks/${task.id}'),
          headers: _headers,
          body: jsonEncode(task.toJson()),
        )
        .timeout(const Duration(seconds: 15));

    _checkStatus(response);
    return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ── DELETE /tasks/:id ────────────────────────────────────────────────────────

  static Future<void> deleteTask(String id) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/tasks/$id'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 204) {
      _checkStatus(response);
    }
  }

  // ── PATCH /tasks/reorder ─────────────────────────────────────────────────────

  static Future<void> reorderTasks(List<String> orderedIds) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/tasks/reorder'),
          headers: _headers,
          body: jsonEncode({'ordered_ids': orderedIds}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 204) {
      _checkStatus(response);
    }
  }

  // ── Error handling ───────────────────────────────────────────────────────────

  static void _checkStatus(http.Response response) {
    if (response.statusCode >= 400) {
      final body = response.body;
      String message;
      try {
        message = (jsonDecode(body) as Map)['detail']?.toString() ?? body;
      } catch (_) {
        message = body;
      }
      throw ApiException(response.statusCode, message);
    }
  }
}

/// Typed exception so the UI can show meaningful error messages.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'API $statusCode: $message';
}
