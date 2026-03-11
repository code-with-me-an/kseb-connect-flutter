import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math';
import '../services/location_service.dart';

class HomeProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  late final RealtimeChannel _channel;

  String userName = "User";
  String locationName = "";
  bool loading = true;

  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> nearbyComplaints = [];

  // ================= REALTIME =================

  void startRealtime() {
    _channel = supabase.channel('home_realtime');

    _channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            loadHomeData(forceRefresh: true);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'complaints',
          callback: (payload) {
            fetchNearbyComplaints();
          },
        )
        .subscribe();
  }

  // ================= LOAD HOME DATA =================

  Future<void> loadHomeData({bool forceRefresh = false}) async {
    loading = true;
    notifyListeners();

    final user = supabase.auth.currentUser;
    if (user == null) {
      loading = false;
      return;
    }

    try {
      final results = await Future.wait([
        _fetchUserName(user.id),
        _fetchLocation(),
        _fetchNotifications(user.id),
      ]);

      userName = results[0] as String;
      locationName = results[1] as String;
      notifications = results[2] as List<Map<String, dynamic>>;

      await fetchNearbyComplaints();
    } catch (e) {
      debugPrint(e.toString());
    }

    loading = false;
    notifyListeners();
  }

  // ================= FETCH NEARBY COMPLAINTS =================

  Future<void> fetchNearbyComplaints() async {
    try {
      final position = await LocationService.getCurrentLocation();

      const double radiusInDegrees = 0.05;

      final minLat = position.latitude - radiusInDegrees;
      final maxLat = position.latitude + radiusInDegrees;

      final minLng = position.longitude - radiusInDegrees;
      final maxLng = position.longitude + radiusInDegrees;

      final response = await supabase
          .from('complaints')
          .select(
              'complaint_id, category, description, latitude, longitude, status, created_at')
          .eq('complaint_type', 'community')
          .gte('latitude', minLat)
          .lte('latitude', maxLat)
          .gte('longitude', minLng)
          .lte('longitude', maxLng)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> complaints = [];

      for (var complaint in response) {
        if (complaint['latitude'] != null && complaint['longitude'] != null) {
          double lat = (complaint['latitude'] as num).toDouble();
          double lng = (complaint['longitude'] as num).toDouble();

          double distance = calculateDistance(
              position.latitude, position.longitude, lat, lng);

          complaint['distance'] = distance;

          complaints.add(complaint);
        }
      }

      complaints.sort(
          (a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      nearbyComplaints = complaints;

      notifyListeners();
    } catch (e) {
      debugPrint("Nearby complaints error: $e");
    }
  }

  // ================= USER NAME =================

  Future<String> _fetchUserName(String id) async {
    final response =
        await supabase.from('users').select('name').eq('id', id).maybeSingle();

    return response?['name'] ?? "User";
  }

  // ================= USER LOCATION =================

  Future<String> _fetchLocation() async {
    final position = await LocationService.getCurrentLocation();

    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    return placemarks.first.locality ?? "Unknown";
  }

  // ================= NOTIFICATIONS =================

  Future<List<Map<String, dynamic>>> _fetchNotifications(String id) async {
    final connections = await supabase
        .from('consumer_connections')
        .select('section_id')
        .eq('user_id', id);

    if (connections.isEmpty) return [];

    final sectionIds = connections.map((c) => c['section_id']).toList();

    final response = await supabase
        .from('notifications')
        .select()
        .inFilter('section_id', sectionIds)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ================= DISTANCE CALCULATION =================

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371;

    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  @override
  void dispose() {
    supabase.removeChannel(_channel);
    super.dispose();
  }
}