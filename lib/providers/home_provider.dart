import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geocoding/geocoding.dart';

import '../services/location_service.dart';
import '../services/realtime_service.dart';
import '../services/local_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  String userName = "User";
  String locationName = "Unknown";
  bool loading = true;

  List<Map<String, dynamic>> notifications = [];

  /// store user sections
  List<String> userSectionIds = [];

  bool _realtimeConnected = false;

  // =====================================================
  // LOAD HOME DATA
  // =====================================================

  Future<void> loadHomeData({bool forceRefresh = false}) async {
    loading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) {
      loading = false;
      return;
    }

    try {
      final results = await Future.wait([
        _fetchUserName(userId),
        _fetchLocation(),
        _fetchNotifications(userId),
      ]);

      userName = results[0] as String;
      locationName = results[1] as String;
      notifications = results[2] as List<Map<String, dynamic>>;

      /// start realtime listener
      _connectRealtime();
    } catch (e) {
      debugPrint("Home load error: $e");
    }

    loading = false;
    notifyListeners();
  }

  // =====================================================
  // CONNECT REALTIME
  // =====================================================

  void _connectRealtime() {
    if (_realtimeConnected) return;

    _realtimeConnected = true;

    RealtimeService.onNotification = (notification) {
      // only section announcement reach the user

      if (notification['recipient_type'] != 'section') return;

      final sectionId = notification['section_id']?.toString();

      if (!userSectionIds.contains(sectionId)) return;

      /// avoid duplicate notifications
      final exists = notifications.any(
        (n) => n['notification_id'] == notification['notification_id'],
      );

      if (exists) return;

      notifications = [
        Map<String, dynamic>.from(notification),
        ...notifications,
      ];

      notifyListeners();
      LocalNotificationService.showNotification(
        title: notification['title'] ?? "Alert",
        body: notification['message'] ?? "",
        isAlert: notification['is_alert'] == true,
      );
    };
  }

  // =====================================================
  // FETCH USER NAME
  // =====================================================

  Future<String> _fetchUserName(String id) async {
    final response = await supabase
        .from('users')
        .select('name')
        .eq('id', id)
        .maybeSingle();

    return response?['name'] ?? "User";
  }

  // =====================================================
  // FETCH USER LOCATION
  // =====================================================

  Future<String> _fetchLocation() async {
    final position = await LocationService.getCurrentLocation();

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    return placemarks.first.locality ?? "Unknown";
  }

  // =====================================================
  // FETCH NOTIFICATIONS
  // =====================================================

  Future<List<Map<String, dynamic>>> _fetchNotifications(String id) async {
    final connections = await supabase
        .from('consumer_connections')
        .select('section_id')
        .eq('user_id', id);

    if (connections.isEmpty) return [];

    userSectionIds = connections
        .map((c) => c['section_id'].toString())
        .toList();

    final response = await supabase
        .from('notifications')
        .select()
        .eq('recipient_type', 'section')
        .inFilter('section_id', userSectionIds)
        .gte('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
