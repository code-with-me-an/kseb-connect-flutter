import 'package:flutter/material.dart';
import 'package:kseb_connect/providers/complaint_provider.dart';
import 'package:kseb_connect/providers/home_provider.dart';
import 'package:kseb_connect/services/realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_login_screen.dart';
import 'users/main_layout.dart';
import 'admin/main_layout.dart';
import 'package:provider/provider.dart';
import 'providers/user_data_provider.dart';
import 'services/local_notification_service.dart';
import 'users/notification_detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ozfkdvalelvgrygihqxr.supabase.co',
    anonKey: 'sb_publishable_XVYY0q-iNacej703cOQmqA_vZ9PBryl',
  );
  RealtimeService.start();

  await LocalNotificationService.initialize((payload) {
    if (payload == null) return;

    navigatorKey.currentState?.pushNamed("/notification", arguments: payload);
  });

  await LocalNotificationService.requestPermission();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(
          create: (_) => ComplaintProvider()..loadComplaints(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// Global Supabase client
final supabase = Supabase.instance.client;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget? _startScreen;

  @override
  void initState() {
    super.initState();
    _decideStartScreen();
  }

  Future<void> _decideStartScreen() async {
    final prefs = await SharedPreferences.getInstance();

    /// 🔹 ADMIN SESSION CHECK
    final isAdminLoggedIn = prefs.getBool('admin_logged_in') ?? false;

    /// 🔹 USER SESSION CHECK
    final keepSignedIn = prefs.getBool('keepSignedIn') ?? false;
    final userLoggedIn = keepSignedIn && supabase.auth.currentUser != null;

    if (isAdminLoggedIn) {
      _startScreen = const AdminLayout();
    } else if (userLoggedIn) {
      _startScreen = const MainLayout();
    } else {
      _startScreen = const LoginScreen();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false,
  navigatorKey: navigatorKey,
  routes: {
    "/notification": (context) => const NotificationDetailScreen(),
  },
  home: _startScreen ??
      const Scaffold(body: Center(child: CircularProgressIndicator())),
);
  }
}
