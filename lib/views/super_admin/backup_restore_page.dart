import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/user_model.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/admin_sidebar.dart';

class BackupRestorePage extends StatefulWidget {
  final UserModel user;

  const BackupRestorePage({
    super.key,
    required this.user,
  });

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  String searchQuery = '';

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> get archiveStream {
    return firestore
        .collection('archives')
        .orderBy('archivedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> get usersStream {
    return firestore.collection('users').snapshots();
  }

  Stream<QuerySnapshot> get clientsStream {
    return firestore.collection('clients').snapshots();
  }

  Stream<QuerySnapshot> get appointmentsStream {
    return firestore.collection('appointments').snapshots();
  }

  Stream<QuerySnapshot> get paymentsStream {
    return firestore.collection('payments').snapshots();
  }

  String formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) date = value.toDate();
    if (value is DateTime) date = value;

    if (date == null) return value?.toString() ?? 'No date';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  List<ArchiveItemModel> buildArchiveItems(List<QueryDocumentSnapshot> docs) {
    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return ArchiveItemModel(
        id: doc.id,
        dataType: (data['dataType'] ??
            data['type'] ??
            data['collectionName'] ??
            'Archive Record')
            .toString(),
        icon: iconForType(
          (data['collectionName'] ?? data['dataType'] ?? data['type'] ?? '')
              .toString(),
        ),
        originalDate: formatDate(data['originalCreatedAt'] ?? data['createdAt']),
        archiveDate: formatDate(data['archivedAt'] ?? data['archiveDate']),
        collectionName: (data['collectionName'] ?? '').toString(),
        originalDocId: (data['originalDocId'] ?? '').toString(),
        restored: data['restored'] == true,
        archiveData: data,
      );
    }).toList();
  }

  IconData iconForType(String value) {
    final type = value.toLowerCase();

    if (type.contains('client') || type.contains('account')) {
      return Icons.business;
    }

    if (type.contains('user')) {
      return Icons.manage_accounts;
    }

    if (type.contains('appointment')) {
      return Icons.calendar_month;
    }

    if (type.contains('payment')) {
      return Icons.account_balance_wallet;
    }

    return Icons.description;
  }

  List<ArchiveItemModel> filterArchiveItems(List<ArchiveItemModel> items) {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) return items;

    return items.where((item) {
      return item.dataType.toLowerCase().contains(query) ||
          item.originalDate.toLowerCase().contains(query) ||
          item.archiveDate.toLowerCase().contains(query) ||
          item.collectionName.toLowerCase().contains(query) ||
          item.originalDocId.toLowerCase().contains(query);
    }).toList();
  }

  List<RecoverAccountModel> buildRecoverAccounts({
    required List<QueryDocumentSnapshot> users,
    required List<QueryDocumentSnapshot> clients,
  }) {
    final accounts = <RecoverAccountModel>[];
    final usedEmails = <String>{};

    for (final doc in users) {
      final data = doc.data() as Map<String, dynamic>;
      final email = (data['email'] ?? '').toString().trim();
      final role = (data['role'] ?? '').toString();

      if (email.isEmpty) continue;

      final key = email.toLowerCase();
      if (usedEmails.contains(key)) continue;
      usedEmails.add(key);

      accounts.add(
        RecoverAccountModel(
          uid: (data['uid'] ?? doc.id).toString(),
          docId: doc.id,
          collectionName: 'users',
          name: (data['businessName'] ??
              data['fullName'] ??
              data['displayName'] ??
              email)
              .toString(),
          email: email,
          role: role.isEmpty ? 'user' : role,
          status: (data['status'] ?? 'active').toString(),
        ),
      );
    }

    for (final doc in clients) {
      final data = doc.data() as Map<String, dynamic>;
      final email = (data['email'] ?? data['ownerEmail'] ?? '').toString();

      if (email.isEmpty) continue;

      final key = email.toLowerCase();
      if (usedEmails.contains(key)) continue;
      usedEmails.add(key);

      accounts.add(
        RecoverAccountModel(
          uid: (data['uid'] ?? doc.id).toString(),
          docId: doc.id,
          collectionName: 'clients',
          name: (data['businessName'] ??
              data['companyName'] ??
              data['fullName'] ??
              email)
              .toString(),
          email: email,
          role: (data['role'] ?? 'client').toString(),
          status: (data['status'] ?? data['subscriptionStatus'] ?? 'active')
              .toString(),
        ),
      );
    }

    accounts.sort((a, b) => a.name.compareTo(b.name));
    return accounts;
  }

  Future<void> sendPasswordResetAndRestore(RecoverAccountModel account) async {
    try {
      await auth.sendPasswordResetEmail(email: account.email);

      final batch = firestore.batch();

      batch.set(
        firestore.collection(account.collectionName).doc(account.docId),
        {
          'status': 'active',
          'isActive': true,
          'accountRecovered': true,
          'passwordResetSent': true,
          'lastPasswordResetAt': FieldValue.serverTimestamp(),
          'recoveredAt': FieldValue.serverTimestamp(),
          'recoveredBy': widget.user.uid,
          'recoveredByName': widget.user.fullName,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        firestore.collection('users').doc(account.uid),
        {
          'status': 'active',
          'isActive': true,
          'accountRecovered': true,
          'passwordResetSent': true,
          'lastPasswordResetAt': FieldValue.serverTimestamp(),
          'recoveredAt': FieldValue.serverTimestamp(),
          'recoveredBy': widget.user.uid,
          'recoveredByName': widget.user.fullName,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        firestore.collection('archives').doc(),
        {
          'dataType': 'Password Reset / Account Recovery',
          'collectionName': account.collectionName,
          'originalDocId': account.docId,
          'targetUserId': account.uid,
          'targetEmail': account.email,
          'targetName': account.name,
          'originalCreatedAt': FieldValue.serverTimestamp(),
          'archivedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'archivedBy': widget.user.uid,
          'archivedByName': widget.user.fullName,
          'status': 'processed',
          'restored': true,
        },
      );

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password reset email sent to ${account.email}. Account is active.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Failed to send password reset email.'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to recover account: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> disableAccount(RecoverAccountModel account) async {
    final batch = firestore.batch();

    batch.set(
      firestore.collection(account.collectionName).doc(account.docId),
      {
        'status': 'disabled',
        'isActive': false,
        'disabledAt': FieldValue.serverTimestamp(),
        'disabledBy': widget.user.uid,
        'disabledByName': widget.user.fullName,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      firestore.collection('users').doc(account.uid),
      {
        'status': 'disabled',
        'isActive': false,
        'disabledAt': FieldValue.serverTimestamp(),
        'disabledBy': widget.user.uid,
        'disabledByName': widget.user.fullName,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      firestore.collection('archives').doc(),
      {
        'dataType': 'Account Disabled',
        'collectionName': account.collectionName,
        'originalDocId': account.docId,
        'targetUserId': account.uid,
        'targetEmail': account.email,
        'targetName': account.name,
        'originalCreatedAt': FieldValue.serverTimestamp(),
        'archivedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'archivedBy': widget.user.uid,
        'archivedByName': widget.user.fullName,
        'status': 'processed',
        'restored': false,
      },
    );

    await batch.commit();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${account.email} has been disabled.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> restoreArchive(ArchiveItemModel item) async {
    final collectionName = item.collectionName;
    final originalDocId = item.originalDocId;
    final payload = item.archiveData['data'];

    if (collectionName.isEmpty || originalDocId.isEmpty || payload is! Map) {
      await firestore.collection('archives').doc(item.id).set(
        {
          'restored': true,
          'restoredAt': FieldValue.serverTimestamp(),
          'restoredBy': widget.user.uid,
          'restoredByName': widget.user.fullName,
          'status': 'processed',
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.dataType} marked as restored.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    final restoredData = Map<String, dynamic>.from(payload);
    restoredData['restoredAt'] = FieldValue.serverTimestamp();
    restoredData['restoredBy'] = widget.user.uid;
    restoredData['restoredByName'] = widget.user.fullName;
    restoredData['isArchived'] = false;
    restoredData['status'] = restoredData['status'] ?? 'active';

    final batch = firestore.batch();

    batch.set(
      firestore.collection(collectionName).doc(originalDocId),
      restoredData,
      SetOptions(merge: true),
    );

    batch.set(
      firestore.collection('archives').doc(item.id),
      {
        'restored': true,
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredBy': widget.user.uid,
        'restoredByName': widget.user.fullName,
        'status': 'processed',
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.dataType} restored back to $collectionName.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> deleteArchive(ArchiveItemModel item) async {
    await firestore.collection('archives').doc(item.id).delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.dataType} deleted from archive.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void openRecoverAccountsDialog(List<RecoverAccountModel> accounts) {
    showDialog(
      context: context,
      builder: (context) {
        return _RecoverAccountsDialog(
          accounts: accounts,
          onRecover: sendPasswordResetAndRestore,
          onDisable: disableAccount,
        );
      },
    );
  }

  Future<void> archiveLiveRecord({
    required String collectionName,
    required QueryDocumentSnapshot doc,
  }) async {
    final data = doc.data() as Map<String, dynamic>;

    final batch = firestore.batch();

    final archiveRef = firestore.collection('archives').doc();
    final originalRef = firestore.collection(collectionName).doc(doc.id);

    batch.set(archiveRef, {
      'dataType': collectionName == 'appointments'
          ? 'Archived Appointment'
          : collectionName == 'payments'
          ? 'Archived Payment'
          : 'Archived Record',
      'collectionName': collectionName,
      'originalDocId': doc.id,
      'data': data,
      'originalCreatedAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
      'archivedAt': FieldValue.serverTimestamp(),
      'archivedBy': widget.user.uid,
      'archivedByName': widget.user.fullName,
      'restored': false,
      'status': 'archived',
    });

    batch.set(originalRef, {
      'isArchived': true,
      'status': 'archived',
      'archivedAt': FieldValue.serverTimestamp(),
      'archivedBy': widget.user.uid,
      'archivedByName': widget.user.fullName,
    }, SetOptions(merge: true));

    await batch.commit();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$collectionName record archived. It will appear in Archive Table.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> restoreLiveRecord({
    required String collectionName,
    required QueryDocumentSnapshot doc,
  }) async {
    await firestore.collection(collectionName).doc(doc.id).set({
      'isArchived': false,
      'status': collectionName == 'appointments' ? 'Pending' : 'Verified',
      'restoredAt': FieldValue.serverTimestamp(),
      'restoredBy': widget.user.uid,
      'restoredByName': widget.user.fullName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$collectionName record restored.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void openModuleDialog({
    required String title,
    required IconData icon,
    required List<QueryDocumentSnapshot> docs,
    required String collectionName,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return _ModuleRecordsDialog(
          title: title,
          icon: icon,
          collectionName: collectionName,
          docs: docs,
          formatDate: formatDate,
          onArchive: archiveLiveRecord,
          onRestore: restoreLiveRecord,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          AdminSidebar(
            user: widget.user,
            selectedMenu: 'Backup & Restore',
          ),
          Expanded(
            child: Column(
              children: [
                AdminHeader(user: widget.user),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: archiveStream,
                    builder: (context, archiveSnapshot) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: usersStream,
                        builder: (context, userSnapshot) {
                          return StreamBuilder<QuerySnapshot>(
                            stream: clientsStream,
                            builder: (context, clientSnapshot) {
                              return StreamBuilder<QuerySnapshot>(
                                stream: appointmentsStream,
                                builder: (context, appointmentSnapshot) {
                                  return StreamBuilder<QuerySnapshot>(
                                    stream: paymentsStream,
                                    builder: (context, paymentSnapshot) {
                                      final isLoading =
                                          archiveSnapshot.connectionState ==
                                              ConnectionState.waiting ||
                                              userSnapshot.connectionState ==
                                                  ConnectionState.waiting ||
                                              clientSnapshot.connectionState ==
                                                  ConnectionState.waiting ||
                                              appointmentSnapshot
                                                  .connectionState ==
                                                  ConnectionState.waiting ||
                                              paymentSnapshot
                                                  .connectionState ==
                                                  ConnectionState.waiting;

                                      if (isLoading) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      final archiveItems = buildArchiveItems(
                                        archiveSnapshot.data?.docs ?? [],
                                      );

                                      final filteredItems = filterArchiveItems(
                                        archiveItems,
                                      );

                                      final recoverAccounts =
                                      buildRecoverAccounts(
                                        users: userSnapshot.data?.docs ?? [],
                                        clients:
                                        clientSnapshot.data?.docs ?? [],
                                      );

                                      return SingleChildScrollView(
                                        padding: const EdgeInsets.fromLTRB(
                                          40,
                                          36,
                                          40,
                                          40,
                                        ),
                                        child: _BackupRestoreContent(
                                          archiveItems: filteredItems,
                                          onSearchChanged: (value) {
                                            setState(() {
                                              searchQuery = value;
                                            });
                                          },
                                          onRecoverAccounts: () {
                                            openRecoverAccountsDialog(
                                              recoverAccounts,
                                            );
                                          },
                                          onOpenAppointments: () {
                                            openModuleDialog(
                                              title: 'Appointment Records',
                                              icon: Icons.calendar_month,
                                              collectionName: 'appointments',
                                              docs: appointmentSnapshot
                                                  .data?.docs ??
                                                  [],
                                            );
                                          },
                                          onOpenPayments: () {
                                            openModuleDialog(
                                              title: 'Payment Records',
                                              icon:
                                              Icons.account_balance_wallet,
                                              collectionName: 'payments',
                                              docs: paymentSnapshot
                                                  .data?.docs ??
                                                  [],
                                            );
                                          },
                                          onRestoreArchive: restoreArchive,
                                          onDeleteArchive: deleteArchive,
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
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

class ArchiveItemModel {
  final String id;
  final String dataType;
  final IconData icon;
  final String originalDate;
  final String archiveDate;
  final String collectionName;
  final String originalDocId;
  final bool restored;
  final Map<String, dynamic> archiveData;

  const ArchiveItemModel({
    required this.id,
    required this.dataType,
    required this.icon,
    required this.originalDate,
    required this.archiveDate,
    required this.collectionName,
    required this.originalDocId,
    required this.restored,
    required this.archiveData,
  });
}

class RecoverAccountModel {
  final String uid;
  final String docId;
  final String collectionName;
  final String name;
  final String email;
  final String role;
  final String status;

  const RecoverAccountModel({
    required this.uid,
    required this.docId,
    required this.collectionName,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });
}

class _BackupRestoreContent extends StatelessWidget {
  final List<ArchiveItemModel> archiveItems;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRecoverAccounts;
  final VoidCallback onOpenAppointments;
  final VoidCallback onOpenPayments;
  final Future<void> Function(ArchiveItemModel item) onRestoreArchive;
  final Future<void> Function(ArchiveItemModel item) onDeleteArchive;

  const _BackupRestoreContent({
    required this.archiveItems,
    required this.onSearchChanged,
    required this.onRecoverAccounts,
    required this.onOpenAppointments,
    required this.onOpenPayments,
    required this.onRestoreArchive,
    required this.onDeleteArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RestoreHeader(),
        const SizedBox(height: 34),
        _RestoreCards(
          onRecoverAccounts: onRecoverAccounts,
          onOpenAppointments: onOpenAppointments,
          onOpenPayments: onOpenPayments,
        ),
        const SizedBox(height: 46),
        _ArchiveTable(
          archiveItems: archiveItems,
          onSearchChanged: onSearchChanged,
          onRestoreArchive: onRestoreArchive,
          onDeleteArchive: onDeleteArchive,
        ),
        const SizedBox(height: 40),
        const _SystemStatusFooter(),
      ],
    );
  }
}

class _RestoreHeader extends StatelessWidget {
  const _RestoreHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Restore Data',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Recover accounts, reset passwords, view database records, and restore archived records.',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RestoreCards extends StatelessWidget {
  final VoidCallback onRecoverAccounts;
  final VoidCallback onOpenAppointments;
  final VoidCallback onOpenPayments;

  const _RestoreCards({
    required this.onRecoverAccounts,
    required this.onOpenAppointments,
    required this.onOpenPayments,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RestoreCard(
            icon: Icons.manage_accounts,
            title: 'Accounts',
            description:
            'Reset forgotten passwords by sending Firebase password reset emails and restoring account status.',
            actionText: 'Recover Credentials',
            onTap: onRecoverAccounts,
          ),
        ),
        const SizedBox(width: 28),
        Expanded(
          child: _RestoreCard(
            icon: Icons.calendar_month,
            title: 'Appointments',
            description:
            'Open live appointment records and review backed-up schedule data.',
            actionText: 'Access Schedules',
            onTap: onOpenAppointments,
          ),
        ),
        const SizedBox(width: 28),
        Expanded(
          child: _RestoreCard(
            icon: Icons.account_balance_wallet,
            title: 'Payments',
            description:
            'Open live payment records and review financial recovery data.',
            actionText: 'Financial Recovery',
            onTap: onOpenPayments,
          ),
        ),
      ],
    );
  }
}

class _RestoreCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionText;
  final VoidCallback onTap;

  const _RestoreCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        height: 270,
        padding: const EdgeInsets.all(34),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(26),
          border: const Border(
            top: BorderSide(
              color: AppColors.primaryContainer,
              width: 2,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 34),
            const SizedBox(height: 30),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  actionText,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoverAccountsDialog extends StatefulWidget {
  final List<RecoverAccountModel> accounts;
  final Future<void> Function(RecoverAccountModel account) onRecover;
  final Future<void> Function(RecoverAccountModel account) onDisable;

  const _RecoverAccountsDialog({
    required this.accounts,
    required this.onRecover,
    required this.onDisable,
  });

  @override
  State<_RecoverAccountsDialog> createState() => _RecoverAccountsDialogState();
}

class _RecoverAccountsDialogState extends State<_RecoverAccountsDialog> {
  String query = '';
  String? loadingEmail;

  List<RecoverAccountModel> get filteredAccounts {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) return widget.accounts;

    return widget.accounts.where((account) {
      return account.name.toLowerCase().contains(q) ||
          account.email.toLowerCase().contains(q) ||
          account.role.toLowerCase().contains(q) ||
          account.status.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> runAction(
      RecoverAccountModel account,
      Future<void> Function(RecoverAccountModel account) action,
      ) async {
    setState(() {
      loadingEmail = account.email;
    });

    await action(account);

    if (!mounted) return;

    setState(() {
      loadingEmail = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Container(
        width: 860,
        constraints: const BoxConstraints(maxHeight: 720),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(45, 52, 54, 0.16),
              blurRadius: 34,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.manage_accounts,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recover / Reset Password',
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Reset Password sends a Firebase reset email and restores the user status to active.',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search name, email, role, or status...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: filteredAccounts.isEmpty
                  ? const Center(
                child: Text(
                  'No accounts found.',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
                  : ListView.separated(
                itemCount: filteredAccounts.length,
                separatorBuilder: (_, __) => const Divider(
                  color: AppColors.surfaceContainerLow,
                ),
                itemBuilder: (context, index) {
                  final account = filteredAccounts[index];
                  final isLoading = loadingEmail == account.email;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                      AppColors.primary.withValues(alpha: 0.10),
                      child: Text(
                        account.name.isEmpty
                            ? '?'
                            : account.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    title: Text(
                      account.name,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Text(
                      '${account.email} • ${account.role} • ${account.status}',
                      style: const TextStyle(
                        color: AppColors.secondary,
                      ),
                    ),
                    trailing: Wrap(
                      spacing: 10,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () => runAction(
                            account,
                            widget.onRecover,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          icon: isLoading
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.lock_reset),
                          label: Text(
                            isLoading ? 'Sending...' : 'Reset Password',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () => runAction(
                            account,
                            widget.onDisable,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(
                              color: AppColors.error,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          icon: const Icon(Icons.block),
                          label: const Text('Disable'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleRecordsDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final String collectionName;
  final List<QueryDocumentSnapshot> docs;
  final String Function(dynamic value) formatDate;
  final Future<void> Function({
  required String collectionName,
  required QueryDocumentSnapshot doc,
  }) onArchive;
  final Future<void> Function({
  required String collectionName,
  required QueryDocumentSnapshot doc,
  }) onRestore;

  const _ModuleRecordsDialog({
    required this.title,
    required this.icon,
    required this.collectionName,
    required this.docs,
    required this.formatDate,
    required this.onArchive,
    required this.onRestore,
  });

  String primaryTitle(Map<String, dynamic> data) {
    return (data['customerName'] ??
        data['serviceName'] ??
        data['name'] ??
        data['clientName'] ??
        data['email'] ??
        'Record')
        .toString();
  }

  String subtitle(Map<String, dynamic> data) {
    if (collectionName == 'appointments') {
      return '${data['serviceName'] ?? 'Service'} • ${data['status'] ?? 'No status'}';
    }

    if (collectionName == 'payments') {
      return '₱${data['amount'] ?? 0} • ${data['paymentMethod'] ?? data['method'] ?? 'Payment'} • ${data['status'] ?? data['paymentStatus'] ?? 'No status'}';
    }

    return data.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Container(
        width: 760,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(45, 52, 54, 0.16),
              blurRadius: 34,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: docs.isEmpty
                  ? const Center(
                child: Text(
                  'No records found.',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
                  : ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(
                  color: AppColors.surfaceContainerLow,
                ),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final isArchived = data['isArchived'] == true ||
                      (data['status'] ?? '').toString().toLowerCase() ==
                          'archived';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              primaryTitle(data),
                              style: const TextStyle(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(
                              '${subtitle(data)}\n${formatDate(data['createdAt'] ?? data['updatedAt'] ?? data['appointmentDate'])}',
                              style: const TextStyle(
                                color: AppColors.secondary,
                              ),
                            ),
                            isThreeLine: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (isArchived)
                          ElevatedButton.icon(
                            onPressed: () => onRestore(
                              collectionName: collectionName,
                              doc: doc,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.restore, size: 18),
                            label: const Text('Restore'),
                          )
                        else ...[
                          OutlinedButton.icon(
                            onPressed: () => onRestore(
                              collectionName: collectionName,
                              doc: doc,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(
                                color: AppColors.primary,
                              ),
                            ),
                            icon: const Icon(Icons.restore, size: 18),
                            label: const Text('Restore'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => onArchive(
                              collectionName: collectionName,
                              doc: doc,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(
                                color: AppColors.error,
                              ),
                            ),
                            icon: const Icon(Icons.archive, size: 18),
                            label: const Text('Archive'),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveTable extends StatelessWidget {
  final List<ArchiveItemModel> archiveItems;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function(ArchiveItemModel item) onRestoreArchive;
  final Future<void> Function(ArchiveItemModel item) onDeleteArchive;

  const _ArchiveTable({
    required this.archiveItems,
    required this.onSearchChanged,
    required this.onRestoreArchive,
    required this.onDeleteArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(42),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(36),
      ),
      child: Column(
        children: [
          _ArchiveHeader(onSearchChanged: onSearchChanged),
          const SizedBox(height: 34),
          const _ArchiveTableHeader(),
          const SizedBox(height: 10),
          if (archiveItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'No archived records yet. Archive a client in Client Management first.',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...archiveItems.map(
                  (item) => _ArchiveTableRow(
                item: item,
                onRestore: () => onRestoreArchive(item),
                onDelete: () => onDeleteArchive(item),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArchiveHeader extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;

  const _ArchiveHeader({
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Archive Table',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Only records archived by the super admin will appear here.',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 280,
          height: 56,
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search archives...',
              hintStyle: const TextStyle(
                color: AppColors.secondary,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.secondary,
                size: 22,
              ),
              filled: true,
              fillColor: AppColors.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.20),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.20),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(
                  color: AppColors.primaryContainer,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArchiveTableHeader extends StatelessWidget {
  const _ArchiveTableHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 26),
      child: Row(
        children: [
          Expanded(flex: 4, child: _ArchiveHeaderText('ARCHIVED RECORD')),
          Expanded(flex: 2, child: _ArchiveHeaderText('ORIGINAL DATE')),
          Expanded(flex: 2, child: _ArchiveHeaderText('ARCHIVE DATE')),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: _ArchiveHeaderText('ACTIONS'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveHeaderText extends StatelessWidget {
  final String text;

  const _ArchiveHeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.secondary,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.6,
      ),
    );
  }
}

class _ArchiveTableRow extends StatelessWidget {
  final ArchiveItemModel item;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _ArchiveTableRow({
    required this.item,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.restored
                        ? '${item.dataType} (Restored)'
                        : item.dataType,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.originalDate,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.archiveDate,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Restore',
                  onPressed: onRestore,
                  icon: const Icon(
                    Icons.restore,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete,
                    color: AppColors.error,
                    size: 26,
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

class _SystemStatusFooter extends StatelessWidget {
  const _SystemStatusFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.surfaceContainerLow),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.circle,
            color: AppColors.primaryContainer,
            size: 9,
          ),
          SizedBox(width: 10),
          Text(
            'SYSTEM ONLINE: ARCHIVE RESTORE ENABLED',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          Spacer(),
          Text(
            'Serenity Management Suite | Backup & Restore',
            style: TextStyle(
              color: AppColors.outlineVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
