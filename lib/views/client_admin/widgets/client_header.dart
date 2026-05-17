import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../models/user_model.dart';
import '../settings/client_settings_page.dart';

class ClientHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onSettingsTap;

  const ClientHeader({
    super.key,
    required this.user,
    this.onSettingsTap,
  });

  void openSettings(BuildContext context) {
    if (onSettingsTap != null) {
      onSettingsTap!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientSettingsPage(user: user),
      ),
    );
  }

  void openNotifications(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
    Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;

    final Offset position = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        overlay.size.width - 330,
        72,
        24,
        0,
      ),
      color: Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: 310,
            child: _NotificationsPopup(user: user),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      color: AppColors.surface.withValues(alpha: 0.90),
      child: Row(
        children: [
          if (MediaQuery.of(context).size.width < 900)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: const Icon(Icons.menu, color: AppColors.onSurface),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          const Spacer(),

          InkWell(
            onTap: () => openNotifications(context),
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.notifications_none,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
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

          InkWell(
            onTap: () => openSettings(context),
            borderRadius: BorderRadius.circular(19),
            child: Container(
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
          ),

          PopupMenuButton<String>(
            tooltip: '',
            offset: const Offset(0, 42),
            onSelected: (value) {
              if (value == 'settings') {
                openSettings(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings'),
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

class _NotificationsPopup extends StatelessWidget {
  final UserModel user;

  const _NotificationsPopup({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      constraints: const BoxConstraints(maxHeight: 520),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: AppColors.primary,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              final notifications = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status =
                (data['status'] ?? '').toString().toLowerCase();

                return status == 'approved' ||
                    status == 'declined' ||
                    status == 'cancelled' ||
                    status == 'rescheduled' ||
                    status == 'completed';
              }).toList();

              notifications.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;

                final aTime = aData['updatedAt'] ?? aData['createdAt'];
                final bTime = bData['updatedAt'] ?? bData['createdAt'];

                if (aTime is Timestamp && bTime is Timestamp) {
                  return bTime.compareTo(aTime);
                }

                return 0;
              });

              if (notifications.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 34),
                  child: Text(
                    'No notifications yet.',
                    style: TextStyle(color: AppColors.secondary),
                  ),
                );
              }

              return Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data =
                    notifications[index].data() as Map<String, dynamic>;

                    final customer = data['customerName'] ?? 'Customer';
                    final service = data['serviceName'] ?? 'Service';
                    final status = data['status'] ?? 'Updated';

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor:
                        AppColors.primary.withValues(alpha: 0.12),
                        child: Icon(
                          _statusIcon(status),
                          color: _statusColor(status),
                        ),
                      ),
                      title: Text(
                        '${_capitalize(status)} appointment',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '$customer • $service',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.secondary,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _capitalize(dynamic value) {
    final text = value.toString();
    if (text.isEmpty) return 'Updated';

    return text[0].toUpperCase() + text.substring(1);
  }

  static IconData _statusIcon(dynamic status) {
    final value = status.toString().toLowerCase();

    if (value == 'approved') return Icons.check_circle_outline;
    if (value == 'declined' || value == 'cancelled') {
      return Icons.cancel_outlined;
    }
    if (value == 'rescheduled') return Icons.event_repeat_outlined;
    if (value == 'completed') return Icons.done_all_outlined;

    return Icons.notifications_none;
  }

  static Color _statusColor(dynamic status) {
    final value = status.toString().toLowerCase();

    if (value == 'approved' || value == 'completed') {
      return AppColors.primary;
    }

    if (value == 'declined' || value == 'cancelled') {
      return Colors.red;
    }

    if (value == 'rescheduled') {
      return Colors.blue;
    }

    return AppColors.secondary;
  }
}