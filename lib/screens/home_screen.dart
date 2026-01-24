import 'package:flutter/material.dart';
import 'report_complaint_screen.dart';
import 'my_complaints_screen.dart';
import 'nearby_complaints_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const navyBlue = Color(0xFF0D3B66);
    const backgroundGrey = Color(0xFFF2F2F2);
    const orangeColor = Color(0xFFE85842); // For Report Button

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
                "Location: Westhill",
                style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Welcome Card (Worker Illustration)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome, Adithyan 👋",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: const TextSpan(
                            text: "You have ",
                            style: TextStyle(color: Colors.black54, fontSize: 14),
                            children: [
                              TextSpan(
                                text: "2 active complaints",
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.assignment_ind_outlined, size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 5),
                            Text(
                              "Last update: Officer assigned",
                              style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Placeholder for the Cartoon Worker Image
                  // Using a network image or icon to simulate the design
                  SizedBox(
                    height: 100,
                    width: 80,
                    child: Image.network(
                      'https://cdn-icons-png.flaticon.com/512/3048/3048122.png', // Generic worker icon
                      fit: BoxFit.contain,
                      errorBuilder: (c, o, s) => const Icon(Icons.engineering, size: 60, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Latest Complaint Status (Tracker)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Latest Complaint Status",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // The Progress Bar
                  Row(
                    children: [
                      _buildStep(true, "Reported", Colors.green),
                      _buildLine(true),
                      _buildStep(true, "Assigned", Colors.green),
                      _buildLine(true, isHalf: true), // Half colored for "In Progress"
                      _buildStep(true, "In Progress", Colors.blue), // Active step
                      _buildLine(false),
                      _buildStep(false, "Resolved", Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Complaint #2515 | Power outage in your area",
                            style: TextStyle(color: Colors.grey[700], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. BIG REPORT BUTTON
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  shadowColor: orangeColor.withOpacity(0.4),
                ),
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportComplaintScreen()),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Icons.favorite, color: orangeColor, size: 18),
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      "Report Complaint",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // 5. Alerts / Announcements
            const Row(
              children: [
                Icon(Icons.campaign, color: Colors.orange, size: 24),
                SizedBox(width: 10),
                Text(
                  "Alerts / Announcements",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // Alert 1 (Yellow)
            _buildAlertCard(
              color: const Color(0xFFFFF8E1), // Light Yellow
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.amber[800]!,
              text: "Power shutdown today at 3 PM in Westhill",
              badgeText: "High Priority",
              badgeColor: Colors.orange[100]!,
              badgeTextColor: Colors.orange[800]!,
            ),
            
            const SizedBox(height: 10),
            
            // Alert 2 (Blue)
            _buildAlertCard(
              color: const Color(0xFFE3F2FD), // Light Blue
              icon: Icons.info_outline,
              iconColor: Colors.blue[800]!,
              text: "Scheduled maintenance tomorrow at 10 AM by KSEB",
              badgeText: "900 m",
              badgeColor: Colors.white,
              badgeTextColor: Colors.grey,
            ),

            const SizedBox(height: 25),

            // 6. Issues Near You
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.green, size: 24),
                SizedBox(width: 10),
                Text(
                  "Issues Near You",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Issue List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildIssueItem("Power outage on Sunset Ave", "1.2 km", isLast: false),
                  _buildIssueItem("Transformer issue at Green St", "900 m", isLast: true),
                ],
              ),
            ),
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  // 1. Progress Step (Dot + Label)
  Widget _buildStep(bool isActive, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 8,
          backgroundColor: isActive ? color : Colors.grey[300],
          child: isActive ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: isActive ? Colors.black87 : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
        )
      ],
    );
  }

  // 2. Progress Line
  Widget _buildLine(bool isActive, {bool isHalf = false}) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 14), // Align with dots
        decoration: BoxDecoration(
          gradient: isHalf
              ? const LinearGradient(colors: [Colors.green, Colors.blue])
              : null,
          color: isHalf ? null : (isActive ? Colors.green : Colors.grey[300]),
        ),
      ),
    );
  }

  // 3. Alert Card
  Widget _buildAlertCard({
    required Color color,
    required IconData icon,
    required Color iconColor,
    required String text,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeTextColor),
            ),
          )
        ],
      ),
    );
  }

  // 4. Issue List Item
  Widget _buildIssueItem(String text, String distance, {required bool isLast}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Text(distance, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}