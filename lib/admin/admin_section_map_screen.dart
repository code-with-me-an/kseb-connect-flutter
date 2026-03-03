import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'complaints_list_screen.dart';

class AdminSectionMapScreen extends StatefulWidget {
  const AdminSectionMapScreen({super.key});

  @override
  State<AdminSectionMapScreen> createState() => _AdminSectionMapScreenState();
}

class _AdminSectionMapScreenState extends State<AdminSectionMapScreen> {
  final MapController _mapController = MapController();
  final supabase = Supabase.instance.client;
  DateTime? _lastFetchTime;
  int? _selectedMarkerIndex;
  List<dynamic> _complaints = [];
  bool _loading = true;

  @override
  @override
void initState() {
  super.initState();
  fetchSectionComplaints(forceRefresh: true);

  Future.doWhile(() async {
    await Future.delayed(const Duration(seconds: 30));
    if (!mounted) return false;
    await fetchSectionComplaints(forceRefresh: true);
    return true;
  });
}
  Future<void> fetchSectionComplaints({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inSeconds < 30) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final sectionId = prefs.getString('admin_section_id');

      if (sectionId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final response = await supabase
          .from('complaints_with_upvotes')
          .select()
          .eq('section_id', sectionId);

      if (mounted) {
        setState(() {
          _complaints = response;
          _loading = false;
          _lastFetchTime = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _complaints = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
  initialCenter: LatLng(11.2588, 75.7804),
  initialZoom: 13,
  onMapReady: () {
    fetchSectionComplaints(forceRefresh: true);
  },
),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),

    MarkerLayer(
  markers: _complaints.asMap().entries.map((entry) {
    int index = entry.key;
    var complaint = entry.value;

    final lat = complaint['latitude'];
    final lng = complaint['longitude'];
    final type = complaint['complaint_type'];

    if (lat == null || lng == null) return null;

    return Marker(
      point: LatLng(
        double.parse(lat.toString()),
        double.parse(lng.toString()),
      ),
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMarkerIndex =
                _selectedMarkerIndex == index ? null : index;
          });
        },
        child: type == 'community'
            ? Stack(
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/communityicon.svg',
                    width: 40,
                    height: 40,
                  ),
                  Positioned(
                    top: 12,
                    child: Text(
                      "${complaint['upvote_count'] ?? 0}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              )
            : SvgPicture.asset(
                "assets/personalicon.svg",
                width: 25,
                height: 25,
              ),
      ),
    );
  }).whereType<Marker>().toList(),
),  
                  ],
                ),

                Positioned(
                  top: 50,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.white,
                    child: Text("Complaints: ${_complaints.length}"),
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
  Widget _buildComplaintPopup(Map<String, dynamic> complaint) {
  final photoUrl = complaint['photo_url'];

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
        )
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Tracking: ${complaint['tracking_code'] ?? ""}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _selectedMarkerIndex = null);
              },
            )
          ],
        ),

        const SizedBox(height: 6),

        Text("Type: ${complaint['complaint_type']}"),
        Text("Category: ${complaint['category']}"),

        const SizedBox(height: 6),

        Text(complaint['description'] ?? ""),

        const SizedBox(height: 10),

        if (photoUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              photoUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ComplaintsListScreen(
                    highlightComplaintId: complaint['complaint_id'],
                    highlightComplaintType: complaint['complaint_type'],
                  ),
                ),
              );
            },
            child: const Text("View / Edit"),
          ),
        )
      ],
    ),
  );
}
}
