import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Real Map
import 'package:latlong2/latlong.dart'; // Coordinates
import 'package:flutter_svg/flutter_svg.dart';

class NearByComplaintsScreen extends StatefulWidget {
  const NearByComplaintsScreen({super.key});

  @override
  State<NearByComplaintsScreen> createState() => _NearByComplaintsScreenState();
}

class _NearByComplaintsScreenState extends State<NearByComplaintsScreen> {
  // Navy Blue color from your design
  final Color navyBlue = const Color(0xFF0D3B66);

  // Track which marker is selected
  int? _selectedMarkerIndex;

  // Real GPS Data for Kozhikode (Calicut) area
  // You can get these from Google Maps (Right click -> properties)
  final List<Map<String, dynamic>> _complaints = [
    {
      "id": 1,
      "title": "Power Outage",
      "location": "Kallai",
      "upvotes": 16,
      "point": const LatLng(11.2300, 75.7900), // Real Coordinates
    },
    {
      "id": 2,
      "title": "Transformer Spark",
      "location": "Pottammal",
      "upvotes": 5,
      "point": const LatLng(11.2650, 75.8100),
    },
    {
      "id": 3,
      "title": "Line Broken",
      "location": "Eranhipalam",
      "upvotes": 12,
      "point": const LatLng(11.2800, 75.7850),
    },
    {
      "id": 4,
      "title": "Low Voltage",
      "location": "Mavoor Road",
      "upvotes": 8,
      "point": const LatLng(11.2500, 75.8000),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // --- Body (Real Map Stack) ---
      body: Stack(
        children: [
          // 1. The Real OpenStreetMap Layer
          FlutterMap(
            options: MapOptions(
              // Center the map on Kozhikode initially
              initialCenter: const LatLng(11.2588, 75.7804),
              initialZoom: 13.0,
              onTap: (_, __) {
                // Close popup if user clicks on empty map area
                setState(() {
                  _selectedMarkerIndex = null;
                });
              },
            ),
            children: [
              // A. Tile Layer (The visual map images)
              // NEW CODE (Fixes the error + Cleaner look)
              TileLayer(
                // CartoDB Light theme (Clean, free, and reliable)
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'], // Needed for CartoDB
                userAgentPackageName:
                    'com.complaintapp.flutter_map', // Use a unique name
              ),

              // B. Marker Layer (Your custom SVG markers)
              MarkerLayer(
                markers: _complaints.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> data = entry.value;

                  return Marker(
                    point: data['point'], // Use real LatLng
                    width: 60,
                    height: 60,
                    // The 'child' is the widget displayed at that coordinate
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          // Toggle selection
                          if (_selectedMarkerIndex == index) {
                            _selectedMarkerIndex = null;
                          } else {
                            _selectedMarkerIndex = index;
                          }
                        });
                      },
                      child: Column(
                        children: [
                          // Your Custom SVG Marker
                          SvgPicture.asset(
                            'assets/marker.svg',
                            width: 40,
                            height: 40,
                          ),
                          // Tiny shadow for depth
                          Container(
                            width: 10,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 2. The Pop-Up Card (Stays at the bottom, same as before)
          if (_selectedMarkerIndex != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildComplaintPopup(_complaints[_selectedMarkerIndex!]),
            ),
        ],
      ),
    );
  }

  // --- Widget for the Pop-up details card ---
  Widget _buildComplaintPopup(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Location Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${data['location']} - ${data['upvotes']} Upvotes",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
              // Close button (Optional, but good UX)
              GestureDetector(
                onTap: () => setState(() => _selectedMarkerIndex = null),
                child: const Icon(Icons.close, color: Colors.grey, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Upvote Button (Full Width)
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Upvoted ${data['title']}!")),
                );
              },
              icon: const Icon(
                Icons.thumb_up_alt_outlined,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                "Upvote",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F51B5), // Indigo/Blue
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
