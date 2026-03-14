import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationDetailScreen extends StatefulWidget {
  const NotificationDetailScreen({super.key});

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final supabase = Supabase.instance.client;
  RealtimeChannel? notificationChannel;

  List notifications = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    startRealtimeNotifications();
  }

  // realtime notification

  void startRealtimeNotifications() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    notificationChannel = supabase
        .channel('realtime:user_notifications_screen')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) async {
            setState(() {
              fetchNotifications();
            });
          },
        )
        .subscribe();
  }

  // notification fetching

  Future<void> fetchNotifications() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      loading = true;
    });

    try {
      final response = await supabase
          .from('notifications')
          .select('''
        *,
        complaints (
          tracking_code
        )
      ''')
          .eq('recipient_type', 'user')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      notifications = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      loading = false;
    });
  }

  String formatTime(String? timestamp) {
    if (timestamp == null) return "";

    final time = DateTime.parse(timestamp).toLocal();
    final difference = DateTime.now().difference(time);

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} min ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hrs ago";
    } else {
      return "${difference.inDays} days ago";
    }
  }

  Future<void> confirmDeleteAll() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor:
              Colors.transparent, // Removes the slight Material 3 purple tint
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                "Delete Notifications",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF222222),
                ),
              ),
            ],
          ),
          content: const Text(
            "Are you sure you want to delete all your notifications? This action cannot be undone.",
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.only(
            right: 16,
            bottom: 16,
            left: 16,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF666666),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Cancel",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // close dialog
                await deleteAllNotifications();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Destructive action color
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Delete",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteAllNotifications() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      loading = true;
    });

    try {
      await supabase.from('notifications').delete().eq('user_id', user.id);

      setState(() {
        notifications.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All notifications deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting notifications: $e")),
      );
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Colors matching the provided UI
    const Color darkBlueAppBar = Color(0xFF0C3D6A);
    const Color lightGreyBackground = Color(0xFFF5F6F8);
    const Color lightBlueIconBg = Color(0xFFEAF4FC);

    return Scaffold(
      backgroundColor: lightGreyBackground,
      appBar: AppBar(
        backgroundColor: darkBlueAppBar,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),

        /// BACK BUTTON (Styled like the reference image)
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        /// DELETE BUTTON
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: notifications.isEmpty ? null : confirmDeleteAll,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D3B66),))
          : notifications.isEmpty
          ? const Center(
              child: Text(
                "No notifications",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: notifications.length,

              itemBuilder: (context, index) {
                final notif = notifications[index];
                final isAlert = notif['is_alert'] == true;

                final trackingCode = notif['complaints']?['tracking_code'];

                final subtitleText = trackingCode != null
                    ? "${notif['message']} (Tracking: $trackingCode)"
                    : notif['message'] ?? "";

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isAlert
                              ? Colors.orange.shade50
                              : lightBlueIconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAlert ? Icons.warning_rounded : Icons.notifications,
                          color: isAlert
                              ? Colors.orange
                              : const Color(0xFF3B9CF2),
                          size: 26,
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif['title'] ?? "Notification",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF222222),
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              subtitleText,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF666666),
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              formatTime(notif['created_at']),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFAAAAAA),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    if (notificationChannel != null) {
      supabase.removeChannel(notificationChannel!);
    }
    super.dispose();
  }
}
