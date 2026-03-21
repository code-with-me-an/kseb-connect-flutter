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
    // 🔹 Always fetch latest complaint from DB (avoid stale data)
    final latestComplaint = await supabase
        .from('complaints')
        .select()
        .eq('complaint_id', complaintId)
        .single();

    // 🔹 Normalize rejected_sections to Set<String>
    final Set<String> rejected =
        (latestComplaint['rejected_sections'] as List? ?? [])
            .map((e) => e.toString())
            .toSet();

    // 🔹 Add current section
    final currentSectionId =
        latestComplaint['section_id'].toString();
    rejected.add(currentSectionId);

    // 🔹 Find next nearest section
    final nextSectionId = await findNextNearestSection(
      latestComplaint['latitude'],
      latestComplaint['longitude'],
      rejected.toList(),
    );

    if (nextSectionId == null) {
      debugPrint("No available section to reassign");
      return;
    }

    // 🔹 Update complaint safely
    await supabase
        .from('complaints')
        .update({
          'section_id': nextSectionId,
          'rejected_sections': rejected.toList(),
          'status': 'awaiting_assignment',
        })
        .eq('complaint_id', complaintId);

    // 🔔 Notify user
    await supabase.from('notifications').insert({
      'complaint_id': complaintId,
      'user_id': latestComplaint['user_id'],
      'recipient_type': 'user',
      'title': 'Complaint Reassigned',
      'message':
          'Your complaint is being reassigned to another section',
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
    const double radius = 0.2;

    // 🔹 Normalize rejected list once (IMPORTANT)
    final Set<String> rejectedSet =
        rejectedSections.map((e) => e.toString()).toSet();

    final sections = await supabase
        .from('sections')
        .select('''
          section_id,
          latitude,
          longitude,
          officers!inner(
            officer_id,
            is_active
          )
        ''')
        .eq('officers.is_active', true)
        .gte('latitude', lat - radius)
        .lte('latitude', lat + radius)
        .gte('longitude', lng - radius)
        .lte('longitude', lng + radius)
        .eq('is_active', true);

    String? nearestId;
    double minDistance = double.infinity;

    for (var section in sections) {
      final id = section['section_id'].toString();

      // 🔴 Critical fix: proper comparison
      if (rejectedSet.contains(id)) continue;

      final sLat = section['latitude'];
      final sLng = section['longitude'];

      if (sLat == null || sLng == null) continue;

      final distance = _calculateDistance(lat, lng, sLat, sLng);

      if (distance < minDistance) {
        minDistance = distance;
        nearestId = id;
      }
    }

    return nearestId;
  } catch (e) {
    debugPrint("Section find error: $e");
    return null;
  }
}

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // in KM

    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);

    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Distance in KM
  }

  double _deg2rad(double deg) {
    return deg * (pi / 180);
  }
}
