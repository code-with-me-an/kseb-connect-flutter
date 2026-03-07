import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'report_complaint_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_data_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  // --- LOGIC FUNCTIONS REMAIN UNTOUCHED ---
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    }
  }

  Future<void> _fetchSectionNotifications() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

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

      final sectionIds = connections.map((c) => c['section_id']).toList();

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

  // --- UI DESIGN ---
  @override
  Widget build(BuildContext context) {
    const backgroundWhite = Color.fromARGB(255, 255, 255, 255); // White shades for background
    const sheetGrey = Color.fromARGB(255, 231, 232, 233); // Slightly grey for the sliding sheet to stand out
    const orangeColor = Color(0xFFE85842); // Action button color
    const textDark = Color(0xFF1E293B); // Dark text for readability

    // Adjusted height to fit the new text and SVG layout
    final double headerRevealHeight = 180.0; 

    return Scaffold(
      backgroundColor: backgroundWhite, 
      body: Stack(
        children: [
          // 1. BACKGROUND HEADER (Fixed in place, White Background, Dark Text)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              // Padding from the top (adjust if MainLayout AppBar overlaps)
              padding: const EdgeInsets.only(top: 20, left: 15, right: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Text
                        loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: textDark))
                            : Text(
                                "Welcome, $userName",
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  color: textDark,
                                ),
                              ),
                        const SizedBox(height: 8),

                        // Location Text
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "Location: ${locationLoading ? "Fetching..." : locationName}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Active Complaints & Updates (Styled simply with dark text)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "2 Active Complaints",
                            style: TextStyle(
                              color: Colors.green.shade800, 
                              fontSize: 12, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Last update: Officer assigned",
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  // Right Side: SVG Lineman Image
                  SizedBox(
                    width: 120, // Adjust width as needed
                    height: 120, // Adjust height as needed
                    child: SvgPicture.asset(
                      'assets/lineman.svg',
                      fit: BoxFit.contain,
                      alignment: Alignment.topRight,
                      placeholderBuilder: (context) => const Icon(
                        Icons.engineering,
                        size: 60,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. FOREGROUND SCROLLABLE SHEET (Overwrites background when scrolled)
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // This invisible box creates the gap so you can see the white header behind it
                  SizedBox(height: headerRevealHeight),

                  // The Main Content Container
                  Container(
                    width: double.infinity,
                    // Ensures the sheet reaches the bottom of the screen
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - headerRevealHeight,
                    ),
                    decoration: BoxDecoration(
                      color: sheetGrey,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5), // Shadow pointing upwards
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Small handle indicator at the top of the sheet
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 25),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        // --- REPORT BUTTON ---
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orangeColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25), // Pill shaped
                              ),
                              elevation: 2,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ReportComplaintScreen(),
                                ),
                              );
                            },
                            label: const Text(
                              "Report a New Complaint",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 35),

                        // --- ALERTS & ANNOUNCEMENTS ---
                        const Row(
                          children: [
                            Icon(Icons.campaign, color: textDark, size: 22),
                            SizedBox(width: 8),
                            Text(
                              "Alerts & Announcements",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        notificationsLoading
                            ? const Center(child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ))
                            : notifications.isEmpty
                                ? const Text("No announcements", style: TextStyle(color: Colors.grey))
                                : Column(
                                    children: notifications.map((notif) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _buildAlertCard(
                                          icon: Icons.info_outline,
                                          iconColor: Colors.blue.shade700,
                                          title: "Notification",
                                          text: notif['message'] ?? '',
                                          date: "Today",
                                          badgeText: "NEW",
                                          badgeColor: Colors.orange.shade100,
                                          badgeTextColor: Colors.orange.shade800,
                                        ),
                                      );
                                    }).toList(),
                                  ),

                        const SizedBox(height: 25),

                        // --- ISSUES NEAR YOU ---
                        const Row(
                          children: [
                            Icon(Icons.location_on, color: textDark, size: 22),
                            SizedBox(width: 8),
                            Text(
                              "Issues Near You",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Static Issue List matching design
                        Column(
                          children: [
                            _buildIssueItem(
                              title: "Power Outage",
                              location: "East Hill",
                              status: "In Progress",
                              distance: "1.2 km away",
                              statusColor: Colors.blue.shade700,
                              iconContainerColor: Colors.orange.shade50,
                              iconColor: Colors.orange,
                            ),
                            _buildIssueItem(
                              title: "Street Light Failure",
                              location: "Nadakkavu",
                              status: "Assigned",
                              distance: "0.8 km away",
                              statusColor: Colors.green.shade600,
                              iconContainerColor: Colors.orange.shade50,
                              iconColor: Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40), // Extra bottom padding for scroll
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildAlertCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String text,
    required String date,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (badgeText.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(4),
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
                      ],
                    ),
                    Text(
                      date,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueItem({
    required String title,
    required String location,
    required String status,
    required String distance,
    required Color statusColor,
    required Color iconContainerColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconContainerColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.domain, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                distance,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}