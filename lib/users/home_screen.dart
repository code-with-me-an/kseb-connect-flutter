import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'report_complaint_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_data_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;

  String userName = "User";
  bool loading = true;
  String locationName = "Fetching location...";
  bool locationLoading = true;
  List<Map<String, dynamic>> notifications = [];
  bool notificationsLoading = true;

  @override
  void initState() {
    super.initState();

    _fetchUserName();
    _fetchCurrentLocationName();
    _fetchSectionNotifications();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserConsumers();
    });
  }

  Future<void> _fetchCurrentLocationName() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationName = "Location Disabled";
          locationLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            locationName = "Permission Denied";
            locationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationName = "Permission Permanently Denied";
          locationLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        setState(() {
          locationName =
              place.locality ??
              place.subLocality ??
              place.administrativeArea ??
              "Unknown Location";
          locationLoading = false;
        });
      } else {
        setState(() {
          locationName = "Unknown Location";
          locationLoading = false;
        });
      }
    } catch (e) {
      debugPrint("LOCATION ERROR: $e");
      setState(() {
        locationName = "Location Error";
        locationLoading = false;
      });
    }
  }

  Future<void> _loadUserConsumers() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;
    final provider = context.read<UserDataProvider>();
    if (provider.consumerConnections.isEmpty) {
      await provider.loadConsumers(user.id);
    }
  }

  Future<void> _fetchUserName() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) setState(() => loading = false);
      return;
    }

    try {
      final response = await supabase
          .from('users')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        if (mounted) {
          setState(() {
            userName = response['name'] ?? "User";
            loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            userName = "User";
            loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
      if (mounted) {
        setState(() {
          userName = "User";
          loading = false;
        });
      }

      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    }
  }

  Future<void> _fetchSectionNotifications() async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Get all sections connected to the user
    final connections = await supabase
        .from('consumer_connections')
        .select('section_id')
        .eq('user_id', user.id);

    if (connections.isEmpty) {
      setState(() {
        notifications = [];
        notificationsLoading = false;
      });
      return;
    }

    final sectionIds =
        connections.map((c) => c['section_id']).toList();

    // Fetch notifications for those sections
    final response = await supabase
        .from('notifications')
        .select()
        .eq('recipient_type', 'section')
        .inFilter('section_id', sectionIds)
        .order('created_at', ascending: false);

    if (mounted) {
      setState(() {
        notifications = List<Map<String, dynamic>>.from(response);
        notificationsLoading = false;
      });
    }
  } catch (e) {
    debugPrint("Notification fetch error: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    const backgroundGrey = Color(0xFFF2F2F2);
    const orangeColor = Color(0xFFE85842); // For Report Button

    return Scaffold(
      backgroundColor: backgroundGrey,
      // --- Body ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Location Text
            Center(
              child: Text(
                "Location: $locationName",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Welcome Card (Worker Illustration)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        loading
                            ? const CircularProgressIndicator()
                            : Text(
                                "Welcome, $userName",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                        const SizedBox(height: 8),
                        RichText(
                          text: const TextSpan(
                            text: "You have ",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: "2 active complaints",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.assignment_ind_outlined,
                              size: 16,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Last update: Officer assigned",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Placeholder for the Cartoon Worker Image
                  // Using a network image or icon to simulate the design
                  SizedBox(
                    height: 100,
                    width: 80,
                    child: Image.network(
                      'https://cdn-icons-png.flaticon.com/512/3048/3048122.png', // Generic worker icon
                      fit: BoxFit.contain,
                      errorBuilder: (c, o, s) => const Icon(
                        Icons.engineering,
                        size: 60,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Latest Complaint Status (Tracker)
            Container(
              padding: const EdgeInsets.all(20),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Latest Complaint Status",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // The Progress Bar
                  Row(
                    children: [
                      _buildStep(true, "Reported", Colors.green),
                      _buildLine(true),
                      _buildStep(true, "Assigned", Colors.green),
                      _buildLine(
                        true,
                        isHalf: true,
                      ), // Half colored for "In Progress"
                      _buildStep(
                        true,
                        "In Progress",
                        Colors.blue,
                      ), // Active step
                      _buildLine(false),
                      _buildStep(false, "Resolved", Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Complaint #2515 | Power outage in your area",
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

            const SizedBox(height: 20),

            // 4. BIG REPORT BUTTON
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  shadowColor: orangeColor.withValues(alpha: 0.4),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReportComplaintScreen(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.favorite, color: orangeColor, size: 18),
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      "Report Complaint",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // 5. Alerts / Announcements
            const Row(
              children: [
                Icon(Icons.campaign, color: Colors.orange, size: 24),
                SizedBox(width: 10),
                Text(
                  "Alerts / Announcements",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),

            notificationsLoading
                ? const Center(child: CircularProgressIndicator())
                : notifications.isEmpty
                ? const Text("No announcements")
                : Column(
                    children: notifications.map((notif) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildAlertCard(
                          color: const Color(0xFFE3F2FD),
                          icon: Icons.campaign,
                          iconColor: Colors.blue,
                          text: notif['message'] ?? '',
                          badgeText: "New",
                          badgeColor: Colors.white,
                          badgeTextColor: Colors.blue,
                        ),
                      );
                    }).toList(),
                  ),

            const SizedBox(height: 25),

            // 6. Issues Near You
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.green, size: 24),
                SizedBox(width: 10),
                Text(
                  "Issues Near You",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Issue List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildIssueItem(
                    "Power outage on Sunset Ave",
                    "1.2 km",
                    isLast: false,
                  ),
                  _buildIssueItem(
                    "Transformer issue at Green St",
                    "900 m",
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  // 1. Progress Step (Dot + Label)
  Widget _buildStep(bool isActive, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 8,
          backgroundColor: isActive ? color : Colors.grey[300],
          child: isActive
              ? const Icon(Icons.check, size: 10, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? Colors.black87 : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // 2. Progress Line
  Widget _buildLine(bool isActive, {bool isHalf = false}) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 14), // Align with dots
        decoration: BoxDecoration(
          gradient: isHalf
              ? const LinearGradient(colors: [Colors.green, Colors.blue])
              : null,
          color: isHalf ? null : (isActive ? Colors.green : Colors.grey[300]),
        ),
      ),
    );
  }

  // 3. Alert Card
  Widget _buildAlertCard({
    required Color color,
    required IconData icon,
    required Color iconColor,
    required String text,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Issue List Item
  Widget _buildIssueItem(String text, String distance, {required bool isLast}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            distance,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
