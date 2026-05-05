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
  final amountController = TextEditingController();
  final customerController = TextEditingController();
  final referenceController = TextEditingController();

  bool isSaving = false;

  bool get isGCash => widget.method == 'GCash';

  @override
  void dispose() {
    amountController.dispose();
    customerController.dispose();
    referenceController.dispose();
    super.dispose();
  }

  Future<void> savePayment() async {
    if (amountController.text.trim().isEmpty ||
        customerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete amount and customer.')),
      );
      return;
    }

    if (isGCash && referenceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter reference number.')),
      );
      return;
    }

    setState(() => isSaving = true);

    await FirebaseFirestore.instance.collection('payments').add({
      'customerName': customerController.text.trim(),
      'service': '',
      'amount': double.tryParse(amountController.text.trim()) ?? 0,
      'method': widget.method,
      'referenceNumber': isGCash ? referenceController.text.trim() : '',
      'status': isGCash ? 'Verified' : 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.method} payment recorded.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: isGCash ? 520 : 620,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 42,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 5, color: const Color(0xFF00B894)),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isGCash ? 34 : 44,
                34,
                isGCash ? 34 : 44,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isGCash
                                  ? 'Confirm GCash Payment'
                                  : 'Record Cash Payment',
                              style: TextStyle(
                                fontSize: isGCash ? 28 : 34,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF161D1F),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isGCash
                                  ? 'Verify and record a digital wallet transaction.'
                                  : 'Manually log a cash transaction into the system.',
                              style: const TextStyle(
                                color: Color(0xFF586062),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),

                  const _Label('AMOUNT (PHP)'),
                  const SizedBox(height: 10),
                  _AmountField(controller: amountController),

                  const SizedBox(height: 28),

                  if (isGCash) ...[
                    const _Label('CUSTOMER NAME'),
                    const SizedBox(height: 10),
                    _InputBox(
                      controller: customerController,
                      hint: 'Enter customer name...',
                    ),
                    const SizedBox(height: 24),
                    const _Label('REFERENCE NUMBER'),
                    const SizedBox(height: 10),
                    _InputBox(
                      controller: referenceController,
                      hint: 'REF-00000000',
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0FFF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFB6F5DF)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Color(0xFF006B55),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ensure the reference number matches exactly as shown on the GCash transaction receipt to prevent reconciliation errors.',
                              style: TextStyle(
                                color: Color(0xFF004233),
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Label('CUSTOMER NAME'),
                              const SizedBox(height: 10),
                              _InputBox(
                                controller: customerController,
                                hint: 'Enter customer name...',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Label('TRANSACTION DATE'),
                              const SizedBox(height: 10),
                              Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF5F7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                      color: Color(0xFF586062),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        DateTime.now()
                                            .toString()
                                            .substring(0, 16),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF586062),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 34),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: TextButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(context),
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
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isSaving
                                    ? 'Saving...'
                                    : isGCash
                                    ? 'Confirm GCash Payment'
                                    : 'Process Cash Payment',
                              ),
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
                              elevation: 8,
                              shadowColor:
                              const Color(0xFF00B894).withOpacity(0.35),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isGCash)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 44,
                  vertical: 22,
                ),
                color: const Color(0xFFEEF5F7),
                child: const Row(
                  children: [
                    Icon(Icons.security, size: 16, color: Color(0x99586062)),
                    SizedBox(width: 10),
                    Text(
                      'SECURE LEDGER ENTRY',
                      style: TextStyle(
                        color: Color(0x99586062),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Spacer(),
                    SizedBox(
                      width: 70,
                      child: Divider(
                        thickness: 4,
                        color: Color(0xFFDDE3E6),
                      ),
                    ),
                  ],
                ),
              ),
          ],
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
        ),
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