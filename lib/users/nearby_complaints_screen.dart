import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import '../main.dart';

class NearByComplaintsScreen extends StatefulWidget {
  const NearByComplaintsScreen({super.key});

  @override
  State<NearByComplaintsScreen> createState() => _NearByComplaintsScreenState();
}

class _NearByComplaintsScreenState extends State<NearByComplaintsScreen> {
  final Color navyBlue = const Color(0xFF0D3B66);
  int? _selectedMarkerIndex;
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _complaints = [];
  bool _loading = true;
  String? _userSectionId;

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final connections = await supabase
          .from('consumer_connections')
          .select('section_id')
          .eq('user_id', user.id)
          .limit(1);

      if (connections.isNotEmpty) {
        _userSectionId = connections[0]['section_id'];
        await _fetchNearbyComplaints();
      } else {
        if (mounted) setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No section found for your consumer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing: $e');
      if (mounted) setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchNearbyComplaints() async {
    if (_userSectionId == null) return;

    try {
      final response = await supabase
          .from('complaints')
          .select()
          .eq('complaint_type', 'community')
          .eq('section_id', _userSectionId!)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _complaints = List<Map<String, dynamic>>.from(response);
          _loading = false;
        });
      }

      debugPrint('Fetched ${_complaints.length} community complaints');
    } catch (e) {
      debugPrint('Error fetching complaints: $e');
      if (mounted) {
        setState(() {
          _complaints = [];
          _loading = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading complaints: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialZoom: 10.0,
                    onTap: (_, __) =>
                        setState(() => _selectedMarkerIndex = null),
                    onMapReady: () {
                      _moveToCurrentLocation();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.complaintapp.flutter_map',
                    ),
                    CurrentLocationLayer(
                      style: const LocationMarkerStyle(
                        marker: DefaultLocationMarker(
                          color: Color.fromARGB(255, 22, 119, 199),
                          child: Icon(Icons.navigation,
                              color: Colors.white, size: 14),
                        ),
                        markerSize: Size(30, 30),
                        markerDirection: MarkerDirection.heading,
                        showHeadingSector: true,
                        headingSectorColor:
                            Color.fromARGB(120, 33, 149, 243),
                        headingSectorRadius: 60,
                      ),
                    ),
                    MarkerLayer(
                      markers: _complaints.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> data = entry.value;

                        final lat = data['latitude'];
                        final lng = data['longitude'];

                        if (lat == null || lng == null) {
                          return null;
                        }

                        return Marker(
                          point: LatLng(
                            double.parse(lat.toString()),
                            double.parse(lng.toString()),
                          ),
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
                      }).whereType<Marker>().toList(),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 40,
                  right: 20,
                  child: FloatingActionButton(
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Colors.black87),
                    onPressed: () {
                      _moveToCurrentLocation();
                    },
                  ),
                ),
                if (_selectedMarkerIndex != null && _complaints.isNotEmpty)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: _buildComplaintPopup(
                        _complaints[_selectedMarkerIndex!]),
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
                    'Tracking: ${data['tracking_code'] ?? "N/A"}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Issue: ${data['category'] ?? "N/A"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.location_on,
                color: Colors.red,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data['description'] ?? "No description",
            style: const TextStyle(fontSize: 12),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            'Status: ${data['status'] ?? "Pending"}',
            style: TextStyle(
              fontSize: 12,
              color: _getStatusColor(data['status'] ?? "Pending"),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in_progress':
      case 'in-progress':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}