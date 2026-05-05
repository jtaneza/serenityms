import 'package:flutter/material.dart';
import '../models/user_model.dart';

import '../views/auth/login_page.dart';

/// SUPER ADMIN
import '../views/super_admin/dashboard_page.dart';
import '../views/super_admin/client_management_page.dart';
import '../views/super_admin/subscriptions_licenses_page.dart';
import '../views/super_admin/system_performance_page.dart';
import '../views/super_admin/system_settings_page.dart';
import '../views/super_admin/system_reports_page.dart';
import '../views/super_admin/backup_restore_page.dart';

/// CLIENT ADMIN
import '../views/client_admin/dashboard/client_dashboard_page.dart';
import '../views/client_admin/client_first_setup_page.dart';

import 'route_names.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final Object? args = settings.arguments;

    switch (settings.name) {
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

    // ================= SUPER ADMIN =================
      case RouteNames.superAdminDashboard:
        return MaterialPageRoute(
          builder: (_) => DashboardPage(user: args as UserModel),
        );

      case RouteNames.clientManagement:
        return MaterialPageRoute(
          builder: (_) => ClientManagementPage(user: args as UserModel),
        );

      case RouteNames.subscriptionsLicenses:
        return MaterialPageRoute(
          builder: (_) => SubscriptionsLicensesPage(user: args as UserModel),
        );

      case RouteNames.systemPerformance:
        return MaterialPageRoute(
          builder: (_) => SystemPerformancePage(user: args as UserModel),
        );

      case RouteNames.systemSettings:
        return MaterialPageRoute(
          builder: (_) => SystemSettingsPage(user: args as UserModel),
        );

      case RouteNames.systemReports:
        return MaterialPageRoute(
          builder: (_) => SystemReportsPage(user: args as UserModel),
        );

      case RouteNames.backupRestore:
        return MaterialPageRoute(
          builder: (_) => BackupRestorePage(user: args as UserModel),
        );

    // ================= CLIENT ADMIN =================
      case RouteNames.clientDashboard:
        return MaterialPageRoute(
          builder: (_) => ClientDashboardPage(user: args as UserModel),
        );

      case RouteNames.clientFirstSetup:
        return MaterialPageRoute(
          builder: (_) => ClientFirstSetupPage(user: args as UserModel),
        );

      default:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}