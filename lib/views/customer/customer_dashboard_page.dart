import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'customer_bottom_nav.dart';
import 'customer_landing_page.dart';
import 'customer_services_page.dart';
// customer_dashboard_page.dart
import 'customer_book_page.dart';


class CustomerDashboardPage extends StatelessWidget {
  const CustomerDashboardPage({super.key});

  Stream<QuerySnapshot> get servicesStream {
    return FirebaseFirestore.instance
        .collection('services')
        .where('status', isEqualTo: 'Active')
        .snapshots();
  }

  String getDurationText(Map<String, dynamic> data) {
    final value = data['duration'] ??
        data['durationMinutes'] ??
        data['serviceDuration'] ??
        data['minutes'];

    if (value == null) return '0 min';

    final text = value.toString();

    if (text.toLowerCase().contains('min')) {
      return text;
    }

    return '$text min';
  }

  Future<String> getCustomerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Customer';

    final doc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .get();

    return doc.data()?['fullName'] ?? 'Customer';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<String>(
                    future: getCustomerName(),
                    builder: (context, snapshot) {
                      return _TopHeader(
                        name: snapshot.data ?? 'Customer',
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  _QuickBookCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerBookPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 34),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Services',
                        style: TextStyle(
                          color: Color(0xFF161D1F),
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerServicesPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'See all',
                          style: TextStyle(
                            color: Color(0xFF006B55),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: servicesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Text(
                            'No available services yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF586062),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: docs.take(5).map((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ServiceCard(
                              serviceId: doc.id,
                              serviceData: data,
                              name: data['name'] ?? data['serviceName'] ?? 'Service',
                              category: data['category'] ?? 'Massage Service',
                              description: data['description'] ?? '',
                              duration: getDurationText(data),
                              price: '₱${data['price'] ?? 0}',
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomerBottomNav(activePage: 'home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String name;

  const _TopHeader({
    required this.name,
  });

  void openNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomerNotificationsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Row(
      children: [
        const SerenityLogo(size: 50),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WELCOME BACK',
                style: TextStyle(
                  color: Color(0xFF586062),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF161D1F),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .where('customerId', isEqualTo: user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            final updates = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = (data['status'] ?? '').toString().toLowerCase();

              return status == 'approved' ||
                  status == 'declined' ||
                  status == 'cancelled' ||
                  status == 'rescheduled' ||
                  status == 'no available therapist';
            }).length;

            return Stack(
              children: [
                IconButton(
                  onPressed: () => openNotifications(context),
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF006B55),
                  ),
                ),
                if (updates > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickBookCard extends StatelessWidget {
  final VoidCallback onTap;

  const _QuickBookCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF006B55),
                Color(0xFF00B894),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF006B55).withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Book Appointment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Choose from your available spa services',
                      style: TextStyle(
                        color: Color(0xDFFFFFFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String serviceId;
  final Map<String, dynamic> serviceData;
  final String name;
  final String category;
  final String description;
  final String duration;
  final String price;

  const _ServiceCard({
    required this.serviceId,
    required this.serviceData,
    required this.name,
    required this.category,
    required this.description,
    required this.duration,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: const Border(
          top: BorderSide(
            color: Color(0x3300B894),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F5EF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.spa,
              color: Color(0xFF006B55),
              size: 36,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF161D1F),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF006B55),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: Color(0xFF586062),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(
                        color: Color(0xFF586062),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        price,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF00A884),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 34,
                      width: 74,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerBookPage(
                                initialServiceId: serviceId,
                                initialService: serviceData,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          backgroundColor: const Color(0xFFEEF5F7),
                          foregroundColor: const Color(0xFF006B55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Book',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class CustomerNotificationsPage extends StatelessWidget {
  const CustomerNotificationsPage({super.key});

  Stream<QuerySnapshot> get notificationsStream {
    final user = FirebaseAuth.instance.currentUser;

    return FirebaseFirestore.instance
        .collection('appointments')
        .where('customerId', isEqualTo: user?.uid)
        .snapshots();
  }

  Color statusColor(String status) {
    final value = status.toLowerCase();

    if (value == 'approved') return const Color(0xFF00A884);
    if (value == 'rescheduled') return const Color(0xFF1565C0);
    if (value == 'declined' || value == 'cancelled') {
      return const Color(0xFFE53935);
    }

    return const Color(0xFF9A6B00);
  }

  String messageFor(Map<String, dynamic> data) {
    final status = (data['status'] ?? 'Pending').toString();
    final service = data['serviceName'] ?? 'your appointment';

    if (status.toLowerCase() == 'approved') {
      return '$service has been approved.';
    }

    if (status.toLowerCase() == 'rescheduled') {
      return '$service was rescheduled. Please check your booking details.';
    }

    if (status.toLowerCase() == 'declined' ||
        status.toLowerCase() == 'cancelled') {
      final reason = data['reason'] ?? data['declineReason'] ?? '';
      return reason.toString().isEmpty
          ? '$service was declined.'
          : '$service was declined. Reason: $reason';
    }

    if (status.toLowerCase() == 'no available therapist') {
      return 'No available therapist at that moment. Please choose another time.';
    }

    return '$service is still pending.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00B894),
        foregroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsStream,
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final status = (data['status'] ?? 'Pending').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: statusColor(status),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor(status),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            messageFor(data),
                            style: const TextStyle(
                              color: Color(0xFF161D1F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}