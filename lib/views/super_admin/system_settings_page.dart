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
                const Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(40, 36, 40, 40),
                    child: _SystemSettingsContent(),
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

class _SystemSettingsContent extends StatelessWidget {
  const _SystemSettingsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SettingsHeader(),
        SizedBox(height: 42),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: _SystemBrandingCard(),
            ),
            SizedBox(width: 32),
            Expanded(
              flex: 5,
              child: _GlobalRulesCard(),
            ),
          ],
        ),
        SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 8,
              child: _EmailConfigurationCard(),
            ),
            SizedBox(width: 32),
            Expanded(
              flex: 4,
              child: _NotificationSettingsCard(),
            ),
          ],
        ),
        SizedBox(height: 42),
        _ActionButtons(),
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
            'Configure the foundational parameters of the Serenity M&S ecosystem. Manage visual identity, communication protocols, and global operational logic.',
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
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
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
  const _SystemBrandingCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.palette,
      title: 'System Branding',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _LabeledInput(
            label: 'System Name',
            value: 'Serenity Management & Services',
          ),
          SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _UploadLogoBox()),
              SizedBox(width: 32),
              SizedBox(width: 210, child: _CurrentIdentityBox()),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadLogoBox extends StatelessWidget {
  const _UploadLogoBox();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Brand Logo'),
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
                  Icons.upload_file,
                  color: AppColors.outlineVariant,
                  size: 42,
                ),
                SizedBox(height: 10),
                Text(
                  'Click to upload or drag & drop',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'SVG, PNG, or WEBP (Max 2MB)',
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
  const _CurrentIdentityBox();

  @override
  Widget build(BuildContext context) {
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
          child: const Center(
            child: Text(
              'Serenity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlobalRulesCard extends StatelessWidget {
  const _GlobalRulesCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.gavel,
      title: 'Global Rules',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _NumberInputWithSuffix(
            label: 'Default Cancellation Policy',
            value: '24',
            suffix: 'Hours',
            helper: 'Minimum window for clients to cancel without penalty.',
          ),
          SizedBox(height: 30),
          _NumberInputWithSuffix(
            label: 'Default Booking Limits',
            value: '3',
            suffix: 'Per Day',
            helper: 'Maximum active appointments allowed per user/day.',
          ),
        ],
      ),
    );
  }
}

class _EmailConfigurationCard extends StatelessWidget {
  const _EmailConfigurationCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.alternate_email,
      title: 'Email Configuration',
      child: Column(
        children: const [
          Row(
            children: [
              Expanded(
                child: _LabeledInput(
                  label: 'SMTP Server',
                  value: 'smtp.serenity-ms.com',
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: _LabeledInput(
                  label: 'Port',
                  value: '587',
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _LabeledInput(
                  label: 'Username',
                  value: 'admin@serenity-ms.com',
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: _PasswordInput(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationSettingsCard extends StatefulWidget {
  const _NotificationSettingsCard();

  @override
  State<_NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<_NotificationSettingsCard> {
  bool emailAlerts = true;
  bool smsAlerts = false;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.notifications_active,
      title: 'Notification Settings',
      child: Column(
        children: [
          _NotificationTile(
            title: 'System-wide Email Alerts',
            subtitle: 'Global delivery for all transaction logs',
            value: emailAlerts,
            onChanged: (value) {
              setState(() {
                emailAlerts = value;
              });
            },
          ),
          const SizedBox(height: 22),
          _NotificationTile(
            title: 'System-wide SMS Alerts',
            subtitle: 'Critical priority alerts via mobile gateway',
            value: smsAlerts,
            onChanged: (value) {
              setState(() {
                smsAlerts = value;
              });
            },
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
  final String value;

  const _LabeledInput({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        TextFormField(
          initialValue: value,
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
  const _PasswordInput();

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
          initialValue: 'admin123456',
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
  final String value;
  final String suffix;
  final String helper;

  const _NumberInputWithSuffix({
    required this.label,
    required this.value,
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
              initialValue: value,
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
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {},
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
            onPressed: () {},
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text(
              'Apply Global Changes',
              style: TextStyle(
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