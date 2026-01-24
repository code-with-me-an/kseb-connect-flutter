import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  // Required when using async in main()
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ozfkdvalelvgrygihqxr.supabase.co',
    anonKey: 'sb_publishable_XVYY0q-iNacej703cOQmqA_vZ9PBryl',
  );

  runApp(const MyApp());
}

// Global Supabase client reference
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
