import 'package:flutter/material.dart';
import 'package:kseb_connect/screens/profile_screen.dart';
import 'home_screen.dart';
import 'my_complaints_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  late List<Widget> _screens;

@override
void initState() {
  super.initState();
  _screens = [
    HomeScreen(onOpenComplaints: () {
      setState(() {
        _currentIndex = 1;
      });
    }),
    const MyComplaintsScreen(),
    const Placeholder(),
    const ProfileScreen(),
  ];
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF0D3B66),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Complaints"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
