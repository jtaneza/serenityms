import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/user_model.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/admin_sidebar.dart';

class SystemReportsPage extends StatefulWidget {
  final UserModel user;

  const SystemReportsPage({
    super.key,
    required this.user,
  });

  @override
  State<SystemReportsPage> createState() => _SystemReportsPageState();
}

class _SystemReportsPageState extends State<SystemReportsPage> {
  String searchQuery = '';
  String selectedClient = 'All Network Partners';

  final List<ReportRowModel> reports = const [
    ReportRowModel(
      clientName: 'Serene Wellness Spas',
      clientId: 'SW-10294',
      reportType: 'Subscription Revenue',
      generatedDate: 'Oct 24, 2023',
      revenueValue: '\$12,450.00',
      status: ReportStatus.processed,
    ),
    ReportRowModel(
      clientName: 'Azure Retreat Centers',
      clientId: 'ARC-8821',
      reportType: 'Client Revenue',
      generatedDate: 'Oct 22, 2023',
      revenueValue: '\$8,920.50',
      status: ReportStatus.processed,
    ),
    ReportRowModel(
      clientName: 'Mountain Peak Medispa',
      clientId: 'MPM-4452',
      reportType: 'Appointment Report',
      generatedDate: 'Oct 21, 2023',
      revenueValue: 'N/A',
      status: ReportStatus.draft,
    ),
    ReportRowModel(
      clientName: 'Global Skin Experts',
      clientId: 'GSE-9912',
      reportType: 'Usage Report',
      generatedDate: 'Oct 19, 2023',
      revenueValue: 'N/A',
      status: ReportStatus.processed,
    ),
    ReportRowModel(
      clientName: 'Urban Oasis Spa',
      clientId: 'UOS-2311',
      reportType: 'Subscription Revenue',
      generatedDate: 'Oct 18, 2023',
      revenueValue: '\$4,500.00',
      status: ReportStatus.processed,
    ),
  ];

  List<ReportRowModel> get filteredReports {
    final query = searchQuery.trim().toLowerCase();

    return reports.where((report) {
      final matchesClient = selectedClient == 'All Network Partners' ||
          report.clientName == selectedClient;

      final matchesSearch = query.isEmpty ||
          report.clientName.toLowerCase().contains(query) ||
          report.clientId.toLowerCase().contains(query) ||
          report.reportType.toLowerCase().contains(query) ||
          report.generatedDate.toLowerCase().contains(query) ||
          report.status.name.toLowerCase().contains(query);

      return matchesClient && matchesSearch;
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
            selectedMenu: 'View System Reports',
          ),
          Expanded(
            child: Column(
              children: [
                AdminHeader(user: widget.user),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(40, 36, 40, 40),
                    child: _SystemReportsContent(
                      reports: filteredReports,
                      totalReports: reports.length,
                      selectedClient: selectedClient,
                      onClientChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedClient = value;
                        });
                      },
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

enum ReportStatus {
  processed,
  draft,
}

class ReportRowModel {
  final String clientName;
  final String clientId;
  final String reportType;
  final String generatedDate;
  final String revenueValue;
  final ReportStatus status;

  const ReportRowModel({
    required this.clientName,
    required this.clientId,
    required this.reportType,
    required this.generatedDate,
    required this.revenueValue,
    required this.status,
  });
}

class _SystemReportsContent extends StatelessWidget {
  final List<ReportRowModel> reports;
  final int totalReports;
  final String selectedClient;
  final ValueChanged<String?> onClientChanged;
  final ValueChanged<String> onSearchChanged;

  const _SystemReportsContent({
    required this.reports,
    required this.totalReports,
    required this.selectedClient,
    required this.onClientChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ReportsHeader(),
        const SizedBox(height: 46),
        const _ReportCategoryCards(),
        const SizedBox(height: 54),
        _ReportsDataPanel(
          reports: reports,
          totalReports: totalReports,
          selectedClient: selectedClient,
          onClientChanged: onClientChanged,
          onSearchChanged: onSearchChanged,
        ),
      ],
    );
  }
}

class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'View System Reports',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 52,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Access and filter detailed reports across your entire client network with clinical precision and real-time data sync.',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCategoryCards extends StatelessWidget {
  const _ReportCategoryCards();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _ReportCategoryCard(
            icon: Icons.account_balance_wallet,
            title: 'Subscription Revenue Report',
            description:
            'Comprehensive summary of ongoing SaaS income streams and recurring billing health.',
            liveView: true,
          ),
        ),
        SizedBox(width: 24),
        Expanded(
          child: _ReportCategoryCard(
            icon: Icons.storefront,
            title: 'Client Revenue Report',
            description:
            'Granular breakdown of earnings generated from individual spa partner accounts and services.',
          ),
        ),
        SizedBox(width: 24),
        Expanded(
          child: _ReportCategoryCard(
            icon: Icons.calendar_month,
            title: 'Appointment Report',
            description:
            'Network-wide booking statistics, including high-traffic periods and cancellation rates.',
          ),
        ),
        SizedBox(width: 24),
        Expanded(
          child: _ReportCategoryCard(
            icon: Icons.insights,
            title: 'Usage Report',
            description:
            'Real-time system activity monitors and platform engagement metrics across all nodes.',
          ),
        ),
      ],
    );
  }
}

