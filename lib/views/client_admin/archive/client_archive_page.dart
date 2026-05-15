import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../widgets/client_main_layout.dart';

class ClientArchivePage extends StatefulWidget {
  final UserModel user;

  const ClientArchivePage({
    super.key,
    required this.user,
  });

  @override
  State<ClientArchivePage> createState() => _ClientArchivePageState();
}

class _ClientArchivePageState extends State<ClientArchivePage> {
  String searchText = '';
  bool isLoading = false;

  Stream<QuerySnapshot> get archiveStream {
    return FirebaseFirestore.instance
        .collection('archives')
        .orderBy('archivedAt', descending: true)
        .snapshots();
  }

  final Set<String> clientCollections = {
    'services',
    'staff',
    'appointments',
    'payments',
    'booking_rules',
  };

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.month}/${date.day}/${date.year}';
    }

    if (value == null) return 'No date';

    return value.toString();
  }

  String getText(
      Map<String, dynamic> data,
      Iterable<String> keys,
      String fallback,
      ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  List<QueryDocumentSnapshot> filterArchives(List<QueryDocumentSnapshot> docs) {
    final clientDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final restored = data['restored'] == true ||
          (data['status'] ?? '').toString().toLowerCase() == 'restored';

      if (restored) return false;

      final collectionName = getText(
        data,
        ['collectionName'],
        '',
      ).toLowerCase();

      final archivedByRole = getText(
        data,
        ['archivedByRole', 'updatedByRole', 'createdByRole'],
        '',
      ).toLowerCase();

      final archivedByName = getText(
        data,
        ['archivedByName', 'createdByName', 'updatedByName'],
        '',
      ).toLowerCase();

      final tenantId = getText(
        data,
        ['tenantId'],
        '',
      );

      final clientCollections = {
        'services',
        'staff',
        'appointments',
        'payments',
        'booking_rules',
      };

      final isClientCollection = clientCollections.contains(collectionName);

      final isSuperAdminArchive =
          archivedByRole == 'super_admin' ||
              archivedByRole == 'super admin' ||
              archivedByName.contains('super admin');

      final userTenantId = widget.user.tenantId.toString();
      final userId = widget.user.uid.toString();

      final belongsToTenant =
          tenantId.isEmpty || tenantId == userTenantId || tenantId == userId;

      return isClientCollection && !isSuperAdminArchive && belongsToTenant;
    }).toList();

    if (searchText.trim().isEmpty) return clientDocs;

    final search = searchText.toLowerCase().trim();

    return clientDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final targetName = getText(
        data,
        [
          'targetName',
          'customerName',
          'serviceName',
          'staffName',
          'name',
        ],
        '',
      ).toLowerCase();

      final dataType = getText(
        data,
        ['dataType', 'type', 'archiveType'],
        '',
      ).toLowerCase();

      final collectionName = getText(
        data,
        ['collectionName'],
        '',
      ).toLowerCase();

      return targetName.contains(search) ||
          dataType.contains(search) ||
          collectionName.contains(search);
    }).toList();
  }

  Future<bool> confirmAction({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> restoreArchive({
    required String archiveId,
    required Map<String, dynamic> data,
  }) async {
    final confirmed = await confirmAction(
      title: 'Restore Archived Record',
      message: 'Are you sure you want to restore this archived record?',
      confirmText: 'Restore',
      confirmColor: const Color(0xFF00A884),
    );

    if (!confirmed) return;

    setState(() => isLoading = true);

    try {
      final collectionName = getText(data, ['collectionName'], '');
      final originalDocId = getText(data, ['originalDocId'], '');

      if (collectionName.isEmpty || originalDocId.isEmpty) {
        showMessage('This archive record has no original collection or document ID.');
        return;
      }

      final restoreData = Map<String, dynamic>.from(data);

      restoreData.remove('archivedAt');
      restoreData.remove('archivedBy');
      restoreData.remove('archivedByName');
      restoreData.remove('archivedByRole');
      restoreData.remove('collectionName');
      restoreData.remove('dataType');
      restoreData.remove('originalDocId');
      restoreData.remove('originalCreatedAt');
      restoreData.remove('restored');
      restoreData.remove('restoredAt');
      restoreData.remove('restoredBy');
      restoreData.remove('restoredByName');
      restoreData.remove('targetEmail');
      restoreData.remove('targetName');
      restoreData.remove('targetUserId');

      restoreData['isArchived'] = false;

      final currentStatus = (restoreData['status'] ?? '').toString().toLowerCase();

      if (currentStatus == 'archived') {
        restoreData['status'] = 'Active';
      }

      restoreData['updatedAt'] = FieldValue.serverTimestamp();
      restoreData['updatedBy'] = widget.user.uid;
      restoreData['updatedByName'] = widget.user.fullName;

      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(originalDocId)
          .set(
        restoreData,
        SetOptions(merge: true),
      );

      await FirebaseFirestore.instance
          .collection('archives')
          .doc(archiveId)
          .delete();

      showMessage('Archived record restored.');
    } catch (e) {
      showMessage('Restore failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> permanentDelete(String archiveId) async {
    final confirmed = await confirmAction(
      title: 'Permanent Delete',
      message:
      'Are you sure you want to permanently delete this archive record? This action cannot be undone.',
      confirmText: 'Delete',
      confirmColor: const Color(0xFFE53935),
    );

    if (!confirmed) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('archives')
          .doc(archiveId)
          .delete();

      showMessage('Archive record permanently deleted.');
    } catch (e) {
      showMessage('Delete failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClientMainLayout(
      user: widget.user,
      currentRoute: 'archive',
      child: Container(
        color: const Color(0xFFF4FAFD),
        child: Stack(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: archiveStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = filterArchives(snapshot.data?.docs ?? []);

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 42,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Archive',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF161D1F),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'View archived services, staff, appointments, payments, and booking rule records.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF586062),
                        ),
                      ),
                      const SizedBox(height: 34),
                      Row(
                        children: [
                          const _SectionLabel(title: 'Archive Table'),
                          const Spacer(),
                          SizedBox(
                            width: 310,
                            height: 44,
                            child: TextField(
                              onChanged: (value) {
                                setState(() => searchText = value);
                              },
                              decoration: InputDecoration(
                                hintText: 'Search archive...',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE9EFF2),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE9EFF2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF00B894),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _ArchiveTable(
                        docs: docs,
                        formatDate: formatDate,
                        getText: getText,
                        onRestore: restoreArchive,
                        onDelete: permanentDelete,
                      ),
                    ],
                  ),
                );
              },
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.12),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 30,
          width: 5,
          decoration: BoxDecoration(
            color: const Color(0xFF00B894),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF161D1F),
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
      ],
    );
  }
}

