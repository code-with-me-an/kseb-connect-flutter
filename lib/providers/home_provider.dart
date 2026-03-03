import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomeProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  String userName = "User";
  String locationName = "";
  bool loading = true;

  List<Map<String, dynamic>> notifications = [];

  Future<void> loadHomeData() async {
    loading = true;
    notifyListeners();

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final results = await Future.wait([
        _fetchUserName(user.id),
        _fetchLocation(),
        _fetchNotifications(user.id),
      ]);

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
}
