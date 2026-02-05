import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'my_complaints_screen.dart';
import 'nearby_complaints_screen.dart';
import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MyComplaintsScreen(),
    NearByComplaintsScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = const [
    "Hello, User",
    "My Complaints",
    "Nearby Complaints",
    "My Profile",
  ];

  // --- NEW: Function to show the Notification Box ---
  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0)), // Rounded corners
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Wrap content height
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Notifications",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(height: 30),

                // Notification Items
                _buildNotificationItem(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  title: "Complaint Resolved",
                  subtitle: "Your voltage issue (CMP12343) has been fixed.",
                  time: "2 hrs ago",
                ),
                const SizedBox(height: 15),
                _buildNotificationItem(
                  icon: Icons.info,
                  color: Colors.blue,
                  title: "Officer Assigned",
                  subtitle: "Officer Rajesh is reviewing your complaint.",
                  time: "5 hrs ago",
                ),
                const SizedBox(height: 15),
                _buildNotificationItem(
                  icon: Icons.warning_amber_rounded,
                  color: Colors.orange,
                  title: "Maintenance Alert",
                  subtitle: "Scheduled power cut tomorrow at 10 AM.",
                  time: "1 day ago",
                ),

                const SizedBox(height: 10),

                // 'View All' Link
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text("View All Notifications"),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Helper Widget for Notification Row ---
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
                    color: Colors.black87),
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
      // ✅ TOP BAR (single source of truth)
      appBar: AppBar(
        backgroundColor: navyBlue,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            // ✅ Trigger the notification dialog here
            onPressed: () => _showNotifications(context),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ✅ BODY SWITCHES HERE
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // ✅ BOTTOM BAR (single)
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 255, 248, 248),
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: navyBlue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: "Complaints"),
          BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined), label: "Map"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}