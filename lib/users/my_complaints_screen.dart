import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> complaints = [];
  bool loading = true;

  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
    Future.microtask(() => startRealtime());
  }

  Future<void> startRealtime() async {
    final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');

  if (userId == null) return;

    _channel = supabase
        .channel('realtime:user_complaints')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'complaints',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            final event = payload.eventType;

            if (event == PostgresChangeEvent.insert) {
              fetchComplaints(); // new complaint
            }

            if (event == PostgresChangeEvent.update) {
              fetchComplaints(); // status changed
            }

            if (event == PostgresChangeEvent.delete) {
              fetchComplaints(); // complaint deleted
            }
          },
        )
        .subscribe();
  }

  Widget _buildStep(int index, int currentStep, String text) {
    Color circleColor;
    Widget? icon;

    if (index < currentStep) {
      circleColor = Colors.green;
      icon = const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (index == currentStep) {
      circleColor = Colors.blue;
      icon = const Icon(Icons.check, size: 14, color: Colors.white);
    } else {
      circleColor = Colors.grey[300]!;
    }

    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
          child: icon,
        ),
        const SizedBox(height: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: index <= currentStep ? circleColor : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(int index, int currentStep) {
    Color color;

    if (index < currentStep) {
      color = Colors.green;
    } else if (index == currentStep) {
      color = Colors.blue;
    } else {
      color = Colors.grey[300]!;
    }

    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: color,
      ),
    );
  }

  void showComplaintStatusDialog(Map<String, dynamic> complaint) {
    String status = complaint['status'] ?? "";

    int step = 0;

    if (status == "pending") {
      step = 1;
    } else if (status == "in-progress") {
      step = 2;
    } else if (status == "resolved") {
      step = 3;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9, // proper width
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Complaint Status",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                /// PROGRESS BAR
                Row(
                  children: [
                    _buildStep(0, step, "Reported"),
                    _buildLine(0, step),

                    _buildStep(1, step, "Assigned"),
                    _buildLine(1, step),

                    _buildStep(2, step, "In Progress"),
                    _buildLine(2, step),

                    _buildStep(3, step, "Resolved"),
                  ],
                ),

                const SizedBox(height: 18),

                /// INFO BOX
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          "Complaint #${complaint['tracking_code']} | ${complaint['description']}",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          (complaint) => complaint['tracking_code'] == complaintId,
        );
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
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> fetchComplaints() async {
    if (mounted) setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
final userId = prefs.getString('user_id');

if (userId == null) {
  if (mounted) setState(() => loading = false);
  return;
}

    try {
      final response = await supabase
          .from('complaints')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          complaints = List<Map<String, dynamic>>.from(response);

          // Custom sorting
          complaints.sort((a, b) {
            int getPriority(String? status) {
              switch (status) {
                case "pending":
                  return 0; // top
                case "in-progress":
                  return 1; // middle
                case "resolved":
                  return 2; // bottom
                default:
                  return 3;
              }
            }

            int statusCompare = getPriority(
              a['status'],
            ).compareTo(getPriority(b['status']));

            if (statusCompare != 0) {
              return statusCompare;
            }

            // If status is same → sort by created_at (latest first)
            DateTime dateA = DateTime.parse(a['created_at']);
            DateTime dateB = DateTime.parse(b['created_at']);

            return dateB.compareTo(dateA);
          });

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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D3B66),))
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

                        return GestureDetector(
                          onTap: () {
                            showComplaintStatusDialog(complaint);
                          },
                          child: ComplaintCard(
                            status: complaint['status'] ?? "",
                            onDelete: () =>
                                confirmDelete(complaint['tracking_code']),
                            id: complaint['tracking_code'] ?? "",
                            title: complaint['category'] ?? "",
                            description: complaint['description'] ?? "",
                            date: complaint['created_at'].toString().substring(
                              0,
                              10,
                            ),
                            statusLabel: complaint['status'] ?? "",
                            statusButtonText: _formatStatus(
                              complaint['status'],
                            ),
                            statusColor: _getStatusColor(complaint['status']),
                          ),
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
      case "in-progress":
        return const Color(0xFF2E77AE);
      case "resolved":
        return const Color(0xFF38D52D);
      default:
        return Colors.grey;
    }
  }
  @override
void dispose() {
  _channel?.unsubscribe();
  super.dispose();
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
  final String status;

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
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status == "resolved"
            ? Colors.grey.shade300
            : const Color(0xFFF9F9F9),
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
            crossAxisAlignment:
                CrossAxisAlignment.center, // Aligns them perfectly horizontally
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
