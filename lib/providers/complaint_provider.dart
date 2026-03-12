import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

import '../services/realtime_service.dart';

class ComplaintProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> complaints = [];
  List<Map<String, dynamic>> nearbyComplaints = [];

  Position? userLocation;

  bool loading = true;
  bool _realtimeStarted = false;

  // ===============================
  // LOAD COMPLAINTS
  // ===============================

  Future<void> loadComplaints() async {
    loading = true;
    notifyListeners();

    try {
      final response = await supabase
          .from('complaints')
          .select('''
          complaint_id,
          user_id,
          complaint_type,
          category,
          description,
          latitude,
          longitude,
          location_name,
          status,
          created_at,
          upvotes(count)
          ''')
          .order('created_at', ascending: false);

      complaints = List<Map<String, dynamic>>.from(response);

      await updateNearbyComplaints();

      startRealtime();
    } catch (e) {
      debugPrint("Complaint load error: $e");
    }

    loading = false;
    notifyListeners();
  }

  // ===============================
  // GET USER LOCATION
  // ===============================

  Future<void> getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) return;

    userLocation = await Geolocator.getCurrentPosition();
  }

  // ===============================
  // UPDATE NEARBY COMPLAINTS
  // ===============================

  Future<void> updateNearbyComplaints() async {
    await getUserLocation();

    if (userLocation == null) return;

    const radius = 0.05;

    final minLat = userLocation!.latitude - radius;
    final maxLat = userLocation!.latitude + radius;

    final minLng = userLocation!.longitude - radius;
    final maxLng = userLocation!.longitude + radius;

    nearbyComplaints = complaints
        .where((c) {
          if (c['complaint_type'] != 'community') return false;

          final lat = (c['latitude'] as num?)?.toDouble();
          final lng = (c['longitude'] as num?)?.toDouble();

          if (lat == null || lng == null) return false;

          return lat >= minLat &&
              lat <= maxLat &&
              lng >= minLng &&
              lng <= maxLng;
        })
        .map((c) {
          final lat = (c['latitude'] as num).toDouble();
          final lng = (c['longitude'] as num).toDouble();

          final distance = calculateDistance(
            userLocation!.latitude,
            userLocation!.longitude,
            lat,
            lng,
          );

          return {
            "id": c['complaint_id'],
            "title": c['category'],
            "description": c['description'],
            "status": c['status'],
            "distance": distance,
            "locationName": c['location_name'],
            "upvotes": (c['upvotes'] as List).isNotEmpty
                ? c['upvotes'][0]['count']
                : 0,
            "point": LatLng(lat, lng),
            "latitude": lat,
            "longitude": lng,
          };
        })
        .toList();

    nearbyComplaints.sort(
      (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
    );

    notifyListeners();
  }

  // ===============================
  // REALTIME SYSTEM
  // ===============================

  void startRealtime() {
    if (_realtimeStarted) return;

    _realtimeStarted = true;

    /// new complaints
    RealtimeService.onComplaint = (data) async {
      final id = data['complaint_id'];

      final exists = complaints.any((c) => c['complaint_id'] == id);

      if (exists) return;

      final response = await supabase
          .from('complaints')
          .select('''
        complaint_id,
        user_id,
        complaint_type,
        category,
        description,
        latitude,
        longitude,
        status,
        created_at,
        upvotes(count)
      ''')
          .eq('complaint_id', id)
          .single();

      complaints.insert(0, response);

      await updateNearbyComplaints();

      notifyListeners();
    };

    /// realtime upvotes
    RealtimeService.onUpvote = (data) {
      final id = data['complaint_id'];

      for (var c in complaints) {
        if (c['complaint_id'] == id) {
          final upvoteList = c['upvotes'] as List?;
          if (upvoteList != null && upvoteList.isNotEmpty) {
            upvoteList[0]['count'] += 1;
          }
        }
      }

      updateNearbyComplaints();
    };
  }

  // ===============================
  // USER COMPLAINTS
  // ===============================

  List<Map<String, dynamic>> userComplaints(String userId) {
    return complaints.where((c) => c['user_id'] == userId).toList();
  }

  // ===============================
  // DISTANCE CALCULATION
  // ===============================

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371;

    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}
