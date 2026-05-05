import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../widgets/client_main_layout.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/recent_activities_card.dart';
import '../widgets/system_performance_card.dart';

class ClientDashboardPage extends StatelessWidget {
  final UserModel user;

  const ClientDashboardPage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return ClientMainLayout(
      user: user,
      currentRoute: 'dashboard',
      child: Container(
        color: const Color(0xFFF4FAFD),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 42),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Operations Overview',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF161D1F),
                  height: 1.1,
                  letterSpacing: -1.2,
                ),
              ),

              const SizedBox(height: 14),

              const SizedBox(
                width: 720,
                child: Text(
                  "Welcome to your business dashboard. Here’s what’s happening at your sanctuary today.",
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF586062),
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const SizedBox(height: 46),

              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth >= 1050;

                  if (isWide) {
                    return const Row(
                      children: [
                        Expanded(
                          child: DashboardStatCard(
                            title: 'Total Appointments',
                            value: '1,284',
                            topBorderColor: Color(0xFF00B894),
                            badgeText: '12.5%',
                            badgeSuffix: 'vs last month',
                            badgeIcon: Icons.trending_up,
                            badgeColor: Color(0xFFE6F5EF),
                            badgeTextColor: Color(0xFF006B55),
                          ),
                        ),

                        SizedBox(width: 24),

                        Expanded(
                          child: DashboardStatCard(
                            title: 'Total Revenue',
                            value: '\$48,290.00',
                            progressValue: 0.72,
                            footerText: '72% of monthly goal',
                          ),
                        ),

                        SizedBox(width: 24),

                        Expanded(
                          child: DashboardStatCard(
                            title: 'Pending Bookings',
                            value: '42',
                            badgeText: 'Needs review',
                            badgeIcon: Icons.priority_high,
                            badgeColor: Color(0xFFFFDAD6),
                            badgeTextColor: Color(0xFFBA1A1A),
                          ),
                        ),

                        SizedBox(width: 24),

                        Expanded(
                          child: DashboardStatCard(
                            title: 'Active Customers',
                            value: '856',
                            footerTextGreen: 'Total network',
                            bottomIcon: Icons.groups_2_outlined,
                          ),
                        ),
                      ],
                    );
                  }

                  return const Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      SizedBox(
                        width: 280,
                        child: DashboardStatCard(
                          title: 'Total Appointments',
                          value: '1,284',
                          topBorderColor: Color(0xFF00B894),
                          badgeText: '12.5%',
                          badgeSuffix: 'vs last month',
                          badgeIcon: Icons.trending_up,
                          badgeColor: Color(0xFFE6F5EF),
                          badgeTextColor: Color(0xFF006B55),
                        ),
                      ),

                      SizedBox(
                        width: 280,
                        child: DashboardStatCard(
                          title: 'Total Revenue',
                          value: '\$48,290.00',
                          progressValue: 0.72,
                          footerText: '72% of monthly goal',
                        ),
                      ),

                      SizedBox(
                        width: 280,
                        child: DashboardStatCard(
                          title: 'Pending Bookings',
                          value: '42',
                          badgeText: 'Needs review',
                          badgeIcon: Icons.priority_high,
                          badgeColor: Color(0xFFFFDAD6),
                          badgeTextColor: Color(0xFFBA1A1A),
                        ),
                      ),

                      SizedBox(
                        width: 280,
                        child: DashboardStatCard(
                          title: 'Active Customers',
                          value: '856',
                          footerTextGreen: 'Total network',
                          bottomIcon: Icons.groups_2_outlined,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 36),

              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth >= 1050;

                  if (isWide) {
                    return const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: SystemPerformanceCard(),
                        ),

                        SizedBox(width: 32),

                        SizedBox(
                          width: 360,
                          child: RecentActivitiesCard(),
                        ),
                      ],
                    );
                  }

                  return const Column(
                    children: [
                      SystemPerformanceCard(),
                      SizedBox(height: 32),
                      RecentActivitiesCard(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}