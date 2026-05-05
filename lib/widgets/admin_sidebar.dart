import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/nav_item_model.dart';
import '../models/user_model.dart';
import '../views/super_admin/client_management_page.dart';
import '../views/super_admin/dashboard_page.dart';
import '../views/auth/login_page.dart';
import '../views/super_admin/subscriptions_licenses_page.dart';
import '../views/super_admin/system_performance_page.dart';
import '../views/super_admin/system_settings_page.dart';
import '../views/super_admin/system_reports_page.dart';
import '../views/super_admin/backup_restore_page.dart';
import '../services/auth_service.dart';

class AdminSidebar extends StatelessWidget {
  final UserModel user;
  final String selectedMenu;

  const AdminSidebar({
    super.key,
    required this.user,
    required this.selectedMenu,
  });

  static const List<NavItemModel> navItems = <NavItemModel>[
    NavItemModel(
      icon: Icons.dashboard_outlined,
      title: 'Dashboard',
    ),
    NavItemModel(
      icon: Icons.groups_outlined,
      title: 'Client Management',
    ),
    NavItemModel(
      icon: Icons.workspace_premium_outlined,
      title: 'Subscriptions & Licenses',
    ),
    NavItemModel(
      icon: Icons.show_chart_outlined,
      title: 'View System Performance',
    ),
    NavItemModel(
      icon: Icons.settings_outlined,
      title: 'Configure System Settings',
    ),
    NavItemModel(
      icon: Icons.receipt_long_outlined,
      title: 'View System Reports',
    ),
    NavItemModel(
      icon: Icons.settings_backup_restore_outlined,
      title: 'Backup & Restore',
    ),
  ];

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
                  child: const Icon(Icons.spa, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Serenity M & S',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.primaryContainer,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.role,
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

          ...navItems.map(
                (item) => _AdminSidebarTile(
              item: item,
              user: user,
              isActive: item.title == selectedMenu,
            ),
          ),

          const Spacer(),

          _AdminSidebarTile(
            item: const NavItemModel(
              icon: Icons.logout_outlined,
              title: 'Logout',
            ),
            user: user,
            isActive: false,
            onTap: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
            },
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _AdminSidebarTile extends StatelessWidget {
  final NavItemModel item;
  final UserModel user;
  final bool isActive;
  final VoidCallback? onTap;

  const _AdminSidebarTile({
    required this.item,
    required this.user,
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
              onTap: onTap ?? () => _handleNavigation(context),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(BuildContext context) {
    if (item.title == 'Dashboard') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(user: user),
        ),
      );
    } else if (item.title == 'Client Management') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ClientManagementPage(user: user),
        ),
      );
    } else if (item.title == 'Subscriptions & Licenses') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionsLicensesPage(user: user),
        ),
      );
    } else if (item.title == 'View System Performance') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SystemPerformancePage(user: user),
        ),
      );
    } else if (item.title == 'Configure System Settings') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SystemSettingsPage(user: user),
        ),
      );
    } else if (item.title == 'View System Reports') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SystemReportsPage(user: user),
        ),
      );
    } else if (item.title == 'Backup & Restore') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BackupRestorePage(user: user),
        ),
      );
    }
  }
}