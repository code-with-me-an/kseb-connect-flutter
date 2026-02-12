import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> complaints = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    setState(() => loading = true);

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('complaints')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    setState(() {
      complaints = List<Map<String, dynamic>>.from(response);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: const Color(0xFF0D3B66), // Your theme color
              onRefresh: fetchComplaints, // Calls API again
              child: complaints.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 300),
                        Center(child: Text("No complaints found")),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: complaints.length,
                      itemBuilder: (context, index) {
                        final complaint = complaints[index];

                        return ComplaintCard(
                          id: complaint['tracking_code'] ?? "",
                          title: complaint['category'] ?? "",
                          description: complaint['description'] ?? "",
                          date: complaint['created_at'].toString().substring(
                            0,
                            10,
                          ),
                          statusLabel: complaint['status'] ?? "",
                          statusButtonText: _formatStatus(complaint['status']),
                          statusColor: _getStatusColor(complaint['status']),
                        );
                      },
                    ),
            ),
    );
  }

  String _formatStatus(String? status) {
    if (status == null) return "";
    return status[0].toUpperCase() + status.substring(1);
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case "pending":
        return const Color(0xFFE89020);
      case "in_progress":
        return const Color(0xFF2E77AE);
      case "resolved":
        return const Color(0xFF38D52D);
      default:
        return Colors.grey;
    }
  }
}

// --- Custom Complaint Card Widget ---
class ComplaintCard extends StatelessWidget {
  final String id;
  final String title;
  final String description;
  final String date;
  final String statusLabel; // Text shown at the bottom
  final String statusButtonText; // Text inside the button
  final Color statusColor;

  const ComplaintCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
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
                    const SizedBox(height: 4),

                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),

                      maxLines: 2,
                      overflow: TextOverflow.ellipsis, // prevents overflow
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
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
