import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeService {

  static final supabase = Supabase.instance.client;

  static RealtimeChannel? _channel;

  // callbacks
  static Function(Map<String,dynamic>)? onComplaint;
  static Function(Map<String,dynamic>)? onUpvote;
  static Function(Map<String,dynamic>)? onNotification;

  static bool _started = false;

  static void start(){

    if(_started) return;

    _started = true;

    _channel = supabase.channel('realtime:app');

    // =====================
    // COMPLAINT INSERT
    // =====================

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'complaints',
      callback: (payload){

        final data = payload.newRecord;

        if(onComplaint != null){
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
      callback: (payload){

        final data = payload.newRecord;

        if(onUpvote != null){
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
      callback: (payload){

        final data = payload.newRecord;

        if(onNotification != null){
          onNotification!(data);
        }

      },
    );

    _channel!.subscribe();
  }

}
