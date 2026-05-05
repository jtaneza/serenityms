import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../routes/route_names.dart';
import '../../services/auth_service.dart';

class ClientFirstSetupPage extends StatefulWidget {
  final UserModel user;

  const ClientFirstSetupPage({
    super.key,
    required this.user,
  });

  @override
  State<ClientFirstSetupPage> createState() => _ClientFirstSetupPageState();
}

class _ClientFirstSetupPageState extends State<ClientFirstSetupPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController businessAddressController = TextEditingController();
  final TextEditingController businessPhoneController = TextEditingController();
  final TextEditingController gcashController = TextEditingController();

  bool saving = false;
  bool obscure1 = true;
  bool obscure2 = true;

  Future<void> completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await AuthService.completeClientFirstSetup(
        user: widget.user,
        newPassword: newPasswordController.text,
        businessAddress: businessAddressController.text.trim(),
        businessPhone: businessPhoneController.text.trim(),
        gcashNumber: gcashController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        RouteNames.clientDashboard,
        arguments: widget.user,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Setup Error: $e")),
      );
    }

    if (mounted) {
      setState(() => saving = false);
    }
  }

  Widget buildField(String label, TextEditingController controller,
      {bool obscure = false, VoidCallback? toggle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: toggle != null
              ? IconButton(
            onPressed: toggle,
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          )
              : null,
          filled: true,
          fillColor: const Color(0xFFE3E9EC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return 'Required field';
          }
          if (label.contains('Password') && v.length < 6) {
            return 'Minimum 6 characters';
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    businessAddressController.dispose();
    businessPhoneController.dispose();
    gcashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.spa, size: 58, color: Color(0xFF006B55)),
                  const SizedBox(height: 20),
                  const Text(
                    'Client First Time Setup',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.user.businessName,
                    style: const TextStyle(
                      color: Color(0xFF586062),
                    ),
                  ),
                  const SizedBox(height: 30),

                  buildField(
                    'Create New Password',
                    newPasswordController,
                    obscure: obscure1,
                    toggle: () => setState(() => obscure1 = !obscure1),
                  ),

                  buildField(
                    'Confirm New Password',
                    confirmPasswordController,
                    obscure: obscure2,
                    toggle: () => setState(() => obscure2 = !obscure2),
                  ),

                  buildField('Business Address', businessAddressController),
                  buildField('Business Contact Number', businessPhoneController),
                  buildField('GCash Number', gcashController),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: saving ? null : completeSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006B55),
                        foregroundColor: Colors.white,
                      ),
                      child: saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'COMPLETE SETUP',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}