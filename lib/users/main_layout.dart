import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'my_complaints_screen.dart';
import 'nearby_complaints_screen.dart';
import 'profile_screen.dart';
import '../main.dart';
import '../services/local_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _realtimeStarted = false;

  int _currentIndex = 0;
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
    _startRealtimeNotifications();
  }

  void _startRealtimeNotifications() {
    if (_realtimeStarted) return;
    _realtimeStarted = true;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    supabase
        .channel('realtime:user_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            final data = payload.newRecord;

            if (data['recipient_type'] != 'user') return;

            LocalNotificationService.showNotification(
              title: data['title'] ?? "Notification",
              body: data['message'] ?? "",
              payload: data['notification_id']?.toString(),
            );
          },
        )
        .subscribe();
  }

  void openNearbyComplaint(double lat, double lng) {
    setState(() {
      _currentIndex = 2;
    });

    mapKey.currentState?.focusComplaint(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    const navyBlue = Color(0xFF0D3B66);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final navigator = Navigator.of(context);

        /// 1. If any route is open → pop it
        if (navigator.canPop()) {
          navigator.pop();
          return;
        }

        /// 2. If not on Home tab → go to Home
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return;
        }

        /// 3. Already on Home → exit app
        navigator.pop(); // closes app
      },

      child: Scaffold(
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
              onPressed: () async {
                Navigator.pushNamed(context, '/notification');
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            const HomeScreen(),
            const MyComplaintsScreen(),
            NearByComplaintsScreen(key: mapKey),
            const ProfileScreen(),
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
            });

            if (index == 2) {
              mapKey.currentState?.refreshMap();
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
      ),
    );
  }
}
