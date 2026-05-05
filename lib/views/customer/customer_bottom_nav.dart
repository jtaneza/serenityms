import 'package:flutter/material.dart';

import 'customer_dashboard_page.dart';
import 'customer_services_page.dart';
import 'customer_book_page.dart';
import 'customer_profile_page.dart';

class CustomerBottomNav extends StatelessWidget {
  final String activePage;

  const CustomerBottomNav({
    super.key,
    required this.activePage,
  });

  void _goTo(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 26,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            active: activePage == 'home',
            onTap: () => _goTo(context, const CustomerDashboardPage()),
          ),
          _BottomNavItem(
            icon: Icons.spa_outlined,
            label: 'Services',
            active: activePage == 'services',
            onTap: () => _goTo(context, const CustomerServicesPage()),
          ),
          _BottomNavItem(
            icon: Icons.calendar_month_rounded,
            label: 'Book',
            active: activePage == 'book',
            onTap: () => _goTo(context, const CustomerBookPage()),
          ),
          _BottomNavItem(
            icon: Icons.event_note_outlined,
            label: 'Bookings',
            active: activePage == 'bookings',
            onTap: () => _goTo(context, const CustomerBookingsPage()),
          ),
          _BottomNavItem(
            icon: Icons.account_circle_outlined,
            label: 'Profile',
            active: activePage == 'profile',
            onTap: () => _goTo(context, const CustomerProfilePage()),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF00A884) : const Color(0xFF8A9AAD);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 5),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}