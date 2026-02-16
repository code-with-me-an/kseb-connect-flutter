import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComplaintsListScreen extends StatefulWidget {
  const ComplaintsListScreen({super.key});

  @override
  State<ComplaintsListScreen> createState() => _ComplaintsListScreenState();
}

class _ComplaintsListScreenState extends State<ComplaintsListScreen> {
  // Toggle State: true = Community, false = Personal
  bool isCommunitySelected = true;

  @override
  void initState() {
    super.initState();
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
        print("Officer record not found");
        return;
      }

      officerSectionId = officer['section_id'];

      await _fetchCommunityComplaints();

      _listenToRealtime();
    } catch (e) {
      print("Error initializing: $e");

      if (mounted) setState(() => loading = false);

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
          .from('complaints')
          .select()
          .eq('section_id', officerSectionId!)
          .eq('complaint_type', 'community')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          communityComplaints = List<Map<String, dynamic>>.from(response);
          loading = false;
        });
      }
    } catch (e) {
      print("Error fetching community complaints: $e");

      if (mounted) {
        setState(() {
          communityComplaints = [];
          loading = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading complaints: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
              try {
                if (payload.newRecord['section_id'] == officerSectionId &&
                    payload.newRecord['complaint_type'] == 'community') {
                  _fetchCommunityComplaints();
                }
              } catch (e) {
                print("Error in realtime callback: $e");
              }
            },
          )
          .subscribe();
    } catch (e) {
      print("Error setting up realtime listener: $e");
    }
  }

  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> communityComplaints = [];
  String? officerSectionId;
  bool loading = true;

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
                  }
                },
                child: ListView(
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
      return _buildComplaintCard(
        title: "Tracking: ${complaint['tracking_code'] ?? ""}",
        subtitle: "Issue: ${complaint['category'] ?? ""}",
        detail: complaint['description'],
        status: complaint['status'] ?? "Pending",
        themeColor: themeColor,
      );
    }).toList();
  }

  // --- 2. Personal Complaints List ---
  List<Widget> _buildPersonalList(Color themeColor) {
    return [
      _buildComplaintCard(
        title: "Complaint ID: #1023",
        subtitle: "Issue: Voltage Issue",
        detail: null, // Personal complaints might not have 'count'
        status: "Pending",
        themeColor: themeColor,
      ),
      _buildComplaintCard(
        title: "Complaint ID: #1024",
        subtitle: "Issue: Post Broken",
        detail: null,
        status: "Pending",
        themeColor: themeColor,
      ),
      _buildComplaintCard(
        title: "Complaint ID: #1025",
        subtitle: "Issue: Voltage issue",
        detail: null,
        status: "In-Progress",
        themeColor: themeColor,
      ),
      _buildComplaintCard(
        title: "Complaint ID: #1026",
        subtitle: "Issue: Voltage Issue",
        detail: null,
        status: "Pending",
        themeColor: themeColor,
      ),
    ];
  }

  // --- Helper: Complaint Card Widget ---
  Widget _buildComplaintCard({
    required String title,
    required String subtitle,
    String? detail,
    required String status,
    required Color themeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title + Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.edit, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      "Edit",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Row 2: Issue Description
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),

          const SizedBox(height: 8),

          // Row 3: Detail (Complaint Count) or Empty
          if (detail != null) ...[
            Text(
              detail,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
          ],

          // Row 4: Status
          Text(
            "Status: $status",
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
