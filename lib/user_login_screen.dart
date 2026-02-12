import 'package:flutter/gestures.dart'; 
import 'package:flutter/material.dart';
import 'package:kseb_connect/admin_login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  bool keepSignedIn = false;
  bool loading = false;

  Future<void> sendOtp() async {
    final name = nameController.text.trim();
    final rawPhone = phoneController.text.trim(); // User types '9876543210'

    // Validation: Check if name is empty or phone is not 10 digits
    if (name.isEmpty || rawPhone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter name and a valid 10-digit number")),
      );
      return;
    }

    setState(() => loading = true);

    // CHANGED: We add +91 here automatically
    final fullPhoneNumber = "+91$rawPhone"; 

    try {
      await supabase.auth.signInWithOtp(phone: fullPhoneNumber);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(name: name, phone: fullPhoneNumber),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("OTP Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
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
                // --- 1. LOGO ---
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

                // --- 2. HEADER TEXT ---
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Welcome",
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
                        "Enter your name and number to access\nyour account",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // --- 3. NAME FIELD ---
                const Text(
                  "Name",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: "your name",
                    filled: true,
                    fillColor: const Color(0xFFE8E8E8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- 4. NUMBER FIELD (UPDATED) ---
                const Text(
                  "Number",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10, // Limits input to 10 characters
                  decoration: InputDecoration(
                    // CHANGED: This puts "+91 " visually inside the box
                    prefixText: "+91 ", 
                    prefixStyle: const TextStyle(
                      color: Colors.black, 
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                    ),
                    hintText: "9876543210",
                    counterText: "", // Hides the generic "0/10" counter below
                    filled: true,
                    fillColor: const Color(0xFFE8E8E8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // --- 5. CHECKBOX ---
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: keepSignedIn,
                        activeColor: primaryColor,
                        onChanged: (val) async {
                          final newVal = val ?? false;
                          setState(() => keepSignedIn = newVal);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('keepSignedIn', newVal);
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

                // --- 6. CONTINUE BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
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

                // --- 7. FOOTER ---
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Admin user? ",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      children: [
                        TextSpan(
                          text: "Sign up here",
                          style: const TextStyle(
                            color: linkColor,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminLoginScreen(),
      ),
    );
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