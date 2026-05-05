import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../widgets/client_main_layout.dart';

class ClientAppointmentsPage extends StatefulWidget {
  final UserModel user;

  const ClientAppointmentsPage({
    super.key,
    required this.user,
  });

  @override
  State<ClientAppointmentsPage> createState() => _ClientAppointmentsPageState();
}

class _ClientAppointmentsPageState extends State<ClientAppointmentsPage> {
  String selectedFilter = 'today';

  Stream<QuerySnapshot> get pendingAppointmentsStream {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('status', isEqualTo: 'Pending')
        .snapshots();
  }

  Stream<QuerySnapshot> get appointmentListStream {
    return FirebaseFirestore.instance.collection('appointments').snapshots();
  }

  Future<void> approveAppointment(String docId) async {
    await FirebaseFirestore.instance.collection('appointments').doc(docId).update({
      'status': 'Approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment approved')),
    );
  }

  Future<void> completeAppointment(String docId) async {
    await FirebaseFirestore.instance.collection('appointments').doc(docId).update({
      'status': 'Completed',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment completed')),
    );
  }

  Future<void> cancelAppointment(String docId) async {
    await _showReasonDialog(
      title: 'Cancel Appointment',
      label: 'Cancellation reason',
      confirmText: 'Cancel Appointment',
      onConfirm: (reason) async {
        await FirebaseFirestore.instance.collection('appointments').doc(docId).update({
          'status': 'Cancelled',
          'declineReason': reason,
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      },
    );
  }

  Future<void> declineAppointment(String docId) async {
    await _showReasonDialog(
      title: 'Decline Appointment',
      label: 'Decline reason',
      confirmText: 'Decline',
      onConfirm: (reason) async {
        await FirebaseFirestore.instance.collection('appointments').doc(docId).update({
          'status': 'Declined',
          'declineReason': reason,
          'declinedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      },
    );
  }

  Future<void> markNoTherapist(String docId) async {
    await FirebaseFirestore.instance.collection('appointments').doc(docId).update({
      'status': 'No Available Therapist',
      'declineReason': 'No available therapist at that moment. Please choose another time.',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as no available therapist')),
    );
  }

  Future<void> rescheduleAppointment(String docId) async {
    DateTime selectedDate = DateTime.now();
    String selectedTime = '9:00 AM';
    final reasonController = TextEditingController();

    final times = const [
      '9:00 AM',
      '10:00 AM',
      '11:00 AM',
      '12:00 PM',
      '1:00 PM',
      '2:00 PM',
      '3:00 PM',
      '4:00 PM',
      '5:00 PM',
      '6:00 PM',
      '7:00 PM',
      '8:00 PM',
      '9:00 PM',
      '10:00 PM',
      '11:00 PM',
      '12:00 AM',
      '1:00 AM',
      '2:00 AM',
    ];

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reschedule Appointment'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CalendarDatePicker(
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      onDateChanged: (date) {
                        setDialogState(() => selectedDate = date);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedTime,
                      items: times
                          .map(
                            (time) => DropdownMenuItem(
                          value: time,
                          child: Text(time),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedTime = value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'New time',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('appointments')
                        .doc(docId)
                        .update({
                      'status': 'Rescheduled',
                      'appointmentDate': Timestamp.fromDate(selectedDate),
                      'appointmentTime': selectedTime,
                      'rescheduleReason': reasonController.text.trim(),
                      'rescheduledAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    if (!context.mounted) return;
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Appointment rescheduled')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showReasonDialog({
    required String title,
    required String label,
    required String confirmText,
    required Future<void> Function(String reason) onConfirm,
  }) async {
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                await onConfirm(reasonController.text.trim());

                if (!context.mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title saved')),
                );
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  List<QueryDocumentSnapshot> filterAppointments(List<QueryDocumentSnapshot> docs) {
    final visibleDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString();

      return status != 'Pending';
    }).toList();

    if (selectedFilter == 'upcoming') return visibleDocs;

    final now = DateTime.now();

    return visibleDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final value = data['appointmentDate'];

      if (value is! Timestamp) return false;

      final date = value.toDate();

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ClientMainLayout(
      user: widget.user,
      currentRoute: 'appointments',
      child: Container(
        color: const Color(0xFFF4FAFD),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 42),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PageHeader(),
              const SizedBox(height: 44),
              StreamBuilder<QuerySnapshot>(
                stream: pendingAppointmentsStream,
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        title: 'Booking Requests',
                        accentColor: const Color(0xFF00B894),
                        badgeText: '${docs.length} PENDING',
                      ),
                      const SizedBox(height: 20),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        )
                      else
                        _BookingRequestsTable(
                          docs: docs,
                          onApprove: approveAppointment,
                          onReschedule: rescheduleAppointment,
                          onDecline: declineAppointment,
                          onNoTherapist: markNoTherapist,
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 38),
              _AppointmentListHeader(
                selectedFilter: selectedFilter,
                onFilterChanged: (value) {
                  setState(() => selectedFilter = value);
                },
              ),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: appointmentListStream,
                builder: (context, snapshot) {
                  final docs = filterAppointments(snapshot.data?.docs ?? []);

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    );
                  }

                  return _AppointmentListTable(
                    docs: docs,
                    onComplete: completeAppointment,
                    onCancel: cancelAppointment,
                    onReschedule: rescheduleAppointment,
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appointments',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Color(0xFF161D1F),
            height: 1.05,
            letterSpacing: -1.4,
          ),
        ),
        SizedBox(height: 18),
        SizedBox(
          width: 720,
          child: Text(
            'Manage customer booking requests, approvals, reschedules, cancellations, and appointment completion.',
            style: TextStyle(
              fontSize: 17,
              color: Color(0xFF586062),
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color accentColor;
  final String? badgeText;

  const _SectionHeader({
    required this.title,
    required this.accentColor,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 34,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF161D1F),
            letterSpacing: -0.4,
          ),
        ),
        if (badgeText != null) ...[
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF00B894),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AppointmentListHeader extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const _AppointmentListHeader({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _SectionHeader(
            title: 'Appointment List',
            accentColor: Color(0xFF94A3B8),
          ),
        ),
        Row(
          children: [
            _FilterChipButton(
              label: 'TODAY',
              selected: selectedFilter == 'today',
              onTap: () => onFilterChanged('today'),
            ),
            const SizedBox(width: 10),
            _FilterChipButton(
              label: 'UPCOMING',
              selected: selectedFilter == 'upcoming',
              onTap: () => onFilterChanged('upcoming'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF006B55) : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF586062),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingRequestsTable extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReschedule;
  final ValueChanged<String> onDecline;
  final ValueChanged<String> onNoTherapist;

  const _BookingRequestsTable({
    required this.docs,
    required this.onApprove,
    required this.onReschedule,
    required this.onDecline,
    required this.onNoTherapist,
  });

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      minWidth: 1080,
      childBuilder: (_) {
        return Column(
          children: [
            const _BookingRequestHeaderRow(),
            if (docs.isEmpty)
              const _EmptyTableRow(text: 'No pending booking requests.')
            else
              ...docs.map(
                    (doc) => _BookingRequestRow(
                  docId: doc.id,
                  data: doc.data() as Map<String, dynamic>,
                  showBorder: doc != docs.last,
                  onApprove: onApprove,
                  onReschedule: onReschedule,
                  onDecline: onDecline,
                  onNoTherapist: onNoTherapist,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BookingRequestHeaderRow extends StatelessWidget {
  const _BookingRequestHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: const Color(0xFFEEF5F7),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _TableHeaderText('CUSTOMER')),
          Expanded(flex: 3, child: _TableHeaderText('SERVICE')),
          Expanded(flex: 2, child: _TableHeaderText('THERAPIST')),
          Expanded(flex: 2, child: _TableHeaderText('DATE/TIME')),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: _TableHeaderText('ACTIONS'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingRequestRow extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final bool showBorder;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReschedule;
  final ValueChanged<String> onDecline;
  final ValueChanged<String> onNoTherapist;

  const _BookingRequestRow({
    required this.docId,
    required this.data,
    required this.showBorder,
    required this.onApprove,
    required this.onReschedule,
    required this.onDecline,
    required this.onNoTherapist,
  });

  @override
  Widget build(BuildContext context) {
    final customerName = data['customerName'] ?? 'No Customer';
    final customerEmail = data['customerEmail'] ?? 'No email';
    final service = data['serviceName'] ?? data['service'] ?? 'No Service';
    final category = data['serviceCategory'] ?? 'Massage Service';
    final therapist = data['staffName'] ?? 'Any available therapist';
    final formatted = _formatAppointment(data);

    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: showBorder
              ? const BorderSide(color: Color(0xFFE9EFF2))
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _CustomerIdentity(
              initials: _initials(customerName),
              name: customerName,
              subtitle: customerEmail,
            ),
          ),
          Expanded(
            flex: 3,
            child: _ServiceText(
              service: service,
              category: category,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              therapist,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF586062),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _DateTimeText(
              date: formatted.$1,
              time: formatted.$2,
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionIconButton(
                  tooltip: 'Approve',
                  icon: Icons.check,
                  backgroundColor: const Color(0x1A00B894),
                  iconColor: const Color(0xFF006B55),
                  hoverColor: const Color(0xFF00B894),
                  onTap: () => onApprove(docId),
                ),
                const SizedBox(width: 10),
                _ActionIconButton(
                  tooltip: 'Reschedule',
                  icon: Icons.event_repeat_outlined,
                  backgroundColor: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF1565C0),
                  hoverColor: const Color(0xFF1565C0),
                  onTap: () => onReschedule(docId),
                ),
                const SizedBox(width: 10),
                _ActionIconButton(
                  tooltip: 'No therapist',
                  icon: Icons.person_off_outlined,
                  backgroundColor: const Color(0xFFFFF7ED),
                  iconColor: const Color(0xFFB45309),
                  hoverColor: const Color(0xFFB45309),
                  onTap: () => onNoTherapist(docId),
                ),
                const SizedBox(width: 10),
                _ActionIconButton(
                  tooltip: 'Decline',
                  icon: Icons.close,
                  backgroundColor: const Color(0x1AFFDAD6),
                  iconColor: const Color(0xFFBA1A1A),
                  hoverColor: const Color(0xFFBA1A1A),
                  onTap: () => onDecline(docId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentListTable extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final ValueChanged<String> onComplete;
  final ValueChanged<String> onCancel;
  final ValueChanged<String> onReschedule;

  const _AppointmentListTable({
    required this.docs,
    required this.onComplete,
    required this.onCancel,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      minWidth: 1080,
      childBuilder: (_) {
        return Column(
          children: [
            const _AppointmentHeaderRow(),
            if (docs.isEmpty)
              const _EmptyTableRow(text: 'No appointments found.')
            else
              ...docs.map(
                    (doc) => _AppointmentRow(
                  docId: doc.id,
                  data: doc.data() as Map<String, dynamic>,
                  showBorder: doc != docs.last,
                  onComplete: onComplete,
                  onCancel: onCancel,
                  onReschedule: onReschedule,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AppointmentHeaderRow extends StatelessWidget {
  const _AppointmentHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: const Color(0xFFEEF5F7),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _TableHeaderText('CUSTOMER')),
          Expanded(flex: 3, child: _TableHeaderText('SERVICE')),
          Expanded(flex: 2, child: _TableHeaderText('THERAPIST')),
          Expanded(flex: 2, child: _TableHeaderText('DATE/TIME')),
          Expanded(flex: 2, child: _TableHeaderText('STATUS')),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: _TableHeaderText('ACTIONS'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final bool showBorder;
  final ValueChanged<String> onComplete;
  final ValueChanged<String> onCancel;
  final ValueChanged<String> onReschedule;

  const _AppointmentRow({
    required this.docId,
    required this.data,
    required this.showBorder,
    required this.onComplete,
    required this.onCancel,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final customerName = data['customerName'] ?? 'No Customer';
    final customerEmail = data['customerEmail'] ?? 'No email';
    final service = data['serviceName'] ?? data['service'] ?? 'No Service';
    final category = data['serviceCategory'] ?? 'Massage Service';
    final therapist = data['staffName'] ?? 'Any available therapist';
    final status = data['status'] ?? 'Pending';
    final formatted = _formatAppointment(data);

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: showBorder
              ? const BorderSide(color: Color(0xFFE9EFF2))
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _CustomerIdentity(
              initials: _initials(customerName),
              name: customerName,
              subtitle: customerEmail,
            ),
          ),
          Expanded(
            flex: 3,
            child: _ServiceText(
              service: service,
              category: category,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              therapist,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF586062),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _DateTimeText(
              date: formatted.$1,
              time: formatted.$2,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusBadge(text: status),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionIconButton(
                  tooltip: 'Complete',
                  icon: Icons.done_all,
                  backgroundColor: const Color(0x1A00B894),
                  iconColor: const Color(0xFF006B55),
                  hoverColor: const Color(0xFF00B894),
                  onTap: () => onComplete(docId),
                ),
                const SizedBox(width: 10),
                _ActionIconButton(
                  tooltip: 'Reschedule',
                  icon: Icons.event_repeat_outlined,
                  backgroundColor: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF1565C0),
                  hoverColor: const Color(0xFF1565C0),
                  onTap: () => onReschedule(docId),
                ),
                const SizedBox(width: 10),
                _ActionIconButton(
                  tooltip: 'Cancel',
                  icon: Icons.close,
                  backgroundColor: const Color(0x1AFFDAD6),
                  iconColor: const Color(0xFFBA1A1A),
                  hoverColor: const Color(0xFFBA1A1A),
                  onTap: () => onCancel(docId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceText extends StatelessWidget {
  final String service;
  final String category;

  const _ServiceText({
    required this.service,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.spa_outlined, color: Color(0xFF00B894), size: 18),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF161D1F),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                category,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF006B55),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyTableRow extends StatelessWidget {
  final String text;

  const _EmptyTableRow({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      color: Colors.white,
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF586062)),
      ),
    );
  }
}

class _TableShell extends StatelessWidget {
  final double minWidth;
  final Widget Function(double tableWidth) childBuilder;

  const _TableShell({
    required this.minWidth,
    required this.childBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(minWidth, constraints.maxWidth);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D2D3436),
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: childBuilder(tableWidth),
            ),
          ),
        );
      },
    );
  }
}

class _CustomerIdentity extends StatelessWidget {
  final String initials;
  final String name;
  final String subtitle;

  const _CustomerIdentity({
    required this.initials,
    required this.name,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InitialAvatar(initials: initials),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF161D1F),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF586062),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String initials;

  const _InitialAvatar({
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EFF2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFF006B55),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _DateTimeText extends StatelessWidget {
  final String date;
  final String time;

  const _DateTimeText({
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date,
          style: const TextStyle(
            color: Color(0xFF161D1F),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            color: Color(0xFF586062),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color hoverColor;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.hoverColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          hoverColor: hoverColor.withOpacity(0.18),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              icon,
              color: iconColor,
              size: 23,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;

  const _StatusBadge({
    required this.text,
  });

  Color get backgroundColor {
    final value = text.toLowerCase();

    if (value == 'approved') return const Color(0x1A00B894);
    if (value == 'completed') return const Color(0xFFEFF6FF);
    if (value == 'rescheduled') return const Color(0xFFE0F2FE);
    if (value == 'declined' ||
        value == 'cancelled' ||
        value == 'no available therapist') {
      return const Color(0xFFFFEBEE);
    }

    return const Color(0xFFFFF5CC);
  }

  Color get textColor {
    final value = text.toLowerCase();

    if (value == 'approved') return const Color(0xFF006B55);
    if (value == 'completed') return const Color(0xFF1565C0);
    if (value == 'rescheduled') return const Color(0xFF0369A1);
    if (value == 'declined' ||
        value == 'cancelled' ||
        value == 'no available therapist') {
      return const Color(0xFFBA1A1A);
    }

    return const Color(0xFF9A6B00);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  final String text;

  const _TableHeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF586062),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));

  if (parts.isEmpty || parts.first.isEmpty) return '?';

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

(String, String) _formatAppointment(Map<String, dynamic> data) {
  final dateValue = data['appointmentDate'];
  final timeValue = data['appointmentTime'];

  if (dateValue is! Timestamp) {
    return ('No date', timeValue?.toString() ?? 'No time');
  }

  final date = dateValue.toDate();

  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return (
  '${months[date.month - 1]} ${date.day}, ${date.year}',
  timeValue?.toString() ?? 'No time',
  );
}