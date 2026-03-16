import 'package:flutter/material.dart';
import '../main.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  String userName = '';
  String phoneNumber = '';
  String joinDate = '';
  String sectionName = '';
  String consumerNumber = '';

  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchProfileDetails();
  }

  Future<void> fetchProfileDetails() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      final data = await supabase
          .from('users')
          .select('''
            name,
            mobile_number,
            created_at,
            consumer_connections(
              consumer_number,
              sections(
                name
              )
            )
          ''')
          .eq('id', userId)
          .single();

      final createdAt = DateTime.parse(data['created_at']);

      String section = '';
      String consumerNo = '';

      if (data['consumer_connections'] != null &&
          data['consumer_connections'].isNotEmpty) {
        final connection = data['consumer_connections'][0];

        section = connection['sections']['name'] ?? '';
        consumerNo = connection['consumer_number'] ?? '';
      }

      if (mounted) {
        setState(() {
          userName = data['name'];
          phoneNumber = data['mobile_number'];
          joinDate = "${_monthName(createdAt.month)} ${createdAt.year}";
          sectionName = section;
          consumerNumber = consumerNo;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Profile details error: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    const navyBlue = Color(0xFF0D3B66);
    const backgroundGrey = Color(0xFFF5F5F5);

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
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D3B66)),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 55, color: Colors.white),
                  ),

                  const SizedBox(height: 30),

                  _buildProfileTile("Name", userName),

                  _buildProfileTile("Member Since", joinDate),

                  _buildProfileTile("Mobile Number", phoneNumber),

                  _buildProfileTile("Consumer Number", consumerNumber),

                  _buildProfileTile("Section", sectionName),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),

          Text(value, style: const TextStyle(fontSize: 15, color: Colors.grey)),
        ],
      ),
    );
  }
}
