import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/nav_item_model.dart';
import '../models/user_model.dart';
import '../screens/client_management_page.dart';
import '../screens/dashboard_page.dart';
import '../screens/login_page.dart';

class AdminSidebar extends StatelessWidget {
  final UserModel user;
  final String selectedMenu;

  const AdminSidebar({
    super.key,
    required this.user,
    required this.selectedMenu,
  });

  static const List<NavItemModel> navItems = <NavItemModel>[
    NavItemModel(icon: Icons.dashboard_outlined, title: 'Dashboard'),
    NavItemModel(icon: Icons.groups_outlined, title: 'Client Management'),
    NavItemModel(icon: Icons.manage_accounts_outlined, title: 'Users & Roles'),
    NavItemModel(icon: Icons.settings_outlined, title: 'System Config'),
    NavItemModel(icon: Icons.monitor_heart_outlined, title: 'Monitoring'),
    NavItemModel(icon: Icons.bar_chart_outlined, title: 'Reports'),
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
                  child: const Icon(Icons.spa, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
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
              isActive: item.title == selectedMenu,
              onTap: () {
                if (item.title == selectedMenu) return;

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
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.title} page not yet built')),
                  );
                }
              },
            ),
          ),
          const Spacer(),
          _AdminSidebarTile(
            item: const NavItemModel(
              icon: Icons.logout_outlined,
              title: 'Logout',
            ),
            isActive: false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
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
  final bool isActive;
  final VoidCallback onTap;

  const _AdminSidebarTile({
    required this.item,
    required this.isActive,
    required this.onTap,
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