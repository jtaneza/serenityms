import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/user_model.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/admin_sidebar.dart';

class SystemSettingsPage extends StatelessWidget {
  final UserModel user;

  const SystemSettingsPage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          AdminSidebar(
            user: user,
            selectedMenu: 'Configure System Settings',
          ),
          Expanded(
            child: Column(
              children: [
                AdminHeader(user: user),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(40, 36, 40, 40),
                    child: _SystemSettingsContent(user: user),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemSettingsContent extends StatefulWidget {
  final UserModel user;

  const _SystemSettingsContent({
    required this.user,
  });

  @override
  State<_SystemSettingsContent> createState() => _SystemSettingsContentState();
}

class _SystemSettingsContentState extends State<_SystemSettingsContent> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController systemNameController = TextEditingController();
  final TextEditingController cancellationHoursController =
  TextEditingController();
  final TextEditingController bookingLimitController = TextEditingController();
  final TextEditingController smtpServerController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController emailAddressController = TextEditingController();
  final TextEditingController emailPasswordController = TextEditingController();

  bool adminClientNotifications = true;
  bool customerMobileNotifications = true;
  bool isLoading = true;
  bool isSaving = false;
  DocumentReference<Map<String, dynamic>> get settingsRef {
    return firestore.collection('system_settings').doc('global');
  }

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  @override
  void dispose() {
    systemNameController.dispose();
    cancellationHoursController.dispose();
    bookingLimitController.dispose();
    smtpServerController.dispose();
    portController.dispose();
    emailAddressController.dispose();
    emailPasswordController.dispose();
    super.dispose();
  }

  Future<void> loadSettings() async {
    try {
      final doc = await settingsRef.get();
      final data = doc.data() ?? {};

      systemNameController.text =
          (data['systemName'] ?? 'Serenity Management & Services').toString();

      cancellationHoursController.text =
          (data['defaultCancellationHours'] ?? 24).toString();

      bookingLimitController.text =
          (data['defaultBookingLimitPerDay'] ?? 3).toString();

      smtpServerController.text =
          (data['smtpServer'] ?? 'smtp.serenity-ms.com').toString();

      portController.text = (data['smtpPort'] ?? 587).toString();

      emailAddressController.text =
          (data['emailAddress'] ?? data['emailUsername'] ?? 'admin@serenity.com')
              .toString();

      emailPasswordController.text =
          (data['emailPassword'] ?? 'Admin123').toString();

      adminClientNotifications = data['adminClientNotifications'] ?? true;
      customerMobileNotifications =
          data['customerMobileNotifications'] ?? true;

    } catch (_) {
      systemNameController.text = 'Serenity Management & Services';
      cancellationHoursController.text = '24';
      bookingLimitController.text = '3';
      smtpServerController.text = 'smtp.serenity-ms.com';
      portController.text = '587';
      emailAddressController.text = 'admin@serenity.com';
      emailPasswordController.text = 'Admin123';
      adminClientNotifications = true;
      customerMobileNotifications = true;
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveSettings() async {
    setState(() {
      isSaving = true;
    });

    final cancellationHours =
        int.tryParse(cancellationHoursController.text.trim()) ?? 24;

    final bookingLimit =
        int.tryParse(bookingLimitController.text.trim()) ?? 3;

    final smtpPort = int.tryParse(portController.text.trim()) ?? 587;

    final data = {
      'systemName': systemNameController.text.trim(),
      'defaultCancellationHours': cancellationHours,
      'defaultBookingLimitPerDay': bookingLimit,
      'smtpServer': smtpServerController.text.trim(),
      'smtpPort': smtpPort,
      'emailAddress': emailAddressController.text.trim(),
      'emailPassword': emailPasswordController.text.trim(),
      'adminClientNotifications': adminClientNotifications,
      'customerMobileNotifications': customerMobileNotifications,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': widget.user.uid,
      'updatedByName': widget.user.fullName,
    };

    await settingsRef.set(data, SetOptions(merge: true));

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('System settings saved.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> discardChanges() async {
    setState(() {
      isLoading = true;
    });

    await loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 120),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsHeader(),
        const SizedBox(height: 42),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: _SystemBrandingCard(
                systemNameController: systemNameController,
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              flex: 5,
              child: _GlobalRulesCard(
                cancellationHoursController: cancellationHoursController,
                bookingLimitController: bookingLimitController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 8,
              child: _EmailConfigurationCard(
                smtpServerController: smtpServerController,
                portController: portController,
                emailAddressController: emailAddressController,
                passwordController: emailPasswordController,
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              flex: 4,
              child: _SystemNotificationSettingsCard(
                adminClientNotifications: adminClientNotifications,
                customerMobileNotifications: customerMobileNotifications,
                onAdminClientChanged: (value) {
                  setState(() {
                    adminClientNotifications = value;
                  });
                },
                onCustomerMobileChanged: (value) {
                  setState(() {
                    customerMobileNotifications = value;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 42),
        _ActionButtons(
          isSaving: isSaving,
          onDiscard: discardChanges,
          onSave: saveSettings,
        ),
      ],
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 820,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Settings',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 52,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Update the system name, booking rules, email setup, and notification settings.',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(34, 34, 34, 34),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(45, 52, 54, 0.05),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
        border: const Border(
          left: BorderSide(
            color: AppColors.primaryContainer,
            width: 7,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),
          child,
        ],
      ),
    );
  }
}

class _SystemBrandingCard extends StatelessWidget {
  final TextEditingController systemNameController;

  const _SystemBrandingCard({
    required this.systemNameController,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.palette,
      title: 'System Branding',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledInput(
            label: 'System Name',
            controller: systemNameController,
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: _DefaultLogoBox(),
              ),
              const SizedBox(width: 32),
              SizedBox(
                width: 210,
                child: _CurrentIdentityBox(
                  controller: systemNameController,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DefaultLogoBox extends StatelessWidget {
  const _DefaultLogoBox();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Default Logo'),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.40),
              width: 2,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.spa,
                  color: AppColors.primary,
                  size: 58,
                ),
                SizedBox(height: 10),
                Text(
                  'Default system logo',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'No Firebase Storage needed',
                  style: TextStyle(
                    color: AppColors.outlineVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrentIdentityBox extends StatelessWidget {
  final TextEditingController controller;

  const _CurrentIdentityBox({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final text =
        controller.text.trim().isEmpty ? 'Serenity' : controller.text.trim();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('Current Identity'),
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.inverseSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.spa,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(height: 10),
                      _IdentityText(text: text),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IdentityText extends StatelessWidget {
  final String text;

  const _IdentityText({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 4,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          height: 1.15,
        ),
      ),
    );
  }
}

class _GlobalRulesCard extends StatelessWidget {
  final TextEditingController cancellationHoursController;
  final TextEditingController bookingLimitController;

  const _GlobalRulesCard({
    required this.cancellationHoursController,
    required this.bookingLimitController,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.gavel,
      title: 'Global Rules',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NumberInputWithSuffix(
            label: 'Default Cancellation Policy',
            controller: cancellationHoursController,
            suffix: 'Hours',
            helper: 'Minimum time before customers can cancel without penalty.',
          ),
          const SizedBox(height: 30),
          _NumberInputWithSuffix(
            label: 'Default Booking Limits',
            controller: bookingLimitController,
            suffix: 'Per Day',
            helper: 'Maximum booking allowed per customer each day.',
          ),
        ],
      ),
    );
  }
}

class _EmailConfigurationCard extends StatelessWidget {
  final TextEditingController smtpServerController;
  final TextEditingController portController;
  final TextEditingController emailAddressController;
  final TextEditingController passwordController;

  const _EmailConfigurationCard({
    required this.smtpServerController,
    required this.portController,
    required this.emailAddressController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.alternate_email,
      title: 'Email Configuration',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _LabeledInput(
                  label: 'SMTP Server',
                  controller: smtpServerController,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _LabeledInput(
                  label: 'Port',
                  controller: portController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _LabeledInput(
                  label: 'Email Address',
                  controller: emailAddressController,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _PasswordInput(
                  controller: passwordController,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SystemNotificationSettingsCard extends StatelessWidget {
  final bool adminClientNotifications;
  final bool customerMobileNotifications;
  final ValueChanged<bool> onAdminClientChanged;
  final ValueChanged<bool> onCustomerMobileChanged;

  const _SystemNotificationSettingsCard({
    required this.adminClientNotifications,
    required this.customerMobileNotifications,
    required this.onAdminClientChanged,
    required this.onCustomerMobileChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.settings_suggest,
      title: 'System Settings',
      child: Column(
        children: [
          _NotificationTile(
            title: 'Admin and Client System Alerts',
            subtitle: 'Show dashboard alerts for admin and client accounts.',
            value: adminClientNotifications,
            onChanged: onAdminClientChanged,
          ),
          const SizedBox(height: 22),
          _NotificationTile(
            title: 'Customer Mobile App Alerts',
            subtitle: 'Show booking and payment alerts in the mobile app.',
            value: customerMobileNotifications,
            onChanged: onCustomerMobileChanged,
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({
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
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primaryContainer,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.surfaceContainerHigh,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _LabeledInput({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _inputDecoration(),
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _PasswordInput extends StatefulWidget {
  final TextEditingController controller;

  const _PasswordInput({
    required this.controller,
  });

  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  bool obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Password'),
        TextFormField(
          controller: widget.controller,
          obscureText: obscure,
          decoration: _inputDecoration().copyWith(
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  obscure = !obscure;
                });
              },
              icon: Icon(
                obscure ? Icons.visibility : Icons.visibility_off,
                color: AppColors.outlineVariant,
                size: 18,
              ),
            ),
          ),
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _NumberInputWithSuffix extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String suffix;
  final String helper;

  const _NumberInputWithSuffix({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        Stack(
          children: [
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration().copyWith(
                contentPadding: const EdgeInsets.fromLTRB(16, 16, 86, 16),
              ),
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 15,
              ),
            ),
            Positioned(
              right: 16,
              top: 17,
              child: Text(
                suffix,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          helper,
          style: const TextStyle(
            color: AppColors.outlineVariant,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.secondary,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: AppColors.surfaceContainerLow,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: AppColors.primaryContainer,
        width: 2,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
  );
}

class _ActionButtons extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onDiscard;
  final VoidCallback onSave;

  const _ActionButtons({
    required this.isSaving,
    required this.onDiscard,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: isSaving ? null : onDiscard,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          ),
          child: const Text(
            'Discard Changes',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 18),
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 184, 148, 0.20),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: TextButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.save, color: Colors.white),
            label: Text(
              isSaving ? 'Saving...' : 'Apply Global Changes',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
