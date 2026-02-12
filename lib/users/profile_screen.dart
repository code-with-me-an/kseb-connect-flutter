import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // 1. Import this
import 'package:kseb_connect/user_login_screen.dart';
import '../main.dart'; // supabase client

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = '';
  String phoneNumber = '';
  String joinDate = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      final data = await supabase
          .from('users')
          .select('name, mobile_number, created_at')
          .eq('id', userId)
          .single();

      final createdAt = DateTime.parse(data['created_at']);

      setState(() {
        userName = data['name'];
        phoneNumber = data['mobile_number'];
        joinDate = "${_monthName(createdAt.month)}-${createdAt.year}";
        loading = false;
      });
    } catch (e) {
      debugPrint("Profile fetch error: $e");
      setState(() => loading = false);
    }
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    const backgroundGrey = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: backgroundGrey,

      // --- Body ---
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Profile Header Section
                  Row(
                    children: [
                      // --- CHANGED: SVG Profile Icon ---
                      ClipOval(
                        child: SvgPicture.asset(
                          'assets/profile.svg', // Your SVG file path
                          width: 70, // Equivalent to radius 35 * 2
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Ownest member since $joinDate",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Phone: $phoneNumber",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  _buildSectionHeader("Manage"),
                  _buildListContainer([
                    _buildListTile(Icons.notes, "My Complaints", onTap: () {}),
                    _buildListTile(
                      Icons.account_balance_wallet_outlined,
                      "Profile",
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 20),

                  _buildSectionHeader("Settings"),
                  _buildListContainer([
                    _buildListTile(
                      Icons.account_circle_outlined,
                      "Account settings",
                      onTap: () {},
                    ),
                    _buildListTile(
                      Icons.notifications_none,
                      "Notification settings",
                      onTap: () {},
                    ),
                    _buildListTile(
                      Icons.help_outline,
                      "Feedback",
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 20),

                  _buildSectionHeader("Others"),
                  _buildListContainer([
                    _buildListTile(
                      Icons.info_outline,
                      "About us",
                      onTap: () {},
                    ),
                    _buildListTile(
                      Icons.question_answer_outlined,
                      "FAQ",
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.grey,
                      ),
                      label: const Text(
                        "Delete my account",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await supabase.auth.signOut();

                        if (!mounted) return;

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        "Log out",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CA0D9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildListContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}
