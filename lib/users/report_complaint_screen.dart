import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:provider/provider.dart';
import '../providers/user_data_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportComplaintScreen extends StatefulWidget {
  const ReportComplaintScreen({super.key});

  @override
  State<ReportComplaintScreen> createState() => _ReportComplaintScreenState();
}

class _ReportComplaintScreenState extends State<ReportComplaintScreen> {
  final supabase = Supabase.instance.client;

  String? _selectedConsumerId;
  String? _selectedSectionId;
  String? complaintType;
  String? category;
  final TextEditingController detailsController = TextEditingController();
  File? _selectedImage;
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  bool _isMapLoading = true;
  bool submitting = false;
  LatLng? _cachedLocation;

  final List<Map<String, String>> personalComplaintTypes = [
    {"value": "power_outage", "label": "POWER OUTAGE"},
    {"value": "voltage_issue", "label": "VOLTAGE ISSUE"},
    {"value": "billing_issue", "label": "BILLING ISSUE"},
    {"value": "meter_issue", "label": "METER ISSUE"},
    {"value": "other", "label": "OTHER"},
  ];

  final List<Map<String, String>> communityComplaintTypes = [
    {"value": "line_issue", "label": "LINE ISSUE"},
    {"value": "transformer_issue", "label": "TRANSFORMER ISSUE"},
    {"value": "street_light", "label": "STREET LIGHT"},
    {"value": "safety_hazard", "label": "SAFETY HAZARD"},
    {"value": "power_outage", "label": "AREA POWER OUTAGE"},
    {"value": "other", "label": "OTHER"},
  ];

  // generate the location name

  Future<String?> getLocationName(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        return [
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(", ");
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }

    return null;
  }

  // generate unique tracking code for each complaint

  String generateTrackingCode() {
    final random = Random();
    String letters = String.fromCharCodes(
      List.generate(3, (_) => random.nextInt(26) + 65),
    );
    String numbers = random.nextInt(100000).toString().padLeft(5, '0');
    return letters + numbers;
  }

