import '../main.dart';
import 'package:flutter/material.dart';
import 'package:kseb_connect/providers/home_provider.dart';
import 'report_complaint_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_data_provider.dart';
import 'main_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeProvider get home => context.watch<HomeProvider>();
  UserDataProvider get userData => context.watch<UserDataProvider>();

  final ScrollController _scrollController = ScrollController();
  double maxPullDown = 40;
  double bottomLimit = 60;
  bool isHolding = false;

  static const Color backgroundWhite = Colors.white;
  static const Color sheetGrey = Color.fromARGB(255, 231, 231, 231);
  static const Color textDark = Colors.black87;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      double offset = _scrollController.offset;

      // restrict pull down
      if (offset < -maxPullDown) {
        _scrollController.jumpTo(-maxPullDown);
      }

      // restrict bottom scroll
      if (offset > _scrollController.position.maxScrollExtent) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = supabase.auth.currentUser!.id;

      context.read<HomeProvider>().loadHomeData();
      context.read<UserDataProvider>().loadUserName(userId);
    });
  }

  // --- UI DESIGN ---
  @override
  Widget build(BuildContext context) {
    if (home.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    const orangeColor = Color(0xFFE85842); // For Report Button
    double headerRevealHeight = 200;

    return Scaffold(
      backgroundColor: backgroundWhite,
      body: Stack(
        children: [
          // 1. BACKGROUND HEADER (Fixed in place, White Background, Dark Text)
          // 1. BACKGROUND HEADER WITH IMAGE
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 265,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/power_bg.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.only(top: 35, left: 18, right: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Text
                    Text(
                      "Welcome, ${userData.userName}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            home.locationName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Active Complaints Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "2 Active Complaints",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Last update: Officer assigned",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. FOREGROUND SCROLLABLE SHEET (Overwrites background when scrolled)
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                children: [
                  // This invisible box creates the gap so you can see the white header behind it
                  SizedBox(height: headerRevealHeight),

                  // The Main Content Container
                  Container(
                    width: double.infinity,
                    // Ensures the sheet reaches the bottom of the screen
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          headerRevealHeight,
                    ),
                    decoration: BoxDecoration(
                      color: sheetGrey,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(
                            0,
                            -5,
                          ), // Shadow pointing upwards
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Small handle indicator at the top of the sheet
                        GestureDetector(
                          onTapDown: (_) {
                            setState(() {
                              isHolding = true;
                            });
                          },
                          onTapUp: (_) {
                            setState(() {
                              isHolding = false;
                            });
                          },
                          onTapCancel: () {
                            setState(() {
                              isHolding = false;
                            });
                          },
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isHolding ? 70 : 40,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 25),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),

                        // --- REPORT BUTTON ---
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
                                  child: const Icon(
                                    Icons.report_problem,
                                    color: orangeColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                const Text(
                                  "Report a New Complaint",
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

                        const SizedBox(height: 35),

                        // --- ALERTS & ANNOUNCEMENTS ---
                        const Row(
                          children: [
                            Icon(
                              Icons.campaign,
                              color: Colors.orange,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Alerts & Announcements",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        home.loading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : home.notifications.isEmpty
                            ? const Text(
                                "No announcements",
                                style: TextStyle(color: Colors.grey),
                              )
                            : Column(
                                children: home.notifications.map((notif) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildAlertCard(
                                      icon: notif['is_alert'] == true
                                          ? Icons.warning_amber_rounded
                                          : Icons.info_outline,
                                      iconColor: Colors.blue.shade700,
                                      title: notif['title'] ?? "Notification",
                                      text: notif['message'] ?? '',
                                      date: "Today",
                                      badgeText: notif['is_read'] == false
                                          ? "NEW"
                                          : "OLD",
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
                            Icon(
                              Icons.location_on,
                              color: Colors.green,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Issues Near You",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Static Issue List matching design
                        home.nearbyComplaints.isEmpty
                            ? const Text(
                                "No issues reported near you",
                                style: TextStyle(color: Colors.grey),
                              )
                            : Column(
                                children: home.nearbyComplaints.map((
                                  complaint,
                                ) {
                                  return GestureDetector(
                                    onTap: () {
                                      MainLayout.openNearbyComplaint(
                                        complaint['latitude'],
                                        complaint['longitude'],
                                      );
                                    },
                                    child: _buildIssueItem(
                                      title:
                                          complaint['category'] ?? "Complaint",
                                      location:
                                          complaint['locationName'] ??
                                          "Unknown",
                                      status: complaint['status'] ?? "Pending",
                                      distance:
                                          "${complaint['distance'].toStringAsFixed(1)} km away",
                                      statusColor: Colors.orange,
                                      iconContainerColor: Colors.orange.shade50,
                                      iconColor: Colors.orange,
                                    ),
                                  );
                                }).toList(),
                              ),
                        const SizedBox(
                          height: 40,
                        ), // Extra bottom padding for scroll
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
            color: Colors.black.withValues(alpha: 0.03),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
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
            color: Colors.black.withValues(alpha: 0.03),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
