import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../routes/route_names.dart';
import '../../../services/auth_service.dart';

import '../appointments/client_appointments_page.dart';
import '../services/client_services_page.dart';
import '../staff/client_staff_page.dart';
import '../payments/client_payments_page.dart';
import '../policy/client_policy_page.dart';
import '../reports/client_reports_page.dart';
import '../dashboard/client_dashboard_page.dart';
import '../settings/client_settings_page.dart';
import '../archive/client_archive_page.dart';

class ClientSidebar extends StatelessWidget {
  final UserModel user;
  final String currentRoute;
  final ValueChanged<String>? onMenuSelected;

  const ClientSidebar({
    super.key,
    required this.user,
    required this.currentRoute,
    this.onMenuSelected,
  });

  static const List<_ClientNavItem> navItems = <_ClientNavItem>[
    _ClientNavItem(
      icon: Icons.dashboard_outlined,
      title: 'Dashboard',
      routeKey: 'dashboard',
    ),
    _ClientNavItem(
      icon: Icons.calendar_month_outlined,
      title: 'Appointments',
      routeKey: 'appointments',
    ),
    _ClientNavItem(
      icon: Icons.medical_services_outlined,
      title: 'Services',
      routeKey: 'services',
    ),
    _ClientNavItem(
      icon: Icons.groups_outlined,
      title: 'Staff',
      routeKey: 'staff',
    ),
    _ClientNavItem(
      icon: Icons.receipt_long_outlined,
      title: 'Payments',
      routeKey: 'payments',
    ),
    _ClientNavItem(
      icon: Icons.policy_outlined,
      title: 'Policy',
      routeKey: 'policy',
    ),
    _ClientNavItem(
      icon: Icons.bar_chart_outlined,
      title: 'Reports',
      routeKey: 'reports',
    ),
    _ClientNavItem(
      icon: Icons.settings_outlined,
      title: 'Settings',
      routeKey: 'settings',
    ),
    _ClientNavItem(
      icon: Icons.archive_outlined,
      title: 'Archive',
      routeKey: 'archive',
    ),
  ];

  void _goToPage(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 255,
      color: AppColors.inverseSurface,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.spa,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.businessName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: const TextStyle(
                          color: AppColors.primaryContainer,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.role,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.sidebarMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),

          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      ...navItems.map(
                            (item) => _ClientSidebarTile(
                          item: item,
                          isActive: item.routeKey == currentRoute,
                          onTap: () {
                            if (item.routeKey == currentRoute) return;

                            if (item.routeKey == 'dashboard') {
                              _goToPage(context, ClientDashboardPage(user: user));
                              return;
                            }
                            if (item.routeKey == 'services') {
                              _goToPage(context, ClientServicesPage(user: user));
                              return;
                            }

                            if (item.routeKey == 'appointments') {
                              _goToPage(context, ClientAppointmentsPage(user: user));
                              return;
                            }

                            if (item.routeKey == 'staff') {
                              _goToPage(context, ClientStaffPage(user: user));
                              return;
                            }

                            if (item.routeKey == 'payments') {
                              _goToPage(context, ClientPaymentsPage(user: user));
                              return;
                            }
                            if (item.routeKey == 'policy') {
                              _goToPage(context, ClientPolicyPage(user: user));
                              return;
                            }
                            if (item.routeKey == 'reports') {
                              _goToPage(context, ClientReportsPage(user: user));
                              return;
                            }
                            if (item.routeKey == 'settings') {
                              _goToPage(context, ClientSettingsPage(user: user));
                            }
                            if (item.routeKey == 'archive') {
                              _goToPage(context, ClientArchivePage(user: user));
                            }
                            if (onMenuSelected != null) {
                              onMenuSelected!(item.routeKey);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ClientSidebarTile(
                        item: const _ClientNavItem(
                          icon: Icons.logout_outlined,
                          title: 'Logout',
                          routeKey: 'logout',
                        ),
                        isActive: false,
                        onTap: () async {
                          await AuthService.logout();

                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              RouteNames.login,
                                  (route) => false,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                    ],
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

class _ClientSidebarTile extends StatelessWidget {
  final _ClientNavItem item;
  final bool isActive;
  final VoidCallback? onTap;

  const _ClientSidebarTile({
    required this.item,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.sidebarActiveBg : Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            color: isActive ? AppColors.primaryContainer : Colors.transparent,
          ),
          Expanded(
            child: ListTile(
              dense: true,
              leading: Icon(
                item.icon,
                size: 22,
                color: isActive
                    ? AppColors.primaryContainer
                    : AppColors.sidebarMuted,
              ),
              title: Text(
                item.title,
                style: TextStyle(
                  color: isActive
                      ? AppColors.primaryContainer
                      : AppColors.sidebarMuted,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientNavItem {
  final IconData icon;
  final String title;
  final String routeKey;

  const _ClientNavItem({
    required this.icon,
    required this.title,
    required this.routeKey,
  });
}