  // Haversine distance formula to calculate distance between two lat/lng points

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // in KM

    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);

    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Distance in KM
  }

  double _deg2rad(double deg) {
    return deg * (pi / 180);
  }

  // get nearest section office

  Future<void> _findNearestSection() async {
    if (_selectedLocation == null) {
      throw Exception("Please pin complaint location on the map.");
    }

    try {
      const double radius = 0.9;

      final lat = _selectedLocation!.latitude;
      final lng = _selectedLocation!.longitude;

      final sections = await supabase
          .from('sections')
          .select('''
          section_id,
          latitude,
          longitude,
          officers!inner(
            officer_id,
            is_active
          )
        ''')
          .eq('officers.is_active', true)
          .gte('latitude', lat - radius)
          .lte('latitude', lat + radius)
          .gte('longitude', lng - radius)
          .lte('longitude', lng + radius)
          .eq('is_active', true);

      if (sections.isEmpty) {
        throw Exception("No nearby section with active officer found.");
      }

      double minDistance = double.infinity;
      String? nearestSectionId;

      for (var section in sections) {
        final sectionLat = section['latitude'];
        final sectionLon = section['longitude'];

        if (sectionLat == null || sectionLon == null) continue;

        double distance = _calculateDistance(lat, lng, sectionLat, sectionLon);

        if (distance < minDistance) {
          minDistance = distance;
          nearestSectionId = section['section_id'];
        }
      }

      if (nearestSectionId == null) {
        throw Exception("Unable to assign section with officer.");
      }

      if (mounted) {
        setState(() {
          _selectedSectionId = nearestSectionId;
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- 1. FIXED: Set the pin immediately when location is found ---
  Future<LatLng?> _getCurrentLocation() async {
    if (_cachedLocation != null) return _cachedLocation;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    Position position = await Geolocator.getCurrentPosition();
    final location = LatLng(position.latitude, position.longitude);
    _cachedLocation = location;
    setState(() {
      _selectedLocation = location;
      _isMapLoading = false;
    });
    return location;
  }

  Future<void> _centerToCurrentLocation() async {
    setState(() {
      _isMapLoading = true;
    });

    final location = await _getCurrentLocation();

    if (!mounted) return;

    if (location != null) {
      setState(() {
        _selectedLocation = location;
        _isMapLoading = false;
      });

      _mapController.move(location, 15.0);
    } else {
      setState(() {
        _isMapLoading = false;
      });
    }
  }

  // ... (Keep _pickImage, uploadImage, submitComplaint same as before) ...
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null && mounted) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<String?> uploadImage(File image) async {
    final fileName =
        'public/complaints/${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      await supabase.storage.from('complaint-images').upload(fileName, image);
      final url = supabase.storage
          .from('complaint-images')
          .getPublicUrl(fileName);
      return url;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> submitComplaint({
    required String complaintTypeUI,
    required String category,
    required String description,

    File? image,
    String? consumerId,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) throw Exception("User not logged in");
    String trackingCode = generateTrackingCode();

    final complaintType = complaintTypeUI.toLowerCase();
    String? imageUrl;
    if (image != null) {
      imageUrl = await uploadImage(image);
    }

    if (complaintType == 'personal' && consumerId == null) {
      throw Exception("Personal complaint requires consumer ID");
    }

    if (complaintType == 'community' &&
        (latitude == null || longitude == null)) {
      throw Exception("Please select a location on the map.");
    }

    if (complaintType == 'community') {
      await _findNearestSection();
    }

    if (latitude != null && longitude != null) {
      locationName = await getLocationName(latitude, longitude);
    }

    if (complaintType == 'personal' && _selectedSectionId == null) {
      throw Exception("Please select consumer connection");
    }

    try {
      final response = await supabase
          .from('complaints')
          .insert({
            'tracking_code': trackingCode,
            'user_id': userId,
            'section_id': _selectedSectionId,
            'complaint_type': complaintType,
            'category': category,
            'description': description,
            'consumer_id': complaintType == 'personal' ? consumerId : null,
            'latitude': latitude,
            'longitude': longitude,
            'location_name': locationName,
            'image_url': imageUrl,
            'status': complaintType == 'community'
                ? 'awaiting'
                : 'pending',
          })
          .select()
          .single();

      // send notification to section officer

      await supabase.from('notifications').insert({
        'complaint_id': response['complaint_id'],
        'recipient_type': 'officer',
        'section_id': _selectedSectionId,
        'title': 'New Complaint Registered',
        'message':
            'Complaint ${response['tracking_code']} has been registered.',
      });

      _showSuccessDialog(response['tracking_code']);
    } on PostgrestException catch (e) {
      // UNIQUE constraint violation
      if (e.code == '23505') {
        // Generate new code and retry once
        trackingCode = generateTrackingCode();

        final response = await supabase
            .from('complaints')
            .insert({
              'tracking_code': trackingCode,
              'user_id': userId,
              'section_id': _selectedSectionId,
              'complaint_type': complaintType,
              'category': category,
              'description': description,
              'consumer_id': complaintType == 'personal' ? consumerId : null,
              'latitude': latitude,
              'longitude': longitude,
              'location_name': locationName,
              'image_url': imageUrl,
              'status': complaintType == 'community'
                  ? 'awaiting'
                  : 'pending',
            })
            .select()
            .single();

        // send notification to section officer

        await supabase.from('notifications').insert({
          'complaint_id': response['complaint_id'],
          'recipient_type': 'officer',
          'section_id': _selectedSectionId,
          'title': 'New Complaint Registered',
          'message':
              'Complaint ${response['tracking_code']} has been registered.',
        });

        _showSuccessDialog(response['tracking_code']);
      } else {
        rethrow;
      }
    } catch (e) {
      debugPrint('Error submitting complaint: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit complaint: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String trackingCode) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE6EEF6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF0D3B66),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Complaint Registered",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D3B66),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Your Tracking Code",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trackingCode,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Color(0xFF0D3B66),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D3B66),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<UserDataProvider>();
    final consumers = userData.consumerConnections;
    final isLoadingConsumers = userData.isLoading;
    const navyBlue = Color(0xFF0D3B66);
    const backgroundGrey = Color(0xFFF5F5F5);
    const uploadButtonColor = Color(0xFFFFF9F0);

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        backgroundColor: navyBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.white,
          ),
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
            // ======================
            //IMPROVEMENT 1: Added Category Dropdown (Personal / Community)
            // ======================
            _buildCustomDropdown(
              hint: "Select Category",
              value: category,
              items: const [
                {"value": "Personal", "label": "Personal"},
                {"value": "Community", "label": "Community"},
              ],
              onChanged: (v) async {
                if (mounted) {
                  setState(() {
                    category = v;
                    complaintType = null;
                    _selectedConsumerId = null;
                    _selectedSectionId = null;
                  });
                }

                final prefs = await SharedPreferences.getInstance();
                final userId = prefs.getString('user_id');

                if (v == "Personal") {
                  if (userId != null) {
                    await context.read<UserDataProvider>().loadConsumers(
                      userId,
                    );
                  }
                } else if (v == "Community") {
                  await _centerToCurrentLocation();
                }
              },
            ),

            const SizedBox(height: 15),
            //Proper dropdown map structure (prevents assertion error)
            _buildCustomDropdown(
              hint: "Select Complaint Type",
              value: complaintType,
              items: category == "Personal"
                  ? personalComplaintTypes
                  : category == "Community"
                  ? communityComplaintTypes
                  : [],
              onChanged: (v) {
                if (mounted) setState(() => complaintType = v);
              },
            ),

            const SizedBox(height: 15),

            // ======================
            //  IMPROVEMENT 5: Show Consumer Dropdown ONLY if Personal
            // ======================
            if (category == "Personal") ...[
              if (isLoadingConsumers)
                const Center(child: CircularProgressIndicator())
              else if (consumers.isEmpty)
                const Text("No consumer connections found.")
              else
                _buildCustomDropdown(
                  hint: "Select Consumer Number",
                  value: _selectedConsumerId,
                  items: consumers.map<Map<String, String>>((e) {
                    return {
                      "value": e['consumer_id'].toString(),
                      "label": e['consumer_number'].toString(),
                    };
                  }).toList(),
                  onChanged: (val) {
                    final selected = consumers.firstWhere(
                      (e) => e['consumer_id'].toString() == val,
                    );

                    setState(() {
                      _selectedConsumerId = selected['consumer_id'].toString();
                      _selectedSectionId = selected['section_id'].toString();
                    });
                  },
                ),
            ],

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
                      _selectedImage != null
                          ? Icons.check_circle
                          : Icons.camera_alt_outlined,
                      color: _selectedImage != null
                          ? Colors.green
                          : Colors.grey[700],
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _selectedImage != null
                          ? "Image Captured"
                          : "Upload Image",
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
                  child: Image.file(
                    _selectedImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // map visible only when the user click the community
            if (category == "Community") ...[
              const SizedBox(height: 20),

              if (_isMapLoading || _selectedLocation == null)
                Container(
                  height: 250,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.white,
                  ),
                  child: const CircularProgressIndicator(),
                )
              else
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
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF0D3B66),
                                ),
                              )
                            : FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _selectedLocation!,
                                  initialZoom: 15.0,
                                  onTap: (_, latlng) {
                                    if (mounted) {
                                      setState(() {
                                        _selectedLocation = latlng;
                                      });
                                    }
                                  },
                                ),
                                children: [
                                  // TileLayer(
                                  //   urlTemplate:
                                  //       "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png",
                                  //   subdomains: const ['a', 'b', 'c', 'd'],
                                  //   userAgentPackageName: "com.complaintapp.flutter_map",
                                  //   maxZoom: 20,
                                  // ),
                                  TileLayer(
                                    urlTemplate:
                                        "https://api.maptiler.com/maps/streets-v4/{z}/{x}/{y}.png?key=6PG81cDlAFK36afvUVNL",
                                    tileDimension: 512,
                                    zoomOffset: -1,
                                    maxZoom: 50,
                                    userAgentPackageName:
                                        "com.complaintapp.flutter_map",
                                    retinaMode: true,
                                  ),

                                  // 2. FIXED: Added the Blue Dot Layer here!
                                  CurrentLocationLayer(
                                    style: const LocationMarkerStyle(
                                      marker: DefaultLocationMarker(
                                        color: Color(0xFF2196F3),
                                        child: Icon(
                                          Icons.navigation,
                                          color: Colors.white,
                                          size: 14,
                                        ),
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
                            onTap: _centerToCurrentLocation,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 5,
                                    color: Colors.black12,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.my_location,
                                size: 20,
                                color: Color(0xFF0D3B66),
                              ),
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
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                        if (complaintType == null ||
                            category == null ||
                            detailsController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please fill all required fields"),
                            ),
                          );
                          return;
                        }
                        if (category == "Personal" &&
                            _selectedConsumerId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select consumer number"),
                            ),
                          );
                          return;
                        }

                        if (mounted) setState(() => submitting = true);

                        try {
                          await submitComplaint(
                            complaintTypeUI: category!,
                            category: complaintType!,
                            description: detailsController.text,
                            image: _selectedImage,
                            consumerId: category == "Personal"
                                ? _selectedConsumerId
                                : null,
                            latitude: _selectedLocation?.latitude,
                            longitude: _selectedLocation?.longitude,
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        } finally {
                          if (mounted) {
                            setState(() => submitting = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D3B66),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "Submit Complaint",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
    required List<Map<String, String>> items,
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
          hint: Text(
            hint,
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item['value'],
              child: Text(
                item['label']!,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),

          onChanged: onChanged,
        ),
      ),
    );
  }
}
