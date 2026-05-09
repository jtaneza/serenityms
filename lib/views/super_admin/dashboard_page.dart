import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/user_model.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/admin_sidebar.dart';

class DashboardPage extends StatelessWidget {
  final UserModel user;

  const DashboardPage({
    super.key,
    required this.user,
  });

  Stream<QuerySnapshot> get clientsStream {
    return FirebaseFirestore.instance.collection('clients').snapshots();
  }

  Stream<QuerySnapshot> get usersStream {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  Stream<QuerySnapshot> get appointmentsStream {
    return FirebaseFirestore.instance.collection('appointments').snapshots();
  }

  Stream<QuerySnapshot> get paymentsStream {
    return FirebaseFirestore.instance.collection('payments').snapshots();
  }

  Stream<QuerySnapshot> get subscriptionPaymentsStream {
    return FirebaseFirestore.instance
        .collection('subscription_payments')
        .snapshots();
  }

  Stream<QuerySnapshot> get subscriptionPlansStream {
    return FirebaseFirestore.instance
        .collection('subscription_plans')
        .snapshots();
  }

  num toNumber(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  DateTime? toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  bool isActiveClient(Map<String, dynamic> data) {
    final status = (data['status'] ?? data['subscriptionStatus'] ?? '')
        .toString()
        .toLowerCase();

    return status == 'active' || status.contains('active');
  }

  bool isExpiredClient(Map<String, dynamic> data) {
    final status = (data['status'] ?? data['subscriptionStatus'] ?? '')
        .toString()
        .toLowerCase();

    final expiry = data['subscriptionExpiry'] ?? data['expiryDate'];

    if (status.contains('expired')) return true;

    if (expiry is Timestamp) {
      return expiry.toDate().isBefore(DateTime.now());
    }

    return false;
  }

  bool isPaid(Map<String, dynamic> data) {
    final status = (data['status'] ?? data['paymentStatus'] ?? '')
        .toString()
        .toLowerCase();

    return status.contains('paid') ||
        status.contains('verified') ||
        status.contains('full payment') ||
        status.contains('completed');
  }

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
                  child: StreamBuilder<QuerySnapshot>(
                    stream: clientsStream,
                    builder: (context, clientSnapshot) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: usersStream,
                        builder: (context, userSnapshot) {
                          return StreamBuilder<QuerySnapshot>(
                            stream: appointmentsStream,
                            builder: (context, appointmentSnapshot) {
                              return StreamBuilder<QuerySnapshot>(
                                stream: paymentsStream,
                                builder: (context, paymentSnapshot) {
                                  return StreamBuilder<QuerySnapshot>(
                                    stream: subscriptionPaymentsStream,
                                    builder: (context, subscriptionSnapshot) {
                                      final clientDocs =
                                          clientSnapshot.data?.docs ?? [];
                                      final userDocs =
                                          userSnapshot.data?.docs ?? [];
                                      final appointmentDocs =
                                          appointmentSnapshot.data?.docs ?? [];
                                      final paymentDocs =
                                          paymentSnapshot.data?.docs ?? [];
                                      final subscriptionDocs =
                                          subscriptionSnapshot.data?.docs ?? [];

                                      final clientData = clientDocs
                                          .map((doc) => doc.data()
                                      as Map<String, dynamic>)
                                          .toList();

                                      final userData = userDocs
                                          .map((doc) => doc.data()
                                      as Map<String, dynamic>)
                                          .toList();

                                      final appointmentData = appointmentDocs
                                          .map((doc) => doc.data()
                                      as Map<String, dynamic>)
                                          .toList();

                                      final paymentData = paymentDocs
                                          .map((doc) => doc.data()
                                      as Map<String, dynamic>)
                                          .toList();

                                      final subscriptionData = subscriptionDocs
                                          .map((doc) => doc.data()
                                      as Map<String, dynamic>)
                                          .toList();

                                      final totalClients = clientDocs.isNotEmpty
                                          ? clientDocs.length
                                          : userData.where((data) {
                                        final role =
                                        (data['role'] ?? '')
                                            .toString()
                                            .toLowerCase();
                                        return role.contains('client');
                                      }).length;

                                      final activeSubscriptions = clientData
                                          .where(isActiveClient)
                                          .length;

                                      final expiredSubscriptions = clientData
                                          .where(isExpiredClient)
                                          .length;

                                      final totalPayments = paymentData
                                          .where(isPaid)
                                          .fold<num>(
                                        0,
                                            (sum, data) =>
                                        sum + toNumber(data['amount']),
                                      );

                                      final totalSubscriptionPayments =
                                      subscriptionData.where(isPaid).fold<num>(
                                        0,
                                            (sum, data) =>
                                        sum +
                                            toNumber(data['amount']),
                                      );

                                      final totalRevenue =
                                          totalPayments + totalSubscriptionPayments;

                                      final recentActivities =
                                      buildRecentActivities(
                                        clientData: clientData,
                                        paymentData: paymentData,
                                        subscriptionData: subscriptionData,
                                        appointmentData: appointmentData,
                                      );

                                      final performanceBars =
                                      buildPerformanceBars(
                                        appointmentData,
                                        paymentData,
                                      );

                                      return SingleChildScrollView(
                                        padding: const EdgeInsets.fromLTRB(
                                          40,
                                          28,
                                          40,
                                          36,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            const DashboardHeader(),
                                            const SizedBox(height: 34),
                                            MetricCardsRow(
                                              totalClients: totalClients,
                                              activeSubscriptions:
                                              activeSubscriptions,
                                              expiredSubscriptions:
                                              expiredSubscriptions,
                                              totalRevenue: totalRevenue,
                                            ),
                                            const SizedBox(height: 32),
                                            DashboardMiddleSection(
                                              performanceBars:
                                              performanceBars,
                                              recentActivities:
                                              recentActivities,
                                            ),
                                            const SizedBox(height: 32),
                                            ActiveSystemLogs(
                                              appointmentsCount:
                                              appointmentDocs.length,
                                              paymentsCount: paymentDocs.length,
                                              clientsCount: totalClients,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<double> buildPerformanceBars(
      List<Map<String, dynamic>> appointments,
      List<Map<String, dynamic>> payments,
      ) {
    final now = DateTime.now();
    final counts = List<int>.filled(7, 0);

    for (final data in appointments) {
      final date = toDate(data['createdAt'] ?? data['appointmentDate']);
      if (date == null) continue;

      final diff = now.difference(date).inDays;
      if (diff >= 0 && diff < 7) {
        final index = 6 - diff;
        counts[index]++;
      }
    }

    for (final data in payments) {
      final date = toDate(data['createdAt'] ?? data['updatedAt']);
      if (date == null) continue;

      final diff = now.difference(date).inDays;
      if (diff >= 0 && diff < 7) {
        final index = 6 - diff;
        counts[index]++;
      }
    }

    final maxCount = counts.fold<int>(
      1,
          (max, value) => value > max ? value : max,
    );

    return counts.map((count) {
      if (count == 0) return 0.15;
      return (count / maxCount).clamp(0.20, 1.0);
    }).toList();
  }

  List<ActivityData> buildRecentActivities({
    required List<Map<String, dynamic>> clientData,
    required List<Map<String, dynamic>> paymentData,
    required List<Map<String, dynamic>> subscriptionData,
    required List<Map<String, dynamic>> appointmentData,
  }) {
    final items = <ActivityData>[];

    for (final data in clientData) {
      items.add(
        ActivityData(
          title: 'Client record updated',
          subtitle: (data['businessName'] ??
              data['companyName'] ??
              data['fullName'] ??
              'Client')
              .toString(),
          time: activityTime(data['updatedAt'] ?? data['createdAt']),
          date: toDate(data['updatedAt'] ?? data['createdAt']),
          isError: isExpiredClient(data),
        ),
      );
    }

    for (final data in subscriptionData) {
      items.add(
        ActivityData(
          title: 'Subscription payment recorded',
          subtitle: (data['clientName'] ??
              data['businessName'] ??
              data['customerName'] ??
              'Subscription')
              .toString(),
          time: activityTime(data['createdAt'] ?? data['updatedAt']),
          date: toDate(data['createdAt'] ?? data['updatedAt']),
          isError: !isPaid(data),
        ),
      );
    }

    for (final data in paymentData) {
      items.add(
        ActivityData(
          title: 'Service payment recorded',
          subtitle: (data['customerName'] ??
              data['clientName'] ??
              data['serviceName'] ??
              'Payment')
              .toString(),
          time: activityTime(data['createdAt'] ?? data['updatedAt']),
          date: toDate(data['createdAt'] ?? data['updatedAt']),
          isError: !isPaid(data),
        ),
      );
    }

    for (final data in appointmentData) {
      final status = (data['status'] ?? 'Pending').toString();

      items.add(
        ActivityData(
          title: '$status appointment',
          subtitle: '${data['customerName'] ?? 'Customer'} • ${data['serviceName'] ?? 'Service'}',
          time: activityTime(data['updatedAt'] ?? data['createdAt']),
          date: toDate(data['updatedAt'] ?? data['createdAt']),
          isError: status.toLowerCase() == 'cancelled' ||
              status.toLowerCase() == 'declined',
        ),
      );
    }

    items.sort((a, b) {
      final aDate = a.date;
      final bDate = b.date;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return items.take(8).toList();
  }

  String activityTime(dynamic value) {
    final date = toDate(value);
    if (date == null) return 'RECENTLY';

    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'JUST NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes} MINUTES AGO';
    if (diff.inHours < 24) return '${diff.inHours} HOURS AGO';
    if (diff.inDays == 1) return 'YESTERDAY';
    return '${diff.inDays} DAYS AGO';
  }
}

class ActivityData {
  final String title;
  final String subtitle;
  final String time;
  final DateTime? date;
  final bool isError;

  ActivityData({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.date,
    required this.isError,
  });
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
  final int totalClients;
  final int activeSubscriptions;
  final int expiredSubscriptions;
  final num totalRevenue;

  const MetricCardsRow({
    super.key,
    required this.totalClients,
    required this.activeSubscriptions,
    required this.expiredSubscriptions,
    required this.totalRevenue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            icon: Icons.groups,
            title: 'Total Clients',
            value: '$totalClients',
            helper: 'Client records from database',
            badgeText: 'Live',
            badgeIcon: Icons.cloud_done,
            isError: false,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: MetricCard(
            icon: Icons.card_membership,
            title: 'Active Subscriptions',
            value: '$activeSubscriptions',
            helper: 'Active client subscription records',
            badgeText: 'Active',
            badgeIcon: Icons.verified,
            isError: false,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: MetricCard(
            icon: Icons.event_busy,
            title: 'Expired Subscriptions',
            value: '$expiredSubscriptions',
            helper: 'Clients needing subscription review',
            badgeText: 'Review',
            badgeIcon: Icons.warning,
            isError: expiredSubscriptions > 0,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: MetricCard(
            icon: Icons.payments_outlined,
            title: 'Total Revenue',
            value: '₱${totalRevenue.toStringAsFixed(2)}',
            helper: 'Payments from database',
            badgeText: 'Paid',
            badgeIcon: Icons.trending_up,
            isError: false,
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
  final List<double> performanceBars;
  final List<ActivityData> recentActivities;

  const DashboardMiddleSection({
    super.key,
    required this.performanceBars,
    required this.recentActivities,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: SystemPerformanceTrends(
            performanceBars: performanceBars,
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: RecentActivitiesCard(
            activities: recentActivities,
          ),
        ),
      ],
    );
  }
}

class SystemPerformanceTrends extends StatelessWidget {
  final List<double> performanceBars;

  const SystemPerformanceTrends({
    super.key,
    required this.performanceBars,
  });

  @override
  Widget build(BuildContext context) {
    final bars = performanceBars.isEmpty
        ? List<double>.filled(7, 0.15)
        : performanceBars;

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
                      'Records created in the last 7 days',
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
                      'LIVE',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.cloud_done_outlined,
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
                    bars.length,
                        (index) {
                      final double bar = bars[index];
                      final bool active = index == bars.length - 1;

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
              ChartDayLabel('6D'),
              ChartDayLabel('5D'),
              ChartDayLabel('4D'),
              ChartDayLabel('3D'),
              ChartDayLabel('2D'),
              ChartDayLabel('YEST'),
              ChartDayLabel('TODAY'),
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
  final List<ActivityData> activities;

  const RecentActivitiesCard({
    super.key,
    required this.activities,
  });

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
          const Text(
            'Recent Activities',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: activities.isEmpty
                ? const Center(
              child: Text(
                'No recent activities yet.',
                style: TextStyle(color: AppColors.secondary),
              ),
            )
                : SingleChildScrollView(
              child: Column(
                children: activities.map((item) {
                  return ActivityDotItem(
                    title: item.title,
                    subtitle: item.subtitle,
                    time: item.time,
                    isError: item.isError,
                  );
                }).toList(),
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
  final int appointmentsCount;
  final int paymentsCount;
  final int clientsCount;

  const ActiveSystemLogs({
    super.key,
    required this.appointmentsCount,
    required this.paymentsCount,
    required this.clientsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Column(
        children: [
          const SystemLogsHeader(),
          const SystemLogsTableHeader(),
          SystemLogRow(
            eventId: 'DB-CLIENTS',
            service: 'Client records',
            count: clientsCount,
          ),
          SystemLogRow(
            eventId: 'DB-APPOINTMENTS',
            service: 'Appointment records',
            count: appointmentsCount,
          ),
          SystemLogRow(
            eventId: 'DB-PAYMENTS',
            service: 'Payment records',
            count: paymentsCount,
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
            'LIVE DATABASE',
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
              child: TableHeaderText('COUNT'),
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
  final int count;

  const SystemLogRow({
    super.key,
    required this.eventId,
    required this.service,
    required this.count,
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
                  'Connected',
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
              '$count records',
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
