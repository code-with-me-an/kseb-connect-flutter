import 'package:flutter/material.dart';
import 'package:kseb_connect/user_login_screen.dart';
import '../main.dart'; // supabase client
import 'profile/about_us_screen.dart';
import 'profile/profile_details_screen.dart';
import 'profile/faq_screen.dart';
import 'profile/notification_settings_screen.dart';
import 'profile/feedback_screen.dart';
import 'main_layout.dart';

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

  final TextEditingController nameController = TextEditingController();

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

      if (mounted) {
        setState(() {
          userName = data['name'];
          phoneNumber = data['mobile_number'];
          joinDate = "${_monthName(createdAt.month)}-${createdAt.year}";
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Profile fetch error: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> deleteAccount() async {
    final userId = supabase.auth.currentUser!.id;

    try {
      // Delete consumer connections
      await supabase
          .from('consumer_connections')
          .delete()
          .eq('user_id', userId);

      // Delete complaints created by user
      await supabase.from('complaints').delete().eq('user_id', userId);

      // Delete upvotes
      await supabase.from('upvotes').delete().eq('user_id', userId);

      // Delete notifications
      await supabase.from('notifications').delete().eq('user_id', userId);

      // Delete user from public.users
      await supabase.from('users').delete().eq('id', userId);

      // Delete auth account
      await supabase.auth.admin.deleteUser(userId);

      // Logout
      await supabase.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("Delete error: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to delete account")));
    }
  }

  Future<void> confirmDeleteAccount() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Account"),

          content: const Text(
            "Are you sure you want to delete your account? This action cannot be undone.",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CA0D9),
              ),

              onPressed: () async {
                Navigator.pop(context);
                await deleteAccount();
              },

              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
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
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D3B66)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Profile Header Section
                  Row(
                    children: [
                      // profile icon
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[400],
                        child: const Icon(
                          Icons.person,
                          size: 55,
                          color: Colors.white,
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
                            "Member since $joinDate",
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
                    _buildListTile(
                      Icons.notes,
                      "My Complaints",
                      onTap: () {
                        MainLayout.openMyComplaints();
                      },
                    ),
                    _buildListTile(
                      Icons.account_balance_wallet_outlined,
                      "Profile",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileDetailsScreen(),
                          ),
                        );
                      },
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildListTile(
                      Icons.help_outline,
                      "Feedback",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FeedbackScreen(
                              userName: userName,
                              phoneNumber: phoneNumber,
                            ),
                          ),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 20),

                  _buildSectionHeader("Others"),
                  _buildListContainer([
                    _buildListTile(
                      Icons.info_outline,
                      "About us",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutUsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildListTile(
                      Icons.question_answer_outlined,
                      "FAQ",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FAQScreen()),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: confirmDeleteAccount,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.grey,
                      ),
                      label: const Text(
                        "Delete my account",
                        style: TextStyle(
                          color: Colors.black,
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
