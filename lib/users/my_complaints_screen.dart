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
  Future<void> deleteComplaint(String complaintId) async {
  try {
    await supabase
        .from('complaints')
        .delete()
        .eq('tracking_code', complaintId);

    // Remove from local list instantly (better UX)
    setState(() {
      complaints.removeWhere(
          (complaint) => complaint['tracking_code'] == complaintId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Complaint deleted successfully"),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to delete complaint: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}
void confirmDelete(String complaintId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Delete Complaint"),
      content: const Text("Are you sure you want to delete this complaint?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            deleteComplaint(complaintId);
          },
          child: const Text(
            "Delete",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}

  Future<void> fetchComplaints() async {
    if (mounted) setState(() => loading = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => loading = false);
      return;
    }

    try {
      final response = await supabase
          .from('complaints')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          complaints = List<Map<String, dynamic>>.from(response);
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching complaints: $e');
      if (mounted) {
        setState(() {
          complaints = [];
          loading = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load complaints: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                          onDelete: () => confirmDelete(complaint['tracking_code']),
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
  final VoidCallback onDelete;

  const ComplaintCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.statusLabel,
    required this.statusButtonText,
    required this.statusColor,
    required this.onDelete,
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
          // Top Section: Info and Status Badge
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

          const SizedBox(height: 16), // A little extra breathing room

          // Bottom Section: Date/Status Text on Left, Delete on Right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center, // Aligns them perfectly horizontally
            children: [
              // Left Side: Date and Small Status Label
              Text(
                "$date  •  $statusLabel",
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),

              // Right Side: Delete Button
              GestureDetector(
                onTap: onDelete,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    SizedBox(width: 4),
                    Text(
                      "Delete",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}