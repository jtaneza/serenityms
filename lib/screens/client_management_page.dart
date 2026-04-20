import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/nav_item_model.dart';
import '../models/user_model.dart';
import 'dashboard_page.dart';
import 'login_page.dart';
import 'profile_settings_page.dart';

class ClientManagementPage extends StatelessWidget {
  final UserModel user;

  const ClientManagementPage({
    super.key,
    required this.user,
  });

  static const List<ClientSpaModel> clients = <ClientSpaModel>[
    ClientSpaModel(
      spaName: 'Serenity Downtown Spa',
      icon: Icons.spa,
      isActive: true,
      adminName: 'Sarah Jenkins',
      email: 'sarah.j@downtownserenity.com',
      phone: '+1 (555) 123-4567',
      locationLine1: '452 Broadway Ave,',
      locationLine2: 'Suite 12, New York, NY 10013',
      totalAppointments: '1,284',
      monthlyRevenue: '\$42,350',
    ),
    ClientSpaModel(
      spaName: 'Tranquil Oasis Spa',
      icon: Icons.pool_outlined,
      isActive: true,
      adminName: 'Marcus Rivera',
      email: 'm.rivera@tranquiloasis.com',
      phone: '+1 (555) 987-6543',
      locationLine1: '8800 Sunset Blvd,',
      locationLine2: 'Los Angeles, CA 90069',
      totalAppointments: '942',
      monthlyRevenue: '\$38,900',
    ),
    ClientSpaModel(
      spaName: 'Blissful Touch Wellness',
      icon: Icons.self_improvement_outlined,
      isActive: false,
      adminName: 'Elena Gilbert',
      email: 'elena.g@blissfultouch.net',
      phone: '+1 (555) 443-2211',
      locationLine1: '1221 Michigan Ave,',
      locationLine2: 'Chicago, IL 60611',
      totalAppointments: '0',
      monthlyRevenue: '\$0',
    ),
    ClientSpaModel(
      spaName: 'Harmony Retreat',
      icon: Icons.nature_people_outlined,
      isActive: true,
      adminName: 'David Chen',
      email: 'd.chen@harmonyretreat.com',
      phone: '+1 (555) 776-8899',
      locationLine1: '55 Mountain View Dr,',
      locationLine2: 'Boulder, CO 80302',
      totalAppointments: '512',
      monthlyRevenue: '\$21,400',
    ),
  ];

