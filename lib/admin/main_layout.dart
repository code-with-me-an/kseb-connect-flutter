import 'package:flutter/material.dart';
import 'package:kseb_connect/admin/admin_profile_screen.dart';
import 'package:kseb_connect/admin/complaints_list_screen.dart';
import 'admin_dashboard.dart';
import 'package:kseb_connect/admin/admin_section_map_screen.dart';



class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _currentIndex = 0;

  // Admin specific screens
  final List<Widget> _screens = const [
    AdminDashboard(), // The dashboard we just made
    ComplaintsListScreen(),
    AdminSectionMapScreen(),
    AdminProfileScreen(),
  ];

  final List<String> _titles = const [
    "Admin Dashboard",
    "All Complaints",
    "Area Map",
    "Admin Profile",
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      // Top Bar
      appBar: AppBar(
        backgroundColor: Color(0xFF219869), // Greenish teal for Admin distinction? Or keep Navy Blue.
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Hides back button
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
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),

      // Body
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // Bottom Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 255, 248, 248),
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF219869),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Complaints"),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}