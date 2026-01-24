import 'package:flutter/material.dart';

class MyComplaintsScreen extends StatelessWidget {
  const MyComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      // --- Body ---
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          // 1. Pending Example
          ComplaintCard(
            id: "CMP12345",
            title: "Power Outage",
            date: "12 dec 2025",
            statusLabel: "pending", // Small lower text
            statusButtonText: "Pending", // Button text
            statusColor: Color(0xFFE89020), // Orange
          ),

          // 2. In Progress Example
          ComplaintCard(
            id: "CMP12347",
            title: "Voltage Issue",
            date: "12 dec 2025",
            statusLabel: "In Progress",
            statusButtonText: "In Progress",
            statusColor: Color(0xFF2E77AE), // Blue
          ),

          // 3. Pending Example 2
          ComplaintCard(
            id: "CMP12340",
            title: "Billing Problem",
            date: "12 dec 2025",
            statusLabel: "pending",
            statusButtonText: "Pending",
            statusColor: Color(0xFFE89020),
          ),

          // 4. Resolved Example
          ComplaintCard(
            id: "CMP12343",
            title: "Voltage Issue",
            date: "12 dec 2025",
            statusLabel: "Resolved",
            statusButtonText: "Resolved",
            statusColor: Color(0xFF38D52D), // Green
          ),
        ],
      ),
    );
  }
}

// --- Custom Complaint Card Widget ---
class ComplaintCard extends StatelessWidget {
  final String id;
  final String title;
  final String date;
  final String statusLabel; // Text shown at the bottom
  final String statusButtonText; // Text inside the button
  final Color statusColor;

  const ComplaintCard({
    super.key,
    required this.id,
    required this.title,
    required this.date,
    required this.statusLabel,
    required this.statusButtonText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9), // Very light grey fill
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400), // Grey border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side: ID and Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ID: $id",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Right Side: Status Button
              Container(
                width: 100, // Fixed width for uniformity
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  statusButtonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Bottom Line: Date and Small Status Label
          Text(
            "$date  •  $statusLabel",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}