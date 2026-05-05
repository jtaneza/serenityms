import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'customer_bottom_nav.dart';
import 'customer_landing_page.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  bool isEditing = false;
  bool isSaving = false;

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getCustomerDoc() {
    return FirebaseFirestore.instance.collection('customers').doc(user!.uid).get();
  }

  Future<void> saveProfile() async {
    if (user == null) return;

    setState(() => isSaving = true);

    try {
      final newEmail = emailController.text.trim();

      await FirebaseFirestore.instance.collection('customers').doc(user!.uid).update({
        'fullName': fullNameController.text.trim(),
        'email': newEmail,
        'phone': phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (newEmail.isNotEmpty && newEmail != user!.email) {
        await user!.verifyBeforeUpdateEmail(newEmail);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent. Confirm it to update login email.'),
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.')),
        );
      }

      setState(() => isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void pickAndUploadProfilePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile photo upload is disabled on the free student version.'),
      ),
    );
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CustomerLandingPage()),
          (_) => false,
    );
  }

  void openChangePassword() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New Password',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (passwordController.text.trim().length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters.'),
                    ),
                  );
                  return;
                }

                try {
                  await user!.updatePassword(passwordController.text.trim());

                  if (!mounted) return;

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password update failed: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void openPaymentHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomerPaymentHistoryPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      body: SafeArea(
        child: Stack(
          children: [
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: getCustomerDoc(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? {};

                final fullName = data['fullName'] ?? 'Customer';
                final email = data['email'] ?? user!.email ?? '';
                final phone = data['phone'] ?? '';

                if (!isEditing) {
                  fullNameController.text = fullName;
                  emailController.text = email;
                  phoneController.text = phone;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B894),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Column(
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: pickAndUploadProfilePhoto,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF006B55),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              fullName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              email,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Personal Information',
                                    style: TextStyle(
                                      color: Color(0xFF161D1F),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: isSaving
                                      ? null
                                      : () {
                                    if (isEditing) {
                                      saveProfile();
                                    } else {
                                      setState(() => isEditing = true);
                                    }
                                  },
                                  child: Text(
                                    isEditing ? 'Save' : 'Edit',
                                    style: const TextStyle(
                                      color: Color(0xFF006B55),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _ProfileField(
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              controller: fullNameController,
                              enabled: isEditing,
                            ),
                            const SizedBox(height: 14),
                            _ProfileField(
                              label: 'Email',
                              icon: Icons.email_outlined,
                              controller: emailController,
                              enabled: isEditing,
                            ),
                            const SizedBox(height: 14),
                            _ProfileField(
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              controller: phoneController,
                              enabled: isEditing,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ProfileActionTile(
                        icon: Icons.receipt_long_outlined,
                        title: 'Payment History',
                        onTap: openPaymentHistory,
                      ),
                      const SizedBox(height: 14),
                      _ProfileActionTile(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        onTap: openChangePassword,
                      ),
                      const SizedBox(height: 14),
                      _LogoutTile(onTap: logout),
                    ],
                  ),
                );
              },
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomerBottomNav(activePage: 'profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerPaymentHistoryPage extends StatelessWidget {
  const CustomerPaymentHistoryPage({super.key});

  User? get user => FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot> get paymentStream {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('customerId', isEqualTo: user?.uid)
        .snapshots();
  }

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.month}/${date.day}/${date.year}';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  color: const Color(0xFF00B894),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Payment History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: paymentStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No payment history yet.',
                            style: TextStyle(
                              color: Color(0xFF586062),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data['serviceName'] ?? 'Service',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '₱${data['downpayment'] ?? data['amount'] ?? 0}',
                                      style: const TextStyle(
                                        color: Color(0xFF00A884),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Payment Method: ${data['paymentMethod'] ?? 'GCash'}'),
                                Text('Payment Status: ${data['paymentStatus'] ?? 'Pending'}'),
                                Text('Booking Status: ${data['status'] ?? 'Pending'}'),
                                Text('Date: ${formatDate(data['appointmentDate'])}'),
                                Text('Time: ${data['appointmentTime'] ?? ''}'),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomerBottomNav(activePage: 'profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool enabled;

  const _ProfileField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: const Color(0xFF586062)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF586062),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF7FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE1E8EA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE1E8EA)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE1E8EA)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F5EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF00A884),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF161D1F),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF8A9AAD),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutTile({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF8F8),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFFCDD2)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            children: [
              Icon(Icons.logout, color: Color(0xFFE53935)),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Color(0xFFE57373)),
            ],
          ),
        ),
      ),
    );
  }
}