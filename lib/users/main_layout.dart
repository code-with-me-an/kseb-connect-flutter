import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'my_complaints_screen.dart';
import 'nearby_complaints_screen.dart';
import 'profile_screen.dart';
import 'about_us_screen.dart';
import '../main.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  static void openNearbyComplaint(double lat, double lng) {
    _MainLayoutState.instance?.openNearbyComplaint(lat, lng);
  }

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  static _MainLayoutState? instance;

  int _currentIndex = 0;
  bool showAbout = false;

  List<Map<String, dynamic>> userNotifications = [];
  bool loadingNotifications = false;

  final GlobalKey<NearByComplaintsScreenState> mapKey =
      GlobalKey<NearByComplaintsScreenState>();

  final List<String> _titles = [
    "KSEB Connect",
    "My Complaints",
    "Nearby Complaints",
    "My Profile",
  ];

  @override
  void initState() {
    super.initState();
    instance = this;
  }

  void openNearbyComplaint(double lat, double lng) {
    setState(() {
      _currentIndex = 2;
      showAbout = false;
    });

    mapKey.currentState?.focusComplaint(lat, lng);
  }

  String _formatTime(String? timestamp) {
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

  Future<void> _fetchUserNotifications() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      loadingNotifications = true;
    });

    try {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('recipient_type', 'user')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      userNotifications = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      loadingNotifications = false;
    });
  }

  void _showNotifications(BuildContext context) {
    bool showAllNotifications = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final notificationsToShow = showAllNotifications
                ? userNotifications
                : userNotifications.take(3).toList();

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 420),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Notifications",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),

                    const Divider(height: 30),

                    /// CONTENT
                    Expanded(
                      child: loadingNotifications
                          ? const Center(child: CircularProgressIndicator())
                          : userNotifications.isEmpty
                              ? const Center(
                                  child: Text(
                                    "No notifications",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Column(
                                    children: notificationsToShow.map((notif) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 15),
                                        child: _buildNotificationItem(
                                          icon: Icons.notifications,
                                          color: notif['is_alert'] == true
                                              ? Colors.orange
                                              : Colors.blue,
                                          title: notif['title'] ??
                                              "Notification",
                                          subtitle: notif['message'] ?? "",
                                          time: _formatTime(
                                              notif['created_at']),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                    ),

                    /// TOGGLE BUTTON
                    if (userNotifications.length > 3)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setDialogState(() {
                              showAllNotifications = !showAllNotifications;
                            });
                          },
                          child: Text(
                            showAllNotifications
                                ? "Hide Notifications"
                                : "View All Notifications",
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const navyBlue = Color(0xFF0D3B66);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: navyBlue,
        elevation: 0,
        centerTitle: true,
        title: Text(
          showAbout ? "About Us" : _titles[_currentIndex],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () async {
              await _fetchUserNotifications();
              _showNotifications(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: showAbout
          ? const AboutUsScreen()
          : IndexedStack(
              index: _currentIndex,
              children: [
                const HomeScreen(),
                const MyComplaintsScreen(),
                NearByComplaintsScreen(key: mapKey),
                ProfileScreen(
                  onAboutTap: () {
                    setState(() {
                      showAbout = true;
                    });
                  },
                ),
              ],
            ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 255, 248, 248),
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: navyBlue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            showAbout = false;
          });

          if (index == 2) {
            mapKey.currentState?.fetchNearbyComplaints();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Complaints",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: "Map",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}