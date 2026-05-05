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

  final List<ArchiveItemModel> archiveItems = const [
    ArchiveItemModel(
      dataType: 'Patient Consent Forms',
      icon: Icons.description,
      originalDate: '14 Mar 2022',
      archiveDate: '02 Oct 2023',
    ),
    ArchiveItemModel(
      dataType: 'Clinical Audit Logs',
      icon: Icons.assignment,
      originalDate: '11 Jan 2021',
      archiveDate: '15 Sep 2023',
    ),
    ArchiveItemModel(
      dataType: 'Expired Licensing Keys',
      icon: Icons.receipt_long,
      originalDate: '05 Jun 2022',
      archiveDate: '10 Aug 2023',
    ),
  ];

  List<ArchiveItemModel> get filteredItems {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return archiveItems;
    }

    return archiveItems.where((item) {
      return item.dataType.toLowerCase().contains(query) ||
          item.originalDate.toLowerCase().contains(query) ||
          item.archiveDate.toLowerCase().contains(query);
    }).toList();
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(40, 36, 40, 40),
                    child: _BackupRestoreContent(
                      archiveItems: filteredItems,
                      onSearchChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
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

class ArchiveItemModel {
  final String dataType;
  final IconData icon;
  final String originalDate;
  final String archiveDate;

  const ArchiveItemModel({
    required this.dataType,
    required this.icon,
    required this.originalDate,
    required this.archiveDate,
  });
}

class _BackupRestoreContent extends StatelessWidget {
  final List<ArchiveItemModel> archiveItems;
  final ValueChanged<String> onSearchChanged;

  const _BackupRestoreContent({
    required this.archiveItems,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RestoreHeader(),
        const SizedBox(height: 34),
        const _RestoreCards(),
        const SizedBox(height: 46),
        _ArchiveTable(
          archiveItems: archiveItems,
          onSearchChanged: onSearchChanged,
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
          'Granular restoration for specific system modules.',
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
  const _RestoreCards();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _RestoreCard(
            icon: Icons.manage_accounts,
            title: 'Accounts',
            description:
            'Quickly restore email and password credentials for clients who have lost access to their accounts.',
            actionText: 'Recover Credentials',
          ),
        ),
        SizedBox(width: 28),
        Expanded(
          child: _RestoreCard(
            icon: Icons.calendar_month,
            title: 'Appointments',
            description:
            'Revert schedule changes or restore accidentally deleted clinical sessions and therapist bookings.',
            actionText: 'Access Schedules',
          ),
        ),
        SizedBox(width: 28),
        Expanded(
          child: _RestoreCard(
            icon: Icons.account_balance_wallet,
            title: 'Payments',
            description:
            'Restore transactional data, billing history, and invoices for financial reconciliation purposes.',
            actionText: 'Financial Recovery',
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

  const _RestoreCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Icon(
            icon,
            color: AppColors.primary,
            size: 34,
          ),
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
    );
  }
}

class _ArchiveTable extends StatelessWidget {
  final List<ArchiveItemModel> archiveItems;
  final ValueChanged<String> onSearchChanged;

  const _ArchiveTable({
    required this.archiveItems,
    required this.onSearchChanged,
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
                'No archive records found',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...archiveItems.map(
                  (item) => _ArchiveTableRow(item: item),
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
                'Review and manage all the archive data stored in the repository.',
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
          Expanded(
            flex: 4,
            child: _ArchiveHeaderText('DATA TYPE'),
          ),
          Expanded(
            flex: 2,
            child: _ArchiveHeaderText('ORIGINAL DATE'),
          ),
          Expanded(
            flex: 2,
            child: _ArchiveHeaderText('ARCHIVE DATE'),
          ),
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

  const _ArchiveTableRow({
    required this.item,
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
                Text(
                  item.dataType,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
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
                  onPressed: () {},
                  icon: const Icon(
                    Icons.restore,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () {},
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
            'SYSTEM ONLINE: ALL NODES SYNCHRONIZED',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          Spacer(),
          Text(
            '© 2023 Clinical Sanctuary Admin Console | v2.4.0-Stable',
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