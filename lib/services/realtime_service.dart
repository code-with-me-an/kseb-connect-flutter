import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_notification_service.dart';

class RealtimeService {
  static final supabase = Supabase.instance.client;

  static RealtimeChannel? _channel;

  // callbacks
  static Function(Map<String, dynamic>)? onComplaint;
  static Function(Map<String, dynamic>)? onUpvote;
  static Function(Map<String, dynamic>)? onNotification;

  static bool _started = false;

  static void start() {
    if (_started) return;

    _started = true;

    _channel = supabase.channel('realtime:app');

    // =====================
    // COMPLAINT INSERT
    // =====================

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'complaints',
      callback: (payload) {
        final data = payload.newRecord;

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

        if (onComplaint != null) {
          onComplaint!(data);
        }
      },
    );

    // =====================
    // UPVOTES INSERT
    // =====================

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'upvotes',
      callback: (payload) {
        final data = payload.newRecord;

        if (onUpvote != null) {
          onUpvote!(data);
        }
      },
    );

    // =====================
    // NOTIFICATIONS
    // =====================

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      callback: (payload) async {
        final data = payload.newRecord;

        if (onNotification != null) {
          onNotification!(data);
        }

        /// ADMIN PHONE NOTIFICATION
        final prefs = await SharedPreferences.getInstance();
        final sectionId = prefs.getString('admin_section_id');

        if (sectionId != null &&
            data['recipient_type'] == 'officer' &&
            data['section_id'] == sectionId) {

          LocalNotificationService.showNotification(
            title: data['title'] ?? "New Complaint",
            body: data['message'] ?? "",
            isAlert: data['is_alert'] ?? false,
            payload: data['complaint_id']?.toString(),
          );
        }
      },
    );

    _channel!.subscribe();
  }
}