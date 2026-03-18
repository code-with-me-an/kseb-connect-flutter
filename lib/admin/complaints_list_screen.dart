import 'package:flutter/material.dart';
import 'package:kseb_connect/admin/complaint_detail_screen.dart';
import 'package:kseb_connect/providers/admin_complaint_provider.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';

class ComplaintsListScreen extends StatefulWidget {
  final String? highlightComplaintId;
  final String? highlightComplaintType;

  const ComplaintsListScreen({
    super.key,
    this.highlightComplaintId,
    this.highlightComplaintType,
  });

  @override
  State<ComplaintsListScreen> createState() => _ComplaintsListScreenState();
}

class _ComplaintsListScreenState extends State<ComplaintsListScreen> {
  // Toggle State: true = Community, false = Personal
  bool isCommunitySelected = true;
  String? _activeHighlightId;

  @override
  void initState() {
    super.initState();

    if (widget.highlightComplaintType == 'personal') {
      isCommunitySelected = false;
    }

    context.read<AdminComplaintProvider>().loadComplaints();

    _activeHighlightId = widget.highlightComplaintId;

    if (_activeHighlightId != null) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => _activeHighlightId = null);
        }
      });
    }
  }

  void _scrollToHighlightedComplaint(List<Map<String, dynamic>> complaints) {
    if (widget.highlightComplaintId == null) return;

    final index = complaints.indexWhere(
      (c) => c['complaint_id'] == widget.highlightComplaintId,
    );

    if (index != -1) {
      Future.delayed(const Duration(milliseconds: 400), () {
        _scrollController.animateTo(
          index * 130,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<String> _getLocationName(dynamic lat, dynamic lng) async {
    try {
      if (lat == null || lng == null) return "Location not available";

      List<Placemark> placemarks = await placemarkFromCoordinates(
        lat.toDouble(),
        lng.toDouble(),
      );

      final place = placemarks.first;

      return place.locality ??
          place.subAdministrativeArea ??
          place.administrativeArea ??
          "Unknown location";
    } catch (e) {
      return "Location not available";
    }
  }

  final ScrollController _scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    const adminThemeColor = Color(0xFF219869);
    const backgroundGrey = Color(0xFFE0E0E0); // Light grey background
    final provider = context.watch<AdminComplaintProvider>();

     if (provider.loading) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      body: const Center(
        child: CircularProgressIndicator(color: adminThemeColor),
      ),
    );
  }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final list = isCommunitySelected ? provider.community : provider.personal;

      _scrollToHighlightedComplaint(list);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // --- CUSTOM TOGGLE HEADER ---
          Container(
            height: 67,
            padding: const EdgeInsets.only(bottom: 7),
            decoration: BoxDecoration(color: backgroundGrey),
            // We use a Stack to create the "Tab" visual effect
            child: Row(
              children: [
                // 1. Community Tab
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isCommunitySelected = true),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCommunitySelected
                            ? backgroundGrey
                            : Colors.white,
                        borderRadius: isCommunitySelected
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ) // Active look
                            : const BorderRadius.only(
                                bottomRight: Radius.circular(20),
                              ), // Inactive cutout effect
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Community",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isCommunitySelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isCommunitySelected
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Personal Tab
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isCommunitySelected = false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: !isCommunitySelected
                            ? backgroundGrey
                            : Colors.white,
                        borderRadius: !isCommunitySelected
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ) // Active look
                            : const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                              ), // Inactive cutout effect
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Personal",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: !isCommunitySelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: !isCommunitySelected
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- COMPLAINT LIST AREA ---
          Expanded(
            child: Container(
              color: backgroundGrey,
              child: RefreshIndicator(
                color: const Color(0xFF219869),
                onRefresh: () => provider.loadComplaints(),
                child: ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: isCommunitySelected
                      ? _buildCommunityList(adminThemeColor, provider)
                      : _buildPersonalList(adminThemeColor, provider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. Community Complaints List ---
  List<Widget> _buildCommunityList(
    Color themeColor,
    AdminComplaintProvider provider,
  ) {
    if (provider.loading) {
      return [const Center(child: CircularProgressIndicator(color: Color(0xFF219869)))];
    }

    if (provider.community.isEmpty) {
      return [const Center(child: Text("No complaints found"))];
    }

    return provider.community.map((complaint) {
      int upvoteCount = complaint['upvote_count'] ?? 0;

      return _buildComplaintCard(
        complaintId: complaint['complaint_id'],
        title: complaint['category'] ?? "",
        tracking: complaint['tracking_code'] ?? "",
        imageUrl: complaint['image_url'],
        upvotes: upvoteCount,
        status: complaint['status'] ?? "pending",
        themeColor: themeColor,
        description: complaint['description'] ?? "",
        latitude: complaint['latitude'],
        longitude: complaint['longitude'],
        locationName: complaint['location_name'],
        highlight: _activeHighlightId == complaint['complaint_id'],
      );
    }).toList();
  }

  // --- 2. Personal Complaints List ---
  List<Widget> _buildPersonalList(
    Color themeColor,
    AdminComplaintProvider provider,
  ) {
    if (provider.loading) {
      return [const Center(child: CircularProgressIndicator(color: Color(0xFF219869)))];
    }

    if (provider.personal.isEmpty) {
      return [const Center(child: Text("No personal complaints found"))];
    }

    return provider.personal.map((complaint) {
      return _buildComplaintCard(
        complaintId: complaint['complaint_id'],
        title: complaint['category'] ?? "",
        tracking: complaint['tracking_code'] ?? "",
        imageUrl: complaint['image_url'],
        upvotes: 0, // personal doesn't have upvotes
        status: complaint['status'] ?? "pending",
        themeColor: themeColor,
        description: complaint['description'] ?? "",
        latitude: complaint['latitude'],
        longitude: complaint['longitude'],
        locationName: complaint['location_name'],
        consumerName: complaint['consumer_connections']?['name'],
        consumerNumber: complaint['consumer_connections']?['consumer_number'],
        highlight: _activeHighlightId == complaint['complaint_id'],
      );
    }).toList();
  }

  // --- Helper: Complaint Card Widget ---
  Widget _buildComplaintCard({
    required String complaintId,
    required String title,
    required String tracking,
    String? imageUrl,
    required int upvotes,
    required String status,
    required Color themeColor,
    required String description,
    dynamic latitude,
    dynamic longitude,
    String? locationName,
    String? consumerName,
    String? consumerNumber,
    bool highlight = false,
  }) {
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

    return GestureDetector(
      onTap: () async {
        String finalLocation = locationName ?? "";

        //  If empty → derive from lat/lng
        if ((finalLocation.isEmpty) && latitude != null && longitude != null) {
          finalLocation = await _getLocationName(latitude, longitude);
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ComplaintDetailScreen(complaintId: complaintId),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: highlight ? Colors.yellow[100] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: highlight
                  ? Border.all(color: Colors.orange, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DETAILS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Issue Title
                      Text(
                        "Issue: $title",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Tracking
                      Text(
                        "Tracking: $tracking",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // UPVOTES
                          if (upvotes >= 0) ...[
                            const Icon(
                              Icons.thumb_up,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$upvotes Upvotes",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],

                          // 🟢 STATUS
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 14, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  status[0].toUpperCase() + status.substring(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 2),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 10,
            child: GestureDetector(
              onTap: () {
                _showStatusDialog(
                  complaintId: complaintId,
                  currentStatus: status,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF219869),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "Edit",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.edit, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                // ✅ Minimal Menu Styling
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
  void dispose() {
    super.dispose();
  }
}
