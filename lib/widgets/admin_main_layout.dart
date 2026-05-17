import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'admin_sidebar.dart';
import 'admin_header.dart';
import '../core/app_colors.dart';

class AdminMainLayout extends StatelessWidget {
  final UserModel user;
  final String currentRoute;
  final Widget child;

  const AdminMainLayout({
    super.key,
    required this.user,
    required this.currentRoute,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isDesktop
          ? null
          : SizedBox(
              width: 255,
              child: Drawer(
                child: AdminSidebar(
                  user: user,
                  selectedMenu: currentRoute,
                ),
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDesktop)
            AdminSidebar(
              user: user,
              selectedMenu: currentRoute,
            ),
          Expanded(
            child: Column(
              children: [
                AdminHeader(user: user),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
