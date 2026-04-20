import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/activity_item_model.dart';
import '../models/health_metric_model.dart';
import '../models/nav_item_model.dart';
import '../models/session_item_model.dart';
import '../models/user_model.dart';
import 'client_management_page.dart';
import 'login_page.dart';

class DashboardPage extends StatelessWidget {
  final UserModel user;

  const DashboardPage({
    super.key,
    required this.user,
  });

  static const List<double> revenueBars = <double>[
    0.40, 0.60, 0.55, 0.86, 0.70, 0.95, 0.65,
  ];

  static const List<NavItemModel> navItems = <NavItemModel>[
    NavItemModel(
      icon: Icons.dashboard_outlined,
      title: 'Dashboard',
      isActive: true,
    ),
    NavItemModel(icon: Icons.groups_outlined, title: 'Client Management'),
    NavItemModel(icon: Icons.manage_accounts_outlined, title: 'Users & Roles'),
    NavItemModel(icon: Icons.settings_outlined, title: 'System Config'),
    NavItemModel(icon: Icons.monitor_heart_outlined, title: 'Monitoring'),
    NavItemModel(icon: Icons.bar_chart_outlined, title: 'Reports'),
    NavItemModel(
      icon: Icons.settings_backup_restore_outlined,
      title: 'Backup & Restore',
    ),
  ];

  static const List<HealthMetricModel> healthMetrics = <HealthMetricModel>[
    HealthMetricModel(title: 'Server Uptime', value: '99.98%', progress: 0.99),
    HealthMetricModel(title: 'API Latency', value: '24ms', progress: 0.15),
  ];

  static const List<ActivityItemModel> activityItems = <ActivityItemModel>[
    ActivityItemModel(
      icon: Icons.person_add_alt_1,
      iconBg: Color(0x3300B894),
      iconColor: AppColors.primary,
      title: 'New Professional Onboarded',
      subtitle: 'Elena Vance added as "Lead Therapist" by Julian Thorne.',
      time: '2 MINS AGO',
    ),
    ActivityItemModel(
      icon: Icons.calendar_month_outlined,
      iconBg: Color(0xFFDAE1E3),
      iconColor: Color(0xFF5D6466),
      title: 'Bulk Appointment Reschedule',
      subtitle:
      '12 maintenance appointments moved for clinical sterilization block.',
      time: '1 HOUR AGO',
    ),
    ActivityItemModel(
      icon: Icons.security_outlined,
      iconBg: AppColors.errorContainer,
      iconColor: AppColors.error,
      title: 'Auth Challenge Flagged',
      subtitle:
      'Multiple failed login attempts from unknown IP 192.168.1.42.',
      time: '3 HOURS AGO',
    ),
  ];

