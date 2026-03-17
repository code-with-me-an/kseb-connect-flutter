import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

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
          "FAQ",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [

          Text(
            "Frequently Asked Questions",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 20),

          FAQCard(
            question: "How do I report a complaint?",
            answer:
                "Go to the home screen and select 'Report Complaint'. Fill in the required details and submit the complaint.",
          ),

          FAQCard(
            question: "How can I track my complaint status?",
            answer:
                "You can track your complaint status in the 'My Complaints' section where updates are shown for each complaint.",
          ),

          FAQCard(
            question: "What types of complaints can I report?",
            answer:
                "You can report issues such as power outages, voltage fluctuations, damaged electrical lines, and other electricity related problems.",
          ),

          FAQCard(
            question: "How long does it take to resolve a complaint?",
            answer:
                "Resolution time depends on the type of issue. KSEB authorities will review and resolve complaints as quickly as possible.",
          ),

          FAQCard(
            question: "Can I see complaints reported by others nearby?",
            answer:
                "Yes. The app allows users to view nearby complaints so you can stay informed about electricity issues in your area.",
          ),

          FAQCard(
            question: "What should I do if my complaint is not resolved?",
            answer:
                "You can follow up through the complaints section or contact KSEB support for further assistance.",
          ),

          FAQCard(
            question: "How can I delete my account?",
            answer:
                "You can delete your account from the Profile page by selecting 'Delete my account' and confirming the action.",
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class FAQCard extends StatelessWidget {
  final String question;
  final String answer;

  const FAQCard({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),

      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),

        iconColor: const Color(0xFF0D3B66),
        collapsedIconColor: Colors.grey,

        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),

        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          )

        ],
      ),
    );
  }
}