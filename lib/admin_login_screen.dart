import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kseb_connect/admin/main_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final supabase = Supabase.instance.client;

  bool keepSignedIn = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _checkAdminLogin();
  }

  /// ✅ AUTO LOGIN CHECK
  Future<void> _checkAdminLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('admin_logged_in') ?? false;

    if (isLoggedIn) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminLayout()),
      );
    }
  }

  /// ADMIN LOGIN FUNCTION
  Future<void> _handleAdminLogin() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter username and password")),
      );
      return;
    }

    if (mounted) setState(() => loading = true);

    try {
      final response = await supabase
          .from('officers')
          .select()
          .eq('username', username)
          .eq('password', password)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setBool('admin_logged_in', true);
        await prefs.setString('admin_id', response['officer_id']);
        await prefs.setString('admin_username', response['username']);
        await prefs.setString('admin_section_id', response['section_id']);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminLayout(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid username or password"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Login failed';

      if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied - Please check RLS policies';
      } else if (e.toString().contains('connection')) {
        errorMessage = 'Network error - Please check your internet';
      } else {
        errorMessage = 'Error: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF333333);
    const primaryColor = Color(0xFF1B4B66);
    const linkColor = Color(0xFF63B931);

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// LOGO
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Image.asset(
                    'assets/logo.png',
                    height: 40,
                    width: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (c, o, s) => const Text(
                      "KSEB CONNECT",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                /// HEADER
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Welcome Admin",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'Monospace',
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Enter your username and password to\naccess your account",
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                /// USERNAME
                const Text(
                  "Username",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    hintText: "your username",
                    filled: true,
                    fillColor: const Color(0xFFE8E8E8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// PASSWORD
                const Text(
                  "Password",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "**********",
                    filled: true,
                    fillColor: const Color(0xFFE8E8E8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                /// KEEP SIGNED IN
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: keepSignedIn,
                        activeColor: primaryColor,
                        onChanged: (val) {
                          setState(() => keepSignedIn = val ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Keep me signed in",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// CONTINUE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : _handleAdminLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: loading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Continue",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const Spacer(flex: 3),

                /// BACK TO USER LOGIN
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "consumer ? ",
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 14),
                      children: [
                        TextSpan(
                          text: "Sign up here",
                          style: const TextStyle(
                            color: linkColor,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pop(context);
                            },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
