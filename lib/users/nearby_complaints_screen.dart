import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NearByComplaintsScreen extends StatefulWidget {
  const NearByComplaintsScreen({super.key});

  @override
  State<NearByComplaintsScreen> createState() =>
      _NearByComplaintsScreenState();
}

class _NearByComplaintsScreenState
    extends State<NearByComplaintsScreen> {
  final Color navyBlue = const Color(0xFF0D3B66);
  int? _selectedMarkerIndex;
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _complaints = [];
  bool _isLoadingComplaints = true;

  @override
  void initState() {
    super.initState();
    _fetchNearbyComplaints();
  }

  // ================= FETCH COMMUNITY COMPLAINTS =================

  Future<void> _fetchNearbyComplaints() async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('complaints')
          .select('''
            complaint_id,
            category,
            description,
            latitude,
            longitude,
            upvotes(count)
          ''')
          .eq('complaint_type', 'community')
          .not('latitude', 'is', null)
          .not('longitude', 'is', null);

      setState(() {
        _complaints = response.map<Map<String, dynamic>>((c) {
          return {
            "id": c['complaint_id'],
            "title": c['category'],
            "description": c['description'],
            "upvotes": (c['upvotes'] as List).isNotEmpty
                ? c['upvotes'][0]['count']
                : 0,
            "point": LatLng(
              (c['latitude'] as num).toDouble(),
              (c['longitude'] as num).toDouble(),
            ),
          };
        }).toList();

        _isLoadingComplaints = false;
      });
    } catch (e) {
      debugPrint("Error fetching complaints: $e");
      setState(() => _isLoadingComplaints = false);
    }
  }

  // ================= MOVE TO CURRENT LOCATION =================

  Future<void> _moveToCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();

    _mapController.move(
      LatLng(position.latitude, position.longitude),
      15.0,
    );
  }

  // ================= UPVOTE LOGIC =================

  Future<void> _upvoteComplaint(String complaintId) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      await supabase.from('upvotes').insert({
        'user_id': user.id,
        'complaint_id': complaintId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upvoted successfully")),
      );

      _fetchNearbyComplaints(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You already upvoted this complaint")),
      );
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _isLoadingComplaints
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
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
                      userAgentPackageName:
                          'com.complaintapp.flutter_map',
                    ),

                    CurrentLocationLayer(
                      style: const LocationMarkerStyle(
                        marker: DefaultLocationMarker(
                          color: Color.fromARGB(255, 22, 119, 199),
                          child: Icon(Icons.navigation,
                              color: Colors.white, size: 14),
                        ),
                        markerSize: Size(30, 30),
                      ),
                    ),

                    MarkerLayer(
                      markers:
                          _complaints.asMap().entries.map((entry) {
                        int index = entry.key;
                        var data = entry.value;

                        return Marker(
                          point: data['point'],
                          width: 35,
                          height: 35,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMarkerIndex =
                                    _selectedMarkerIndex == index
                                        ? null
                                        : index;
                              });
                            },
                            child: SvgPicture.asset(
                              'assets/marker.svg',
                              width: 35,
                              height: 35,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

          Positioned(
            bottom: 40,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location,
                  color: Colors.black87),
              onPressed: _moveToCurrentLocation,
            ),
          ),

          if (_selectedMarkerIndex != null)
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

  // ================= POPUP =================

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
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'],
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${data['upvotes']} Upvotes",
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(
                    () => _selectedMarkerIndex = null),
                child: const Icon(Icons.close,
                    color: Colors.grey, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data['description'],
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _upvoteComplaint(data['id']),
              icon: const Icon(Icons.thumb_up_alt_outlined,
                  color: Colors.white, size: 20),
              label: const Text("Upvote",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF3F51B5),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