class _ArchiveTable extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final String Function(dynamic value) formatDate;
  final String Function(
      Map<String, dynamic> data,
      List<String> keys,
      String fallback,
      ) getText;
  final Future<void> Function({
  required String archiveId,
  required Map<String, dynamic> data,
  }) onRestore;
  final Future<void> Function(String archiveId) onDelete;

  const _ArchiveTable({
    required this.docs,
    required this.formatDate,
    required this.getText,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 620),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const _ArchiveTableHeader(),
            if (docs.isEmpty)
              const SizedBox(
                height: 140,
                child: Center(
                  child: Text(
                    'No archived records found.',
                    style: TextStyle(
                      color: Color(0xFF586062),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                final dataType = getText(
                  data,
                  ['dataType', 'type', 'archiveType'],
                  'Archived Record',
                );

                final collectionName = getText(
                  data,
                  ['collectionName'],
                  'Unknown Collection',
                );

                final targetName = getText(
                  data,
                  [
                    'targetName',
                    'customerName',
                    'serviceName',
                    'staffName',
                    'name',
                    'businessName',
                  ],
                  'No target name',
                );

                final archivedBy = getText(
                  data,
                  ['archivedByName', 'createdByName', 'updatedByName'],
                  'Unknown',
                );

                final restored = data['restored'] == true;

                return _ArchiveTableRow(
                  dataType: dataType,
                  collectionName: collectionName,
                  targetName: targetName,
                  archivedBy: archivedBy,
                  archivedAt: formatDate(data['archivedAt'] ?? data['createdAt']),
                  status: restored
                      ? 'Restored'
                      : getText(data, ['status'], 'Archived'),
                  restored: restored,
                  onRestore: restored
                      ? null
                      : () {
                    onRestore(
                      archiveId: doc.id,
                      data: data,
                    );
                  },
                  onDelete: () => onDelete(doc.id),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ArchiveTableHeader extends StatelessWidget {
  const _ArchiveTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEF5F7),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderText('ARCHIVE TYPE')),
          Expanded(flex: 2, child: _HeaderText('COLLECTION')),
          Expanded(flex: 3, child: _HeaderText('TARGET RECORD')),
          Expanded(flex: 2, child: _HeaderText('ARCHIVED BY')),
          Expanded(flex: 2, child: _HeaderText('ARCHIVE DATE')),
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

class _ArchiveTableRow extends StatelessWidget {
  final String dataType;
  final String collectionName;
  final String targetName;
  final String archivedBy;
  final String archivedAt;
  final String status;
  final bool restored;
  final VoidCallback? onRestore;
  final VoidCallback onDelete;

  const _ArchiveTableRow({
    required this.dataType,
    required this.collectionName,
    required this.targetName,
    required this.archivedBy,
    required this.archivedAt,
    required this.status,
    required this.restored,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9EFF2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              dataType,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF161D1F),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              collectionName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF586062),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              targetName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF161D1F),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              archivedBy,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF586062),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              archivedAt,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF586062),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _ArchiveStatusPill(
              status: status,
              restored: restored,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Tooltip(
                  message: restored ? 'Already restored' : 'Restore',
                  child: IconButton(
                    onPressed: onRestore,
                    icon: Icon(
                      Icons.restore_outlined,
                      color: restored
                          ? const Color(0xFF9E9E9E)
                          : const Color(0xFF006B55),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Permanent Delete',
                  child: IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFE53935),
                    ),
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

class _ArchiveStatusPill extends StatelessWidget {
  final String status;
  final bool restored;

  const _ArchiveStatusPill({
    required this.status,
    required this.restored,
  });

  @override
  Widget build(BuildContext context) {
    final color = restored ? const Color(0xFF1565C0) : const Color(0xFF006B55);
    final background =
    restored ? const Color(0xFFEFF6FF) : const Color(0xFFE0F7F0);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
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
        color: Color(0xFF586062),
        fontWeight: FontWeight.w900,
        fontSize: 11,
        letterSpacing: 1.8,
      ),
    );
  }
}