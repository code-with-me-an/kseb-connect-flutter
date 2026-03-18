import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_notification_service.dart';

class UserRealtimeService {
  static final supabase = Supabase.instance.client;

  static RealtimeChannel? _channel;

  static Function(Map<String, dynamic>)? onComplaint;
  static Function(Map<String, dynamic>)? onUpvote;
  static Function(Map<String, dynamic>)? onNotification;

  static bool _started = false;

  static void start(String userId, List<String> userSectionIds) {
    if (_started) return;

    _started = true;

    _channel = supabase.channel('realtime:user');

    // =====================
    // COMPLAINT INSERT / UPDATE
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
    // UPVOTES
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
      callback: (payload) {
        final data = payload.newRecord;

        if (data['recipient_type'] == 'user') {
          if (data['user_id'] != userId) return;
        } else if (data['recipient_type'] == 'section') {
          final sectionId = data['section_id']?.toString();

          if (!userSectionIds.contains(sectionId)) return;
        } else {
          return;
        }

        if (onNotification != null) {
          onNotification!(data);
        }

        LocalNotificationService.showNotification(
          title: data['title'] ?? "Notification",
          body: data['message'] ?? "",
          isAlert: data['is_alert'] ?? false,
          payload: data['notification_id']?.toString(),
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
