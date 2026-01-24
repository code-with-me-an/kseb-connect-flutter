import 'dart:io'; // Needed for File
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Needed for SVG pin
import 'package:image_picker/image_picker.dart'; // Needed for Camera

class ReportComplaintScreen extends StatefulWidget {
  const ReportComplaintScreen({super.key});

  @override
  State<ReportComplaintScreen> createState() => _ReportComplaintScreenState();
}

class _ReportComplaintScreenState extends State<ReportComplaintScreen> {
  String? complaintType;
  String? category;
  final TextEditingController detailsController = TextEditingController();

  // 1. Variable to store the selected image
  File? _selectedImage;

  // 2. Function to open camera and pick image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      // Use ImageSource.camera for Camera, ImageSource.gallery for Gallery
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to capture image: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define specific colors from the design
    const navyBlue = Color(0xFF0D3B66);
    const backgroundGrey = Color(0xFFF5F5F5);
    const uploadButtonColor = Color(0xFFFFF9F0); // Light cream color

    return Scaffold(
      backgroundColor: backgroundGrey,

      // --- AppBar ---
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

      // --- Body ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Complaint Type Dropdown
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
              ],
              onChanged: (v) => setState(() => complaintType = v),
            ),

            const SizedBox(height: 15),

            // 2. Category Dropdown
            _buildCustomDropdown(
              hint: "Category",
              value: category,
              items: ["Personal", "Community"],
              onChanged: (v) => setState(() => category = v),
            ),

            const SizedBox(height: 15),

            // 3. Details Text Field
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

            // 4. Upload Image Button (Cream colored)
            GestureDetector(
              onTap: _pickImage, // Calls the camera function
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
                      // Change icon if image is selected
                      _selectedImage != null
                          ? Icons.check_circle
                          : Icons.camera_alt_outlined,
                      color:
                          _selectedImage != null
                              ? Colors.green
                              : Colors.grey[700],
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      // Change text if image is selected
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

            // Optional: Preview the image below the button if taken
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

            // 5. Map Placeholder
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                image: const DecorationImage(
                  image: NetworkImage(
                    "https://mt1.google.com/vt/lyrs=m&x=0&y=0&z=1",
                  ),
                  fit: BoxFit.cover,
                  opacity: 0.4,
                ),
              ),
              child: Stack(
                children: [
                  // Center SVG Pin
                  Center(
                    child: SvgPicture.asset(
                      'assets/marker.svg',
                      width: 40,
                      height: 40,
                      // Optional: Color filter if your SVG is black and you want it red
                      // colorFilter: ColorFilter.mode(Colors.red[700]!, BlendMode.srcIn),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 6. Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: navyBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Complaint Submitted")),
                  );
                },
                child: const Text(
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

  // Helper widget for the custom styled dropdowns
  Widget _buildCustomDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      width: double.infinity,
      height: 55, // Fixed height
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
          items:
              items.map((e) {
                // Formatter: Turns "power_outage" into "Power outage"
                String displayText = e.replaceAll('_', ' ');
                if (displayText.isNotEmpty) {
                  displayText =
                      displayText[0].toUpperCase() + displayText.substring(1);
                }

                return DropdownMenuItem(
                  value: e,
                  child: Text(
                    displayText,
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