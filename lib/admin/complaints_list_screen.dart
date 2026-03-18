import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'complaint_detail_screen.dart';
import 'main_layout.dart';
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
  } else {
    isCommunitySelected = true;
  }

  _activeHighlightId = widget.highlightComplaintId;

  if (_activeHighlightId != null) {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _activeHighlightId = null;
        });
      }
    });
  }

  _initialize();
}

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getString('admin_id');

    if (adminId == null) return;

    try {
      final officer = await supabase
          .from('officers')
          .select('section_id')
          .eq('officer_id', adminId)
          .maybeSingle();

      if (officer == null) {
        return;
      }

      officerSectionId = officer['section_id'];

      await _fetchCommunityComplaints();
      await _fetchPersonalComplaints();
      _listenToRealtime();
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading admin data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchCommunityComplaints() async {
    if (officerSectionId == null) return;

    if (mounted) setState(() => loading = true);

    try {
      final response = await supabase
          .from('complaints_with_upvotes')
          .select()
          .eq('section_id', officerSectionId!)
          .eq('complaint_type', 'community')
          .order('upvote_count', ascending: false)
          .order('created_at', ascending: false);
      //for debug....remove cheyyanam
      print("Fetched complaints:");
      print(response);

      if (mounted) {
        setState(() {
          communityComplaints = List<Map<String, dynamic>>.from(response);
          loading = false;
        });

      _scrollToHighlightedComplaint(communityComplaints);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          communityComplaints = [];
          loading = false;
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading complaints: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchPersonalComplaints() async {
    if (officerSectionId == null) return;

    if (mounted) setState(() => loading = true);

    try {
      final response = await supabase
          .from('complaints')
          .select()
          .eq('section_id', officerSectionId!)
          .eq('complaint_type', 'personal')
          .order('created_at', ascending: true);

      if (mounted) {
       setState(() {
  personalComplaints = List<Map<String, dynamic>>.from(response);
  loading = false;
});

_scrollToHighlightedComplaint(personalComplaints);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          personalComplaints = [];
          loading = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading personal complaints: $e")),
      );
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

  void _listenToRealtime() {
  try {
    supabase
        .channel('complaints-channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'complaints',
          callback: (payload) {
            if (!mounted || officerSectionId == null) return;

            final record = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;

            if (record['section_id'] == officerSectionId) {

              if (record['complaint_type'] == 'community') {
                _fetchCommunityComplaints();
              } 
              else if (record['complaint_type'] == 'personal') {
                _fetchPersonalComplaints();
              }
            }
          },
        )
        .subscribe();
  } catch (e) {
    debugPrint("Realtime error: $e");
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
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> communityComplaints = [];
  List<Map<String, dynamic>> personalComplaints = [];
  String? officerSectionId;
  bool loading = true;
  final ScrollController _scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    const adminThemeColor = Color(0xFF219869);
    const backgroundGrey = Color(0xFFE0E0E0); // Light grey background

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
                onRefresh: () async {
                  if (isCommunitySelected) {
                    await _fetchCommunityComplaints();
                  } else {
                    await _fetchPersonalComplaints();
                  }
                },
                child: ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: isCommunitySelected
                      ? _buildCommunityList(adminThemeColor)
                      : _buildPersonalList(adminThemeColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. Community Complaints List ---
  List<Widget> _buildCommunityList(Color themeColor) {
    if (loading) {
      return [const Center(child: CircularProgressIndicator())];
    }

    if (communityComplaints.isEmpty) {
      return [const Center(child: Text("No complaints found"))];
    }

    return communityComplaints.map((complaint) {
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
  List<Widget> _buildPersonalList(Color themeColor) {
    if (loading) {
      return [const Center(child: CircularProgressIndicator())];
    }

    if (personalComplaints.isEmpty) {
      return [const Center(child: Text("No personal complaints found"))];
    }

    return personalComplaints.map((complaint) {
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

  // 🔥 If empty → derive from lat/lng
  if ((finalLocation.isEmpty) && latitude != null && longitude != null) {
    finalLocation = await _getLocationName(latitude, longitude);
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AdminLayout(
        initialIndex: 1,
        complaintData: {
          'complaint_id': complaintId,
          'tracking_code': tracking,
          'category': title,
          'image_url': imageUrl,
          'description': description,
          'status': status,
          'location_name': finalLocation,
        },
      ),
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
        border: highlight ? Border.all(color: Colors.orange, width: 2) : null,
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
    // 🖼 SHOW IMAGE ONLY IF EXISTS
  if (imageUrl != null && imageUrl.isNotEmpty) ...[
  Padding(
    padding: const EdgeInsets.only(top: 6), // 👈 adjust this value
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      ),
    ),
  ),
  const SizedBox(width: 12),
],

    // 📄 DETAILS
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
    // 👍 UPVOTES
    if (upvotes > 0) ...[
      const Icon(Icons.thumb_up, size: 14, color: Colors.orange),
      const SizedBox(width: 4),
      Text(
        "$upvotes Upvotes",
        style: const TextStyle(fontWeight: FontWeight.w500),
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
          title: const Text("Update Status"),
          content: DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            items: const [
              DropdownMenuItem(value: "pending", child: Text("Pending")),
              DropdownMenuItem(value: "in-progress",child: Text("In-Progress"),),
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
      // 1️⃣ Update complaint status
      await supabase
          .from('complaints')
          .update({'status': newStatus})
          .eq('complaint_id', complaintId);

      // 2️⃣ Get complaint owner
      final complaint = await supabase
          .from('complaints')
          .select('user_id')
          .eq('complaint_id', complaintId)
          .single();

      final ownerId = complaint['user_id'];

      // 3️⃣ Create notification
      await supabase.from('notifications').insert({
        'complaint_id': complaintId,
        'user_id': ownerId,
        'recipient_type': 'user',
        'title': 'Complaint Status Updated',
        'message': 'Your complaint status is now $newStatus',
      });

      _fetchCommunityComplaints();
      _fetchPersonalComplaints();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  void dispose() {
    supabase.removeAllChannels();
    super.dispose();
  }
}