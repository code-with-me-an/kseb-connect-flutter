import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kseb_connect/providers/admin_complaint_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'main_layout.dart';

class AdminSectionMapScreen extends StatefulWidget {
  const AdminSectionMapScreen({super.key});

  @override
  State<AdminSectionMapScreen> createState() => _AdminSectionMapScreenState();
}

class _AdminSectionMapScreenState extends State<AdminSectionMapScreen> {
  final MapController _mapController = MapController();
  String? _selectedComplaintId;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    context.read<AdminComplaintProvider>().loadComplaints();
  }

  double getMarkerSize(double zoom) {
    if (zoom < 9) return 15;
    if (zoom < 11) return 20;
    if (zoom < 13) return 25;
    if (zoom < 15) return 35;
    return 42;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminComplaintProvider>();
    double zoom = _mapReady ? _mapController.camera.zoom : 13.0;
    double markerSize = getMarkerSize(zoom);
    return Scaffold(
      body: provider.loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF219869)))
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      provider.sectionLat ?? 11.2588,
                      provider.sectionLng ?? 75.7804,
                    ),
                    initialZoom: 13,

                    onMapReady: () {
                      _mapReady = true;
                    },

                    onPositionChanged: (position, hasGesture) {
                      setState(() {});
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
                      userAgentPackageName: "com.complaintapp.flutter_map",
                      retinaMode: true,
                    ),
                    MarkerLayer(
                      markers: provider.allComplaints
                          .asMap()
                          .entries
                          .map((entry) {
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
                              width: markerSize,
                              height: markerSize,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedComplaintId =
                                        _selectedComplaintId ==
                                            complaint['complaint_id']
                                        ? null
                                        : complaint['complaint_id'];
                                  });
                                },
                                child: type == 'community'
                                    ? Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          SvgPicture.asset(
                                            'assets/communityicon.svg',
                                            width: markerSize,
                                            height: markerSize,
                                          ),
                                          Positioned(
                                            top: markerSize * 0.2,
                                            child: Text(
                                              "${complaint['upvote_count'] ?? 0}",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: markerSize * 0.35,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : SvgPicture.asset(
                                        "assets/personalicon.svg",
                                        width: markerSize * 0.6,
                                        height: markerSize * 0.6,
                                      ),
                              ),
                            );
                          })
                          .whereType<Marker>()
                          .toList(),
                    ),
                  ],
                ),

                Positioned(
                  top: 50,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.white,
                    child: Text("Complaints: ${provider.allComplaints.length}"),
                  ),
                ),
                if (_selectedComplaintId != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Builder(
                      builder: (_) {
                        final selectedComplaint = provider.getComplaintById(
                          _selectedComplaintId!,
                        );

                        if (selectedComplaint == null) {
                          return const SizedBox(); // safe fallback
                        }

                        return _buildComplaintPopup(selectedComplaint);
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildComplaintPopup(Map<String, dynamic> complaint) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Tracking: ${complaint['tracking_code'] ?? "N/A"}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedComplaintId = null),
                child: const Icon(Icons.close, size: 18),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Type + Category (inline)
          Text(
            "${complaint['complaint_type']} • ${complaint['category']}",
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),

          const SizedBox(height: 8),

          // Description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT SIDE (text content)
              Expanded(
                child: Text(
                  complaint['description'] ?? "",
                  style: const TextStyle(fontSize: 14),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // RIGHT SIDE (image)
              if (complaint['image_url'] != null &&
                  complaint['image_url'].toString().isNotEmpty) ...[
                const SizedBox(width: 10),

                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      complaint['image_url'],
                      height: 75,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Extra Details Row
          Row(
            children: [
              // Upvotes (only for community)
              if (complaint['complaint_type'] == 'community')
                Row(
                  children: [
                    Icon(
                      Icons.thumb_up_alt,
                      size: 14,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${complaint['upvote_count'] ?? 0} Upvotes",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),

              const SizedBox(width: 12),

              // Status
              if (complaint['status'] != null)
                Text(
                  complaint['status'],
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(complaint['status']),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminLayout(
                      initialIndex: 1,
                      highlightComplaintId: complaint['complaint_id'],
                      highlightComplaintType: complaint['complaint_type'],
                    ),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "View / Edit",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
