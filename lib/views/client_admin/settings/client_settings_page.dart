import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../widgets/client_main_layout.dart';

class ClientSettingsPage extends StatefulWidget {
  final UserModel user;

  const ClientSettingsPage({
    super.key,
    required this.user,
  });

  @override
  State<ClientSettingsPage> createState() => _ClientSettingsPageState();
}

class _ClientSettingsPageState extends State<ClientSettingsPage> {
  bool appNotifications = true;
  bool systemNotifications = true;

  Map<String, dynamic> currentData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .get();

    if (!mounted) return;

    setState(() {
      currentData = doc.data() ?? {};
      appNotifications = currentData['appNotifications'] ?? true;
      systemNotifications = currentData['systemNotifications'] ?? true;
      isLoading = false;
    });
  }

  Future<void> updateUserField(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('clients')
        .doc(widget.user.tenantId)
        .set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await loadSettings();
  }

  void changePassword() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool isSaving = false;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> savePassword() async {
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              if (newPassword.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters.'),
                  ),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match.'),
                  ),
                );
                return;
              }

              setDialogState(() => isSaving = true);

              try {
                final authUser = FirebaseAuth.instance.currentUser;

                if (authUser == null) {
                  throw FirebaseAuthException(
                    code: 'not-logged-in',
                    message: 'No logged in user.',
                  );
                }

                await authUser.updatePassword(newPassword);

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.user.uid)
                    .update({
                  'updatedAt': FieldValue.serverTimestamp(),
                  'passwordUpdatedAt': FieldValue.serverTimestamp(),
                });

                if (!mounted) return;

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password updated successfully.'),
                  ),
                );
              } on FirebaseAuthException catch (e) {
                setDialogState(() => isSaving = false);

                String message = e.message ?? 'Failed to update password.';

                if (e.code == 'requires-recent-login') {
                  message =
                  'For security, please logout and login again before changing password.';
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            }

            return AlertDialog(
              title: const Text('Change Password'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : savePassword,
                  child: Text(isSaving ? 'Saving...' : 'Update Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void openEditProfileDialog() {
    final nameController = TextEditingController(
      text: currentData['fullName'] ?? widget.user.fullName,
    );

    final emailController = TextEditingController(
      text: currentData['email'] ?? widget.user.email,
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(
                controller: nameController,
                label: 'Admin Name',
              ),
              _DialogField(
                controller: emailController,
                label: 'Email',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await updateUserField({
                'fullName': nameController.text.trim(),
                'adminName': nameController.text.trim(),
                'email': emailController.text.trim(),
              });

              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  void openEditBusinessDialog() {
    final businessNameController = TextEditingController(
      text: currentData['businessName'] ?? widget.user.businessName,
    );
    final addressController = TextEditingController(
      text: currentData['businessAddress'] ?? widget.user.businessAddress,
    );
    final phoneController = TextEditingController(
      text: currentData['businessPhone'] ?? widget.user.businessPhone,
    );
    final gcashController = TextEditingController(
      text: currentData['gcashNumber'] ?? widget.user.gcashNumber,
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Business Info'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(controller: businessNameController, label: 'Business Name'),
              _DialogField(controller: addressController, label: 'Business Address'),
              _DialogField(controller: phoneController, label: 'Business Phone'),
              _DialogField(controller: gcashController, label: 'GCash Number'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await updateUserField({
                'businessName': businessNameController.text.trim(),
                'businessAddress': addressController.text.trim(),
                'businessPhone': phoneController.text.trim(),
                'gcashNumber': gcashController.text.trim(),
              });

              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void openEditOperatingHoursDialog() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final operatingHours =
    Map<String, dynamic>.from(currentData['operatingHours'] ?? {});

    final openControllers = <String, TextEditingController>{};
    final closeControllers = <String, TextEditingController>{};

    for (final day in days) {
      final data = operatingHours[day];

      if (data is Map) {
        openControllers[day] = TextEditingController(
          text: (data['open'] ?? data['start'] ?? data['from'] ?? '').toString(),
        );
        closeControllers[day] = TextEditingController(
          text: (data['close'] ?? data['end'] ?? data['to'] ?? '').toString(),
        );
      } else {
        openControllers[day] = TextEditingController();
        closeControllers[day] = TextEditingController();
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Operating Hours'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: days.map((day) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 105,
                        child: Text(
                          day,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: openControllers[day],
                          decoration: const InputDecoration(
                            labelText: 'Open',
                            hintText: '9:00 AM',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: closeControllers[day],
                          decoration: const InputDecoration(
                            labelText: 'Close',
                            hintText: '2:00 AM',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newHours = <String, dynamic>{};

              for (final day in days) {
                newHours[day] = {
                  'open': openControllers[day]!.text.trim(),
                  'close': closeControllers[day]!.text.trim(),
                };
              }

              await updateUserField({'operatingHours': newHours});

              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> updateNotificationSetting({
    required bool app,
    required bool system,
  }) async {
    setState(() {
      appNotifications = app;
      systemNotifications = system;
    });

    await updateUserField({
      'appNotifications': app,
      'systemNotifications': system,
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessName = currentData['businessName'] ?? widget.user.businessName;
    final fullName = currentData['fullName'] ?? widget.user.fullName;
    final email = currentData['email'] ?? widget.user.email;
    final address = currentData['businessAddress'] ?? widget.user.businessAddress;
    final phone = currentData['businessPhone'] ?? widget.user.businessPhone;
    final gcash = currentData['gcashNumber'] ?? widget.user.gcashNumber;
    final operatingHours =
    Map<String, dynamic>.from(currentData['operatingHours'] ?? {});

    return ClientMainLayout(
      user: widget.user,
      currentRoute: 'settings',
      child: Container(
        color: const Color(0xFFF4FAFD),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 52),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF161D1F),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Configure your administrative profile, business details, and operational preferences for $businessName.',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF586062),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 56),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: _AdminProfileCard(
                      fullName: fullName,
                      email: email,
                      onChangePassword: changePassword,
                      onEditProfile: openEditProfileDialog,
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 5,
                    child: _NotificationsCard(
                      appNotifications: appNotifications,
                      systemNotifications: systemNotifications,
                      onAppChanged: (value) {
                        updateNotificationSetting(
                          app: value,
                          system: systemNotifications,
                        );
                      },
                      onSystemChanged: (value) {
                        updateNotificationSetting(
                          app: appNotifications,
                          system: value,
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _BusinessInfoCard(
                      businessName: businessName,
                      address: address,
                      phone: phone,
                      gcash: gcash,
                      onEdit: openEditBusinessDialog,
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: _OperatingHoursCard(
                      operatingHours: operatingHours,
                      onEdit: openEditOperatingHoursDialog,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminProfileCard extends StatelessWidget {
  final String fullName;
  final String email;
  final VoidCallback onChangePassword;
  final VoidCallback onEditProfile;

  const _AdminProfileCard({
    required this.fullName,
    required this.email,
    required this.onChangePassword,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      leftAccent: true,
      child: Padding(
        padding: const EdgeInsets.all(34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Profile',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage your personal credentials',
              style: TextStyle(color: Color(0xFF586062)),
            ),
            const SizedBox(height: 34),
            Row(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0FFF4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF006B55),
                    size: 46,
                  ),
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isEmpty ? 'Admin User' : fullName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 16, color: Color(0xFF586062)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 34),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onChangePassword,
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Change Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006B55),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  ),
                ),
                const SizedBox(width: 18),
                TextButton(
                  onPressed: onEditProfile,
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Color(0xFF006B55),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  final bool appNotifications;
  final bool systemNotifications;
  final ValueChanged<bool> onAppChanged;
  final ValueChanged<bool> onSystemChanged;

  const _NotificationsCard({
    required this.appNotifications,
    required this.systemNotifications,
    required this.onAppChanged,
    required this.onSystemChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: const Color(0xFFE3E9EC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: Color(0xFF006B55)),
              SizedBox(width: 14),
              Text(
                'Notifications',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _SwitchTile(
            title: 'App Notifications',
            subtitle: 'Customer booking updates',
            value: appNotifications,
            onChanged: onAppChanged,
          ),
          const SizedBox(height: 20),
          _SwitchTile(
            title: 'System Notifications',
            subtitle: 'Admin alerts and reminders',
            value: systemNotifications,
            onChanged: onSystemChanged,
          ),
        ],
      ),
    );
  }
}

class _BusinessInfoCard extends StatelessWidget {
  final String businessName;
  final String address;
  final String phone;
  final String gcash;
  final VoidCallback onEdit;

  const _BusinessInfoCard({
    required this.businessName,
    required this.address,
    required this.phone,
    required this.gcash,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.all(34),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Business Info',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
              ],
            ),
            const SizedBox(height: 26),
            _InfoBox(label: 'Company Name', value: businessName),
            _InfoBox(label: 'Address', value: address),
            _InfoBox(label: 'Phone', value: phone),
            _InfoBox(label: 'GCash Number', value: gcash),
          ],
        ),
      ),
    );
  }
}

class _OperatingHoursCard extends StatelessWidget {
  final Map<String, dynamic> operatingHours;
  final VoidCallback onEdit;

  const _OperatingHoursCard({
    required this.operatingHours,
    required this.onEdit,
  });

  String getHours(String day) {
    final data = operatingHours[day];

    if (data is Map) {
      final open = data['open'] ?? data['start'] ?? data['from'];
      final close = data['close'] ?? data['end'] ?? data['to'];

      if (open != null &&
          close != null &&
          open.toString().isNotEmpty &&
          close.toString().isNotEmpty) {
        return '$open - $close';
      }
    }

    if (data is String && data.isNotEmpty) return data;

    return 'Not set';
  }

  @override
  Widget build(BuildContext context) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return _CardShell(
      topAccent: true,
      child: Padding(
        padding: const EdgeInsets.all(34),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Operating Hours',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ...days.map((day) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE9EFF2))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        day,
                        style: const TextStyle(color: Color(0xFF586062), fontSize: 16),
                      ),
                    ),
                    Text(
                      getHours(day),
                      style: const TextStyle(
                        color: Color(0xFF161D1F),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF586062), fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF00B894),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF586062),
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value.isEmpty ? 'Not set' : value,
            style: const TextStyle(
              color: Color(0xFF161D1F),
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  final bool leftAccent;
  final bool topAccent;

  const _CardShell({
    required this.child,
    this.leftAccent = false,
    this.topAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: leftAccent
              ? const BorderSide(color: Color(0xFF00B894), width: 4)
              : BorderSide.none,
          top: topAccent
              ? const BorderSide(color: Color(0xFF00B894), width: 4)
              : BorderSide.none,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _DialogField({
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFEEF5F7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}