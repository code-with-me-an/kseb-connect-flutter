import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {

  bool notificationsEnabled = true;

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
          "Notification Settings",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Notifications",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Control whether you receive notifications from KSEB Connect regarding complaint updates and important alerts.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
              ),
            ),

            const SizedBox(height: 25),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),

              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),

                title: const Text(
                  "Enable Notifications",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),

                subtitle: const Text(
                  "Receive updates about your complaints",
                ),

                value: notificationsEnabled,

                activeThumbColor: const Color(0xFF0D3B66),

                onChanged: (value) {
                  setState(() {
                    notificationsEnabled = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            Text(
              notificationsEnabled
                  ? "You will receive notifications from the app."
                  : "Notifications are currently turned off.",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            )
          ],
        ),
      ),
    );
  }
}