import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSectionMapScreen extends StatefulWidget {
  const AdminSectionMapScreen({super.key});

  @override
  State<AdminSectionMapScreen> createState() =>
      _AdminSectionMapScreenState();
}

class _AdminSectionMapScreenState extends State<AdminSectionMapScreen> {

  final MapController _mapController = MapController();
  final supabase = Supabase.instance.client;

  List<dynamic> _complaints = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchSectionComplaints();
  }

  Future<void> fetchSectionComplaints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sectionId = prefs.getString('admin_section_id');

      if (sectionId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      try {
        final response = await supabase
            .from('complaints')
            .select()
            .eq('section_id', sectionId);

        if (mounted) {
          setState(() {
            _complaints = response;
            _loading = false;
          });
        }
      } catch (queryError) {
        if (mounted) {
          setState(() {
            _complaints = [];
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
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
            options: const MapOptions(
              initialCenter: LatLng(11.2588, 75.7804),
              initialZoom: 13,
            ),
          children: [
  TileLayer(
    urlTemplate:
        'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
    subdomains: const ['a', 'b', 'c'],
  ),

  MarkerLayer(
    markers: _complaints.map((complaint) {

      final lat = complaint['latitude'];
      final lng = complaint['longitude'];
      final type = complaint['complaint_type'];

      if (lat == null || lng == null) {
        return null;
      }

      return Marker(
        point: LatLng(
          double.parse(lat.toString()),
          double.parse(lng.toString()),
        ),
        width: 40,
        height: 40,
        child: Icon(
          Icons.location_on,
          size: 35,
          
          color: type == 'community'
              ? Colors.red
              : Colors.blue,
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

        ],
      ),
    );
  }
}