class _ReportCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool liveView;

  const _ReportCategoryCard({
    required this.icon,
    required this.title,
    required this.description,
    this.liveView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          top: BorderSide(
            color: liveView ? AppColors.primaryContainer : Colors.transparent,
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
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const Spacer(),
              if (liveView)
                const Text(
                  'LIVE VIEW',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 21,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsDataPanel extends StatelessWidget {
  final List<ReportRowModel> reports;
  final int totalReports;
  final String selectedClient;
  final ValueChanged<String?> onClientChanged;
  final ValueChanged<String> onSearchChanged;

  const _ReportsDataPanel({
    required this.reports,
    required this.totalReports,
    required this.selectedClient,
    required this.onClientChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _ReportsFilterBar(
            selectedClient: selectedClient,
            onClientChanged: onClientChanged,
            onSearchChanged: onSearchChanged,
          ),
          const SizedBox(height: 28),
          _ReportsTable(
            reports: reports,
            totalReports: totalReports,
          ),
        ],
      ),
    );
  }
}

class _ReportsFilterBar extends StatelessWidget {
  final String selectedClient;
  final ValueChanged<String?> onClientChanged;
  final ValueChanged<String> onSearchChanged;

  const _ReportsFilterBar({
    required this.selectedClient,
    required this.onClientChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ClientDropdown(
            selectedClient: selectedClient,
            onChanged: onClientChanged,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _SearchReportsField(
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(width: 24),
        const _ExportButton(),
      ],
    );
  }
}

class _ClientDropdown extends StatelessWidget {
  final String selectedClient;
  final ValueChanged<String?> onChanged;

  const _ClientDropdown({
    required this.selectedClient,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const clients = [
      'All Network Partners',
      'Serene Wellness Spas',
      'Azure Retreat Centers',
      'Mountain Peak Medispa',
      'Global Skin Experts',
      'Urban Oasis Spa',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FilterLabel('BY CLIENT'),
        DropdownButtonFormField<String>(
          value: selectedClient,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down),
          decoration: _fieldDecoration(),
          items: clients.map((client) {
            return DropdownMenuItem<String>(
              value: client,
              child: Text(
                client,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SearchReportsField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchReportsField({
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FilterLabel('SEARCH REPORTS'),
        TextField(
          onChanged: onChanged,
          decoration: _fieldDecoration().copyWith(
            hintText: 'Client name or ID...',
            hintStyle: TextStyle(
              color: AppColors.secondary.withValues(alpha: 0.50),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterLabel extends StatelessWidget {
  final String text;

  const _FilterLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.secondary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: AppColors.surfaceContainerLowest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(
        color: AppColors.primary,
        width: 2,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 15,
    ),
  );
}

class _ExportButton extends StatelessWidget {
  const _ExportButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(9),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 184, 148, 0.18),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download, color: Colors.white),
          label: const Text(
            'Export Data',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportsTable extends StatelessWidget {
  final List<ReportRowModel> reports;
  final int totalReports;

  const _ReportsTable({
    required this.reports,
    required this.totalReports,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const _ReportsTableHeader(),
          if (reports.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Text(
                'No reports found',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...reports.map(
                  (report) => _ReportTableRow(report: report),
            ),
          _ReportsPagination(
            visibleCount: reports.length,
            totalReports: totalReports,
          ),
        ],
      ),
    );
  }
}

class _ReportsTableHeader extends StatelessWidget {
  const _ReportsTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerHigh.withValues(alpha: 0.50),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _TableHeaderText('CLIENT NAME')),
          Expanded(flex: 3, child: _TableHeaderText('REPORT TYPE')),
          Expanded(flex: 2, child: _TableHeaderText('GENERATED DATE')),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: _TableHeaderText('REVENUE VALUE'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(child: _TableHeaderText('STATUS')),
          ),
          SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  final String text;

  const _TableHeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.secondary,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.6,
      ),
    );
  }
}

class _ReportTableRow extends StatelessWidget {
  final ReportRowModel report;

  const _ReportTableRow({
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.surfaceContainerLow),
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
                  report.clientName,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.clientId,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              report.reportType,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              report.generatedDate,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              report.revenueValue,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: report.revenueValue == 'N/A'
                    ? AppColors.secondary
                    : AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: _ReportStatusBadge(status: report.status),
            ),
          ),
          SizedBox(
            width: 44,
            child: IconButton(
              tooltip: 'View Report',
              onPressed: () {},
              icon: const Icon(
                Icons.visibility,
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

class _ReportStatusBadge extends StatelessWidget {
  final ReportStatus status;

  const _ReportStatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color textColor;
    late final Color bgColor;

    switch (status) {
      case ReportStatus.processed:
        label = 'PROCESSED';
        textColor = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.10);
        break;
      case ReportStatus.draft:
        label = 'DRAFT';
        textColor = AppColors.secondary;
        bgColor = AppColors.surfaceContainerHigh;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ReportsPagination extends StatelessWidget {
  final int visibleCount;
  final int totalReports;

  const _ReportsPagination({
    required this.visibleCount,
    required this.totalReports,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLow.withValues(alpha: 0.30),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      child: Row(
        children: [
          Text(
            'SHOWING 1 TO $visibleCount OF $totalReports ENTRIES',
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const Spacer(),
          const _PaginationButton(
            icon: Icons.chevron_left,
            active: false,
          ),
          SizedBox(width: 8),
          const _PaginationNumber(
            number: '1',
            active: true,
          ),
          SizedBox(width: 8),
          const _PaginationNumber(
            number: '2',
            active: false,
          ),
          SizedBox(width: 8),
          const _PaginationNumber(
            number: '3',
            active: false,
          ),
          SizedBox(width: 8),
          const _PaginationButton(
            icon: Icons.chevron_right,
            active: false,
          ),
        ],
      ),
    );
  }
}

class _PaginationNumber extends StatelessWidget {
  final String number;
  final bool active;

  const _PaginationNumber({
    required this.number,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: active
            ? const [
          BoxShadow(
            color: Color.fromRGBO(0, 107, 85, 0.20),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ]
            : null,
      ),
      child: Center(
        child: Text(
          number,
          style: TextStyle(
            color: active ? Colors.white : AppColors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _PaginationButton({
    required this.icon,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: active ? Colors.white : AppColors.secondary,
      ),
    );
  }
}