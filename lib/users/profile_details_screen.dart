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
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  // Profile Header Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 25, horizontal: 20),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: Column(
                      children: [

                        const CircleAvatar(
                          radius: 45,
                          backgroundColor: Color(0xFFE0E0E0),
                          child: Icon(
                            Icons.person,
                            size: 55,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "Member since $joinDate",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Profile Details
                  _buildProfileTile(Icons.phone, "Mobile Number", phoneNumber),

                  _buildProfileTile(Icons.confirmation_number,
                      "Consumer Number", consumerNumber),

                  _buildProfileTile(
                      Icons.location_city, "Section", sectionName),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [

          Icon(
            icon,
            color: const Color(0xFF0D3B66),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}