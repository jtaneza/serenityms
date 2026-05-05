import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/user_model.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/admin_header.dart';

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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderSection(),
        SizedBox(height: 42),
        _StatsGrid(),
        SizedBox(height: 44),
        _ChartsSection(),
      ],
    );
  }
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
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.business,
            label: 'Total Clients',
            value: '1,284',
            percent: '+4.2%',
          ),
        ),
        SizedBox(width: 24),
        Expanded(
          child: _StatCard(
            icon: Icons.event_available,
            label: 'Total Bookings',
            value: '42,901',
            percent: '+12.5%',
          ),
        ),
        SizedBox(width: 24),
        Expanded(
          child: _StatCard(
            icon: Icons.payments,
            label: 'Revenue',
            value: '\$1.4M',
            percent: '+8.1%',
          ),
        ),
        SizedBox(width: 24),
        Expanded(
          child: _StatCard(
            icon: Icons.group_work,
            label: 'Active Users',
            value: '8,642',
            percent: '+2.4%',
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
  final String percent;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.percent,
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
          Row(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  percent,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
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
  const _ChartsSection();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _UsageTrendsCard(),
        ),
        SizedBox(width: 32),
        Expanded(
          child: _TopClientsCard(),
        ),
      ],
    );
  }
}

class _UsageTrendsCard extends StatelessWidget {
  const _UsageTrendsCard();

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usage Trends',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Requests and tasks over the last 7 days',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _LegendDot(color: AppColors.primaryContainer, label: 'Requests'),
              SizedBox(width: 18),
              _LegendDot(color: AppColors.surfaceContainerHigh, label: 'Tasks'),
            ],
          ),
          const SizedBox(height: 44),
          Expanded(
            child: CustomPaint(
              painter: _UsageChartPainter(),
              child: Container(),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DayLabel('MON'),
              _DayLabel('TUE'),
              _DayLabel('WED'),
              _DayLabel('THU'),
              _DayLabel('FRI'),
              _DayLabel('SAT'),
              _DayLabel('SUN'),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsageChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.surfaceContainer
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final taskPaint = Paint()
      ..color = AppColors.surfaceContainerHigh.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final taskLinePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final requestPaint = Paint()
      ..color = AppColors.primaryContainer
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final requestPointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final requestPointStroke = Paint()
      ..color = AppColors.primaryContainer
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final taskPoints = [
      Offset(0, size.height * .78),
      Offset(size.width * .16, size.height * .72),
      Offset(size.width * .32, size.height * .75),
      Offset(size.width * .48, size.height * .66),
      Offset(size.width * .64, size.height * .82),
      Offset(size.width * .80, size.height * .86),
      Offset(size.width, size.height * .82),
    ];

    final taskPath = Path()..moveTo(taskPoints.first.dx, taskPoints.first.dy);
    for (final point in taskPoints.skip(1)) {
      taskPath.lineTo(point.dx, point.dy);
    }

    final areaPath = Path.from(taskPath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(areaPath, taskPaint);
    canvas.drawPath(taskPath, taskLinePaint);

    final requestPoints = [
      Offset(0, size.height * .55),
      Offset(size.width * .16, size.height * .32),
      Offset(size.width * .32, size.height * .44),
      Offset(size.width * .48, size.height * .12),
      Offset(size.width * .64, size.height * .25),
      Offset(size.width * .80, size.height * .02),
      Offset(size.width, size.height * .20),
    ];

    final requestPath = Path()
      ..moveTo(requestPoints.first.dx, requestPoints.first.dy);

    for (final point in requestPoints.skip(1)) {
      requestPath.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(requestPath, requestPaint);

    for (final index in [1, 3, 5, 6]) {
      canvas.drawCircle(requestPoints[index], 5, requestPointPaint);
      canvas.drawCircle(requestPoints[index], 5, requestPointStroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DayLabel extends StatelessWidget {
  final String label;

  const _DayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.secondary,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _TopClientsCard extends StatelessWidget {
  const _TopClientsCard();

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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Clients',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 28),
          _TopClientItem(
            initials: 'EM',
            name: 'Emerald Mist Spa',
            percent: '98.2%',
            progress: 0.982,
          ),
          _TopClientItem(
            initials: 'ZV',
            name: 'Zenith Vibe\nWellness',
            percent: '94.5%',
            progress: 0.945,
          ),
          _TopClientItem(
            initials: 'SL',
            name: 'Slate Luxury Baths',
            percent: '89.1%',
            progress: 0.891,
          ),
          _TopClientItem(
            initials: 'OC',
            name: 'Oceanic Cure',
            percent: '88.3%',
            progress: 0.883,
          ),
          Spacer(),
          Center(
            child: Text(
              'View All Client Stats',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopClientItem extends StatelessWidget {
  final String initials;
  final String name;
  final String percent;
  final double progress;

  const _TopClientItem({
    required this.initials,
    required this.name,
    required this.percent,
    required this.progress,
  });

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
                percent,
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