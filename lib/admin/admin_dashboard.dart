import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundGrey = Color(0xFFF2F2F2);
    // Colors from your design
    const blueColor = Color(0xFF1B4B66); // Dark Blue for icons
    const orangeColor = Color(0xFFF09E00); // Orange for pending
    const lightBlueColor = Color(0xFF2196F3); // Blue for progress
    const greenColor = Color(0xFF4CAF50); // Green for resolved

    return Scaffold(
      backgroundColor: backgroundGrey,
      
      // --- Body ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Location Text
            const Center(
              child: Text(
                "Location: westhill",
                style: TextStyle(
                  color: Colors.grey, 
                  fontSize: 14, 
                  fontWeight: FontWeight.w500
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Total Complaints Card
            _buildStatCard(
              icon: Icons.assignment, // Clipboard icon
              iconColor: blueColor,
              count: "124",
              label: "Total Complaints",
              subLabel: "Total number of complaints",
            ),

            const SizedBox(height: 15),

            // 3. Pending Card
            _buildStatCard(
              icon: Icons.hourglass_empty, // Hourglass icon
              iconColor: orangeColor,
              count: "42",
              label: "Pending",
              subLabel: "Unresolved complaints pending",
            ),

            const SizedBox(height: 15),

            // 4. In Progress Card
            _buildStatCard(
              icon: Icons.settings, // Gear icon
              iconColor: lightBlueColor,
              count: "58",
              label: "In Progress",
              subLabel: "Complaints being actively worked on",
            ),

            const SizedBox(height: 15),

            // 5. Resolved Card
            _buildStatCard(
              icon: Icons.check_circle_outline, // Checkmark icon
              iconColor: greenColor,
              count: "24",
              label: "Resolved",
              subLabel: "Complaints that have been resolved",
            ),
            
            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
    );
  }

  // --- Helper Widget: Stat Card ---
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
        borderRadius: BorderRadius.circular(20), // Rounded corners like design
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align icon to top
        children: [
          // The Icon (Big & Colored)
          Icon(
            icon,
            size: 50, // Large icon size
            color: iconColor,
          ),
          
          const SizedBox(width: 20), // Space between icon and text
          
          // The Text Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label (e.g., "Total Complaints")
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black87
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Count (e.g., "124")
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 32, // Big number font
                    fontWeight: FontWeight.bold,
                    color: iconColor, // Number matches icon color
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Sub-label (e.g., "Total number of complaints")
                Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: 13, 
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
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