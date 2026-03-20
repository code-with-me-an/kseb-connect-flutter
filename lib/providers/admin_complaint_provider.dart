import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class AdminComplaintProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> allComplaints = [];

  List<Map<String, dynamic>> get community =>
      allComplaints.where((c) => c['complaint_type'] == 'community').toList();

  List<Map<String, dynamic>> get personal =>
      allComplaints.where((c) => c['complaint_type'] == 'personal').toList();

  Map<String, dynamic>? getComplaintById(String id) {
    try {
      return allComplaints.firstWhere((c) => c['complaint_id'] == id);
    } catch (e) {
      return null;
    }
  }

  String? sectionId;
  bool loading = true;

  bool _realtimeStarted = false;

  double? sectionLat;
  double? sectionLng;

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

    final sectionData = await supabase
        .from('sections')
        .select('latitude, longitude')
        .eq('section_id', currentSectionId)
        .single();

    sectionLat = sectionData['latitude'];
    sectionLng = sectionData['longitude'];

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

  Future<void> rejectAndReassign(String complaintId) async {
    try {
      final complaint = allComplaints.firstWhere(
        (c) => c['complaint_id'] == complaintId,
      );

      // 🔹 Get rejected sections
      List rejected = complaint['rejected_sections'] ?? [];
      rejected = List.from(rejected);

      // 🔹 Add current section
      rejected.add(complaint['section_id']);

      // 🔹 Find next nearest section
      final nextSectionId = await findNextNearestSection(
        complaint['latitude'],
        complaint['longitude'],
        rejected,
      );

      if (nextSectionId == null) {
        debugPrint("No available section to reassign");
        return;
      }

      // 🔥 Update complaint
      await supabase
          .from('complaints')
          .update({
            'section_id': nextSectionId,
            'rejected_sections': rejected,
            'status': 'awaiting_assignment',
          })
          .eq('complaint_id', complaintId);

      // 🔔 Optional: notify user
      await supabase.from('notifications').insert({
        'complaint_id': complaintId,
        'user_id': complaint['user_id'],
        'recipient_type': 'user',
        'title': 'Complaint Reassigned',
        'message': 'Your complaint is being reassigned to another section',
      });
    } catch (e) {
      debugPrint("Reject error: $e");
    }
  }

  Future<String?> findNextNearestSection(
    double? lat,
    double? lng,
    List rejectedSections,
  ) async {
    if (lat == null || lng == null) return null;

    try {
      final sections = await supabase.from('sections').select();

      String? nearestId;
      double minDistance = double.infinity;

      for (var section in sections) {
        if (rejectedSections.contains(section['section_id'])) continue;

        final sLat = section['latitude'];
        final sLng = section['longitude'];

        if (sLat == null || sLng == null) continue;

        final distance = sqrt(pow(lat - sLat, 2) + pow(lng - sLng, 2));

        if (distance < minDistance) {
          minDistance = distance;
          nearestId = section['section_id'];
        }
      }

      return nearestId;
    } catch (e) {
      debugPrint("Section find error: $e");
      return null;
    }
  }
}
