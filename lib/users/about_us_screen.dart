import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    

    return Container(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "About KSEB Connect",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 15),

            Text(
              "KSEB Connect is a complaint management application designed to simplify the process of reporting electricity related issues to Kerala State Electricity Board.",
              style: TextStyle(fontSize: 15),
            ),

            SizedBox(height: 15),

            Text(
              "Users can quickly report power failures, voltage problems, and other electrical issues directly through their mobile devices.",
              style: TextStyle(fontSize: 15),
            ),

            SizedBox(height: 20),

            Text(
              "Key Features",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text("• Easy complaint reporting"),
            Text("• Track complaint status"),
            Text("• View nearby complaints"),
            Text("• User friendly interface"),

            SizedBox(height: 20),

            Text(
              "This system improves communication between electricity consumers and KSEB authorities, making complaint handling faster and more transparent.",
              style: TextStyle(fontSize: 15),
            ),

            SizedBox(height: 30),

            
          ],
        ),
      ),
    );
  }
}