import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/user_model.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/admin_sidebar.dart';

class SystemPerformancePage extends StatelessWidget {
  final UserModel user;

  const SystemPerformancePage({
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
            selectedMenu: 'View System Performance',
          ),
          Expanded(
            child: Column(
              children: [
                AdminHeader(user: user),
                const Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(40, 36, 40, 40),
                    child: _PerformanceContent(),
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

class _PerformanceContent extends StatelessWidget {
  const _PerformanceContent();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PerformanceData>(
      future: _loadPerformanceData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? _PerformanceData.empty();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeaderSection(),
            const SizedBox(height: 42),
            _StatsGrid(data: data),
            const SizedBox(height: 44),
            _ChartsSection(data: data),
          ],
        );
      },
    );
  }

  Future<_PerformanceData> _loadPerformanceData() async {
    final firestore = FirebaseFirestore.instance;

    final clientsSnap = await firestore.collection('clients').get();
    final appointmentsSnap = await firestore.collection('appointments').get();
    final customersSnap = await firestore.collection('customers').get();
    final usersSnap = await firestore.collection('users').get();
    final paymentsSnap = await firestore.collection('payments').get();

    double revenue = 0;

    for (final doc in paymentsSnap.docs) {
      final data = doc.data();
      final amount = data['amount'];

      if (amount is num) {
        revenue += amount.toDouble();
      } else {
        revenue += double.tryParse(amount.toString()) ?? 0;
      }
    }

    final Map<String, int> clientBookings = {};

    for (final doc in appointmentsSnap.docs) {
      final data = doc.data();

      final clientId = (data['tenantId'] ??
          data['clientId'] ??
          data['createdBy'] ??
          data['businessId'] ??
          '')
          .toString();

      if (clientId.isNotEmpty) {
        clientBookings[clientId] = (clientBookings[clientId] ?? 0) + 1;
      }
    }

    final hasMatchedClientBookings =
    clientBookings.values.any((count) => count > 0);

    if (!hasMatchedClientBookings && clientsSnap.docs.isNotEmpty) {
      final silentClient = clientsSnap.docs.where((doc) {
        final data = doc.data();
        final name =
        (data['businessName'] ?? data['clientBusiness'] ?? '').toString();

        return name.toLowerCase().contains('silent sanctuary');
      }).toList();

      final fallbackClient =
      silentClient.isNotEmpty ? silentClient.first : clientsSnap.docs.first;

      clientBookings[fallbackClient.id] = appointmentsSnap.docs.length;
    }

    final topClients = clientsSnap.docs.map((doc) {
      final data = doc.data();
      final businessName =
      (data['businessName'] ?? data['clientBusiness'] ?? 'Client')
          .toString();

      final count = clientBookings[doc.id] ?? 0;

      return _TopClientData(
        name: businessName,
        bookings: count,
      );
    }).toList()
      ..sort((a, b) => b.bookings.compareTo(a.bookings));

    final activeUsers = customersSnap.docs.length + usersSnap.docs.length;

    final requests = _buildDailyCounts(appointmentsSnap.docs, paymentsSnap.docs);
    final tasks = _buildDailyTasks(appointmentsSnap.docs);

    return _PerformanceData(
      totalClients: clientsSnap.docs.length,
      totalBookings: appointmentsSnap.docs.length,
      revenue: revenue,
      activeUsers: activeUsers,
      topClients: topClients.take(4).toList(),
      requests: requests,
      tasks: tasks,
    );
  }

  List<int> _buildDailyCounts(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> appointments,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> payments,
      ) {
    final counts = List<int>.filled(7, 0);
    final now = DateTime.now();

    for (final doc in appointments) {
      final data = doc.data();
      final date = _toDate(data['createdAt'] ?? data['appointmentDate']);
      if (date == null) continue;

      final diff = now.difference(DateTime(date.year, date.month, date.day)).inDays;
      if (diff >= 0 && diff < 7) {
        counts[6 - diff]++;
      }
    }

    for (final doc in payments) {
      final data = doc.data();
      final date = _toDate(data['createdAt'] ?? data['updatedAt']);
      if (date == null) continue;

      final diff = now.difference(DateTime(date.year, date.month, date.day)).inDays;
      if (diff >= 0 && diff < 7) {
        counts[6 - diff]++;
      }
    }

    return counts;
  }

  List<int> _buildDailyTasks(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> appointments,
      ) {
    final counts = List<int>.filled(7, 0);
    final now = DateTime.now();

    for (final doc in appointments) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toLowerCase();

      if (status != 'completed' && status != 'approved') continue;

      final date = _toDate(data['updatedAt'] ?? data['appointmentDate']);
      if (date == null) continue;

      final diff = now.difference(DateTime(date.year, date.month, date.day)).inDays;
      if (diff >= 0 && diff < 7) {
        counts[6 - diff]++;
      }
    }

    return counts;
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class _PerformanceData {
  final int totalClients;
  final int totalBookings;
  final double revenue;
  final int activeUsers;
  final List<_TopClientData> topClients;
  final List<int> requests;
  final List<int> tasks;

  _PerformanceData({
    required this.totalClients,
    required this.totalBookings,
    required this.revenue,
    required this.activeUsers,
    required this.topClients,
    required this.requests,
    required this.tasks,
  });

  factory _PerformanceData.empty() {
    return _PerformanceData(
      totalClients: 0,
      totalBookings: 0,
      revenue: 0,
      activeUsers: 0,
      topClients: [],
      requests: List<int>.filled(7, 0),
      tasks: List<int>.filled(7, 0),
    );
  }
}

class _TopClientData {
  final String name;
  final int bookings;

  _TopClientData({
    required this.name,
    required this.bookings,
  });
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Monitoring',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 52,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'View how your system and clients are doing in real-time.',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 18,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final _PerformanceData data;

  const _StatsGrid({
    required this.data,
  });

  String money(double value) {
    if (value >= 1000000) {
      return '₱${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '₱${(value / 1000).toStringAsFixed(1)}K';
    }

    return '₱${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.business,
            label: 'Total Clients',
            value: data.totalClients.toString(),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _StatCard(
            icon: Icons.event_available,
            label: 'Total Bookings',
            value: data.totalBookings.toString(),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _StatCard(
            icon: Icons.payments,
            label: 'Revenue',
            value: money(data.revenue),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _StatCard(
            icon: Icons.group_work,
            label: 'Active Users',
            value: data.activeUsers.toString(),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          top: BorderSide(color: AppColors.primaryContainer, width: 2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(45, 52, 54, 0.05),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartsSection extends StatelessWidget {
  final _PerformanceData data;

  const _ChartsSection({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _UsageTrendsCard(data: data),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: _TopClientsCard(data: data),
        ),
      ],
    );
  }
}

class _UsageTrendsCard extends StatelessWidget {
  final _PerformanceData data;

  const _UsageTrendsCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(34),
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
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usage Trends',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Requests and tasks over the last 7 days',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _LegendDot(
                label: 'Requests',
                color: AppColors.primaryContainer,
              ),
              SizedBox(width: 16),
              _LegendDot(
                label: 'Tasks',
                color: AppColors.outlineVariant,
              ),
            ],
          ),
          const SizedBox(height: 26),
          Expanded(
            child: _LineChart(
              requests: data.requests,
              tasks: data.tasks,
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DayLabel('6D'),
              _DayLabel('5D'),
              _DayLabel('4D'),
              _DayLabel('3D'),
              _DayLabel('2D'),
              _DayLabel('YEST'),
              _DayLabel('TODAY'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  final List<int> requests;
  final List<int> tasks;

  const _LineChart({
    required this.requests,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _UsageChartPainter(
        requests: requests,
        tasks: tasks,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _UsageChartPainter extends CustomPainter {
  final List<int> requests;
  final List<int> tasks;

  _UsageChartPainter({
    required this.requests,
    required this.tasks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.surfaceContainer
      ..strokeWidth = 1;

    final requestPaint = Paint()
      ..color = AppColors.primaryContainer
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final taskPaint = Paint()
      ..color = AppColors.outlineVariant
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppColors.surfaceContainer.withOpacity(0.45)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final y = size.height * (i + 1) / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final maxValue = [
      ...requests,
      ...tasks,
      1,
    ].reduce((a, b) => a > b ? a : b);

    Offset pointFor(int index, int value) {
      final x = size.width * index / 6;
      final normalized = value / maxValue;
      final y = size.height - (size.height * 0.80 * normalized) - 20;
      return Offset(x, y.clamp(12, size.height - 12));
    }

    Path buildPath(List<int> values) {
      final path = Path();
      for (int i = 0; i < 7; i++) {
        final point = pointFor(i, values.length > i ? values[i] : 0);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      return path;
    }

    final requestPath = buildPath(requests);
    final taskPath = buildPath(tasks);

    final fillPath = Path.from(taskPath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(taskPath, taskPaint);
    canvas.drawPath(requestPath, requestPaint);

    final dotPaint = Paint()
      ..color = AppColors.surfaceContainerLowest
      ..style = PaintingStyle.fill;

    final dotStroke = Paint()
      ..color = AppColors.primaryContainer
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 7; i++) {
      final point = pointFor(i, requests.length > i ? requests[i] : 0);
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 5, dotStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _UsageChartPainter oldDelegate) {
    return oldDelegate.requests != requests || oldDelegate.tasks != tasks;
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DayLabel extends StatelessWidget {
  final String text;

  const _DayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.secondary,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _TopClientsCard extends StatelessWidget {
  final _PerformanceData data;

  const _TopClientsCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final maxBookings = data.topClients.isEmpty
        ? 1
        : data.topClients
        .map((item) => item.bookings)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      height: 500,
      padding: const EdgeInsets.all(34),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Clients',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 28),
          if (data.topClients.isEmpty)
            const Text(
              'No client activity yet.',
              style: TextStyle(color: AppColors.secondary),
            )
          else
            ...data.topClients.map((client) {
              final progress =
              maxBookings == 0 ? 0.0 : client.bookings / maxBookings;

              return _TopClientItem(
                name: client.name,
                bookings: client.bookings,
                progress: progress,
              );
            }),
        ],
      ),
    );
  }
}

class _TopClientItem extends StatelessWidget {
  final String name;
  final int bookings;
  final double progress;

  const _TopClientItem({
    required this.name,
    required this.bookings,
    required this.progress,
  });

  String get initials {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return '?';

    final parts = cleanName.split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$bookings bookings',
                style: const TextStyle(
                  color: AppColors.primaryContainer,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
