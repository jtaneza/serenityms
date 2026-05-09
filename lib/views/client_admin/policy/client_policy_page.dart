import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../widgets/client_main_layout.dart';

class ClientPolicyPage extends StatefulWidget {
  final UserModel user;

  const ClientPolicyPage({
    super.key,
    required this.user,
  });

  @override
  State<ClientPolicyPage> createState() => _ClientPolicyPageState();
}

class _ClientPolicyPageState extends State<ClientPolicyPage> {
  double depositPercent = 20;
  int noticeHours = 24;
  bool chargeNoShows = true;
  String lateFeeType = 'percentage';

  final fullRefundController = TextEditingController();
  final partialRefundController = TextEditingController();
  final noRefundController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  DocumentReference<Map<String, dynamic>> get ruleRef {
    return FirebaseFirestore.instance
        .collection('booking_rules')
        .doc(widget.user.tenantId);
  }
  @override
  void initState() {
    super.initState();
    loadRules();
  }

  @override
  void dispose() {
    fullRefundController.dispose();
    partialRefundController.dispose();
    noRefundController.dispose();
    super.dispose();
  }

  Future<void> loadRules() async {
    try {
      final doc = await ruleRef.get();

      if (doc.exists) {
        final data = doc.data() ?? {};

        depositPercent = ((data['depositPercent'] ?? 20) as num).toDouble();
        noticeHours = ((data['noticeHours'] ?? 24) as num).toInt();
        chargeNoShows = data['chargeNoShows'] ?? true;
        lateFeeType = data['lateFeeType'] ?? 'percentage';

        fullRefundController.text = data['fullRefundRule'] ??
            'If a customer cancels more than 48 hours before their visit, they get all their money back.';

        partialRefundController.text = data['partialRefundRule'] ??
            'If a customer cancels between 24 and 48 hours before their visit, they get half of their deposit back as credit.';

        noRefundController.text = data['noRefundRule'] ??
            'If a customer cancels with less than 24 hours notice or does not show up, they lose their whole deposit.';
      } else {
        fullRefundController.text =
        'If a customer cancels more than 48 hours before their visit, they get all their money back.';
        partialRefundController.text =
        'If a customer cancels between 24 and 48 hours before their visit, they get half of their deposit back as credit.';
        noRefundController.text =
        'If a customer cancels with less than 24 hours notice or does not show up, they lose their whole deposit.';
      }
    } catch (e) {
      fullRefundController.text =
      'If a customer cancels more than 48 hours before their visit, they get all their money back.';
      partialRefundController.text =
      'If a customer cancels between 24 and 48 hours before their visit, they get half of their deposit back as credit.';
      noRefundController.text =
      'If a customer cancels with less than 24 hours notice or does not show up, they lose their whole deposit.';
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> saveRules() async {
    setState(() => isSaving = true);

    try {
      await ruleRef.set({
        'depositPercent': depositPercent.round(),
        'noticeHours': noticeHours,
        'chargeNoShows': chargeNoShows,
        'lateFeeType': lateFeeType,
        'fullRefundRule': fullRefundController.text.trim(),
        'partialRefundRule': partialRefundController.text.trim(),
        'noRefundRule': noRefundController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': widget.user.businessName,
        'updatedByRole': widget.user.role,
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking rules saved.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClientMainLayout(
      user: widget.user,
      currentRoute: 'policy',
      child: Container(
        color: const Color(0xFFF4FAFD),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 40, vertical: 42),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Booking & Payment Rules',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF161D1F),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Set how customers book, pay, cancel, and receive refund notices.',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF586062),
                ),
              ),
              const SizedBox(height: 42),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: _DepositCard(
                      depositPercent: depositPercent,
                      lateFeeType: lateFeeType,
                      onDepositChanged: (value) {
                        setState(() => depositPercent = value);
                      },
                      onFeeTypeChanged: (value) {
                        setState(() => lateFeeType = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 5,
                    child: _LateCancellationCard(
                      noticeHours: noticeHours,
                      chargeNoShows: chargeNoShows,
                      onNoticeChanged: (value) {
                        setState(() => noticeHours = value);
                      },
                      onNoShowChanged: (value) {
                        setState(() => chargeNoShows = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _RefundRulesCard(
                fullRefundController: fullRefundController,
                partialRefundController: partialRefundController,
                noRefundController: noRefundController,
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    isSaving
                        ? 'Saving...'
                        : 'Deposit: ${depositPercent.round()}% • Notice: $noticeHours hrs',
                    style: const TextStyle(
                      color: Color(0xFF586062),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    height: 58,
                    width: 190,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : saveRules,
                      icon: const Icon(Icons.save),
                      label: Text(isSaving ? 'Saving...' : 'Save Rules'),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _DepositCard extends StatelessWidget {
  final double depositPercent;
  final String lateFeeType;
  final ValueChanged<double> onDepositChanged;
  final ValueChanged<String> onFeeTypeChanged;

  const _DepositCard({
    required this.depositPercent,
    required this.lateFeeType,
    required this.onDepositChanged,
    required this.onFeeTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _PolicyCard(
      topBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: _CardHeading(
                  title: 'Booking Deposits',
                  subtitle: 'Charge customers a fee to hold their spot.',
                ),
              ),
              Icon(
                Icons.payments_outlined,
                color: Color(0x6600B894),
                size: 40,
              ),
            ],
          ),
          const SizedBox(height: 34),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DEPOSIT AMOUNT',
                  style: TextStyle(
                    color: Color(0xFF586062),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E9EC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${depositPercent.round()}%',
                  style: const TextStyle(
                    color: Color(0xFF006B55),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Slider(
            min: 0,
            max: 100,
            value: depositPercent,
            activeColor: const Color(0xFF00B894),
            inactiveColor: const Color(0xFFE3E9EC),
            onChanged: onDepositChanged,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Text(
                  '0% (NO DEPOSIT)',
                  style: TextStyle(
                    color: Color(0xFF6C7A74),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Spacer(),
                Text(
                  '100% (PAY IN FULL)',
                  style: TextStyle(
                    color: Color(0xFF6C7A74),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'LATE CANCELLATION FEE',
            style: TextStyle(
              color: Color(0xFF586062),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _TypeButton(
                  active: lateFeeType == 'percentage',
                  icon: Icons.percent,
                  label: 'Percentage',
                  onTap: () => onFeeTypeChanged('percentage'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TypeButton(
                  active: lateFeeType == 'fixed',
                  icon: Icons.payments_outlined,
                  label: '₱ Set Amount',
                  onTap: () => onFeeTypeChanged('fixed'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LateCancellationCard extends StatelessWidget {
  final int noticeHours;
  final bool chargeNoShows;
  final ValueChanged<int> onNoticeChanged;
  final ValueChanged<bool> onNoShowChanged;

  const _LateCancellationCard({
    required this.noticeHours,
    required this.chargeNoShows,
    required this.onNoticeChanged,
    required this.onNoShowChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: noticeHours.toString());

    return _PolicyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Late Cancellations',
                  style: TextStyle(
                    color: Color(0xFF161D1F),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.timer_off_outlined,
                color: Color(0x6600B894),
                size: 34,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'NOTICE NEEDED (HOURS)',
            style: TextStyle(
              color: Color(0xFF586062),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              onNoticeChanged(int.tryParse(value) ?? 24);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFEEF5F7),
              suffixText: 'hrs',
              suffixStyle: const TextStyle(
                color: Color(0xFF586062),
                fontWeight: FontWeight.w700,
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 34),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Charge No-Shows',
                        style: TextStyle(
                          color: Color(0xFF161D1F),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Bill people who do not show up',
                        style: TextStyle(
                          color: Color(0xFF586062),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: chargeNoShows,
                  activeColor: const Color(0xFF00B894),
                  onChanged: onNoShowChanged,
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            'New rules will only affect bookings made from now on.',
            style: TextStyle(
              color: Color(0x99586062),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefundRulesCard extends StatelessWidget {
  final TextEditingController fullRefundController;
  final TextEditingController partialRefundController;
  final TextEditingController noRefundController;

  const _RefundRulesCard({
    required this.fullRefundController,
    required this.partialRefundController,
    required this.noRefundController,
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
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _RefundColumn(
              icon: Icons.check_circle_outline,
              iconColor: const Color(0xFF006B55),
              iconBg: const Color(0xFFE8F5F1),
              title: 'Full Refund',
              controller: fullRefundController,
            ),
          ),
          Container(width: 1, height: 270, color: const Color(0xFFE9EFF2)),
          Expanded(
            child: _RefundColumn(
              icon: Icons.adjust,
              iconColor: const Color(0xFF586062),
              iconBg: const Color(0xFFE3E9EC),
              title: 'Half Refund',
              controller: partialRefundController,
            ),
          ),
          Container(width: 1, height: 270, color: const Color(0xFFE9EFF2)),
          Expanded(
            child: _RefundColumn(
              icon: Icons.cancel_outlined,
              iconColor: const Color(0xFFBA1A1A),
              iconBg: const Color(0xFFFFDAD6),
              title: 'No Refund',
              controller: noRefundController,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefundColumn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final TextEditingController controller;

  const _RefundColumn({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270,
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF161D1F),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'HOW IT WORKS',
            style: TextStyle(
              color: Color(0xFF586062),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFEEF5F7),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: const TextStyle(
                color: Color(0xFF3C4A44),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final Widget child;
  final bool topBorder;

  const _PolicyCard({
    required this.child,
    this.topBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: topBorder
            ? const Border(
          top: BorderSide(color: Color(0xFF00B894), width: 2),
        )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CardHeading({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF161D1F),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF586062),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TypeButton({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor:
          active ? const Color(0xFF006B55) : const Color(0xFFE9EFF2),
          foregroundColor: active ? Colors.white : const Color(0xFF586062),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}