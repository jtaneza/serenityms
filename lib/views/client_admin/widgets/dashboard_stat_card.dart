import 'package:flutter/material.dart';

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;

  final String? badgeText;
  final String? badgeSuffix;
  final IconData? badgeIcon;
  final Color? badgeColor;
  final Color? badgeTextColor;

  final double? progressValue;
  final String? footerText;

  final IconData? bottomIcon;
  final String? footerTextGreen;

  final Color? topBorderColor;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    this.badgeText,
    this.badgeSuffix,
    this.badgeIcon,
    this.badgeColor,
    this.badgeTextColor,
    this.progressValue,
    this.footerText,
    this.bottomIcon,
    this.footerTextGreen,
    this.topBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE9EFF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D2D3436),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (topBorderColor != null)
            Positioned(
              top: -26,
              left: -26,
              right: -26,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: topBorderColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
              ),
            ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF586062),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF161D1F),
                  height: 1.1,
                  letterSpacing: -0.4,
                ),
              ),

              const Spacer(),

              if (progressValue != null)
                _ProgressFooter(
                  progressValue: progressValue!,
                  footerText: footerText ?? '',
                )
              else if (badgeText != null)
                _BadgeFooter(
                  badgeText: badgeText!,
                  badgeSuffix: badgeSuffix,
                  badgeIcon: badgeIcon,
                  badgeColor: badgeColor,
                  badgeTextColor: badgeTextColor,
                )
              else if (footerTextGreen != null)
                  _GreenFooter(
                    text: footerTextGreen!,
                    icon: bottomIcon ?? Icons.info_outline,
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressFooter extends StatelessWidget {
  final double progressValue;
  final String footerText;

  const _ProgressFooter({
    required this.progressValue,
    required this.footerText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 6,
            backgroundColor: const Color(0xFFE9EFF2),
            valueColor: const AlwaysStoppedAnimation(
              Color(0xFF006B55),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          footerText,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF586062),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BadgeFooter extends StatelessWidget {
  final String badgeText;
  final String? badgeSuffix;
  final IconData? badgeIcon;
  final Color? badgeColor;
  final Color? badgeTextColor;

  const _BadgeFooter({
    required this.badgeText,
    this.badgeSuffix,
    this.badgeIcon,
    this.badgeColor,
    this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = badgeTextColor ?? const Color(0xFF161D1F);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: badgeColor ?? const Color(0xFFE9EFF2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badgeIcon != null) ...[
                Icon(
                  badgeIcon,
                  size: 14,
                  color: textColor,
                ),
                const SizedBox(width: 4),
              ],

              Text(
                badgeText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),

        if (badgeSuffix != null) ...[
          const SizedBox(width: 10),

          Expanded(
            child: Text(
              badgeSuffix!,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF586062),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _GreenFooter extends StatelessWidget {
  final String text;
  final IconData icon;

  const _GreenFooter({
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF006B55),
        ),

        const SizedBox(width: 6),

        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF006B55),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}