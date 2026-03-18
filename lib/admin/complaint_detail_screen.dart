import 'package:flutter/material.dart';
import 'package:kseb_connect/providers/admin_complaint_provider.dart';
import 'package:provider/provider.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final String complaintId;

  const ComplaintDetailScreen({super.key, required this.complaintId});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {

  Future<void> _showStatusDialog({
  required String complaintId,
  required String currentStatus,
}) async {
  String selectedStatus = currentStatus;

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          "Update Status",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownMenu<String>(
              initialSelection: selectedStatus,
              expandedInsets: EdgeInsets.zero,
              // This helps control the vertical position logic
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: "pending", label: "Pending"),
                DropdownMenuEntry(value: "in-progress", label: "In-Progress"),
                DropdownMenuEntry(value: "resolved", label: "Resolved"),
              ],
              onSelected: (value) {
                if (value != null) selectedStatus = value;
              },
              // Minimal Menu Styling
              menuStyle: MenuStyle(
                backgroundColor: WidgetStateProperty.all(Colors.white),
                elevation: WidgetStateProperty.all(8),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                // Adjusting alignment to make it feel more integrated
                alignment: Alignment.topLeft, 
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF219869)),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<AdminComplaintProvider>();
              await provider.updateStatus(complaintId, selectedStatus);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF219869),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Update"),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminComplaintProvider>();
    final complaint = provider.getComplaintById(widget.complaintId);
    if (complaint == null) {
      return const Scaffold(body: Center(child: Text("Complaint not found")));
    }
    final imageUrl = complaint['image_url'];
    final tracking = complaint['tracking_code'] ?? "";
    final category = complaint['category'] ?? "";
    final description = complaint['description'] ?? "";
    final status = complaint['status'] ?? "pending";
    final location = complaint['location_name'] ?? "Not available";
    final consumerName = complaint['consumer_name'];
    final consumerNumber = complaint['consumer_number'];
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

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),

      appBar: AppBar(
        backgroundColor: const Color(0xFF219869),
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          "Complaint Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // DETAILS CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IMAGE (only if exists)
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

                  // DETAILS CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Complaint ID:",
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          tracking,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const Divider(height: 24),

                        const Text(
                          "Issue Name:",
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(category, style: const TextStyle(fontSize: 16)),
                        if (consumerName != null && consumerNumber != null) ...[
                          const Divider(height: 24),

                          const Text(
                            "Consumer Name:",
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(consumerName),
                          const Divider(height: 24),
                          const SizedBox(height: 10),

                          const Text(
                            "Consumer Number:",
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(consumerNumber),
                        ],
                        const Divider(height: 24),

                        const Text(
                          "Description:",
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(description),

                        const Divider(height: 24),

                        const Text("Location:", style: TextStyle(fontSize: 16)),
                        Text(location),

                        const Divider(height: 24),

                        const Text(
                          "Current Status:",
                          style: TextStyle(fontSize: 16),
                        ),

                        const SizedBox(height: 6),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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

                        const Text(
                          "Assigned to Team A",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // EDIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final complaintId = complaint['complaint_id'];
                        final status = complaint['status'] ?? "pending";

                        _showStatusDialog(
                          complaintId: complaintId,
                          currentStatus: status,
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Status"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF219869),
                        foregroundColor: Colors.white, // ✅ ADD THIS
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
  }
}
