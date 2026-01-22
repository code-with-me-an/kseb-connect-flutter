import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        leading: const SizedBox(), // ❌ No back button because it's a tab
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.notifications),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileHeader(),
            const SizedBox(height: 20),
            _section("Manage", [
              _tile(Icons.list_alt, "My Complaints"),
              _tile(Icons.person, "Profile"),
            ]),
            const SizedBox(height: 16),
            _section("Settings", [
              _tile(Icons.settings, "Account settings"),
              _tile(Icons.notifications, "Notification settings"),
              _tile(Icons.feedback, "Feedback"),
            ]),
            const SizedBox(height: 16),
            _section("Others", [
              _tile(Icons.info, "About us"),
              _tile(Icons.help_outline, "FAQ"),
            ]),
            const SizedBox(height: 20),
            _dangerButton("Delete my account"),
            const SizedBox(height: 10),
            _logoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(
              "https://i.pravatar.cc/150?img=11"),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ananthu",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Ownest member since Jan-2026"),
            Text("Phone: +91 9876543210"),
          ],
        )
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        )
      ],
    );
  }

  Widget _tile(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  Widget _dangerButton(String text) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.delete),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey[700],
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Widget _logoutButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.logout),
      label: const Text("Log out"),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}
