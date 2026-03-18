import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.complaint['image_url'];
    final tracking = widget.complaint['tracking_code'] ?? "";
    final category = widget.complaint['category'] ?? "";
    final description = widget.complaint['description'] ?? "";
    final status = widget.complaint['status'] ?? "pending";
    final location = widget.complaint['location_name'] ?? "Not available";

    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case "resolved":
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case "in-progress":
        statusColor = Colors.orange;
        statusIcon = Icons.construction;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.hourglass_bottom;
    }

 return Container(
  color: const Color(0xFFE0E0E0),
  child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
         
            const SizedBox(height: 16),

            // 📄 DETAILS CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
               children: [
  // 🖼 IMAGE (only if exists)
  if (imageUrl != null && imageUrl.isNotEmpty) ...[
    ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    ),
    const SizedBox(height: 16),
  ],

  // 📄 DETAILS CARD
  Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Complaint ID:",
            style: TextStyle(fontSize: 16)),
        Text(
          tracking,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const Divider(height: 24),

        const Text("Issue Name:",
            style: TextStyle(fontSize: 16)),
        Text(
          category,
          style: const TextStyle(fontSize: 16),
        ),

        const Divider(height: 24),

        const Text("Description:",
            style: TextStyle(fontSize: 16)),
        Text(description),

        const Divider(height: 24),

        const Text("Location:",
            style: TextStyle(fontSize: 16)),
        Text(location),

        const Divider(height: 24),

        const Text("Current Status:",
            style: TextStyle(fontSize: 16)),

        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        const Text("Assigned to Team A",
            style: TextStyle(color: Colors.grey)),
      ],
    ),
  ),

  const SizedBox(height: 20),

  // ✏️ EDIT BUTTON
  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
 onPressed: () {
  final complaintId = widget.complaint['complaint_id'];
  final status = widget.complaint['status'] ?? "pending";

  _showStatusDialog(
    complaintId: complaintId,
    currentStatus: status,
  );
},
      icon: const Icon(Icons.edit),
      label: const Text("Edit Status"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF219869),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  ),
]
              ),
            ),

            
          ],
        ),
      ),
    );
  }
  Future<void> _showStatusDialog({
  required String complaintId,
  required String currentStatus,
}) async {
  String selectedStatus = currentStatus;

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Update Status"),
        content: DropdownButtonFormField<String>(
          initialValue: selectedStatus,
          items: const [
            DropdownMenuItem(value: "pending", child: Text("Pending")),
            DropdownMenuItem(value: "in-progress", child: Text("In-Progress")),
            DropdownMenuItem(value: "resolved", child: Text("Resolved")),
          ],
          onChanged: (value) {
            selectedStatus = value!;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateComplaintStatus(complaintId, selectedStatus);
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      );
    },
  );
}

Future<void> _updateComplaintStatus(
  String complaintId,
  String newStatus,
) async {
  try {
    await supabase
        .from('complaints')
        .update({'status': newStatus})
        .eq('complaint_id', complaintId);

    final complaintData = await supabase
        .from('complaints')
        .select('user_id')
        .eq('complaint_id', complaintId)
        .single();

    final ownerId = complaintData['user_id'];

    await supabase.from('notifications').insert({
      'complaint_id': complaintId,
      'user_id': ownerId,
      'recipient_type': 'user',
      'title': 'Complaint Status Updated',
      'message': 'Your complaint status is now $newStatus',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Status updated")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}
}