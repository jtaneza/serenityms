import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../widgets/client_main_layout.dart';
import 'add_staff_modal.dart';

class ClientStaffPage extends StatelessWidget {
  final UserModel user;

  const ClientStaffPage({
    super.key,
    required this.user,
  });

  Future<void> deleteStaff(BuildContext context, String docId) async {
    await FirebaseFirestore.instance.collection('staff').doc(docId).delete();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Staff member deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClientMainLayout(
      user: user,
      currentRoute: 'staff',
      child: Container(
        color: const Color(0xFFF4FAFD),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('staff')
              .where('isArchived', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 42),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Staff List',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF161D1F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'View and edit your team members.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF586062),
                    ),
                  ),
                  const SizedBox(height: 48),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;

                      return GridView.count(
                        crossAxisCount: isWide ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: isWide ? 1.65 : 1.45,
                        children: [
                          StaffStatCard(
                            title: 'TOTAL PEOPLE',
                            value: '${docs.length}',
                            subtitle: 'Real data',
                            icon: Icons.groups,
                            highlighted: true,
                          ),
                          StaffStatCard(
                            title: 'WORKING NOW',
                            value: '${docs.where((d) {
                              final data = d.data() as Map<String, dynamic>;
                              return (data['status'] ?? 'Active') == 'Active';
                            }).length}',
                            subtitle: 'Active staff',
                            icon: Icons.how_to_reg,
                            highlighted: true,
                          ),
                          StaffStatCard(
                            title: 'TOTAL SERVICES',
                            value: '${docs.fold<int>(
                              0,
                                  (total, d) {
                                final data = d.data() as Map<String, dynamic>;
                                final services =
                                List<String>.from(data['services'] ?? []);
                                return total + services.length;
                              },
                            )}',
                            subtitle: 'Assigned services',
                            icon: Icons.spa_outlined,
                            highlighted: true,
                            greenSubtitle: true,
                          ),
                          StaffStatCard(
                            title: 'AWAY STAFF',
                            value: '${docs.where((d) {
                              final data = d.data() as Map<String, dynamic>;
                              final status = data['status'] ?? 'Active';
                              return status != 'Active';
                            }).length}',
                            subtitle: 'Not available',
                            icon: Icons.person_off_outlined,
                            highlighted: true,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 42),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 26,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Team Directory',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF161D1F),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => AddStaffModal(tenantId: user.tenantId),
                                  );
                                },
                                icon: const Icon(Icons.person_add),
                                label: const Text('Add Staff'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006B55),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          color: const Color(0xFFEEF5F7),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 18,
                          ),
                          child: const Row(
                            children: [
                              Expanded(flex: 3, child: TableHeader('NAME')),
                              Expanded(
                                  flex: 2, child: TableHeader('SPECIALTY')),
                              Expanded(flex: 3, child: TableHeader('SERVICES')),
                              Expanded(flex: 2, child: TableHeader('STATUS')),
                              Expanded(flex: 3, child: TableHeader('SCHEDULE')),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TableHeader('ACTIONS'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          )
                        else if (docs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No staff members yet. Click Add Staff to create one.',
                              style: TextStyle(color: Color(0xFF586062)),
                            ),
                          )
                        else
                          ...docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;

                            return StaffRow(
                              docId: doc.id,
                              data: data,
                              onEdit: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => AddStaffModal(
                                    tenantId: user.tenantId,
                                    docId: doc.id,
                                    staffData: data,
                                  ),
                                );
                              },
                              onDelete: () => deleteStaff(context, doc.id),
                            );
                          }),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 18,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0x11EEF5F7),
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(18),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Showing ${docs.length} staff members',
                                style: const TextStyle(
                                  color: Color(0xFF586062),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class StaffRow extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StaffRow({
    super.key,
    required this.docId,
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'No Name';
    final role = data['role'] ?? 'Staff';
    final specialty = data['specialization'] ?? '';
    final services = List<String>.from(data['services'] ?? []);
    final schedule = data['schedule'] ?? '';
    final status = data['status'] ?? 'Active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEF5F7)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE3E9EC),
                  child: Text(
                    name.toString().isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Color(0xFF006B55),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF161D1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF586062),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              specialty,
              style: const TextStyle(
                color: Color(0xFF006B55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              children: services
                  .map(
                    (service) => Text(
                  service,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3C4A44),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  .toList(),
            ),
          ),
          Expanded(
            flex: 2,
            child: StaffStatusBadge(status: status),
          ),
          Expanded(
            flex: 3,
            child: Text(
              schedule,
              style: const TextStyle(
                color: Color(0xFF3C4A44),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 20),
                  color: const Color(0xFF586062),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: const Color(0xFFBA1A1A),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StaffStatusBadge extends StatelessWidget {
  final String status;

  const StaffStatusBadge({
    super.key,
    required this.status,
  });

  Color get backgroundColor {
    switch (status) {
      case 'Active':
        return const Color(0xFFD8F8EA);
      case 'On Leave':
        return const Color(0xFFFFF3CD);
      case 'Rest Day':
        return const Color(0xFFE3E9EC);
      case 'Away':
        return const Color(0xFFFFE0E0);
      case 'Inactive':
        return const Color(0xFFE9E9E9);
      default:
        return const Color(0xFFE3E9EC);
    }
  }

  Color get textColor {
    switch (status) {
      case 'Active':
        return const Color(0xFF006B55);
      case 'On Leave':
        return const Color(0xFF946200);
      case 'Rest Day':
        return const Color(0xFF586062);
      case 'Away':
        return const Color(0xFFBA1A1A);
      case 'Inactive':
        return const Color(0xFF586062);
      default:
        return const Color(0xFF586062);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
      ),
    );
  }
}

class StaffStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool highlighted;
  final bool greenSubtitle;

  const StaffStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.highlighted = false,
    this.greenSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: highlighted
            ? const Border(
          top: BorderSide(color: Color(0xFF00B894), width: 3),
        )
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B894).withOpacity(0.10),
            blurRadius: 28,
            spreadRadius: 1,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title)),
              Icon(icon, color: const Color(0xFF00B894)),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle),
        ],
      ),
    );
  }
}

class TableHeader extends StatelessWidget {
  final String text;

  const TableHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 2,
        color: Color(0xFF586062),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}