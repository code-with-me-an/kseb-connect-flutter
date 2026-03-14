import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  int expiryDays = 1;
  DateTime? customExpiryDate;

  bool loading = true;
  bool sending = false;
  bool isImportantAlert = false;

  // Colors used for the theme
  static const blueColor = Color(0xFF1B4B66);
  static const greenColor = Color(0xFF219869);
  static const textDark = Colors.black87;

  // Controllers for the announcement text fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchComplaintStats();
  }

  Future<void> pickCustomExpiryDate() async {
    DateTime today = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 4)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      // Theme builder to match the calendar to your app's system style
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: greenColor, // Header background color & active color
              onPrimary: Colors.white, // Header text color
              onSurface: textDark, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: greenColor, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        customExpiryDate = pickedDate;
      });
    }
  }

  Future<void> sendAnnouncement() async {
    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getString('admin_id');
    final sectionId = prefs.getString('admin_section_id');

    if (adminId == null || sectionId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Admin session missing")));
      return;
    }

    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and Message required")),
      );
      return;
    }

    try {
      setState(() => sending = true);

      await supabase.from('notifications').insert({
        'recipient_type': 'section',
        'section_id': sectionId.toString(),
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'is_read': false,
        'is_alert': isImportantAlert,
        'expires_at': DateTime.now()
            .add(Duration(days: expiryDays))
            .toIso8601String(),
      });

      _titleController.clear();
      _messageController.clear();
      setState(() => isImportantAlert = false); // Reset checkbox

      if (!mounted) return;

      //Show Custom Success Popup
      showSuccessPopup();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error sending announcement: $e")));
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  // Success Dialog Widget ---
  void showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false, // Forces user to click 'OK'
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: greenColor, size: 70),
                const SizedBox(height: 20),
                const Text(
                  "Success!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: blueColor,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Announcement sent successfully.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Close the dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    const orangeColor = Color(0xFFF09E00);
    const lightBlueColor = Color(0xFF2196F3);

    return Scaffold(
      backgroundColor: backgroundGrey,
      body: loading
          // Changed loading indicator color to green
          ? const Center(child: CircularProgressIndicator(color: greenColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 2x2 Grid for Stats ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildGridStatCard(
                          icon: Icons.assignment,
                          iconColor: blueColor,
                          count: totalCount.toString(),
                          label: "Total Complaints",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildGridStatCard(
                          icon: Icons.hourglass_empty,
                          iconColor: orangeColor,
                          count: pendingCount.toString(),
                          label: "Pending",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGridStatCard(
                          icon: Icons.settings,
                          iconColor: lightBlueColor,
                          count: inProgressCount.toString(),
                          label: "In Progress",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildGridStatCard(
                          icon: Icons.check_circle_outline,
                          iconColor: greenColor,
                          count: resolvedCount.toString(),
                          label: "Resolved",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Divider(thickness: 1.5),
                  const SizedBox(height: 20),

                  // --- Create Announcement Section ---
                  const Text(
                    "Create Announcement",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Title TextField
                  TextField(
                    controller: _titleController,
                    cursorColor: greenColor, // Changed cursor color
                    decoration: InputDecoration(
                      labelText: "Title",
                      floatingLabelStyle: const TextStyle(color: greenColor), // Changed floating label color
                      hintText: "Enter title",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Message TextField
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    cursorColor: greenColor, // Changed cursor color
                    decoration: InputDecoration(
                      labelText: "Message",
                      floatingLabelStyle: const TextStyle(color: greenColor), // Changed floating label color
                      hintText: "Enter your message here...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  //Alert Checkbox
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: isImportantAlert,
                          activeColor: greenColor, 
                          onChanged: (val) {
                            setState(() => isImportantAlert = val ?? false);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Alert (Mark as important)",
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // expire dropdown
                  // Custom structure adapted from ReportComplaintScreen
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          "Announcement Duration",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 55,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: expiryDays,
                            isExpanded: true, // Prevents overflow
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text("1 Day")),
                              DropdownMenuItem(value: 2, child: Text("2 Days")),
                              DropdownMenuItem(value: 3, child: Text("3 Days")),
                              DropdownMenuItem(value: 0, child: Text("Custom Date")),
                            ],
                            onChanged: (val) async {
                              if (val == 0) {
                                await pickCustomExpiryDate();
                              } else {
                                setState(() {
                                  expiryDays = val ?? 1;
                                  customExpiryDate = null;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (customExpiryDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Expires on: ${DateFormat('dd MMM yyyy').format(customExpiryDate!)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Send Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: sending ? null : sendAnnouncement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: greenColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: sending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Send",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // Refactored stat card to place Icon and Count horizontally
  Widget _buildGridStatCard({
    required IconData icon,
    required Color iconColor,
    required String count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon and Count in a horizontal row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: iconColor),
              const SizedBox(width: 12),
              Text(
                count,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Label on the next line
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}