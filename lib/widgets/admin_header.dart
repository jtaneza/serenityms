import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/user_model.dart';
import '../views/super_admin/profile_settings_page.dart';

class AdminHeader extends StatelessWidget {
  final UserModel user;

  const AdminHeader({
    super.key,
    required this.user,
  });

  void openNotifications(BuildContext context) {
    final RenderBox overlay =
    Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;

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
            child: _AdminNotificationsPopup(user: user),
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

          IconButton(
            onPressed: () => openNotifications(context),
            tooltip: 'Notifications',
            icon: Stack(
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
            onSelected: (value) {
              if (value == 'profile') {
                ProfileSettingsModal.show(context, user: user);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'profile',
                child: Text('Profile Settings'),
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

class _AdminNotificationsPopup extends StatelessWidget {
  final UserModel user;

  const _AdminNotificationsPopup({
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
                  'System Notifications',
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
                .collection('users')
                .snapshots(),
            builder: (context, snapshot) {
              final users = snapshot.data?.docs ?? [];
              
              final sortedList = users.toList()..sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;

                final aTime = aData['createdAt'];
                final bTime = bData['createdAt'];

                if (aTime is Timestamp && bTime is Timestamp) {
                  return bTime.compareTo(aTime);
                }
                return 0;
              });

              final docs = sortedList.take(15).toList();

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 34),
                  child: Text(
                    'No system notifications yet.',
                    style: TextStyle(color: AppColors.secondary),
                  ),
                );
              }

              return Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    final name = data['fullName'] ?? 'System User';
                    final role = data['role'] ?? 'User';

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor:
                        AppColors.primary.withValues(alpha: 0.12),
                        child: const Icon(
                          Icons.person_add_alt_1_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        'New $role registration',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        name,
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
}