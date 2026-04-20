import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_sidebar.dart';

class AdminLayout extends StatelessWidget {
  final UserModel user;
  final String selectedMenu;
  final Widget child;

  const AdminLayout({
    super.key,
    required this.user,
    required this.selectedMenu,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(
            user: user,
            selectedMenu: selectedMenu,
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