import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboardProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  int total = 0;
  int pending = 0;
  int inProgress = 0;
  int resolved = 0;

  bool loading = true;

  String? sectionId;
  RealtimeChannel? _channel;

  // ================================
  // LOAD INITIAL DATA
  // ================================
  Future<void> loadDashboard() async {
    loading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    sectionId = prefs.getString('admin_section_id');

    if (sectionId == null) {
      loading = false;
      notifyListeners();
      return;
    }

    final response = await supabase
        .from('complaints')
        .select('status')
        .eq('section_id', sectionId!);

    _calculateCounts(response);

    _startRealtime(); // start realtime here

    loading = false;
    notifyListeners();
  }

  // ================================
  // COUNT LOGIC
  // ================================
  void _calculateCounts(List data) {
    total = data.length;
    pending = 0;
    inProgress = 0;
    resolved = 0;

    for (var c in data) {
      if (c['status'] == 'pending') pending++;
      if (c['status'] == 'in-progress') inProgress++;
      if (c['status'] == 'resolved') resolved++;
    }
  }

  // ================================
  // REALTIME
  // ================================
  void _startRealtime() {
    if (_channel != null) {
      supabase.removeChannel(_channel!);
    }

    _channel = supabase.channel('admin-dashboard')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'complaints',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'section_id',
          value: sectionId,
        ),
        callback: _handleRealtime,
      )
      ..subscribe();
  }

  void _handleRealtime(PostgresChangePayload payload) {
    final newData = payload.newRecord;
    final oldData = payload.oldRecord;

    // INSERT
    if (payload.eventType == PostgresChangeEvent.insert) {
      total++;
      _increment(newData['status']);
    }

    // UPDATE
    if (payload.eventType == PostgresChangeEvent.update) {
      final oldStatus = oldData['status'];
      final newStatus = newData['status'];

      if (oldStatus != newStatus) {
        _decrement(oldStatus);
        _increment(newStatus);
      }
    }
    if (payload.eventType == PostgresChangeEvent.delete) {
      total = total > 0 ? total - 1 : 0;

      if (oldData.isNotEmpty && oldData['status'] != null) {
        _decrement(oldData['status']);
      } else {
        // fallback (important)
        loadDashboard(); // force refresh
        return;
      }
    }

    notifyListeners();
  }

  void _increment(String status) {
    if (status == 'pending') pending++;
    if (status == 'in-progress') inProgress++;
    if (status == 'resolved') resolved++;
  }

  void _decrement(String status) {
    if (status == 'pending') pending--;
    if (status == 'in-progress') inProgress--;
    if (status == 'resolved') resolved--;
  }

  @override
  void dispose() {
    if (_channel != null) {
      supabase.removeChannel(_channel!);
    }
    super.dispose();
  }
}
