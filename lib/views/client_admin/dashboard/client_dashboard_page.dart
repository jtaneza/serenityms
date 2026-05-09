import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../widgets/client_main_layout.dart';

class ClientDashboardPage extends StatelessWidget {
  final UserModel user;

  const ClientDashboardPage({
    super.key,
    required this.user,
  });

  Stream<QuerySnapshot> get appointmentsStream {
    return FirebaseFirestore.instance.collection('appointments').snapshots();
  }

  Stream<QuerySnapshot> get servicesStream {
    return FirebaseFirestore.instance.collection('services').snapshots();
  }

  Stream<QuerySnapshot> get staffStream {
    return FirebaseFirestore.instance.collection('staff').snapshots();
  }
  num getAmount(Map<String, dynamic> data) {
    final value = data['downpayment'] ?? data['amount'] ?? data['price'] ?? 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  bool isPaid(Map<String, dynamic> data) {
    final status = (data['paymentStatus'] ?? data['status'] ?? '')
        .toString()
        .toLowerCase();

    return status.contains('verified') ||
        status.contains('paid') ||
        status.contains('completed') ||
        status.contains('full payment');
  }

  @override
  Widget build(BuildContext context) {
    return ClientMainLayout(
      user: user,
      currentRoute: 'dashboard',
      child: Container(
        color: const Color(0xFFF4FAFD),
        child: StreamBuilder<QuerySnapshot>(
          stream: appointmentsStream,
          builder: (context, appointmentSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: servicesStream,
              builder: (context, serviceSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: staffStream,
                  builder: (context, staffSnapshot) {
                    final appointments = appointmentSnapshot.data?.docs ?? [];
                    final services = serviceSnapshot.data?.docs ?? [];
                    final staff = staffSnapshot.data?.docs ?? [];

                    final appointmentData = appointments
                        .map((doc) => doc.data() as Map<String, dynamic>)
                        .toList();

                    final paidAppointments =
                    appointmentData.where((data) => isPaid(data)).toList();

                    final totalRevenue = paidAppointments.fold<num>(
                      0,
                          (sum, data) => sum + getAmount(data),
                    );

                    final pendingCount = appointmentData.where((data) {
                      return (data['status'] ?? '')
                          .toString()
                          .toLowerCase() ==
                          'pending';
                    }).length;

                    final completedCount = appointmentData.where((data) {
                      return (data['status'] ?? '')
                          .toString()
                          .toLowerCase() ==
                          'completed';
                    }).length;

                    final activeStaff = staff.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return (data['status'] ?? 'Active').toString() ==
                          'Active';
                    }).length;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 42,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.businessName} Dashboard',
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF161D1F),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Real-time overview of your appointments, revenue, services, and staff.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF586062),
                            ),
                          ),
                          const SizedBox(height: 42),

                          GridView.count(
                            crossAxisCount: 4,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            childAspectRatio: 1.65,
                            children: [
                              _DashboardCard(
                                title: 'Total Appointments',
                                value: '${appointments.length}',
                                subtitle: 'All booking records',
                                icon: Icons.calendar_month_outlined,
                              ),
                              _DashboardCard(
                                title: 'Total Revenue',
                                value: '₱${totalRevenue.toStringAsFixed(2)}',
                                subtitle: 'Verified payments only',
                                icon: Icons.payments_outlined,
                              ),
                              _DashboardCard(
                                title: 'Pending Bookings',
                                value: '$pendingCount',
                                subtitle: 'Needs review',
                                icon: Icons.pending_actions_outlined,
                                warning: true,
                              ),
                              _DashboardCard(
                                title: 'Active Staff',
                                value: '$activeStaff',
                                subtitle: '${services.length} services',
                                icon: Icons.groups_outlined,
                              ),
                            ],
                          ),

                          const SizedBox(height: 46),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _RecentAppointmentsCard(
                                  appointments: appointments,
                                ),
                              ),
                              const SizedBox(width: 30),
                              Expanded(
                                child: _BusinessSummaryCard(
                                  user: user,
                                  servicesCount: services.length,
                                  staffCount: staff.length,
                                  completedCount: completedCount,
                                  totalAppointments: appointments.length,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool warning;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = warning ? const Color(0xFFBA1A1A) : const Color(0xFF006B55);

    return Container(
      padding: const EdgeInsets.all(26),
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
              size: 82,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
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
                style: TextStyle(
                  color: color,
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

class _RecentAppointmentsCard extends StatelessWidget {
  final List<QueryDocumentSnapshot> appointments;

  const _RecentAppointmentsCard({
    required this.appointments,
  });

  @override
  Widget build(BuildContext context) {
    final recent = [...appointments];

    recent.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      final aDate = aData['createdAt'];
      final bDate = bData['createdAt'];

      if (aDate is Timestamp && bDate is Timestamp) {
        return bDate.compareTo(aDate);
      }

      return 0;
    });

    final visible = recent.take(6).toList();

    return _Panel(
      title: 'Recent Appointments',
      child: Column(
        children: [
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(34),
              child: Text(
                'No appointments yet.',
                style: TextStyle(color: Color(0xFF586062)),
              ),
            )
          else
            ...visible.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return _AppointmentTile(
                customerName: data['customerName'] ?? 'Customer',
                serviceName: data['serviceName'] ?? 'Service',
                status: data['status'] ?? 'Pending',
                date: _formatDate(data['appointmentDate']),
                time: data['appointmentTime'] ?? '',
              );
            }),
        ],
      ),
    );
  }

