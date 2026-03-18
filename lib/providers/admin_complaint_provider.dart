import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminComplaintProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> allComplaints = [];

  List<Map<String, dynamic>> get community =>
      allComplaints.where((c) => c['complaint_type'] == 'community').toList();

  List<Map<String, dynamic>> get personal =>
      allComplaints.where((c) => c['complaint_type'] == 'personal').toList();

  String? sectionId;
  bool loading = true;

  bool _realtimeStarted = false;

  // =============================
  // LOAD DATA
  // =============================

  Future<void> loadComplaints() async {
    loading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final currentSectionId = prefs.getString('admin_section_id');

    if (currentSectionId == null) {
      loading = false;
      notifyListeners();
      return;
    }

    sectionId = currentSectionId;

    try {
      final response = await supabase
          .from('complaints_with_upvotes')
          .select()
          .eq('section_id', currentSectionId)
          .order('created_at', ascending: false);

      allComplaints = List<Map<String, dynamic>>.from(response);

      _startRealtime(currentSectionId);
    } catch (e) {
      debugPrint("Admin complaint error: $e");
    }

    loading = false;
    notifyListeners();
  }

  // =============================
  // REALTIME
  // =============================

  void _startRealtime(String currentSectionId) {
    if (_realtimeStarted) return;
    _realtimeStarted = true;

    supabase
        .channel('admin-complaints')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'complaints',
          callback: (payload) {
            final record = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;

            if (record['section_id'] != sectionId) return;
            
            loadComplaints(); // keep this for now
          },
        )
        .subscribe();
  }

  // =============================
  // UPDATE STATUS
  // =============================

  Future<void> updateStatus(String id, String status) async {
    try {
      await supabase
          .from('complaints')
          .update({'status': status})
          .eq('complaint_id', id);

      final complaint = await supabase
          .from('complaints')
          .select('user_id')
          .eq('complaint_id', id)
          .single();

      await supabase.from('notifications').insert({
        'complaint_id': id,
        'user_id': complaint['user_id'],
        'recipient_type': 'user',
        'title': 'Complaint Status Updated',
        'message': 'Your complaint is now $status',
      });
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }
}
