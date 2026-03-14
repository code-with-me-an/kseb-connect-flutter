import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final supabase = Supabase.instance.client;

  List notifications = [];
  bool loading = true;

  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  // ==============================
  // FETCH NOTIFICATIONS
  // ==============================

  Future<void> fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final sectionId = prefs.getString('admin_section_id');

    if (sectionId == null) return;

    try {
      final response = await supabase
          .from('notifications')
          .select('''
            *,
            complaints (
              tracking_code,
              category,
              description
            )
          ''')
          .eq('recipient_type', 'officer')
          .eq('section_id', sectionId)
          .order('created_at', ascending: false);

      setState(() {
        notifications = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        loading = false;
      });
    }
  }

  // ==============================
  // FORMAT TIME
  // ==============================

  String formatTime(String? timestamp) {
    if (timestamp == null) return "";

    final time = DateTime.parse(timestamp).toLocal();
    final difference = DateTime.now().difference(time);

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} min ago";
    }

    if (difference.inHours < 24) {
      return "${difference.inHours} hrs ago";
    }

    return "${difference.inDays} days ago";
  }

  // ==============================
  // DELETE ALL
  // ==============================

  Future<void> deleteAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final sectionId = prefs.getString('admin_section_id');

    if (sectionId == null) return;

    setState(() {
      loading = true;
    });

    try {
      await supabase.from('notifications').delete().eq('section_id', sectionId);

      notifications.clear();

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

  // ==============================
  // UI
  // ==============================

  Future<void> confirmDeleteAll() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,

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
            "Are you sure you want to delete all notifications? This action cannot be undone.",
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
            /// CANCEL
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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

            /// DELETE
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await deleteAllNotifications();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color(0xFF219869);
    const background = Color(0xFFF5F6F8);

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: notifications.isEmpty ? null : confirmDeleteAll,
          ),
        ],
      ),

      body: RefreshIndicator(
        color: const Color(0xFF219869), // green reload color
        onRefresh: fetchNotifications,
        child: loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 300),
                  Center(
                    child: CircularProgressIndicator(color: Color(0xFF219869)),
                  ),
                ],
              )
            : notifications.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 300),
                  Center(
                    child: Text(
                      "No notifications",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final isAlert = notif['is_alert'] == true;

                  final trackingCode = notif['complaints']?['tracking_code'];

                  final subtitle = trackingCode != null
                      ? "${notif['message']} (Tracking: $trackingCode)"
                      : notif['message'];

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
                                : const Color(0xFFEAF4FC),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAlert
                                ? Icons.warning_rounded
                                : Icons.notifications,
                            color: isAlert
                                ? Colors.orange
                                : const Color(0xFF3B9CF2),
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
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle ?? "",
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
      ),
    );
  }

  @override
  void dispose() {
    if (channel != null) {
      supabase.removeChannel(channel!);
    }

    super.dispose();
  }
}
