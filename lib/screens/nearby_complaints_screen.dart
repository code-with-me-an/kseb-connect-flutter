import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator

class NearByComplaintsScreen extends StatefulWidget {
  const NearByComplaintsScreen({super.key});

  @override
  State<NearByComplaintsScreen> createState() => _NearByComplaintsScreenState();
}

class _NearByComplaintsScreenState extends State<NearByComplaintsScreen> {
  final Color navyBlue = const Color(0xFF0D3B66);
  int? _selectedMarkerIndex;

  // 1. Create the MapController
  final MapController _mapController = MapController();

  // 2. Logic to Find User & Move Map
  Future<void> _moveToCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition();

    // Move the map to the user's location
    _mapController.move(
      LatLng(position.latitude, position.longitude),
      15.0, // Zoom level
    );
  }

  final List<Map<String, dynamic>> _complaints = [
    {
      "id": 1,
      "title": "Power Outage",
      "location": "Kallai",
      "upvotes": 16,
      "point": const LatLng(11.2300, 75.7900),
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
      body: Stack(
        children: [
          FlutterMap(
            // 3. Connect the controller
            mapController: _mapController, 
            options: MapOptions(
              initialZoom: 10.0,
              onTap: (_, __) => setState(() => _selectedMarkerIndex = null),
              
              // 4. Move to user location immediately when map is ready
              onMapReady: () {
                _moveToCurrentLocation();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.complaintapp.flutter_map',
                
              ),
              
              CurrentLocationLayer(
                style: const LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    color: Color.fromARGB(255, 22, 119, 199),
                    child: Icon(Icons.navigation, color: Colors.white, size: 14),
                  ),
                  markerSize: Size(30, 30),
                  markerDirection: MarkerDirection.heading,
                  showHeadingSector: true,
                  headingSectorColor: Color.fromARGB(120, 33, 149, 243),
                  headingSectorRadius: 60,
                ),
              ),

              MarkerLayer(
                markers: _complaints.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> data = entry.value;

                  return Marker(
                    point: data['point'],
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedMarkerIndex == index) {
                            _selectedMarkerIndex = null;
                          } else {
                            _selectedMarkerIndex = index;
                          }
                        });
                      },
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            'assets/marker.svg',
                            width: 35,
                            height: 35,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 5. Floating Action Button with Logic
          Positioned(
            bottom: 40,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.black87),
              onPressed: () {
                // Call the function when button is clicked
                _moveToCurrentLocation();
              },
            ),
          ),

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

  Widget _buildComplaintPopup(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              GestureDetector(
                onTap: () => setState(() => _selectedMarkerIndex = null),
                child: const Icon(Icons.close, color: Colors.grey, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Upvoted ${data['title']}!")),
                );
              },
              icon: const Icon(Icons.thumb_up_alt_outlined, color: Colors.white, size: 20),
              label: const Text(
                "Upvote",
                style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F51B5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}