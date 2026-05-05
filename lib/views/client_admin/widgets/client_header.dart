import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../routes/route_names.dart';
import '../../../services/auth_service.dart';

class ClientHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onSettingsTap;

  const ClientHeader({
    super.key,
    required this.user,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      color: AppColors.surface.withValues(alpha: 0.90),
      child: Row(
        children: [
          const Spacer(),

          Stack(
            children: [
              const Icon(
                Icons.notifications_none,
                color: AppColors.secondary,
                size: 24,
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 22),

          Container(
            width: 1,
            height: 32,
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),

          const SizedBox(width: 16),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                user.fullName,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.role,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: AppColors.primaryContainer.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
              size: 20,
            ),
          ),

          PopupMenuButton<String>(
            tooltip: '',
            offset: const Offset(0, 42),
            onSelected: (value) async {
              if (value == 'settings') {
                if (onSettingsTap != null) {
                  onSettingsTap!();
                }
              } else if (value == 'logout') {
                await AuthService.logout();

                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    RouteNames.login,
                        (route) => false,
                  );
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings'),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.secondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}