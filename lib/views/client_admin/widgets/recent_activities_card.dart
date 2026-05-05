import 'package:flutter/material.dart';

class RecentActivitiesCard extends StatelessWidget {
  const RecentActivitiesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 560,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EFF2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDDE3E6),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D2D3436),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF161D1F),
            ),
          ),

          const SizedBox(height: 30),

          const ActivityItem(
            icon: Icons.event_available_outlined,
            iconBg: Color(0x1A006B55),
            iconColor: Color(0xFF006B55),
            title: 'New appointment booked',
            subtitle: 'Thai Massage - 2:00 PM today',
            time: '2 MINS AGO',
          ),

          const SizedBox(height: 24),

          const ActivityItem(
            icon: Icons.payments_outlined,
            iconBg: Color(0x1A00B894),
            iconColor: Color(0xFF006B55),
            title: 'Payment received',
            subtitle: 'Invoice #89221 - \$120.00',
            time: '45 MINS AGO',
          ),

          const SizedBox(height: 24),

          const ActivityItem(
            icon: Icons.person_add_alt_1_outlined,
            iconBg: Color(0xFFE3E9EC),
            iconColor: Color(0xFF586062),
            title: 'New customer profile created',
            subtitle: 'Sarah J. Jenkins',
            time: '2 HOURS AGO',
          ),

          const SizedBox(height: 24),

          const ActivityItem(
            icon: Icons.edit_calendar_outlined,
            iconBg: Color(0xFFE3E9EC),
            iconColor: Color(0xFF586062),
            title: 'Staff schedule updated',
            subtitle: "Dr. Elena's shift adjusted",
            time: 'YESTERDAY',
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF006B55),
                side: const BorderSide(
                  color: Color(0x33006B55),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'View Full Audit Log',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  const ActivityItem({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF161D1F),
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF586062),
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                time,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6C7A74),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}