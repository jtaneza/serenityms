import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'customer_bottom_nav.dart';

class CustomerBookPage extends StatefulWidget {
  final String? initialServiceId;
  final Map<String, dynamic>? initialService;

  const CustomerBookPage({
    super.key,
    this.initialServiceId,
    this.initialService,
  });

  @override
  State<CustomerBookPage> createState() => _CustomerBookPageState();
}

class _CustomerBookPageState extends State<CustomerBookPage> {
  int step = 1;

  String? selectedServiceId;
  Map<String, dynamic>? selectedService;

  String? selectedStaffId;
  Map<String, dynamic>? selectedStaff;

  DateTime? selectedDate;
  String? selectedTime;

  String paymentMethod = 'GCash';
  bool isSaving = false;

  double depositPercent = 20;

  final gcashReferenceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedServiceId = widget.initialServiceId;
    selectedService = widget.initialService;
    loadBookingRules();
  }

  @override
  void dispose() {
    gcashReferenceController.dispose();
    super.dispose();
  }


  Future<void> loadBookingRules() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('booking_rules')
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();

        if (!mounted) return;

        setState(() {
          depositPercent = ((data['depositPercent'] ?? 20) as num).toDouble();
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        depositPercent = 20;
      });
    }
  }

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

  Stream<QuerySnapshot> get servicesStream {
    return FirebaseFirestore.instance
        .collection('services')
        .where('status', isEqualTo: 'Active')
        .snapshots();
  }

  Stream<QuerySnapshot> get staffStream {
    return FirebaseFirestore.instance.collection('staff').snapshots();
  }

  String getServiceName(Map<String, dynamic> data) {
    return (data['name'] ?? data['serviceName'] ?? 'Service').toString();
  }

  String getCategory(Map<String, dynamic> data) {
    return (data['category'] ?? 'Massage Service').toString();
  }

  String getDurationText(Map<String, dynamic> data) {
    final value = data['duration'] ??
        data['durationMinutes'] ??
        data['serviceDuration'] ??
        data['minutes'];

    if (value == null) return '0 min';

    final text = value.toString();
    if (text.toLowerCase().contains('min')) return text;

    return '$text min';
  }

  num getPrice(Map<String, dynamic> data) {
    final value = data['price'] ?? 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  String formatDate(DateTime date) {
    const months = [
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

    return '${months[date.month - 1]} ${date.day}';
  }

  Future<void> confirmBooking() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('Please login first.');
      return;
    }

    if (selectedService == null || selectedDate == null || selectedTime == null) {
      showMessage('Please complete booking details.');
      return;
    }

    if (gcashReferenceController.text.trim().isEmpty) {
      showMessage('Please enter your GCash reference number.');
      return;
    }

    setState(() => isSaving = true);

    try {
      final customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      final customerData = customerDoc.data() ?? {};
      final price = getPrice(selectedService!);
      final downpayment = (price * (depositPercent / 100)).round();

      await FirebaseFirestore.instance.collection('appointments').add({
        'customerId': user.uid,
        'customerName': customerData['fullName'] ?? user.email ?? 'Customer',
        'customerEmail': user.email,
        'customerPhone': customerData['phone'] ?? '',
        'serviceId': selectedServiceId,
        'serviceName': getServiceName(selectedService!),
        'serviceCategory': getCategory(selectedService!),
        'serviceDuration': getDurationText(selectedService!),
        'staffId': selectedStaffId,
        'staffName': selectedStaff == null
            ? 'Any available therapist'
            : (selectedStaff!['fullName'] ??
            selectedStaff!['name'] ??
            selectedStaff!['staffName'] ??
            'Therapist')
            .toString(),
        'appointmentDate': Timestamp.fromDate(selectedDate!),
        'appointmentTime': selectedTime,
        'amount': price,
        'downpayment': downpayment,
        'paymentMethod': 'GCash',
        'paymentStatus': 'Pending Booking Payment',
        'gcashReferenceNumber': gcashReferenceController.text.trim(),
        'paymentType': 'Booking Downpayment',
        'downpaymentRate': depositPercent.round(),
        'cancellationPenaltyNote':
        'If cancellation is made after 24 hours, 10% may be deducted from the downpayment.',
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CustomerBookingsPage(),
        ),
      );
    } catch (e) {
      showMessage('Booking failed: $e');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void nextStep() {
    if (step == 1 && selectedService == null) {
      showMessage('Please select a service.');
      return;
    }

    if (step == 2 && selectedStaff == null) {
      showMessage('Please select a therapist.');
      return;
    }

    if (step == 3 && (selectedDate == null || selectedTime == null)) {
      showMessage('Please select date and time.');
      return;
    }

    if (step < 5) {
      setState(() => step++);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget buildStepContent() {
    if (step == 1) return buildServiceStep();
    if (step == 2) return buildTherapistStep();
    if (step == 3) return buildDateTimeStep();
    if (step == 4) return buildConfirmStep();
    return buildPaymentStep();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                  color: const Color(0xFF00B894),
                  child: const Text(
                    'Book Appointment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                  color: Colors.white,
                  child: _StepIndicator(step: step),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
                    child: buildStepContent(),
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomerBottomNav(activePage: 'book'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildServiceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Select Service'),
        const SizedBox(height: 14),
        StreamBuilder<QuerySnapshot>(
          stream: servicesStream,
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (docs.isEmpty) {
              return const Text('No services available.');
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final active = selectedServiceId == doc.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SelectableCard(
                    active: active,
                    icon: Icons.spa,
                    title: getServiceName(data),
                    subtitle:
                    '${getCategory(data)}\n${getDurationText(data)}   •   ₱${getPrice(data)}',
                    onTap: () {
                      setState(() {
                        selectedServiceId = doc.id;
                        selectedService = data;
                      });
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 22),
        _PrimaryButton(
          label: 'Continue',
          onPressed: nextStep,
        ),
      ],
    );
  }

  Widget buildTherapistStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Select Therapist'),
        const SizedBox(height: 14),
        StreamBuilder<QuerySnapshot>(
          stream: staffStream,
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (docs.isEmpty) {
              return _SelectableCard(
                active: selectedStaffId == 'any',
                icon: Icons.person_outline,
                title: 'Any available therapist',
                subtitle: 'Assign automatically',
                onTap: () {
                  setState(() {
                    selectedStaffId = 'any';
                    selectedStaff = {
                      'fullName': 'Any available therapist',
                    };
                  });
                },
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final active = selectedStaffId == doc.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SelectableCard(
                    active: active,
                    icon: Icons.person_outline,
                    title: (data['fullName'] ??
                        data['name'] ??
                        data['staffName'] ??
                        'Therapist')
                        .toString(),
                    subtitle: (data['specialty'] ??
                        data['specialization'] ??
                        'Massage Therapist')
                        .toString(),
                    onTap: () {
                      setState(() {
                        selectedStaffId = doc.id;
                        selectedStaff = data;
                      });
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 22),
        _BackContinueRow(
          onBack: () => setState(() => step--),
          onContinue: nextStep,
        ),
      ],
    );
  }

  Widget buildDateTimeStep() {
    final date = selectedDate ?? DateTime.now();
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Select Date'),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE1E8EA)),
          ),
          child: CalendarDatePicker(
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 60)),
            onDateChanged: (date) {
              setState(() {
                selectedDate = date;
                selectedTime = null;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Select Time'),
        const SizedBox(height: 8),
        const Text(
          'Red means your selected therapist is already booked at that time.',
          style: TextStyle(
            color: Color(0xFF586062),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
              .where(
            'appointmentDate',
            isLessThan: Timestamp.fromDate(end),
          )
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            bool isUnavailable(String time) {
              return docs.any((doc) {
                final data = doc.data() as Map<String, dynamic>;

                final status = (data['status'] ?? '').toString().toLowerCase();
                final staffId = (data['staffId'] ?? '').toString();
                final appointmentTime =
                (data['appointmentTime'] ?? '').toString();

                final activeBooking =
                    status == 'pending' || status == 'approved';

                final sameStaff = selectedStaffId != null &&
                    selectedStaffId != 'any' &&
                    staffId == selectedStaffId;

                return activeBooking && sameStaff && appointmentTime == time;
              });
            }

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: times.map((time) {
                final active = selectedTime == time;
                final unavailable = isUnavailable(time);

                return _DateTimeChip(
                  label: unavailable ? '$time\nBooked' : time,
                  active: active,
                  unavailable: unavailable,
                  onTap: unavailable
                      ? null
                      : () {
                    setState(() => selectedTime = time);
                  },
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 28),
        _BackContinueRow(
          onBack: () => setState(() => step--),
          onContinue: nextStep,
        ),
      ],
    );
  }

  Widget buildConfirmStep() {
    final price = selectedService == null ? 0 : getPrice(selectedService!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Confirm Booking'),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              _SummaryRow(
                icon: Icons.calendar_month,
                label: 'Service',
                value: getServiceName(selectedService ?? {}),
                subValue: selectedService == null
                    ? ''
                    : '${getCategory(selectedService!)} • ${getDurationText(selectedService!)}',
              ),
              const SizedBox(height: 14),
              _SummaryRow(
                icon: Icons.person_outline,
                label: 'Therapist',
                value: selectedStaff == null
                    ? 'Any available therapist'
                    : (selectedStaff!['fullName'] ??
                    selectedStaff!['name'] ??
                    selectedStaff!['staffName'] ??
                    'Therapist')
                    .toString(),
              ),
              const SizedBox(height: 14),
              _SummaryRow(
                icon: Icons.schedule,
                label: 'Date & Time',
                value:
                '${selectedDate == null ? '' : formatDate(selectedDate!)} at ${selectedTime ?? ''}',
              ),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      color: Color(0xFF586062),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₱$price',
                    style: const TextStyle(
                      color: Color(0xFF00A884),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _BackContinueRow(
          onBack: () => setState(() => step--),
          onContinue: nextStep,
        ),
      ],
    );
  }

  Widget buildPaymentStep() {
    final price = selectedService == null ? 0 : getPrice(selectedService!);
    final downpayment = (price * (depositPercent / 100)).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Payment'),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              _PaymentAmountRow(label: 'Service Amount', value: '₱$price'),
              const SizedBox(height: 10),
              _PaymentAmountRow(
                label: 'Downpayment (${depositPercent.round()}%)',
                value: '₱$downpayment',
              ),
              const Divider(height: 28),
              _PaymentAmountRow(
                label: 'Amount to Pay Now',
                value: '₱$downpayment',
                highlight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Payment Method'),
        const SizedBox(height: 14),
        _PaymentMethodCard(
          title: 'GCash',
          subtitle: 'Pay via GCash',
          icon: Icons.account_balance_wallet_outlined,
          active: true,
          onTap: () => setState(() => paymentMethod = 'GCash'),
        ),
        const SizedBox(height: 18),
        const _SectionTitle('GCash Reference Number'),
        const SizedBox(height: 10),
        TextField(
          controller: gcashReferenceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter GCash reference number',
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF006B55),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE1E8EA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE1E8EA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF00B894),
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Color(0xFF9A6B00),
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Reminder: If you cancel your appointment after 24 hours, 20% may be deducted from your downpayment. Final penalty rules will be handled by the spa admin.',
                  style: TextStyle(
                    color: Color(0xFF6D4C00),
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _BackContinueRow(
          onBack: () => setState(() => step--),
          continueLabel: isSaving ? 'Saving...' : 'Confirm Booking',
          onContinue: isSaving ? null : confirmBooking,
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;

  const _StepIndicator({
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        final number = index + 1;
        final completed = number < step;
        final active = number == step;

        return Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: active || completed
                  ? const Color(0xFF00B894)
                  : const Color(0xFFE6F5EF),
              child: completed
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                '$number',
                style: TextStyle(
                  color: active
                      ? Colors.white
                      : const Color(0xFF586062),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (index != 4)
              Container(
                width: 34,
                height: 2,
                color: completed
                    ? const Color(0xFF00B894)
                    : const Color(0xFFE6F5EF),
              ),
          ],
        );
      }),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SelectableCard({
    required this.active,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? const Color(0xFF00B894) : const Color(0xFFDDE3E6),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F5EF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF006B55), size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF161D1F),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF586062),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF00B894),
              ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool unavailable;
  final VoidCallback? onTap;

  const _DateTimeChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.unavailable = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    if (unavailable) {
      backgroundColor = const Color(0xFFFFEBEE);
      foregroundColor = const Color(0xFFE53935);
      borderColor = const Color(0xFFE53935);
    } else if (active) {
      backgroundColor = const Color(0xFF00B894);
      foregroundColor = Colors.white;
      borderColor = const Color(0xFF00B894);
    } else {
      backgroundColor = Colors.white;
      foregroundColor = const Color(0xFF161D1F);
      borderColor = const Color(0xFFDDE3E6);
    }

    return SizedBox(
      width: 98,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00B894),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _BackContinueRow extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onContinue;
  final String continueLabel;

  const _BackContinueRow({
    required this.onBack,
    required this.onContinue,
    this.continueLabel = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF006B55),
                side: const BorderSide(color: Color(0xFF00B894)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Back',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PrimaryButton(
            label: continueLabel,
            onPressed: onContinue,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF161D1F),
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF00B894), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF586062))),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF161D1F),
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subValue != null && subValue!.isNotEmpty)
                Text(
                  subValue!,
                  style: const TextStyle(color: Color(0xFF586062)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentAmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _PaymentAmountRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            color:
            highlight ? const Color(0xFF00A884) : const Color(0xFF161D1F),
            fontSize: highlight ? 18 : 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SelectableCard(
      active: active,
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}

class CustomerBookingsPage extends StatefulWidget {
  const CustomerBookingsPage({super.key});

  @override
  State<CustomerBookingsPage> createState() => _CustomerBookingsPageState();
}

class _CustomerBookingsPageState extends State<CustomerBookingsPage> {
  String selectedStatus = 'Pending';

  Stream<QuerySnapshot> get bookingsStream {
    final user = FirebaseAuth.instance.currentUser;

    return FirebaseFirestore.instance
        .collection('appointments')
        .where('customerId', isEqualTo: user?.uid)
        .snapshots();
  }

  Future<void> cancelBooking(String docId) async {
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason for cancellation',
            border: OutlineInputBorder(),
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
                'status': 'Cancelled',
                'cancelledBy': 'Customer',
                'customerCancelReason': reasonController.text.trim(),
                'cancelledAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });

              if (!context.mounted) return;

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking cancelled.')),
              );
            },
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statuses = [
      'Pending',
      'Approved',
      'Rescheduled',
      'Completed',
      'Cancelled',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                  color: const Color(0xFF00B894),
                  child: const Text(
                    'My Bookings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  color: Colors.white,
                  height: 52,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: statuses.map((status) {
                        final active = selectedStatus == status;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: TextButton(
                            onPressed: () {
                              setState(() => selectedStatus = status);
                            },
                            child: Text(
                              status,
                              style: TextStyle(
                                color: active
                                    ? const Color(0xFF00A884)
                                    : const Color(0xFF586062),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: bookingsStream,
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];

                      final filtered = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['status'] ?? '').toString() ==
                            selectedStatus;
                      }).toList();

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text(
                            'No bookings found.',
                            style: TextStyle(
                              color: Color(0xFF586062),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final doc = filtered[index];
                          final data = doc.data() as Map<String, dynamic>;

                          return _BookingCard(
                            docId: doc.id,
                            data: data,
                            onCancel: cancelBooking,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomerBottomNav(activePage: 'bookings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final ValueChanged<String> onCancel;

  const _BookingCard({
    required this.docId,
    required this.data,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final date = data['appointmentDate'];
    String dateText = '';

    if (date is Timestamp) {
      final d = date.toDate();
      dateText = '${d.month}/${d.day}/${d.year}';
    }

    final status = (data['status'] ?? 'Pending').toString();
    final canCancel = status == 'Pending' || status == 'Approved';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data['serviceName'] ?? 'Service',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '₱${data['amount'] ?? 0}',
                style: const TextStyle(
                  color: Color(0xFF00A884),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _StatusPill(status: status),
          const SizedBox(height: 12),
          Text('Type: ${data['serviceCategory'] ?? 'Massage Service'}'),
          Text('Therapist: ${data['staffName'] ?? 'Any available therapist'}'),
          Text('Date: $dateText'),
          Text('Time: ${data['appointmentTime'] ?? ''}'),
          Text('GCash Ref: ${data['gcashReferenceNumber'] ?? 'No reference'}'),
          Text('Downpayment: ₱${data['downpayment'] ?? 0} (${data['downpaymentRate'] ?? 20}%)'),
          if (canCancel) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: () => onCancel(docId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE53935),
                  side: const BorderSide(color: Color(0xFFE53935)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel Booking',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({
    required this.status,
  });

  Color get backgroundColor {
    final value = status.toLowerCase();

    if (value == 'approved') return const Color(0x1A00B894);
    if (value == 'completed') return const Color(0xFFEFF6FF);
    if (value == 'rescheduled') return const Color(0xFFE0F2FE);
    if (value == 'cancelled' || value == 'declined') {
      return const Color(0xFFFFEBEE);
    }

    return const Color(0xFFFFF5CC);
  }

  Color get textColor {
    final value = status.toLowerCase();

    if (value == 'approved') return const Color(0xFF006B55);
    if (value == 'completed') return const Color(0xFF1565C0);
    if (value == 'rescheduled') return const Color(0xFF0369A1);
    if (value == 'cancelled' || value == 'declined') {
      return const Color(0xFFBA1A1A);
    }

    return const Color(0xFF9A6B00);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}