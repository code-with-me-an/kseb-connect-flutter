import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackScreen extends StatefulWidget {
  final String userName;
  final String phoneNumber;

  const FeedbackScreen({
    super.key,
    required this.userName,
    required this.phoneNumber,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _controller = TextEditingController();

  Future<void> sendFeedback(String feedback) async {
    String subject = Uri.encodeComponent("KSEB Connect App Feedback");

    String body = Uri.encodeComponent('''
User: ${widget.userName}
Phone: ${widget.phoneNumber}

Feedback:
$feedback
''');

    final Uri emailUri = Uri.parse(
      "mailto:code.with.me.an@gmail.com?subject=$subject&body=$body",
    );

    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);

      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unable to open email app")));
    }
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

        title: const Text(
          "Send Feedback",
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
              "We value your feedback",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),

              child: const Text(
                "If you have any suggestions, improvements, or issues with the app, please let us know. Your feedback helps us improve KSEB Connect.",
                style: TextStyle(fontSize: 15),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Your Feedback",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),

              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    maxLines: 5,

                    decoration: const InputDecoration(
                      hintText: "Write your feedback here...",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),

                      onPressed: () {
                        if (_controller.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please enter feedback"),
                            ),
                          );
                          return;
                        }

                        sendFeedback(_controller.text);
                      },

                      child: const Text(
                        "Send Feedback",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
