import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final supabase = Supabase.instance.client;

  int totalCount = 0;
  int pendingCount = 0;
  int inProgressCount = 0;
  int resolvedCount = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchComplaintStats();
  }

  Future<void> fetchComplaintStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sectionId = prefs.getString('admin_section_id');

      if (sectionId == null) {
        setState(() => loading = false);
        return;
      }

      final response = await supabase
          .from('complaints')
          .select('status')
          .eq('section_id', sectionId);

      int total = response.length;
      int pending = 0;
      int inProgress = 0;
      int resolved = 0;

      for (var complaint in response) {
        final status = complaint['status'];

        if (status == 'pending') {
          pending++;
        } else if (status == 'in-progress') {
          inProgress++;
        } else if (status == 'resolved') {
          resolved++;
        }
      }

      setState(() {
        totalCount = total;
        pendingCount = pending;
        inProgressCount = inProgress;
        resolvedCount = resolved;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundGrey = Color(0xFFF2F2F2);
    const blueColor = Color(0xFF1B4B66);
    const orangeColor = Color(0xFFF09E00);
    const lightBlueColor = Color(0xFF2196F3);
    const greenColor = Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: backgroundGrey,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Admin Dashboard",
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildStatCard(
                    icon: Icons.assignment,
                    iconColor: blueColor,
                    count: totalCount.toString(),
                    label: "Total Complaints",
                    subLabel: "Total number of complaints",
                  ),

                  const SizedBox(height: 15),

                  _buildStatCard(
                    icon: Icons.hourglass_empty,
                    iconColor: orangeColor,
                    count: pendingCount.toString(),
                    label: "Pending",
                    subLabel: "Unresolved complaints pending",
                  ),

                  const SizedBox(height: 15),

                  _buildStatCard(
                    icon: Icons.settings,
                    iconColor: lightBlueColor,
                    count: inProgressCount.toString(),
                    label: "In Progress",
                    subLabel: "Complaints being actively worked on",
                  ),

                  const SizedBox(height: 15),

                  _buildStatCard(
                    icon: Icons.check_circle_outline,
                    iconColor: greenColor,
                    count: resolvedCount.toString(),
                    label: "Resolved",
                    subLabel: "Complaints that have been resolved",
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String count,
    required String label,
    required String subLabel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 50, color: iconColor),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}