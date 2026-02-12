import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart'; // Ensure this is imported

class ReportComplaintScreen extends StatefulWidget {
  const ReportComplaintScreen({super.key});

  @override
  State<ReportComplaintScreen> createState() => _ReportComplaintScreenState();
}

class _ReportComplaintScreenState extends State<ReportComplaintScreen> {
  String? complaintType;
  String? category;
  final TextEditingController detailsController = TextEditingController();
  File? _selectedImage;
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  bool _isMapLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // --- 1. FIXED: Set the pin immediately when location is found ---
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isMapLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isMapLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isMapLoading = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      _isMapLoading = false;
      // ✅ This puts the Red Pin on the Blue Dot immediately
      _selectedLocation = LatLng(position.latitude, position.longitude);
    });

    _mapController.move(
      LatLng(position.latitude, position.longitude),
      15.0,
    );
  }

  // ... (Keep _pickImage, uploadImage, submitComplaint same as before) ...
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<String?> uploadImage(File image) async {
    final supabase = Supabase.instance.client;
    final fileName ='public/complaints/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await supabase.storage.from('complaint-images').upload(fileName, image);
    return supabase.storage.from('complaint-images').getPublicUrl(fileName);
  }

  Future<void> submitComplaint({
    required String complaintTypeUI,
    required String category,
    required String description,
    File? image,
    String? consumerId,
    double? latitude,
    double? longitude,
  }) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) throw Exception("User not logged in");

    final complaintType = complaintTypeUI.toLowerCase();
    String? imageUrl;
    if (image != null) {
      imageUrl = await uploadImage(image);
    }

    if (complaintType == 'personal' && consumerId == null) {
      throw Exception("Personal complaint requires consumer ID");
    }

    if (complaintType == 'community' && (latitude == null || longitude == null)) {
      throw Exception("Please select a location on the map.");
    }

    await supabase.from('complaints').insert({
      'user_id': user.id,
      'section_id': '50768a6c-9ef1-4424-aef5-11bc54b88411',
      'complaint_type': complaintType,
      'category': category,
      'description': description,
      'consumer_id': complaintType == 'personal' ? consumerId : null,
      'latitude': complaintType == 'community' ? latitude : null,
      'longitude': complaintType == 'community' ? longitude : null,
      'image_url': imageUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    const navyBlue = Color(0xFF0D3B66);
    const backgroundGrey = Color(0xFFF5F5F5);
    const uploadButtonColor = Color(0xFFFFF9F0);

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        backgroundColor: navyBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Report Complaint",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomDropdown(
              hint: "Select Complaint Type",
              value: complaintType,
              items: [
                'power_outage', 'voltage_issue', 'billing_issue', 'meter_issue',
                'line_issue', 'transformer_issue', 'street_light', 'safety_hazard', 'etc',
              ],
              onChanged: (v) => setState(() => complaintType = v),
            ),
            const SizedBox(height: 15),
            _buildCustomDropdown(
              hint: "Category",
              value: category,
              items: ["Personal", "Community"],
              onChanged: (v) => setState(() => category = v),
            ),
            const SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: detailsController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Complaint Details",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: uploadButtonColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedImage != null ? Icons.check_circle : Icons.camera_alt_outlined,
                      color: _selectedImage != null ? Colors.green : Colors.grey[700],
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _selectedImage != null ? "Image Captured" : "Upload Image",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 20),

            // --- REAL INTERACTIVE MAP ---
            Container(
              height: 250, 
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    _isMapLoading
                        ? const Center(child: CircularProgressIndicator())
                        : FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: const LatLng(11.2588, 75.7804),
                              initialZoom: 15.0,
                              onTap: (_, latlng) {
                                setState(() {
                                  _selectedLocation = latlng;
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                                userAgentPackageName: 'com.complaintapp.report',
                              ),
                              
                              // 2. FIXED: Added the Blue Dot Layer here!
                              CurrentLocationLayer(
                                style: const LocationMarkerStyle(
                                  marker: DefaultLocationMarker(
                                    color: Color(0xFF2196F3),
                                    child: Icon(Icons.navigation, color: Colors.white, size: 14),
                                  ),
                                  markerSize: Size(20, 20),
                                  markerDirection: MarkerDirection.heading,
                                ),
                              ),

                              if (_selectedLocation != null)
                                MarkerLayer(
                                  // 3. FIXED: Ensures marker stands UP on the location
                                  rotate: false,
                                  alignment: Alignment.bottomCenter, 
                                  markers: [
                                    Marker(
                                      point: _selectedLocation!,
                                      width: 40,
                                      height: 40,
                                      child: SvgPicture.asset(
                                        'assets/marker.svg',
                                        width: 40,
                                        height: 40,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                    
                    Positioned(
                      top: 10,
                      right: 10,
                      child: InkWell(
                        onTap: _getCurrentLocation,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black12)],
                          ),
                          child: const Icon(Icons.my_location, size: 20, color: Color(0xFF0D3B66)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_selectedLocation != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Text(
                  "Pinned Location: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}",
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: navyBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () async {
                  try {
                    await submitComplaint(
                      complaintTypeUI: category!,
                      category: complaintType!,
                      description: detailsController.text,
                      image: _selectedImage,
                      consumerId: category == "Personal" ? "<CONSUMER_ID_HERE>" : null,
                      latitude: _selectedLocation?.latitude,
                      longitude: _selectedLocation?.longitude,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Complaint submitted successfully")),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
                child: const Text(
                  "Submit Complaint",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      width: double.infinity,
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items.map((e) {
            String displayText = e.replaceAll('_', ' ');
            if (displayText.isNotEmpty) {
              displayText = displayText[0].toUpperCase() + displayText.substring(1);
            }
            return DropdownMenuItem(
              value: e,
              child: Text(
                displayText,
                style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}