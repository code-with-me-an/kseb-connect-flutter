import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kseb_connect/screens/main_layout.dart';
import 'package:pinput/pinput.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'home_screen.dart'; // Ensure this file exists and contains HomeScreen class

class OtpScreen extends StatefulWidget {
  final String name;
  final String phone;

  const OtpScreen({super.key, required this.name, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final otpController = TextEditingController();

  // NEW: Variable to track input length for button color change
  String _otpCode = "";
  bool verifying = false;

  Timer? _timer;
  int _start = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _start = 30;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _timer?.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) return;

    setState(() => verifying = true);

    try {
      debugPrint("VERIFY OTP → ${widget.phone} : $otp");

      final response = await supabase.auth.verifyOTP(
        phone: widget.phone,
        token: otp,
        type: OtpType.sms,
      );

      final user = response.user;
      if (user == null) throw 'User is null';

      await supabase.from('users').upsert({
        'id': user.id,
        'name': widget.name,
        'mobile_number': widget.phone,
        'last_login_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainLayout()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => verifying = false);
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1B4B66);
    const linkColor = Color(0xFF63B931);
    const scaffoldColor = Color(0xFFEEEEEE);

    final defaultPinTheme = PinTheme(
      width: 45,
      height: 50,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 1,
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: primaryColor, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios, size: 20),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Change number",
                        style: TextStyle(
                          color: linkColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                const Text(
                  "Enter authentication code",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: "Enter the 6-digit code sent to ",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: widget.phone,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                Pinput(
                  controller: otpController,
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  keyboardType: TextInputType.number,
                  // NEW: Update state as user types to change button color
                  onChanged: (value) {
                    setState(() {
                      _otpCode = value;
                    });
                  },
                  onCompleted: (pin) => verifyOtp(),
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                ),

                const SizedBox(height: 30),

                if (!_canResend)
                  Text(
                    "Resend OTP in ${_start}s",
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    // Only enable if logic allows (not verifying AND length is 6)
                    onPressed: (verifying || _otpCode.length < 6)
                        ? null
                        : verifyOtp,
                    style: ElevatedButton.styleFrom(
                      // NEW: Dynamic Background Color (Blue if 6 digits, Grey otherwise)
                      backgroundColor: _otpCode.length == 6
                          ? primaryColor
                          : const Color(0xFFE0E0E0),
                      // NEW: Dynamic Text Color (White if 6 digits, Grey otherwise)
                      foregroundColor: _otpCode.length == 6
                          ? Colors.white
                          : const Color(0xFF888888),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: verifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              // Color is handled by foregroundColor property above
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                if (_canResend)
                  TextButton(
                    onPressed: () {
                      startTimer();
                      supabase.auth.signInWithOtp(phone: widget.phone);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("OTP Resent!")),
                      );
                    },
                    child: const Text(
                      "Resend code",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
