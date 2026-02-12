import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../admin_login_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? adminData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  /// 🔹 FETCH ADMIN DATA
  Future<void> _fetchAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getString('admin_id');

    if (adminId == null) {
      setState(() => loading = false);
      return;
    }

    final response = await supabase
        .from('officers')
        .select()
        .eq('officer_id', adminId)
        .maybeSingle();

    if (response != null) {
      setState(() {
        adminData = response;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  /// 🔹 LOGOUT FUNCTION
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('admin_logged_in');
    await prefs.remove('admin_id');
    await prefs.remove('admin_username');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const adminThemeColor = Color(0xFF219869);
    const backgroundGrey = Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: backgroundGrey,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : adminData == null
              ? const Center(child: Text("Admin data not found"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      vertical: 30, horizontal: 20),
                  child: Column(
                    children: [
                      /// PROFILE AVATAR
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[400],
                        child: const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      /// NAME
                      Text(
                        adminData!['name'] ?? "Admin",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// INFO
                      _buildInfoRow(Icons.phone,
                          adminData!['mobile'] ?? "Not Available"),
                      _buildInfoRow(Icons.email,
                          adminData!['email'] ?? "Not Available"),
                      _buildInfoRow(Icons.person,
                          "Username: ${adminData!['username'] ?? ""}"),

                      const SizedBox(height: 40),

                      /// EDIT PROFILE (placeholder for now)
                      _buildActionButton(
                        icon: Icons.edit,
                        iconColor: adminThemeColor,
                        text: "Edit Profile",
                        onTap: () {
                          // You can navigate to edit screen later
                        },
                      ),

                      const SizedBox(height: 15),

                      /// LOGOUT BUTTON
                      _buildActionButton(
                        icon: Icons.power_settings_new,
                        iconColor: Colors.red,
                        text: "Logout",
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF219869), size: 24),
          const SizedBox(width: 15),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