  static String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.month}/${date.day}/${date.year}';
    }

    return 'No date';
  }
}

class _AppointmentTile extends StatelessWidget {
  final String customerName;
  final String serviceName;
  final String status;
  final String date;
  final String time;

  const _AppointmentTile({
    required this.customerName,
    required this.serviceName,
    required this.status,
    required this.date,
    required this.time,
  });

  Color get statusColor {
    final value = status.toLowerCase();

    if (value == 'approved' || value == 'completed') {
      return const Color(0xFF006B55);
    }

    if (value == 'cancelled' || value == 'declined') {
      return const Color(0xFFBA1A1A);
    }

    if (value == 'rescheduled') {
      return const Color(0xFF1565C0);
    }

    return const Color(0xFF9A6B00);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 18,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9EFF2)),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE3E9EC),
            child: Text(
              customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Color(0xFF006B55),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF161D1F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  serviceName,
                  style: const TextStyle(
                    color: Color(0xFF586062),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$date $time',
                style: const TextStyle(
                  color: Color(0xFF586062),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BusinessSummaryCard extends StatelessWidget {
  final UserModel user;
  final int servicesCount;
  final int staffCount;
  final int completedCount;
  final int totalAppointments;

  const _BusinessSummaryCard({
    required this.user,
    required this.servicesCount,
    required this.staffCount,
    required this.completedCount,
    required this.totalAppointments,
  });

  @override
  Widget build(BuildContext context) {
    final completionRate = totalAppointments == 0
        ? 0
        : ((completedCount / totalAppointments) * 100).round();

    return _Panel(
      title: 'Business Summary',
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryLine(label: 'Business', value: user.businessName),
            _SummaryLine(label: 'Admin', value: user.fullName),
            _SummaryLine(label: 'Email', value: user.email),
            _SummaryLine(label: 'Services', value: '$servicesCount'),
            _SummaryLine(label: 'Staff', value: '$staffCount'),
            _SummaryLine(label: 'Completion Rate', value: '$completionRate%'),
            _SummaryLine(
              label: 'GCash',
              value: user.gcashNumber.isEmpty ? 'Not set' : user.gcashNumber,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF586062),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF161D1F),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
            color: const Color(0xFFEEF5F7),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF161D1F),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}