import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

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
        title: const Text(
          "About Us",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "About KSEB Connect",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // Main description card
            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),

              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "KSEB Connect is a complaint management application designed to simplify the process of reporting electricity related issues to Kerala State Electricity Board.",
                    style: TextStyle(fontSize: 15),
                  ),

                  SizedBox(height: 12),

                  Text(
                    "Users can quickly report power failures, voltage problems, and other electrical issues directly through their mobile devices.",
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Key Features",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Features Card
            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),

              child: const Column(
                children: [

                  FeatureTile(
                    icon: Icons.report_problem_outlined,
                    text: "Easy complaint reporting",
                  ),

                  SizedBox(height: 10),

                  FeatureTile(
                    icon: Icons.track_changes,
                    text: "Track complaint status",
                  ),

                  SizedBox(height: 10),

                  FeatureTile(
                    icon: Icons.location_on_outlined,
                    text: "View nearby complaints",
                  ),

                  SizedBox(height: 10),

                  FeatureTile(
                    icon: Icons.phone_android,
                    text: "User friendly interface",
                  ),

                ],
              ),
            ),

            const SizedBox(height: 25),

            // Final description card
            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),

              child: const Text(
                "This system improves communication between electricity consumers and KSEB authorities, making complaint handling faster and more transparent.",
                style: TextStyle(fontSize: 15),
              ),
            ),

            const SizedBox(height: 30),

          ],
        ),
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {

  final IconData icon;
  final String text;

  const FeatureTile({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [

        Icon(
          icon,
          size: 22,
          color: Color(0xFF0D3B66),
        ),

        SizedBox(width: 10),

        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 15),
          ),
        ),

      ],
    );
  }
}