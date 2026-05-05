import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import 'client_sidebar.dart';
import 'client_header.dart';

class ClientMainLayout extends StatelessWidget {
  final UserModel user;
  final String currentRoute;
  final Widget child;

  const ClientMainLayout({
    super.key,
    required this.user,
    required this.currentRoute,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          ClientSidebar(
            user: user,
            currentRoute: currentRoute,
          ),
          Expanded(
            child: Column(
              children: [
                ClientHeader(user: user),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}