import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PaymentModal extends StatefulWidget {
  final String method;

  const PaymentModal({
    super.key,
    required this.method,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  String? selectedAppointmentId;
  Map<String, dynamic>? selectedAppointment;

  final amountController = TextEditingController();
  final referenceController = TextEditingController();

  bool isSaving = false;

  bool get isGCash => widget.method == 'GCash';

  @override
  void dispose() {
    amountController.dispose();
    referenceController.dispose();
    super.dispose();
  }

  num _toNumber(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  num _totalAmount(Map<String, dynamic> data) {
    return _toNumber(data['amount'] ?? data['total'] ?? data['price'] ?? 0);
  }

  num _paidAmount(Map<String, dynamic> data) {
    return _toNumber(data['paidAmount'] ?? data['downpayment'] ?? 0);
  }

  num _balance(Map<String, dynamic> data) {
    final balance = _totalAmount(data) - _paidAmount(data);
    return balance < 0 ? 0 : balance;
  }

  bool _canCollect(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().toLowerCase();
    final paymentStatus = (data['paymentStatus'] ?? '').toString().toLowerCase();

    final serviceDone = status == 'completed' || status == 'approved';
    final notFullPaid = !paymentStatus.contains('full');

    return serviceDone && notFullPaid && _balance(data) > 0;
  }

  Future<void> savePayment() async {
    if (selectedAppointmentId == null || selectedAppointment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select customer and service.')),
      );
      return;
    }

    if (isGCash && referenceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter reference number.')),
      );
      return;
    }

    final data = selectedAppointment!;
    final amount = _toNumber(amountController.text.trim());

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than zero.')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final total = _totalAmount(data);
      final oldPaid = _paidAmount(data);
      final newPaid = oldPaid + amount;
      final newBalance = total - newPaid;

      await FirebaseFirestore.instance.collection('payments').add({
        'appointmentId': selectedAppointmentId,
        'customerId': data['customerId'] ?? '',
        'customerName': data['customerName'] ?? '',
        'serviceId': data['serviceId'] ?? '',
        'service': data['serviceName'] ?? data['service'] ?? '',
        'serviceName': data['serviceName'] ?? data['service'] ?? '',
        'amount': amount,
        'method': widget.method,
        'paymentMethod': widget.method,
        'referenceNumber': isGCash ? referenceController.text.trim() : '',
        'gcashReferenceNumber': isGCash ? referenceController.text.trim() : '',
        'status': 'Full Payment',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(selectedAppointmentId)
          .update({
        'paidAmount': newPaid,
        'balance': newBalance <= 0 ? 0 : newBalance,
        'paymentStatus': newBalance <= 0 ? 'Full Payment' : 'Partial Payment',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.method} payment recorded.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 620,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 5, color: const Color(0xFF00B894)),
            Padding(
              padding: const EdgeInsets.fromLTRB(44, 34, 44, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isGCash
                              ? 'Confirm GCash Payment'
                              : 'Record Cash Payment',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF161D1F),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a completed service with remaining balance. Amount will auto-fill.',
                    style: TextStyle(
                      color: Color(0xFF586062),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 28),

                  const _Label('SELECT CUSTOMER / SERVICE'),
                  const SizedBox(height: 10),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('appointments')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];

                      final validDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _canCollect(data);
                      }).toList();

                      final dropdownItems = validDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final customer = data['customerName'] ?? 'Customer';
                        final service = data['serviceName'] ?? 'Service';
                        final balance = _balance(data);

                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(
                            '$customer - $service | Balance: ₱${balance.toStringAsFixed(2)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList();

                      final safeValue = dropdownItems.any(
                            (item) => item.value == selectedAppointmentId,
                      )
                          ? selectedAppointmentId
                          : null;

                      return DropdownButtonFormField<String>(
                        value: safeValue,
                        isExpanded: true,
                        decoration: _dropdownDecoration(),
                        items: dropdownItems,
                        onChanged: (value) {
                          if (value == null) return;

                          final doc = validDocs.firstWhere((d) => d.id == value);
                          final data = doc.data() as Map<String, dynamic>;
                          final balance = _balance(data);

                          setState(() {
                            selectedAppointmentId = doc.id;
                            selectedAppointment = data;
                            amountController.text = balance.toStringAsFixed(2);
                          });
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  const _Label('AMOUNT (PHP)'),
                  const SizedBox(height: 10),
                  _AmountField(controller: amountController),

                  if (selectedAppointment != null) ...[
                    const SizedBox(height: 18),
                    _BalanceSummary(data: selectedAppointment!),
                  ],

                  if (isGCash) ...[
                    const SizedBox(height: 24),
                    const _Label('REFERENCE NUMBER'),
                    const SizedBox(height: 10),
                    _InputBox(
                      controller: referenceController,
                      hint: 'Enter GCash reference number',
                    ),
                  ],

                  const SizedBox(height: 34),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: TextButton(
                            onPressed:
                            isSaving ? null : () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF586062),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: isSaving ? null : savePayment,
                            icon: Icon(
                              isGCash
                                  ? Icons.check_circle_outline
                                  : Icons.payments_outlined,
                              size: 18,
                            ),
                            label: Text(
                              isSaving
                                  ? 'Saving...'
                                  : isGCash
                                  ? 'Confirm GCash Payment'
                                  : 'Process Cash Payment',
                            ),
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      hintText: 'Select customer and service',
      filled: true,
      fillColor: const Color(0xFFEEF5F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _BalanceSummary extends StatelessWidget {
  final Map<String, dynamic> data;

  const _BalanceSummary({required this.data});

  num _toNumber(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final total = _toNumber(data['amount']);
    final paid = _toNumber(data['paidAmount'] ?? data['downpayment']);
    final balance = total - paid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0FFF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB6F5DF)),
      ),
      child: Text(
        'Total: ₱${total.toStringAsFixed(2)}    Paid: ₱${paid.toStringAsFixed(2)}    Balance: ₱${balance.toStringAsFixed(2)}',
        style: const TextStyle(
          color: Color(0xFF004233),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF586062),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;

  const _AmountField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        color: Color(0xFF161D1F),
      ),
      decoration: InputDecoration(
        prefixText: '₱  ',
        prefixStyle: const TextStyle(
          color: Color(0xFF006B55),
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
        hintText: '0.00',
        filled: true,
        fillColor: const Color(0xFFE3E9EC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _InputBox({
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFEEF5F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}