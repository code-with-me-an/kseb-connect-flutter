import 'package:flutter/material.dart';
import 'report_complaint_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onOpenComplaints;

  const HomeScreen({super.key, required this.onOpenComplaints});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0D3B66),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Hello, User", ),
        
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.notifications),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Location: westhill",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            _menuButton(
              color: Colors.deepOrange,
              icon: Icons.favorite,
              text: "Report Complaint",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportComplaintScreen(),
                  ),
                );
              },
            ),

            _menuButton(
  color: Colors.blue,
  icon: Icons.list,
  text: "My Complaints",
  onTap: onOpenComplaints,
),


            _menuButton(
              color: Colors.green,
              icon: Icons.location_on,
              text: "NearBy Complaints",
              onTap: () {},
            ),

            _menuButton(
              color: Colors.lightBlue,
              icon: Icons.person,
              text: "Profile",
              onTap: () {},
            ),
          ],
        ),
      ),

      
    );
  }

  Widget _menuButton({
    required Color color,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: color),
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white),
          label: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
