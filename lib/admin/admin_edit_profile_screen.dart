import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminEditProfileScreen extends StatefulWidget {
  const AdminEditProfileScreen({super.key});

  @override
  State<AdminEditProfileScreen> createState() =>
      _AdminEditProfileScreenState();
}

class _AdminEditProfileScreenState extends State<AdminEditProfileScreen> {
  final supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final currentPasswordController = TextEditingController();

  bool loading = true;
  bool saving = false;

  bool showCurrentPassword = false;
  bool showNewPassword = false;

  String? adminId;
  String? originalUsername;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    adminId = prefs.getString('admin_id');

    if (adminId == null) return;

    final data = await supabase
        .from('officers')
        .select()
        .eq('officer_id', adminId!)
        .single();

    nameController.text = data['name'] ?? '';
    usernameController.text = data['username'] ?? '';
    mobileController.text = data['mobile'] ?? '';
    emailController.text = data['email'] ?? '';

    originalUsername = data['username'];

    setState(() => loading = false);
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      final verifyResponse = await supabase.rpc(
        'verify_officer_login',
        params: {
          'input_username': originalUsername,
          'input_password': currentPasswordController.text.trim(),
        },
      ).maybeSingle();

      if (verifyResponse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Incorrect current password")),
        );
        setState(() => saving = false);
        return;
      }

      await supabase.rpc('update_officer_profile', params: {
        'officer_id_input': adminId,
        'name_input': nameController.text.trim(),
        'username_input': usernameController.text.trim(),
        'email_input': emailController.text.trim(),
        'mobile_input': mobileController.text.trim(),
        'new_password': newPasswordController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => saving = false);
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    newPasswordController.dispose();
    currentPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF219869);
    const backgroundColor = Color(0xFFF4F6F8);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: themeColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    /// ACCOUNT INFO
                    _buildSectionCard(
                      title: "Account Information",
                      icon: Icons.person_outline,
                      children: [
                        _buildField("Name", nameController),
                        _buildField("Username", usernameController),
                        _buildField("Mobile", mobileController,
                            keyboard: TextInputType.phone),
                        _buildField("Email", emailController,
                            keyboard: TextInputType.emailAddress),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// SECURITY
                    _buildSectionCard(
                      title: "Security",
                      icon: Icons.lock_outline,
                      children: [
                        _buildPasswordField(
                          "Current Password",
                          currentPasswordController,
                          showCurrentPassword,
                          () => setState(() =>
                              showCurrentPassword = !showCurrentPassword),
                        ),
                        _buildPasswordField(
                          "New Password",
                          newPasswordController,
                          showNewPassword,
                          () => setState(
                              () => showNewPassword = !showNewPassword),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    /// SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: saving
                            ? const CircularProgressIndicator(
                                color: Colors.black,
                              )
                            : const Text(
                                "Save Changes",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// SECTION CARD
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF219869)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF219869),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  /// NORMAL FIELD
  Widget _buildField(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "$label is required";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: _getIcon(label),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// PASSWORD FIELD WITH TOGGLE
  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool isVisible,
    VoidCallback toggle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        validator: (value) {
          if (label == "Current Password" &&
              (value == null || value.isEmpty)) {
            return "Current password is required";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: toggle,
          ),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Icon _getIcon(String label) {
    switch (label) {
      case "Name":
        return const Icon(Icons.person_outline);
      case "Username":
        return const Icon(Icons.account_circle_outlined);
      case "Mobile":
        return const Icon(Icons.phone_outlined);
      case "Email":
        return const Icon(Icons.email_outlined);
      default:
        return const Icon(Icons.edit);
    }
  }
}