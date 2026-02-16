import 'dart:io';
import 'dart:math';
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
    final supabase = Supabase.instance.client;

  List<dynamic> _consumerConnections = [];
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

  String generateTrackingCode() {
    final random = Random();

    // Generate 3 uppercase letters
    String letters = String.fromCharCodes(
      List.generate(3, (_) => random.nextInt(26) + 65),
    );

    // Generate 5 digit number (00000 - 99999)
    String numbers = random.nextInt(100000).toString().padLeft(5, '0');

    return letters + numbers;
  }

  Future<String> generateUniqueTrackingCode() async {
    final supabase = Supabase.instance.client;

    int attempts = 0;
    while (attempts < 10) {
      try {
        String code = generateTrackingCode();

        final existing = await supabase
            .from('complaints')
            .select('tracking_code')
            .eq('tracking_code', code)
            .maybeSingle();

        if (existing == null) {
          return code;
        }

        attempts++;
      } catch (e) {
        debugPrint('Error generating tracking code: $e');
        attempts++;

        if (attempts >= 10) {
          throw Exception('Failed to generate tracking code after 10 attempts');
        }
      }
    }

    throw Exception('Could not generate unique tracking code');
  }

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
      if (mounted) setState(() => _isMapLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isMapLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isMapLoading = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition();

    if (mounted) {
      setState(() {
        _isMapLoading = false;
        //  This puts the Red Pin on the Blue Dot immediately
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
    }

    _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
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
    final supabase = Supabase.instance.client;
    final fileName =
        'public/complaints/${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      await supabase.storage.from('complaint-images').upload(fileName, image);
      final url = supabase.storage.from('complaint-images').getPublicUrl(fileName);
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
  }) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    String trackingCode = await generateUniqueTrackingCode();

    if (user == null) throw Exception("User not logged in");

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

    // ✅ ADD THIS: Require section for all complaints
    if (_selectedSectionId == null || _selectedSectionId!.isEmpty) {
      throw Exception("Please select a section for the complaint");
    }

    try {
      final response = await supabase
          .from('complaints')
          .insert({
            'tracking_code': trackingCode,
            'user_id': user.id,
            'section_id': _selectedSectionId,
            'complaint_type': complaintType,
            'category': category,
            'description': description,
            'consumer_id': complaintType == 'personal' ? consumerId : null,
            'latitude': latitude,
            'longitude': longitude,
            'image_url': imageUrl,
          })
          .select()
          .single();

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
                // Top Icon
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

                // Title
                const Text(
                  "Complaint Registered",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D3B66),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 15),

                const Text(
                  "Your Tracking Code",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 8),

                // Tracking Code Highlight
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
                    response['tracking_code'],
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Color(0xFF0D3B66),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Button
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D3B66),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
Future<void> fetchConsumerConnections() async {
  final user = supabase.auth.currentUser;

  if (user == null) return;

  try {
    final response = await supabase
        .from('consumer_connections')
        .select()
        .eq('user_id', user.id);

    if (mounted) {
      setState(() {
        _consumerConnections = response;
      });
    }
  } catch (e) {
    debugPrint('Error fetching consumer connections: $e');
    if (mounted) {
      setState(() {
        _consumerConnections = [];
      });
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading connections: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  // ✅ NEW METHOD: Get user's default section for community complaints
  Future<void> _fetchUserDefaultSection() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final connections = await supabase
          .from('consumer_connections')
          .select('section_id')
          .eq('user_id', user.id)
          .limit(1);

      if (connections.isNotEmpty) {
        if (mounted) {
          setState(() {
            _selectedSectionId = connections[0]['section_id'].toString();
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No section found. Please add a consumer connection.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching default section: $e');
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
// 🔥 IMPROVEMENT 1: Added Category Dropdown (Personal / Community)
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

        // ✅ CHANGED: Reset section only for Personal
        if (v == "Personal") {
          _selectedSectionId = null;
        }
        _selectedConsumerId = null;
      });
    }

    // ✅ CHANGED: Fetch connections for Personal, section for Community
    if (v == "Personal") {
      await fetchConsumerConnections();
    } else if (v == "Community") {
      await _fetchUserDefaultSection();
    }
  },
),

const SizedBox(height: 15),
// 🔥 IMPROVEMENT 4: Proper dropdown map structure (prevents assertion error)
_buildCustomDropdown(
  hint: "Select Complaint Type",
  value: complaintType,
  items: [
    'power_outage',
    'voltage_issue',
    'billing_issue',
    'meter_issue',
    'line_issue',
    'transformer_issue',
    'street_light',
    'safety_hazard',
    'etc',
  ].map((e) => {
        "value": e,
        "label": e.replaceAll('_', ' ').toUpperCase(),
      }).toList(),
  onChanged: (v) {
    if (mounted) setState(() => complaintType = v);
  },
),

            const SizedBox(height: 15),
// ======================
// 🔥 IMPROVEMENT 5: Show Consumer Dropdown ONLY if Personal
// ======================

if (category == "Personal" && _consumerConnections.isNotEmpty)
  _buildCustomDropdown(
    hint: "Select Consumer Number",
    value: _selectedConsumerId,
    items: _consumerConnections.map<Map<String, String>>((e) {
      return {
        "value": e['consumer_id'].toString(),
        "label": e['consumer_number'].toString(),
      };
    }).toList(),
    onChanged: (val) {
      final selected = _consumerConnections
          .firstWhere((e) => e['consumer_id'].toString() == val);

      if (mounted) {
        setState(() {
          _selectedConsumerId = selected['consumer_id'].toString();
          _selectedSectionId = selected['section_id'].toString();
        });
      }
    },
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
                                if (mounted) {
                                  setState(() {
                                    _selectedLocation = latlng;
                                  });
                                }
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                                userAgentPackageName: 'com.complaintapp.report',
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
                        onTap: _getCurrentLocation,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(blurRadius: 5, color: Colors.black12),
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
                      if (category == "Personal" && _selectedConsumerId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Please select consumer number")),
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
