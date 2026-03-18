import 'package:flutter/material.dart';
import 'package:kseb_connect/providers/admin_complaint_provider.dart';
import 'package:kseb_connect/providers/admin_dashboard_provider.dart';
import 'package:kseb_connect/providers/complaint_provider.dart';
import 'package:kseb_connect/providers/home_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'providers/section_provider.dart';
import 'user_login_screen.dart';
import 'users/main_layout.dart';
import 'admin/main_layout.dart';

import 'providers/user_data_provider.dart';
import 'services/local_notification_service.dart';

import 'users/notification_detail_screen.dart';
import 'admin/admin_notification_screen.dart';

import 'package:kseb_connect/services/user_realtime_service.dart';
import 'package:kseb_connect/services/admin_realtime_service.dart';

/// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Global Supabase client
final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ozfkdvalelvgrygihqxr.supabase.co',
    anonKey: 'sb_publishable_XVYY0q-iNacej703cOQmqA_vZ9PBryl',
  );

  /// Initialize local notifications
  await LocalNotificationService.initialize((payload) async {
    if (payload == null) return;

    final prefs = await SharedPreferences.getInstance();
    final isAdmin = prefs.getBool('admin_logged_in') ?? false;

    /// Navigate based on session type
    if (isAdmin) {
      navigatorKey.currentState?.pushNamed(
        "/adminNotification",
        arguments: payload,
      );
    } else {
      navigatorKey.currentState?.pushNamed("/notification", arguments: payload);
    }
  });

  /// Request notification permission
  await LocalNotificationService.requestPermission();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(
          create: (_) => ComplaintProvider()..loadComplaints(),
        ),
        ChangeNotifierProvider(
          create: (_) => SectionProvider()..loadSections(),
        ),
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
        ChangeNotifierProvider(create: (_) => AdminComplaintProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

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

  /// Decide whether to open
  /// Admin UI, User UI, or Login
  Future<void> _decideStartScreen() async {
    final prefs = await SharedPreferences.getInstance();

    // ADMIN SESSION
    final isAdminLoggedIn = prefs.getBool('admin_logged_in') ?? false;

    // USER SESSION
    final keepSignedIn = prefs.getBool('keepSignedIn') ?? false;
    final userLoggedIn = keepSignedIn && supabase.auth.currentUser != null;

    // IMPORTANT: CLEAR OLD CHANNELS FIRST
    await supabase.removeAllChannels();

    if (isAdminLoggedIn) {
      AdminRealtimeService.start(); // ADMIN ONLY
      _startScreen = const AdminLayout();
    } else if (userLoggedIn) {
      final userId = supabase.auth.currentUser!.id;
      _startScreen = const MainLayout();
    } else {
      _startScreen = const LoginScreen();
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,

      /// App routes
      routes: {
        /// User notification screen
        "/notification": (context) => const NotificationDetailScreen(),

        /// Admin notification screen
        "/adminNotification": (context) => const AdminNotificationScreen(),
      },

      /// Start screen
      home:
          _startScreen ??
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