  static const List<SessionItemModel> sessionItems = <SessionItemModel>[
    SessionItemModel(
      name: 'Sarah Chen',
      service: 'Deep Tissue Therapy - Room 04',
      status: 'In Progress',
      time: 'Ends 14:45',
    ),
    SessionItemModel(
      name: 'Marcus Miller',
      service: 'Post-Surgical Recovery - Suite A',
      status: 'Starting Soon',
      time: 'Starts 15:00',
    ),
    SessionItemModel(
      name: 'Private Guest',
      service: 'Aromatherapy - VIP Wing',
      status: 'Waitlist',
      time: 'Standby',
      placeholderAvatar: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          Sidebar(user: user),
          Expanded(
            child: Column(
              children: [
                const TopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const EditorialHeader(),
                        const SizedBox(height: 28),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Expanded(flex: 8, child: RevenueCard()),
                            SizedBox(width: 20),
                            Expanded(flex: 4, child: SystemHealthCard()),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Expanded(flex: 7, child: ActivitySection()),
                            SizedBox(width: 20),
                            Expanded(flex: 5, child: ActiveSessionsCard()),
                          ],
                        ),
                      ],
                    ),
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

class Sidebar extends StatelessWidget {
  final UserModel user;

  const Sidebar({
    super.key,
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
                  child: const Icon(Icons.spa, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Serenity M & S',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.primaryContainer,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Super Admin',
                        style: TextStyle(
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
          ...DashboardPage.navItems.map(
                (item) => SidebarTile(item: item, user: user),
          ),
          const Spacer(),
          SidebarTile(
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

class SidebarTile extends StatelessWidget {
  final NavItemModel item;
  final UserModel user;
  final VoidCallback? onTap;

  const SidebarTile({
    super.key,
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
                size: 22,
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
                  fontSize: 14,
                ),
              ),
              onTap: onTap ??
                      () {
                    if (item.title == 'Client Management') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientManagementPage(user: user),
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

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      color: AppColors.surface.withValues(alpha: 0.90),
      child: Row(
        children: [
          Container(
            width: 285,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search system logs or records...',
                hintStyle: TextStyle(color: AppColors.secondary),
                prefixIcon: Icon(Icons.search, color: AppColors.secondary),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
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
            children: const [
              Text(
                'Julian Thorne',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Super Admin',
                style: TextStyle(
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
            child: const Icon(Icons.person, color: AppColors.primary, size: 20),
          ),
          PopupMenuButton<String>(
            tooltip: '',
            offset: const Offset(0, 42),
            onSelected: (String value) {
              if (value == 'profile') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile Settings clicked')),
                );
              }
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem<String>(
                value: 'profile',
                child: Text('Profile Settings'),
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

class EditorialHeader extends StatelessWidget {
  const EditorialHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operations Overview',
          style: TextStyle(
            fontSize: 52,
            height: 1.0,
            letterSpacing: -1.2,
            fontWeight: FontWeight.w900,
            color: AppColors.onSurface,
          ),
        ),
        SizedBox(height: 14),
        SizedBox(
          width: 820,
          child: Text(
            'Welcome back, Julian. The clinical sanctuary is operating at optimal capacity. System health is stable with high throughput in scheduled treatments.',
            style: TextStyle(
              fontSize: 16,
              height: 1.55,
              color: AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }
}

class SerenityCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool topAccent;
  final Color backgroundColor;

  const SerenityCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(28),
    this.topAccent = false,
    this.backgroundColor = AppColors.surfaceContainerLowest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(45, 52, 54, 0.05),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          if (topAccent)
            Container(
              height: 2,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}

class RevenueCard extends StatelessWidget {
  const RevenueCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SerenityCard(
      topAccent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEEKLY REVENUE PERFORMANCE',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '\$42,890.50',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, size: 16, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      '+12.5%',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 250,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(DashboardPage.revenueBars.length, (
                  int index,
                  ) {
                final double bar = DashboardPage.revenueBars[index];
                final bool active = index == 5;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Container(
                      height: 210 * bar,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : AppColors.surfaceContainerHigh,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class SystemHealthCard extends StatelessWidget {
  const SystemHealthCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.inverseSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(45, 52, 54, 0.08),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SYSTEM HEALTH',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 26),
          ...DashboardPage.healthMetrics.map(
                (metric) => Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: HealthMetricTile(metric: metric),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Backup Status',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              StatusChip(label: 'SYNCHRONIZED'),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Run Diagnostics',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HealthMetricTile extends StatelessWidget {
  final HealthMetricModel metric;

  const HealthMetricTile({
    super.key,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              metric.title,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Spacer(),
            Text(
              metric.value,
              style: const TextStyle(
                color: AppColors.primaryFixed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: metric.progress,
            minHeight: 6,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.primaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;

  const StatusChip({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ActivitySection extends StatelessWidget {
  const ActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'System Activity',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Spacer(),
            Text(
              'Export Logs',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...DashboardPage.activityItems.map(
              (item) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ActivityCard(item: item),
          ),
        ),
      ],
    );
  }
}

class ActivityCard extends StatelessWidget {
  final ActivityItemModel item;

  const ActivityCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(item.icon, color: item.iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      item.time,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    height: 1.5,
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

class ActiveSessionsCard extends StatelessWidget {
  const ActiveSessionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Active Sessions',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Spacer(),
              CurrentChip(),
            ],
          ),
          const SizedBox(height: 24),
          ...DashboardPage.sessionItems.map(
                (session) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: SessionTile(session: session),
            ),
          ),
          const SizedBox(height: 14),
          const OccupancyCard(),
        ],
      ),
    );
  }
}

class CurrentChip extends StatelessWidget {
  const CurrentChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        '8 Current',
        style: TextStyle(
          color: AppColors.primaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class SessionTile extends StatelessWidget {
  final SessionItemModel session;

  const SessionTile({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = session.status == 'Waitlist'
        ? AppColors.secondary
        : AppColors.primary;

    return Row(
      children: [
        session.placeholderAvatar
            ? Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.person, color: AppColors.secondary),
        )
            : Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.name,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                session.service,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              session.status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              session.time,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class OccupancyCard extends StatelessWidget {
  const OccupancyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Occupancy at 85% for this afternoon session.',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(
                3,
                    (index) => Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    '+5',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}