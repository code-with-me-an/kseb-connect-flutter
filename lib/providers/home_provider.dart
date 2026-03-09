import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math';
class HomeProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  String userName = "User";
  String locationName = "";
  bool loading = true;

  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> nearbyComplaints = [];
  Future<void> loadHomeData() async {
    loading = true;
    notifyListeners();

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
   Position position = await Geolocator.getCurrentPosition();

final results = await Future.wait([
  _fetchUserName(user.id),
  _fetchLocation(),
  _fetchNotifications(user.id),
]);

await _fetchNearbyComplaints(position);

      userName = results[0] as String;
      locationName = results[1] as String;
      notifications = results[2] as List<Map<String, dynamic>>;
    } catch (e) {
      debugPrint(e.toString());
    }

    loading = false;
    notifyListeners();
  }

  Future<String> _fetchUserName(String id) async {
    final response = await supabase
        .from('users')
        .select('name')
        .eq('id', id)
        .maybeSingle();

    return response?['name'] ?? "User";
  }

  Future<String> _fetchLocation() async {
    Position position = await Geolocator.getCurrentPosition();

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    return placemarks.first.locality ?? "Unknown";
  }

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
  Future<void> _fetchNearbyComplaints(Position userPosition) async {

  final response = await supabase
      .from('complaints')
      .select('complaint_id, category, latitude, longitude, status, created_at')
      .order('created_at', ascending: false);

  nearbyComplaints = [];

  for (var complaint in response) {

    if (complaint['latitude'] != null && complaint['longitude'] != null) {

      double distance = calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        complaint['latitude'].toDouble(),
        complaint['longitude'].toDouble(),
      );

    if (distance <= 5) {

  final locationName = await getLocationName(
    complaint['latitude'].toDouble(),
    complaint['longitude'].toDouble(),
  );

  complaint['distance'] = distance;
  complaint['locationName'] = locationName;

  nearbyComplaints.add(complaint);
}
    }
  }
}
}
double calculateDistance(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadius = 6371; // km

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
Future<String> getLocationName(double lat, double lng) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;

      return place.locality ??
          place.subLocality ??
          place.administrativeArea ??
          "Unknown";
    }
  } catch (e) {
    debugPrint(e.toString());
  }

  return "Unknown";
}