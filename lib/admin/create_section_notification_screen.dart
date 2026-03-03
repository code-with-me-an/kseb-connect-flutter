import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateSectionNotificationScreen extends StatefulWidget {
  const CreateSectionNotificationScreen({super.key});

  @override
  State<CreateSectionNotificationScreen> createState() =>
      _CreateSectionNotificationScreenState();
}

class _CreateSectionNotificationScreenState
    extends State<CreateSectionNotificationScreen> {
  final supabase = Supabase.instance.client;

  final titleController = TextEditingController();
  final messageController = TextEditingController();

  bool loading = false;

  Future<void> sendNotification() async {
  final prefs = await SharedPreferences.getInstance();
  final adminId = prefs.getString('admin_id');
  final sectionId = prefs.getString('admin_section_id');

  print("Admin ID: $adminId");
  print("Section ID: $sectionId");

  if (adminId == null || sectionId == null) {
    print("Admin session missing ❌");
    return;
  }

  if (titleController.text.trim().isEmpty ||
      messageController.text.trim().isEmpty) {
    print("Title or message empty");
    return;
  }

  try {
    print("Inserting section notification...");

    await supabase.from('notifications').insert({
      'recipient_type': 'section',
      'section_id': sectionId,
      'title': titleController.text.trim(),
      'message': messageController.text.trim(),
      'is_read': false,
    });

    print("Notification inserted ✅");

    if (mounted) Navigator.pop(context);

  } catch (e) {
    print("Insert Error: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Announcement")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Message"),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: loading ? null : sendNotification,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Send"),
            )
          ],
        ),
      ),
    );
  }
}