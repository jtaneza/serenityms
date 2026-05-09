import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/user_model.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/admin_sidebar.dart';

class SubscriptionsLicensesPage extends StatelessWidget {
  final UserModel user;

  const SubscriptionsLicensesPage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          AdminSidebar(
            user: user,
            selectedMenu: 'Subscriptions & Licenses',
          ),
          Expanded(
            child: Column(
              children: [
                AdminHeader(user: user),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(40, 36, 40, 32),
                    child: _SubscriptionContent(user: user),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionContent extends StatelessWidget {
  final UserModel user;

  const _SubscriptionContent({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeaderSection(),
        const SizedBox(height: 60),
        _PlansSection(user: user),
        const SizedBox(height: 60),
        _LicenseAndPaymentSection(user: user),
        const SizedBox(height: 50),
        const Center(
          child: Text(
            '© 2023 Serenity Management Systems. Professional License Management Console.',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscriptions & Licenses',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 48,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Manage and set up access for different institutions.',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PlansSection extends StatelessWidget {
  final UserModel user;

  const _PlansSection({
    required this.user,
  });

  CollectionReference<Map<String, dynamic>> get plansRef =>
      FirebaseFirestore.instance.collection('subscription_plans');

  Future<void> seedDefaultPlans() async {
    final snap = await plansRef.limit(1).get();

    if (snap.docs.isNotEmpty) return;

    await plansRef.add({
      'tier': 'GOLD TIER',
      'name': 'Yearly',
      'price': 1800,
      'suffix': '/yr',
      'buttonText': 'Manage Plan',
      'popular': true,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': user.uid,
    });

    await plansRef.add({
      'tier': 'PLATINUM TIER',
      'name': 'Lifetime',
      'price': 9500,
      'suffix': '',
      'buttonText': 'Edit Details',
      'popular': false,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': user.uid,
    });
  }

  void openPlanDialog(
      BuildContext context, {
        String? docId,
        Map<String, dynamic>? data,
      }) {
    final tierController = TextEditingController(
      text: data?['tier']?.toString() ?? '',
    );
    final nameController = TextEditingController(
      text: data?['name']?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: data?['price']?.toString() ?? '',
    );
    final suffixController = TextEditingController(
      text: data?['suffix']?.toString() ?? '',
    );

    bool popular = data?['popular'] == true;
    bool isActive = data?['isActive'] != false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(docId == null ? 'Add Subscription Plan' : 'Edit Plan'),
            content: SizedBox(
              width: 430,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DialogField(controller: tierController, label: 'Tier'),
                  _DialogField(controller: nameController, label: 'Plan Name'),
                  _DialogField(controller: priceController, label: 'Price'),
                  _DialogField(
                    controller: suffixController,
                    label: 'Suffix',
                    hint: '/yr or empty',
                  ),
                  SwitchListTile(
                    value: popular,
                    onChanged: (value) {
                      setDialogState(() => popular = value);
                    },
                    title: const Text('Popular Plan'),
                  ),
                  SwitchListTile(
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() => isActive = value);
                    },
                    title: const Text('Active'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final price =
                      double.tryParse(priceController.text.trim()) ?? 0;

                  final payload = {
                    'tier': tierController.text.trim(),
                    'name': nameController.text.trim(),
                    'price': price,
                    'suffix': suffixController.text.trim(),
                    'buttonText': docId == null ? 'Manage Plan' : 'Edit Details',
                    'popular': popular,
                    'isActive': isActive,
                    'updatedAt': FieldValue.serverTimestamp(),
                    'updatedBy': user.uid,
                  };

                  if (docId == null) {
                    await plansRef.add({
                      ...payload,
                      'createdAt': FieldValue.serverTimestamp(),
                      'createdBy': user.uid,
                    });
                  } else {
                    await plansRef.doc(docId).update(payload);
                  }

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    seedDefaultPlans();

    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.payments_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text(
              'Available Plans',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 28),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: plansRef.where('isActive', isEqualTo: true).snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            return Row(
              children: [
                ...docs.take(2).map((doc) {
                  final data = doc.data();

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 28),
                      child: _PlanCard(
                        tier: data['tier']?.toString() ?? 'PLAN',
                        name: data['name']?.toString() ?? 'Plan',
                        price: _money(data['price']),
                        suffix: data['suffix']?.toString() ?? '',
                        buttonText: data['buttonText']?.toString() ?? 'Edit',
                        popular: data['popular'] == true,
                        onTap: () => openPlanDialog(
                          context,
                          docId: doc.id,
                          data: data,
                        ),
                      ),
                    ),
                  );
                }),
                Expanded(
                  child: _CustomTierCard(
                    onTap: () => openPlanDialog(context),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _money(dynamic value) {
    final amount = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String tier;
  final String name;
  final String price;
  final String suffix;
  final String buttonText;
  final bool popular;
  final VoidCallback onTap;

  const _PlanCard({
    required this.tier,
    required this.name,
    required this.price,
    required this.suffix,
    required this.buttonText,
    required this.popular,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          top: BorderSide(
            color: popular ? AppColors.primary : AppColors.primaryContainer,
            width: popular ? 4 : 2,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(45, 52, 54, 0.05),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (popular)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tier,
                style: TextStyle(
                  color: popular ? AppColors.primary : AppColors.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 9),
                    child: Text(
                      '₱',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    price,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  if (suffix.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Text(
                        suffix,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              InkWell(
                onTap: onTap,
                child: Container(
                  height: 46,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: popular ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: popular
                        ? null
                        : Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        color: popular ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomTierCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CustomTierCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.50),
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: AppColors.secondary),
              ),
              const SizedBox(height: 18),
              const Text(
                'Define Custom Tier',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LicenseAndPaymentSection extends StatelessWidget {
  final UserModel user;

  const _LicenseAndPaymentSection({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _LicenseTableSection(user: user)),
        const SizedBox(width: 44),
        Expanded(child: _RightPanel(user: user)),
      ],
    );
  }
}

class _LicenseTableSection extends StatelessWidget {
  final UserModel user;

  const _LicenseTableSection({
    required this.user,
  });

  CollectionReference<Map<String, dynamic>> get clientsRef =>
      FirebaseFirestore.instance.collection('clients');

  void openLicenseDialog(
      BuildContext context,
      String clientId,
      Map<String, dynamic> data,
      ) {
    final planController = TextEditingController(
      text: data['subscriptionPlan']?.toString() ?? '',
    );
    final expiryController = TextEditingController(
      text: data['subscriptionExpiry']?.toString() ?? '',
    );

    String status = data['subscriptionStatus']?.toString() ?? 'Active';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Client License'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DialogField(controller: planController, label: 'Plan'),
                  _DialogField(
                    controller: expiryController,
                    label: 'Expiry Date',
                    hint: 'Dec 14, 2024 / Never',
                  ),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(value: 'Expired', child: Text('Expired')),
                      DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => status = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await clientsRef.doc(clientId).set({
                    'subscriptionPlan': planController.text.trim(),
                    'subscriptionExpiry': expiryController.text.trim(),
                    'subscriptionStatus': status,
                    'updatedAt': FieldValue.serverTimestamp(),
                    'updatedBy': user.uid,
                  }, SetOptions(merge: true));

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> archiveClient(
      BuildContext context,
      String clientId,
      Map<String, dynamic> data,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Archive Client License'),
        content: Text(
          'Archive ${data['businessName'] ?? data['clientName'] ?? 'this client'}? '
              'This will move the client license record to Backup & Restore archives.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final batch = FirebaseFirestore.instance.batch();

    final clientRef = clientsRef.doc(clientId);
    final archiveRef = FirebaseFirestore.instance.collection('archives').doc();

    batch.set(archiveRef, {
      'dataType': 'Archived Client License',
      'collectionName': 'clients',
      'originalDocId': clientId,
      'data': {
        ...data,
        'isArchived': false,
        'status': data['status'] ?? 'active',
      },
      'originalCreatedAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
      'archivedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'archivedBy': user.uid,
      'archivedByName': user.fullName,
      'status': 'archived',
      'restored': false,
    });

    batch.set(clientRef, {
      'isArchived': true,
      'subscriptionStatus': 'Archived',
      'status': 'archived',
      'isActive': false,
      'archivedAt': FieldValue.serverTimestamp(),
      'archivedBy': user.uid,
      'archivedByName': user.fullName,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': user.uid,
    }, SetOptions(merge: true));

    await batch.commit();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Client license archived. It will appear in Backup & Restore.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> renewClientLicense(
      BuildContext context,
      String clientId,
      Map<String, dynamic> data,
      ) async {
    final planController = TextEditingController(
      text: data['subscriptionPlan']?.toString() ?? 'Yearly',
    );
    final expiryController = TextEditingController(
      text: data['subscriptionExpiry']?.toString() ?? 'January 01 2027',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renew Client License'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(controller: planController, label: 'Plan'),
              _DialogField(
                controller: expiryController,
                label: 'New Expiry Date',
                hint: 'January 01 2027 / Never',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Renew'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    await clientsRef.doc(clientId).set({
      'subscriptionPlan': planController.text.trim(),
      'subscriptionExpiry': expiryController.text.trim(),
      'subscriptionStatus': 'Active',
      'status': 'active',
      'isActive': true,
      'isArchived': false,
      'renewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': user.uid,
    }, SetOptions(merge: true));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Client license renewed and activated.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: clientsRef.snapshots(),
      builder: (context, snapshot) {
        final clients = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data();
          final status = (data['subscriptionStatus'] ?? data['status'] ?? '')
              .toString()
              .toLowerCase();

          return data['isArchived'] != true && status != 'archived';
        }).toList();

        return Column(
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: AppColors.primary),
                const SizedBox(width: 12),
                const Text(
                  'Active Client Licenses',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                _TotalChip(total: clients.length),
              ],
            ),
            const SizedBox(height: 26),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(45, 52, 54, 0.05),
                    blurRadius: 32,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const _LicenseTableHeader(),
                  if (clients.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'No clients found.',
                        style: TextStyle(color: AppColors.secondary),
                      ),
                    )
                  else
                    ...clients.map((doc) {
                      return _LicenseRow(
                        docId: doc.id,
                        data: doc.data(),
                        onEdit: () => openLicenseDialog(
                          context,
                          doc.id,
                          doc.data(),
                        ),
                        onRenew: () => renewClientLicense(
                          context,
                          doc.id,
                          doc.data(),
                        ),
                        onArchive: () => archiveClient(
                          context,
                          doc.id,
                          doc.data(),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TotalChip extends StatelessWidget {
  final int total;

  const _TotalChip({
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$total TOTAL',
        style: const TextStyle(
          color: AppColors.secondary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LicenseTableHeader extends StatelessWidget {
  const _LicenseTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderText('CLIENT NAME')),
          Expanded(flex: 2, child: _HeaderText('PLAN')),
          Expanded(flex: 2, child: _HeaderText('EXPIRY DATE')),
          Expanded(flex: 2, child: _HeaderText('STATUS')),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: _HeaderText('ACTIONS'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LicenseRow extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onRenew;
  final VoidCallback onArchive;

  const _LicenseRow({
    required this.docId,
    required this.data,
    required this.onEdit,
    required this.onRenew,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final clientName =
        data['businessName']?.toString() ?? data['clientName']?.toString() ?? 'Client';
    final clientCode = data['clientCode']?.toString() ?? docId;
    final plan = data['subscriptionPlan']?.toString() ?? 'No Plan';
    final expiry = data['subscriptionExpiry']?.toString() ?? 'Not set';
    String status = data['subscriptionStatus']?.toString() ??
        ((data['isActive'] == false) ? 'Expired' : 'Active');

    final expiryLower = expiry.toLowerCase();
    if (expiryLower != 'never' && expiryLower != 'not set') {
      final parsedExpiry = DateTime.tryParse(expiry);
      if (parsedExpiry != null && parsedExpiry.isBefore(DateTime.now())) {
        status = 'Expired';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.surfaceContainer),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $clientCode',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              plan,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              expiry,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _LicenseStatusBadge(status: status),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit license',
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Renew / activate license',
                    onPressed: onRenew,
                    icon: const Icon(
                      Icons.verified,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Archive license',
                    onPressed: onArchive,
                    icon: const Icon(
                      Icons.archive,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;

  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.secondary,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _LicenseStatusBadge extends StatelessWidget {
  final String status;

  const _LicenseStatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final value = status.toLowerCase();

    late final String label;
    late final Color textColor;
    late final Color bgColor;

    if (value == 'active') {
      label = 'ACTIVE';
      textColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.12);
    } else if (value == 'expired') {
      label = 'EXPIRED';
      textColor = AppColors.error;
      bgColor = AppColors.errorContainer;
    } else if (value == 'archived') {
      label = 'ARCHIVED';
      textColor = AppColors.secondary;
      bgColor = AppColors.surfaceContainerHigh;
    } else {
      label = 'PENDING';
      textColor = AppColors.secondary;
      bgColor = AppColors.surfaceContainerHigh;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  final UserModel user;

  const _RightPanel({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RecentPaymentsSection(user: user),
        const SizedBox(height: 28),
        const _RevenueGrowthCard(),
      ],
    );
  }
}

class _RecentPaymentsSection extends StatelessWidget {
  final UserModel user;

  const _RecentPaymentsSection({
    required this.user,
  });

  CollectionReference<Map<String, dynamic>> get paymentsRef =>
      FirebaseFirestore.instance.collection('subscription_payments');

  void openPaymentDialog(BuildContext context) {
    final amountController = TextEditingController();
    final methodController = TextEditingController();
    final clientController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Record Subscription Payment'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(controller: amountController, label: 'Amount'),
              _DialogField(controller: methodController, label: 'Method'),
              _DialogField(controller: clientController, label: 'Client Name'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await paymentsRef.add({
                'amount': double.tryParse(amountController.text.trim()) ?? 0,
                'method': methodController.text.trim(),
                'clientName': clientController.text.trim(),
                'status': 'Paid',
                'createdAt': FieldValue.serverTimestamp(),
                'createdBy': user.uid,
              });

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.history, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text(
              'Recent Payments',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => openPaymentDialog(context),
              icon: const Icon(Icons.add, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 26),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: paymentsRef.snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            docs.sort((a, b) {
              final aTime = a.data()['createdAt'];
              final bTime = b.data()['createdAt'];

              if (aTime is Timestamp && bTime is Timestamp) {
                return bTime.compareTo(aTime);
              }

              return 0;
            });

            return _PaymentsCard(docs: docs.take(5).toList());
          },
        ),
      ],
    );
  }
}

class _PaymentsCard extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  const _PaymentsCard({
    required this.docs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(45, 52, 54, 0.05),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: docs.isEmpty
          ? const Text(
        'No subscription payments yet.',
        style: TextStyle(color: AppColors.secondary),
      )
          : Column(
        children: [
          ...docs.map((doc) {
            final data = doc.data();
            return Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: _PaymentItem(
                icon: Icons.payments,
                amount: '₱${_money(data['amount'])}',
                method:
                '${data['method'] ?? 'Payment'} • ${_date(data['createdAt'])}',
              ),
            );
          }),
          const SizedBox(height: 4),
          const Text(
            'View History',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  static String _money(dynamic value) {
    final amount = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return amount.toStringAsFixed(2);
  }

  static String _date(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.month}/${date.day}/${date.year}';
    }

    return 'No date';
  }
}

class _PaymentItem extends StatelessWidget {
  final IconData icon;
  final String amount;
  final String method;

  const _PaymentItem({
    required this.icon,
    required this.amount,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                method,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.outlineVariant),
      ],
    );
  }
}

class _RevenueGrowthCard extends StatelessWidget {
  const _RevenueGrowthCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.inverseSurface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(45, 52, 54, 0.12),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: const Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revenue Growth',
                style: TextStyle(
                  color: AppColors.primaryContainer,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '+12.4%',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Increase in renewals compared to last month.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(
              Icons.trending_up,
              color: Colors.white12,
              size: 90,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;

  const _DialogField({
    required this.controller,
    required this.label,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}