import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/user_model.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/admin_header.dart';

class SubscriptionsLicensesPage extends StatelessWidget {
  final UserModel user;

  const SubscriptionsLicensesPage({
    super.key,
    required this.user,
  });

  static const List<LicenseModel> licenses = [
    LicenseModel(
      clientName: 'Harbor Health Group',
      clientId: 'HHG-4402',
      plan: 'Yearly Gold',
      expiryDate: 'Dec 14, 2024',
      status: LicenseStatus.active,
    ),
    LicenseModel(
      clientName: 'Summit Wellness Center',
      clientId: 'SWC-9912',
      plan: 'Monthly Silver',
      expiryDate: 'Oct 28, 2023',
      status: LicenseStatus.expired,
    ),
    LicenseModel(
      clientName: 'NeoDynamics Clinic',
      clientId: 'NDC-0128',
      plan: 'Lifetime Platinum',
      expiryDate: 'Never',
      status: LicenseStatus.pending,
    ),
    LicenseModel(
      clientName: 'Tranquil Oasis Spa',
      clientId: 'TOS-5581',
      plan: 'Yearly Bronze',
      expiryDate: 'Jan 20, 2025',
      status: LicenseStatus.active,
    ),
    LicenseModel(
      clientName: 'Blissful Touch Wellness',
      clientId: 'BTW-3309',
      plan: 'Monthly Silver',
      expiryDate: 'Feb 15, 2024',
      status: LicenseStatus.pending,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          AdminSidebar(
            user: user,
            selectedMenu: 'Subscriptions & Licenses',
          ),
          Expanded(
            child: Column(
              children: [
                AdminHeader(user: user),
                const Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(40, 36, 40, 32),
                    child: _SubscriptionContent(),
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

enum LicenseStatus { active, expired, pending }

class LicenseModel {
  final String clientName;
  final String clientId;
  final String plan;
  final String expiryDate;
  final LicenseStatus status;

  const LicenseModel({
    required this.clientName,
    required this.clientId,
    required this.plan,
    required this.expiryDate,
    required this.status,
  });
}

class _SubscriptionContent extends StatelessWidget {
  const _SubscriptionContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderSection(),
        SizedBox(height: 60),
        _PlansSection(),
        SizedBox(height: 60),
        _LicenseAndPaymentSection(),
        SizedBox(height: 50),
        Center(
          child: Text(
            '© 2023 Serenity Management Systems. Professional License Management Console.',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
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
          'Subscriptions & Licenses',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 48,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Manage and set up access for different institutions.',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PlansSection extends StatelessWidget {
  const _PlansSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.payments_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text(
              'Available Plans',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 28),
        const Row(
          children: [
            Expanded(
              child: _PlanCard(
                tier: 'GOLD TIER',
                name: 'Yearly',
                price: '1,800',
                suffix: '/yr',
                buttonText: 'Manage Plan',
                popular: true,
              ),
            ),
            SizedBox(width: 28),
            Expanded(
              child: _PlanCard(
                tier: 'PLATINUM TIER',
                name: 'Lifetime',
                price: '9,500',
                suffix: '',
                buttonText: 'Edit Details',
                popular: false,
              ),
            ),
            SizedBox(width: 28),
            Expanded(child: _CustomTierCard()),
          ],
        ),
      ],
    );
  }
}


class _PlanCard extends StatelessWidget {
  final String tier;
  final String name;
  final String price;
  final String suffix;
  final String buttonText;
  final bool popular;

  const _PlanCard({
    required this.tier,
    required this.name,
    required this.price,
    required this.suffix,
    required this.buttonText,
    required this.popular,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          top: BorderSide(
            color: popular ? AppColors.primary : AppColors.primaryContainer,
            width: popular ? 4 : 2,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(45, 52, 54, 0.05),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (popular)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tier,
                style: TextStyle(
                  color: popular ? AppColors.primary : AppColors.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 9),
                    child: Text(
                      '\$',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    price,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  if (suffix.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Text(
                        suffix,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Container(
                height: 46,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: popular ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: popular
                      ? null
                      : Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Center(
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      color: popular ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomTierCard extends StatelessWidget {
  const _CustomTierCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.50),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: AppColors.secondary),
            ),
            const SizedBox(height: 18),
            const Text(
              'Define Custom Tier',
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LicenseAndPaymentSection extends StatelessWidget {
  const _LicenseAndPaymentSection();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _LicenseTableSection()),
        SizedBox(width: 44),
        Expanded(child: _RightPanel()),
      ],
    );
  }
}

class _LicenseTableSection extends StatelessWidget {
  const _LicenseTableSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          children: [
            Icon(Icons.verified, color: AppColors.primary),
            SizedBox(width: 12),
            Text(
              'Active Client Licenses',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            Spacer(),
            _TotalChip(),
          ],
        ),
        const SizedBox(height: 26),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
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
              const _LicenseTableHeader(),
              ...SubscriptionsLicensesPage.licenses.map(
                    (license) => _LicenseRow(license: license),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        '5 TOTAL',
        style: TextStyle(
          color: AppColors.secondary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LicenseTableHeader extends StatelessWidget {
  const _LicenseTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderText('CLIENT NAME')),
          Expanded(flex: 2, child: _HeaderText('PLAN')),
          Expanded(flex: 2, child: _HeaderText('EXPIRY DATE')),
          Expanded(flex: 2, child: _HeaderText('STATUS')),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: _HeaderText('ACTIONS'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LicenseRow extends StatelessWidget {
  final LicenseModel license;

  const _LicenseRow({
    required this.license,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.surfaceContainer),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  license.clientName,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${license.clientId}',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              license.plan,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              license.expiryDate,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _LicenseStatusBadge(status: license.status),
          ),
          const Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: _LicenseActions(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;

  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.secondary,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _LicenseStatusBadge extends StatelessWidget {
  final LicenseStatus status;

  const _LicenseStatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color textColor;
    late final Color bgColor;

    switch (status) {
      case LicenseStatus.active:
        label = 'ACTIVE';
        textColor = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.12);
        break;
      case LicenseStatus.expired:
        label = 'EXPIRED';
        textColor = AppColors.error;
        bgColor = AppColors.errorContainer;
        break;
      case LicenseStatus.pending:
        label = 'PENDING';
        textColor = AppColors.secondary;
        bgColor = AppColors.surfaceContainerHigh;
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _LicenseActions extends StatelessWidget {
  const _LicenseActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.edit, color: AppColors.secondary, size: 20),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.archive, color: AppColors.secondary, size: 20),
        ),
      ],
    );
  }
}

class _RightPanel extends StatelessWidget {
  const _RightPanel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _RecentPaymentsSection(),
        SizedBox(height: 28),
        _RevenueGrowthCard(),
      ],
    );
  }
}

class _RecentPaymentsSection extends StatelessWidget {
  const _RecentPaymentsSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Icon(Icons.history, color: AppColors.primary),
            SizedBox(width: 12),
            Text(
              'Recent Payments',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SizedBox(height: 26),
        _PaymentsCard(),
      ],
    );
  }
}

class _PaymentsCard extends StatelessWidget {
  const _PaymentsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(45, 52, 54, 0.05),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        children: [
          _PaymentItem(
            icon: Icons.credit_card,
            amount: '\$1,800.00',
            method: 'Visa • Oct 12, 2023',
          ),
          SizedBox(height: 24),
          _PaymentItem(
            icon: Icons.account_balance,
            amount: '\$199.00',
            method: 'Bank Transfer • Oct 09, 2023',
          ),
          SizedBox(height: 24),
          _PaymentItem(
            icon: Icons.payments,
            amount: '\$9,500.00',
            method: 'Wire • Oct 01, 2023',
          ),
          SizedBox(height: 24),
          Text(
            'View History',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final IconData icon;
  final String amount;
  final String method;

  const _PaymentItem({
    required this.icon,
    required this.amount,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                method,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.outlineVariant),
      ],
    );
  }
}

class _RevenueGrowthCard extends StatelessWidget {
  const _RevenueGrowthCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.inverseSurface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(45, 52, 54, 0.12),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: const Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revenue Growth',
                style: TextStyle(
                  color: AppColors.primaryContainer,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '+12.4%',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Increase in renewals compared to last month.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(
              Icons.trending_up,
              color: Colors.white12,
              size: 90,
            ),
          ),
        ],
      ),
    );
  }
}