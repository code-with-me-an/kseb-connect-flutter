import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_notification_service.dart';

class AdminRealtimeService {
  static final supabase = Supabase.instance.client;

  static RealtimeChannel? _channel;

  static Function(Map<String, dynamic>)? onComplaint;
  static Function(Map<String, dynamic>)? onNotification;

  static bool _started = false;

  static void start() async {
    if (_started) return;

    _started = true;

    final prefs = await SharedPreferences.getInstance();
    final sectionId = prefs.getString('admin_section_id');

    if (sectionId == null) return;

    _channel = supabase.channel('realtime:admin');

    // =====================
    // COMPLAINTS (SECTION BASED)
    // =====================

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'complaints',
      callback: (payload) {
        final data = payload.newRecord;

        if (data['section_id'] != sectionId) return;

        if (onComplaint != null) {
          onComplaint!(data);
        }
      },
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'complaints',
      callback: (payload) {
        final data = payload.newRecord;

        if (data['section_id'] != sectionId) return;

        if (onComplaint != null) {
          onComplaint!(data);
        }
      },
    );

    // =====================
    // ADMIN NOTIFICATIONS ONLY
    // =====================

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      callback: (payload) {
        final data = payload.newRecord;

        if (data['recipient_type'] != 'officer') return;
        if (data['section_id'] != sectionId) return;

        if (onNotification != null) {
          onNotification!(data);
        }

        LocalNotificationService.showNotification(
          title: data['title'] ?? "New Complaint",
          body: data['message'] ?? "",
          isAlert: data['is_alert'] ?? false,
          payload: data['complaint_id']?.toString(),
        );
      },
    );

    _channel!.subscribe();
  }

  static Future<void> stop() async {
    if (_channel != null) {
      await supabase.removeChannel(_channel!);
      _channel = null;
    }
    _started = false;
  }
}