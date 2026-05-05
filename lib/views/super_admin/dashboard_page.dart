import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/user_model.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/admin_header.dart';

class DashboardPage extends StatelessWidget {
  final UserModel user;

  const DashboardPage({
    super.key,
    required this.user,
  });

  static const List<double> performanceBars = <double>[
    0.40,
    0.65,
    0.45,
    0.85,
    0.60,
    0.75,
    0.55,
    0.92,
    0.70,
    0.65,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          AdminSidebar(
            user: user,
            selectedMenu: 'Dashboard',
          ),
          Expanded(
            child: Column(
              children: [
                AdminHeader(user: user),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(40, 28, 40, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        DashboardHeader(),
                        SizedBox(height: 34),
                        MetricCardsRow(),
                        SizedBox(height: 32),
                        DashboardMiddleSection(),
                        SizedBox(height: 32),
                        ActiveSystemLogs(),
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

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 38,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          width: 620,
          child: Text(
            'System-wide monitoring and institutional management for Serenity Medical Systems.',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 16,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class MetricCardsRow extends StatelessWidget {
  const MetricCardsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: MetricCard(
            icon: Icons.groups,
            title: 'Total Clients',
            value: '1,428',
            helper: 'Growth from last month',
            badgeText: '12.4%',
            badgeIcon: Icons.trending_up,
            isError: false,
          ),
        ),
        SizedBox(width: 24),
        Expanded(
          child: MetricCard(
            icon: Icons.card_membership,
            title: 'Active Subscriptions',
            value: '1,284',
            helper: 'Current retention rate',
            badgeText: '98%',
            badgeIcon: Icons.verified,
            isError: false,
          ),
        ),
        SizedBox(width: 24),
        Expanded(
          child: MetricCard(
            icon: Icons.event_busy,
            title: 'Expired Subscriptions',
            value: '12',
            helper: 'Requiring immediate action',
            badgeText: '1.2%',
            badgeIcon: Icons.warning,
            isError: true,
          ),
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String helper;
  final String badgeText;
  final IconData badgeIcon;
  final bool isError;

  const MetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.helper,
    required this.badgeText,
    required this.badgeIcon,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final Color accentColor = isError ? AppColors.error : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 26),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(badgeIcon, size: 14, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            helper,
            style: const TextStyle(
              color: AppColors.outlineVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardMiddleSection extends StatelessWidget {
  const DashboardMiddleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: SystemPerformanceTrends(),
        ),
        SizedBox(width: 32),
        Expanded(
          child: RecentActivitiesCard(),
        ),
      ],
    );
  }
}

class SystemPerformanceTrends extends StatelessWidget {
  const SystemPerformanceTrends({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 480,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
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
                      'System Performance Trends',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Real-time throughput and load balancing statistics',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Text(
                      'MONTHLY',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.onSurface,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    5,
                        (_) => Container(
                      height: 1,
                      color: AppColors.surfaceContainer,
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    DashboardPage.performanceBars.length,
                        (index) {
                      final double bar = DashboardPage.performanceBars[index];
                      final bool active = index == 3 || index == 7;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            height: 260 * bar,
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
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ChartDayLabel('MON'),
              ChartDayLabel('TUE'),
              ChartDayLabel('WED'),
              ChartDayLabel('THU'),
              ChartDayLabel('FRI'),
              ChartDayLabel('SAT'),
              ChartDayLabel('SUN'),
            ],
          ),
        ],
      ),
    );
  }
}

class ChartDayLabel extends StatelessWidget {
  final String label;

  const ChartDayLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.secondary,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
      ),
    );
  }
}

class RecentActivitiesCard extends StatelessWidget {
  const RecentActivitiesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 480,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Recent Activities',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ActivityDotItem(
                    title: 'New client registered',
                    subtitle: 'Harbor View Medical Center',
                    time: '2 MINUTES AGO',
                    isError: false,
                  ),
                  ActivityDotItem(
                    title: 'Subscription renewed',
                    subtitle: 'Oasis Wellness (Enterprise)',
                    time: '1 HOUR AGO',
                    isError: false,
                  ),
                  ActivityDotItem(
                    title: 'Subscription expired',
                    subtitle: 'Evergreen Family Clinic',
                    time: '4 HOURS AGO',
                    isError: true,
                  ),
                  ActivityDotItem(
                    title: 'Backup successful',
                    subtitle: 'Daily system state archive',
                    time: 'YESTERDAY',
                    isError: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityDotItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool isError;

  const ActivityDotItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotColor = isError ? AppColors.error : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.outlineVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
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

class ActiveSystemLogs extends StatelessWidget {
  const ActiveSystemLogs({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Column(
        children: const [
          SystemLogsHeader(),
          SystemLogsTableHeader(),
          SystemLogRow(
            eventId: 'SR-7729-X',
            service: 'Auth-Microservice-A',
            timestamp: '2023-11-04 10:24:02',
          ),
          SystemLogRow(
            eventId: 'SR-7730-X',
            service: 'Data-Validator-B',
            timestamp: '2023-11-04 10:25:44',
          ),
          SystemLogRow(
            eventId: 'SR-7731-X',
            service: 'Reporting-Engine-Main',
            timestamp: '2023-11-04 10:30:11',
          ),
        ],
      ),
    );
  }
}

class SystemLogsHeader extends StatelessWidget {
  const SystemLogsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Row(
        children: [
          Text(
            'Active System Logs',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Spacer(),
          Text(
            'VIEW ALL LOGS',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class SystemLogsTableHeader extends StatelessWidget {
  const SystemLogsTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: TableHeaderText('EVENT ID'),
          ),
          Expanded(
            flex: 2,
            child: TableHeaderText('STATUS'),
          ),
          Expanded(
            flex: 3,
            child: TableHeaderText('SERVICE'),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: TableHeaderText('TIMESTAMP'),
            ),
          ),
        ],
      ),
    );
  }
}

class TableHeaderText extends StatelessWidget {
  final String text;

  const TableHeaderText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.secondary,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
      ),
    );
  }
}

class SystemLogRow extends StatelessWidget {
  final String eventId;
  final String service;
  final String timestamp;

  const SystemLogRow({
    super.key,
    required this.eventId,
    required this.service,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.surfaceContainer),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              eventId,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Operational',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              service,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              timestamp,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}