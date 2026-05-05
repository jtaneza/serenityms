import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../widgets/client_main_layout.dart';
import 'payment_modal.dart';

class ClientPaymentsPage extends StatefulWidget {
  final UserModel user;

  const ClientPaymentsPage({
    super.key,
    required this.user,
  });

  @override
  State<ClientPaymentsPage> createState() => _ClientPaymentsPageState();
}

class _ClientPaymentsPageState extends State<ClientPaymentsPage> {
  final searchController = TextEditingController();

  String selectedRange = 'Last 30 Days';
  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _openPaymentModal(String method) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentModal(method: method),
    );
  }

  DateTime? _getDate(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    final appointmentDate = data['appointmentDate'];

    if (createdAt is Timestamp) return createdAt.toDate();
    if (appointmentDate is Timestamp) return appointmentDate.toDate();

    return null;
  }

  bool _inSelectedRange(Map<String, dynamic> data) {
    final date = _getDate(data);
    if (date == null) return true;

    final now = DateTime.now();

    if (selectedRange == 'Today') {
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }

    if (selectedRange == 'This Week') {
      return now.difference(date).inDays <= 7;
    }

    return now.difference(date).inDays <= 30;
  }

  List<_PaymentRecord> _filterRecords(List<_PaymentRecord> records) {
    final query = searchQuery.trim().toLowerCase();

    return records.where((record) {
      final customer = record.customerName.toLowerCase();
      final service = record.service.toLowerCase();
      final method = record.method.toLowerCase();
      final status = record.status.toLowerCase();
      final ref = record.reference.toLowerCase();

      final matchesSearch = query.isEmpty ||
          customer.contains(query) ||
          service.contains(query) ||
          method.contains(query) ||
          status.contains(query) ||
          ref.contains(query);

      return matchesSearch && _inSelectedRange(record.rawData);
    }).toList();
  }

  _PaymentRecord _paymentFromPaymentDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return _PaymentRecord(
      id: doc.id,
      source: 'Manual',
      customerName: (data['customerName'] ?? 'No Customer').toString(),
      service: (data['service'] ?? data['serviceName'] ?? '').toString(),
      amount: data['amount'] ?? 0,
      method: (data['method'] ?? data['paymentMethod'] ?? 'Cash').toString(),
      status: (data['status'] ?? 'Pending').toString(),
      reference: (data['reference'] ??
          data['gcashReferenceNumber'] ??
          data['receiptNumber'] ??
          '')
          .toString(),
      createdAt: data['createdAt'],
      rawData: data,
    );
  }

  _PaymentRecord _paymentFromAppointmentDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return _PaymentRecord(
      id: doc.id,
      source: 'Online Booking',
      customerName: (data['customerName'] ?? 'No Customer').toString(),
      service: (data['serviceName'] ?? data['service'] ?? '').toString(),
      amount: data['downpayment'] ?? 0,
      method: (data['paymentMethod'] ?? 'GCash').toString(),
      status: (data['paymentStatus'] ?? 'Pending Booking Payment').toString(),
      reference: (data['gcashReferenceNumber'] ?? '').toString(),
      createdAt: data['createdAt'],
      rawData: data,
    );
  }

  Future<void> verifyAppointmentPayment(String appointmentId) async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update({
      'paymentStatus': 'Verified',
      'paymentVerifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Online payment verified.')),
    );
  }

  Future<void> markPaymentPending(String appointmentId) async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update({
      'paymentStatus': 'Pending Booking Payment',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment marked as pending.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClientMainLayout(
      user: widget.user,
      currentRoute: 'payments',
      child: Container(
        color: const Color(0xFFF4FAFD),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 42),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payments',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF161D1F),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Manage customer downpayments, online GCash references, and onsite cash payments.',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF586062),
                ),
              ),
              const SizedBox(height: 42),
              const SectionTitle(title: 'RECORD TRANSACTION'),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: PaymentActionCard(
                      title: 'Record Cash Payment',
                      badge: 'ONSITE',
                      icon: Icons.payments_outlined,
                      description:
                      'Directly log onsite cash payments received at the cashier.',
                      buttonText: 'Process Cash',
                      filledButton: true,
                      onPressed: () => _openPaymentModal('Cash'),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: PaymentActionCard(
                      title: 'Record GCash Payment',
                      badge: 'E-WALLET',
                      icon: Icons.account_balance_wallet_outlined,
                      description:
                      'Record verified e-wallet payments for manual transactions.',
                      buttonText: 'Process GCash',
                      filledButton: true,
                      onPressed: () => _openPaymentModal('GCash'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 70),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SectionTitle(title: 'PAYMENT HISTORY'),
                  Row(
                    children: [
                      SizedBox(
                        width: 175,
                        height: 44,
                        child: _RangeDropdown(
                          value: selectedRange,
                          items: const [
                            'Last 30 Days',
                            'This Week',
                            'Today',
                          ],
                          onChanged: (value) {
                            setState(() => selectedRange = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 230,
                        height: 44,
                        child: TextField(
                          controller: searchController,
                          onChanged: (value) {
                            setState(() => searchQuery = value);
                          },
                          decoration: InputDecoration(
                            hintText: 'By Customer / Ref',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('payments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, paymentsSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('appointments')
                        .snapshots(),
                    builder: (context, appointmentsSnapshot) {
                      if (paymentsSnapshot.connectionState ==
                          ConnectionState.waiting ||
                          appointmentsSnapshot.connectionState ==
                              ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        );
                      }

                      final paymentDocs = paymentsSnapshot.data?.docs ?? [];
                      final appointmentDocs =
                          appointmentsSnapshot.data?.docs ?? [];

                      final records = <_PaymentRecord>[
                        ...paymentDocs.map(_paymentFromPaymentDoc),
                        ...appointmentDocs
                            .where((doc) {
                          final data =
                          doc.data() as Map<String, dynamic>;
                          final method =
                          (data['paymentMethod'] ?? '').toString();
                          final ref = (data['gcashReferenceNumber'] ?? '')
                              .toString();

                          return method == 'GCash' || ref.isNotEmpty;
                        })
                            .map(_paymentFromAppointmentDoc),
                      ];

                      records.sort((a, b) {
                        final aDate = _recordDate(a);
                        final bDate = _recordDate(b);
                        return bDate.compareTo(aDate);
                      });

                      final filtered = _filterRecords(records);

                      return PaymentsTable(
                        records: filtered,
                        onVerify: verifyAppointmentPayment,
                        onMarkPending: markPaymentPending,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

DateTime _recordDate(_PaymentRecord record) {
  if (record.createdAt is Timestamp) {
    return (record.createdAt as Timestamp).toDate();
  }

  final appointmentDate = record.rawData['appointmentDate'];
  if (appointmentDate is Timestamp) {
    return appointmentDate.toDate();
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}

class _PaymentRecord {
  final String id;
  final String source;
  final String customerName;
  final String service;
  final dynamic amount;
  final String method;
  final String status;
  final String reference;
  final dynamic createdAt;
  final Map<String, dynamic> rawData;

  const _PaymentRecord({
    required this.id,
    required this.source,
    required this.customerName,
    required this.service,
    required this.amount,
    required this.method,
    required this.status,
    required this.reference,
    required this.createdAt,
    required this.rawData,
  });
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 34, height: 2, color: const Color(0xFF00B894)),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF006B55),
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class PaymentActionCard extends StatelessWidget {
  final String title;
  final String badge;
  final IconData icon;
  final String description;
  final String buttonText;
  final bool filledButton;
  final VoidCallback onPressed;

  const PaymentActionCard({
    super.key,
    required this.title,
    required this.badge,
    required this.icon,
    required this.description,
    required this.buttonText,
    required this.filledButton,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          top: BorderSide(color: Color(0xFF00B894), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B894).withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F5EF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF006B55),
                  size: 30,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: badge == 'E-WALLET'
                      ? const Color(0xFFE6F5EF)
                      : const Color(0xFFEEF5F7),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: badge == 'E-WALLET'
                        ? const Color(0xFF006B55)
                        : const Color(0xFF586062),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            title,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: Color(0xFF161D1F),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF586062),
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A884),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _RangeDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 48),
      color: Colors.white,
      elevation: 10,
      constraints: const BoxConstraints(
        minWidth: 175,
        maxWidth: 190,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onSelected: onChanged,
      itemBuilder: (context) {
        return items.map((item) {
          return PopupMenuItem<String>(
            value: item,
            height: 46,
            child: Text(item),
          );
        }).toList();
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF161D1F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 20),
          ],
        ),
      ),
    );
  }
}

class PaymentsTable extends StatelessWidget {
  final List<_PaymentRecord> records;
  final ValueChanged<String> onVerify;
  final ValueChanged<String> onMarkPending;

  const PaymentsTable({
    super.key,
    required this.records,
    required this.onVerify,
    required this.onMarkPending,
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
            color: const Color(0xFFEEF5F7),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            child: const Row(
              children: [
                Expanded(flex: 3, child: TableHeader('CUSTOMER NAME')),
                Expanded(flex: 3, child: TableHeader('SERVICE')),
                Expanded(flex: 3, child: TableHeader('DATE/TIME')),
                Expanded(flex: 2, child: TableHeader('AMOUNT')),
                Expanded(flex: 2, child: TableHeader('METHOD')),
                Expanded(flex: 3, child: TableHeader('REFERENCE')),
                Expanded(flex: 2, child: TableHeader('STATUS')),
                Expanded(flex: 2, child: TableHeader('ACTION')),
              ],
            ),
          ),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(36),
              child: Text(
                'No payment records yet.',
                style: TextStyle(color: Color(0xFF586062)),
              ),
            )
          else
            ...records.map((record) {
              return PaymentRow(
                record: record,
                onVerify: onVerify,
                onMarkPending: onMarkPending,
              );
            }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            color: const Color(0x11EEF5F7),
            alignment: Alignment.centerLeft,
            child: Text(
              'Showing ${records.length} transactions',
              style: const TextStyle(color: Color(0xFF586062)),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentRow extends StatelessWidget {
  final _PaymentRecord record;
  final ValueChanged<String> onVerify;
  final ValueChanged<String> onMarkPending;

  const PaymentRow({
    super.key,
    required this.record,
    required this.onVerify,
    required this.onMarkPending,
  });

  @override
  Widget build(BuildContext context) {
    final customer = record.customerName;
    final dateText = _formatDate(record);
    final amount = double.tryParse(record.amount.toString()) ?? 0;
    final isOnlineBooking = record.source == 'Online Booking';
    final isVerified = record.status.toLowerCase() == 'verified';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9EFF2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE3E9EC),
                  child: Text(
                    customer.isNotEmpty ? customer[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Color(0xFF586062),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    customer,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF161D1F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text(record.service)),
          Expanded(flex: 3, child: Text(dateText)),
          Expanded(
            flex: 2,
            child: Text(
              '₱${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(flex: 2, child: PaymentMethodBadge(method: record.method)),
          Expanded(
            flex: 3,
            child: Text(
              record.reference.isEmpty ? '-' : record.reference,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(flex: 2, child: PaymentStatusBadge(status: record.status)),
          Expanded(
            flex: 2,
            child: isOnlineBooking
                ? TextButton(
              onPressed: () {
                if (isVerified) {
                  onMarkPending(record.id);
                } else {
                  onVerify(record.id);
                }
              },
              child: Text(isVerified ? 'Undo' : 'Verify'),
            )
                : const Text(
              'Manual',
              style: TextStyle(
                color: Color(0xFF586062),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(_PaymentRecord record) {
    dynamic value = record.createdAt;

    value ??= record.rawData['appointmentDate'];

    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.month}/${date.day}/${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    return 'Just now';
  }
}

class PaymentMethodBadge extends StatelessWidget {
  final String method;

  const PaymentMethodBadge({super.key, required this.method});

  @override
  Widget build(BuildContext context) {
    final isGcash = method.toLowerCase() == 'gcash';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isGcash ? const Color(0xFFD8F8EA) : const Color(0xFFE9EFF2),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          method.toUpperCase(),
          style: TextStyle(
            color: isGcash ? const Color(0xFF006B55) : const Color(0xFF586062),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class PaymentStatusBadge extends StatelessWidget {
  final String status;

  const PaymentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final verified = status.toLowerCase() == 'verified';

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: verified ? const Color(0xFF00B894) : const Color(0xFFBBCAC3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            status.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
              verified ? const Color(0xFF006B55) : const Color(0xFF586062),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class TableHeader extends StatelessWidget {
  final String text;

  const TableHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 2,
        color: Color(0xFF586062),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}