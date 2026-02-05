import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ozfkdvalelvgrygihqxr.supabase.co',
    anonKey: 'sb_publishable_XVYY0q-iNacej703cOQmqA_vZ9PBryl',
  );

  final prefs = await SharedPreferences.getInstance();
  final keepSignedIn = prefs.getBool('keepSignedIn') ?? false;

  final client = Supabase.instance.client;

  if (!keepSignedIn && client.auth.currentUser != null) {
    await client.auth.signOut();
  }

  runApp(MyApp(keepSignedIn: keepSignedIn));
}

// Global Supabase client reference (use throughout app)
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  final bool keepSignedIn;
  const MyApp({super.key, required this.keepSignedIn});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = keepSignedIn && supabase.auth.currentUser != null;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const MainLayout() : const LoginScreen(),
    );
  }
}
