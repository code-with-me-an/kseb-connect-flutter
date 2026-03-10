import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NearByComplaintsScreen extends StatefulWidget {

  final double? highlightLat;
  final double? highlightLng;

  const NearByComplaintsScreen({
    super.key,
    this.highlightLat,
    this.highlightLng,
  });

  @override
  State<NearByComplaintsScreen> createState() =>
      NearByComplaintsScreenState();
}

class NearByComplaintsScreenState extends State<NearByComplaintsScreen> {
  DateTime? _lastFetchTime;
  final Color navyBlue = const Color(0xFF0D3B66);
  int? _selectedMarkerIndex;
  int? _highlightIndex;
  bool _mapReady = false;
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _complaints = [];
  bool _isLoadingComplaints = true;

  @override
  void initState() {
    super.initState();
    fetchNearbyComplaints();
  }

  // ================= FETCH COMMUNITY COMPLAINTS =================

  Future<void> fetchNearbyComplaints({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inSeconds < 30) {
      return;
    }

    setState(() => _isLoadingComplaints = true);

    final supabase = Supabase.instance.client;

    try {
      final userLocation = await _getUserLocation();
      if (userLocation == null) {
        setState(() => _isLoadingComplaints = false);
        return;
      }

      const double radiusInDegrees = 0.05; // ~5km

      final minLat = userLocation.latitude - radiusInDegrees;
      final maxLat = userLocation.latitude + radiusInDegrees;
      final minLng = userLocation.longitude - radiusInDegrees;
      final maxLng = userLocation.longitude + radiusInDegrees;

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
          .gte('latitude', minLat)
          .lte('latitude', maxLat)
          .gte('longitude', minLng)
          .lte('longitude', maxLng);

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

        _lastFetchTime = DateTime.now();
        _isLoadingComplaints = false;
      });
    } catch (e) {
      setState(() => _isLoadingComplaints = false);
    }
  }

  // get user location

  Future<LatLng?> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    Position position = await Geolocator.getCurrentPosition();

    return LatLng(position.latitude, position.longitude);
  }

  // move to current location on map

  Future<void> _moveToCurrentLocation() async {
    final userLocation = await _getUserLocation();

    if (userLocation == null) return;

    _mapController.move(userLocation, 15.0);
  }


  void _focusHighlightedComplaint() {
  if (!_mapReady) return;

  if (widget.highlightLat == null || widget.highlightLng == null) return;

  for (int i = 0; i < _complaints.length; i++) {
    final point = _complaints[i]['point'];

    if ((point.latitude - widget.highlightLat!).abs() < 0.0001 &&
        (point.longitude - widget.highlightLng!).abs() < 0.0001) {

      setState(() {
        _highlightIndex = i;
        _selectedMarkerIndex = i;
      });

      _mapController.move(point, 16);

      Future.delayed(const Duration(seconds: 7), () {
        if (mounted) {
          setState(() => _highlightIndex = null);
        }
      });

      break;
    }
  }
}
void focusComplaint(double lat, double lng) {

  for (int i = 0; i < _complaints.length; i++) {
    final point = _complaints[i]['point'];

    if ((point.latitude - lat).abs() < 0.0001 &&
        (point.longitude - lng).abs() < 0.0001) {

      setState(() {
        _highlightIndex = i;
        _selectedMarkerIndex = i;
      });

      _mapController.move(point, 16);

      Future.delayed(const Duration(seconds: 7), () {
        if (mounted) {
          setState(() => _highlightIndex = null);
        }
      });

      break;
    }
  }
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Upvoted successfully")));

      fetchNearbyComplaints(); // Refresh list
    } catch (e) {
      if (!mounted) return;
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
                    minZoom: 7.0,
                    onTap: (_, _) =>
                        setState(() => _selectedMarkerIndex = null),
                    onMapReady: () async {
    _mapReady = true;

    await _moveToCurrentLocation();

    _focusHighlightedComplaint();
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
                          child: Icon(
                            Icons.navigation,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        markerSize: Size(30, 30),
                      ),
                    ),

                    MarkerLayer(
                      markers: _complaints.asMap().entries.map((entry) {
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
                           child: AnimatedScale(
  duration: const Duration(milliseconds: 300),
  scale: _highlightIndex == index ? 1.5 : 1.0,
  child: SvgPicture.asset(
    'assets/marker.svg',
    width: _highlightIndex == index ? 45 : 35,
    height: _highlightIndex == index ? 45 : 35,
  ),
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
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.black87),
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

  // ================= POPUP =================

  Widget _buildComplaintPopup(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${data['upvotes']} Upvotes",
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
          const SizedBox(height: 10),
          Text(data['description'], style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: () => _upvoteComplaint(data['id']),
              icon: const Icon(
                Icons.thumb_up_alt_outlined,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                "Upvote",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F51B5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