  static const List<NavItemModel> navItems = <NavItemModel>[
    NavItemModel(icon: Icons.dashboard_outlined, title: 'Dashboard'),
    NavItemModel(
      icon: Icons.groups_outlined,
      title: 'Client Management',
      isActive: true,
    ),
    NavItemModel(icon: Icons.manage_accounts_outlined, title: 'Users & Roles'),
    NavItemModel(icon: Icons.settings_outlined, title: 'System Config'),
    NavItemModel(icon: Icons.monitor_heart_outlined, title: 'Monitoring'),
    NavItemModel(icon: Icons.description_outlined, title: 'Reports'),
    NavItemModel(
      icon: Icons.settings_backup_restore_outlined,
      title: 'Backup & Restore',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          _ClientSidebar(user: user),
          Expanded(
            child: Column(
              children: [
                _ClientTopBar(user: user),
                const Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(32, 28, 32, 32),
                    child: _ClientManagementContent(),
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

class ClientSpaModel {
  final String spaName;
  final IconData icon;
  final bool isActive;
  final String adminName;
  final String email;
  final String phone;
  final String locationLine1;
  final String locationLine2;
  final String totalAppointments;
  final String monthlyRevenue;

  const ClientSpaModel({
    required this.spaName,
    required this.icon,
    required this.isActive,
    required this.adminName,
    required this.email,
    required this.phone,
    required this.locationLine1,
    required this.locationLine2,
    required this.totalAppointments,
    required this.monthlyRevenue,
  });
}

class _ClientSidebar extends StatelessWidget {
  final UserModel user;

  const _ClientSidebar({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 255,
      color: AppColors.inverseSurface,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.spa, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Serenity M & S',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.primaryContainer,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.role,
                        style: const TextStyle(
                          color: AppColors.sidebarMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          ...ClientManagementPage.navItems.map(
                (item) => _ClientSidebarTile(item: item, user: user),
          ),
          const Spacer(),
          _ClientSidebarTile(
            item: const NavItemModel(
              icon: Icons.logout_outlined,
              title: 'Logout',
            ),
            user: user,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _ClientSidebarTile extends StatelessWidget {
  final NavItemModel item;
  final UserModel user;
  final VoidCallback? onTap;

  const _ClientSidebarTile({
    required this.item,
    required this.user,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = item.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.sidebarActiveBg : Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            color: active ? AppColors.primaryContainer : Colors.transparent,
          ),
          Expanded(
            child: ListTile(
              dense: true,
              leading: Icon(
                item.icon,
                color: active
                    ? AppColors.primaryContainer
                    : AppColors.sidebarMuted,
              ),
              title: Text(
                item.title,
                style: TextStyle(
                  color: active
                      ? AppColors.primaryContainer
                      : AppColors.sidebarMuted,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              onTap: onTap ??
                      () {
                    if (item.title == 'Dashboard') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DashboardPage(user: user),
                        ),
                      );
                    }
                  },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientTopBar extends StatelessWidget {
  final UserModel user;

  const _ClientTopBar({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      color: AppColors.surface.withValues(alpha: 0.90),
      child: Row(
        children: [
          const Spacer(),
          Stack(
            children: [
              const Icon(
                Icons.notifications_none,
                color: AppColors.secondary,
                size: 24,
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Container(
            width: 1,
            height: 32,
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.role,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          PopupMenuButton<String>(
            tooltip: '',
            offset: const Offset(0, 42),
            onSelected: (String value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileSettingsPage(user: user),
                  ),
                );
              } else if (value == 'logout') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem<String>(
                value: 'profile',
                child: Text('Profile Settings'),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.only(left: 2),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.secondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientManagementContent extends StatelessWidget {
  const _ClientManagementContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client Management',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage spa client accounts and location performance.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(45, 52, 54, 0.10),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.add_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Add New Client',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(45, 52, 54, 0.04),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Filter by spa name, admin, or city...',
                      hintStyle: TextStyle(color: AppColors.secondary),
                      prefixIcon: Icon(Icons.search, color: AppColors.secondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.tune, color: AppColors.secondary),
                    SizedBox(width: 10),
                    Text(
                      'Filters',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ClientManagementPage.clients.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 28,
            mainAxisSpacing: 28,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            return ClientSpaCard(client: ClientManagementPage.clients[index]);
          },
        ),
      ],
    );
  }
}

class ClientSpaCard extends StatelessWidget {
  final ClientSpaModel client;

  const ClientSpaCard({
    super.key,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = client.isActive
        ? const Color(0xFF10B981)
        : const Color(0xFFB8C1CC);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(45, 52, 54, 0.05),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
        border: const Border(
          top: BorderSide(color: AppColors.primaryContainer, width: 2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(client.icon, color: AppColors.primary, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.spaName,
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            client.isActive ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: AppColors.secondary),
              ],
            ),
            const SizedBox(height: 22),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _InfoBlock(
                      title: 'CLIENT ADMIN',
                      name: client.adminName,
                      line1: client.email,
                      line2: client.phone,
                      line1Icon: Icons.mail,
                      line2Icon: Icons.call,
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    color: AppColors.surfaceContainer,
                  ),
                  Expanded(
                    child: _LocationBlock(
                      title: 'LOCATION',
                      line1: client.locationLine1,
                      line2: client.locationLine2,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: AppColors.surfaceContainer,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _MetricMiniCard(
                    label: 'Total Appointments',
                    value: client.totalAppointments,
                    valueColor: AppColors.onSurface,
                    faded: !client.isActive,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricMiniCard(
                    label: 'Monthly Revenue',
                    value: client.monthlyRevenue,
                    valueColor: AppColors.primary,
                    faded: !client.isActive,
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

class _InfoBlock extends StatelessWidget {
  final String title;
  final String name;
  final String line1;
  final String line2;
  final IconData line1Icon;
  final IconData line2Icon;

  const _InfoBlock({
    required this.title,
    required this.name,
    required this.line1,
    required this.line2,
    required this.line1Icon,
    required this.line2Icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(line1Icon, size: 16, color: AppColors.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                line1,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(line2Icon, size: 16, color: AppColors.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                line2,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LocationBlock extends StatelessWidget {
  final String title;
  final String line1;
  final String line2;

  const _LocationBlock({
    required this.title,
    required this.line1,
    required this.line2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$line1\n$line2',
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _MetricMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool faded;

  const _MetricMiniCard({
    required this.label,
    required this.value,
    required this.valueColor,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}