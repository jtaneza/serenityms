import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../widgets/client_main_layout.dart';

class ClientReportsPage extends StatelessWidget {
  final UserModel user;

  const ClientReportsPage({
    super.key,
    required this.user,
  });

  Stream<QuerySnapshot> get appointmentsStream {
    return FirebaseFirestore.instance.collection('appointments').snapshots();
  }

  num getAmount(Map<String, dynamic> data) {
    final value = data['downpayment'] ?? data['amount'] ?? 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.month}/${date.day}/${date.year}';
    }
    return 'No date';
  }

  String formatTime(Map<String, dynamic> data) {
    return (data['appointmentTime'] ?? '').toString();
  }

  bool isPaid(Map<String, dynamic> data) {
    final status = (data['paymentStatus'] ?? '').toString().toLowerCase();
    return status == 'verified' ||
        status == 'paid' ||
        status == 'completed' ||
        status.contains('verified');
  }

  @override
  Widget build(BuildContext context) {
    return ClientMainLayout(
      user: user,
      currentRoute: 'reports',
      child: Container(
        color: const Color(0xFFF4FAFD),
        child: StreamBuilder<QuerySnapshot>(
          stream: appointmentsStream,
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            final appointments = docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();

            final paidAppointments =
            appointments.where((data) => isPaid(data)).toList();

            final totalSales = paidAppointments.fold<num>(
              0,
                  (sum, data) => sum + getAmount(data),
            );

            final completedCount = appointments.where((data) {
              return (data['status'] ?? '').toString().toLowerCase() ==
                  'completed';
            }).length;

            final completionRate = appointments.isEmpty
                ? 0
                : ((completedCount / appointments.length) * 100).round();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 42),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reports',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF161D1F),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'View sales and appointment reports from your booking database.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF586062),
                    ),
                  ),
                  const SizedBox(height: 42),

                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Total Sales',
                          value: '₱${totalSales.toStringAsFixed(2)}',
                          subtitle: 'Verified online/downpayment records',
                          icon: Icons.payments_outlined,
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Total Appointments',
                          value: '${appointments.length}',
                          subtitle: '$completionRate% Completion Rate',
                          icon: Icons.calendar_month_outlined,
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Pending Requests',
                          value: '${appointments.where((data) {
                            return (data['status'] ?? '')
                                .toString()
                                .toLowerCase() ==
                                'pending';
                          }).length}',
                          subtitle: 'Waiting for approval',
                          icon: Icons.pending_actions_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  _SectionHeader(
                    title: 'Sales Report',
                    subtitle:
                    'Detailed payment history from verified customer bookings.',
                  ),
                  const SizedBox(height: 18),
                  _SalesReportTable(
                    records: paidAppointments,
                    formatDate: formatDate,
                    getAmount: getAmount,
                  ),

                  const SizedBox(height: 42),

                  _SectionHeader(
                    title: 'Appointment Report',
                    subtitle:
                    'Real-time status tracking for all scheduled sessions.',
                  ),
                  const SizedBox(height: 18),
                  _AppointmentReportTable(
                    records: appointments,
                    formatDate: formatDate,
                    formatTime: formatTime,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 155,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          top: BorderSide(color: Color(0xFF00B894), width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -12,
            child: Icon(
              icon,
              size: 92,
              color: const Color(0xFF00B894).withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF586062),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF161D1F),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF006B55),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF161D1F),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF586062),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SalesReportTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final String Function(dynamic value) formatDate;
  final num Function(Map<String, dynamic> data) getAmount;

  const _SalesReportTable({
    required this.records,
    required this.formatDate,
    required this.getAmount,
  });

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      child: Column(
        children: [
          const _TableHeader(
            columns: ['DATE', 'SERVICE', 'CUSTOMER', 'AMOUNT'],
            flexes: [2, 3, 3, 2],
          ),
          if (records.isEmpty)
            const _EmptyRow(text: 'No verified payment records yet.')
          else
            ...records.map((data) {
              return _TableRowShell(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      formatDate(data['createdAt'] ?? data['appointmentDate']),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _ServicePill(
                        text: data['serviceName'] ?? 'Service',
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(data['customerName'] ?? 'Customer'),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '₱${getAmount(data).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _AppointmentReportTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final String Function(dynamic value) formatDate;
  final String Function(Map<String, dynamic> data) formatTime;

  const _AppointmentReportTable({
    required this.records,
    required this.formatDate,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      child: Column(
        children: [
          const _TableHeader(
            columns: ['DATE / TIME', 'CUSTOMER', 'SERVICE', 'STATUS'],
            flexes: [2, 3, 3, 2],
          ),
          if (records.isEmpty)
            const _EmptyRow(text: 'No appointment records yet.')
          else
            ...records.map((data) {
              return _TableRowShell(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDate(data['appointmentDate']),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          formatTime(data),
                          style: const TextStyle(
                            color: Color(0xFF586062),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(data['customerName'] ?? 'Customer'),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      data['serviceName'] ?? 'Service',
                      style: const TextStyle(color: Color(0xFF586062)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _StatusText(status: data['status'] ?? 'Pending'),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _TableShell extends StatelessWidget {
  final Widget child;

  const _TableShell({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TableHeader extends StatelessWidget {
  final List<String> columns;
  final List<int> flexes;

  const _TableHeader({
    required this.columns,
    required this.flexes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEF5F7),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
      child: Row(
        children: List.generate(columns.length, (index) {
          return Expanded(
            flex: flexes[index],
            child: Text(
              columns[index],
              textAlign:
              index == columns.length - 1 ? TextAlign.right : TextAlign.left,
              style: const TextStyle(
                color: Color(0xFF586062),
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.8,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TableRowShell extends StatelessWidget {
  final List<Widget> children;

  const _TableRowShell({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9EFF2)),
        ),
      ),
      child: Row(children: children),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String text;

  const _EmptyRow({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF586062)),
      ),
    );
  }
}

class _ServicePill extends StatelessWidget {
  final String text;

  const _ServicePill({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F5EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF006B55),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  final String status;

  const _StatusText({
    required this.status,
  });

  Color get color {
    final value = status.toLowerCase();

    if (value == 'approved' || value == 'completed') {
      return const Color(0xFF006B55);
    }

    if (value == 'cancelled' || value == 'declined') {
      return const Color(0xFFE53935);
    }

    if (value == 'rescheduled') {
      return const Color(0xFF1565C0);
    }

    return const Color(0xFF9A6B00);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}