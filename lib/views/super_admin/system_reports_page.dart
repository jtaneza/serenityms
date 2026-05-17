import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/app_colors.dart';
import '../../models/user_model.dart';
import '../../widgets/admin_main_layout.dart';

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

  Stream<QuerySnapshot> get clientsStream {
    return FirebaseFirestore.instance.collection('clients').snapshots();
  }

  Stream<QuerySnapshot> get usersStream {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  Stream<QuerySnapshot> get appointmentsStream {
    return FirebaseFirestore.instance.collection('appointments').snapshots();
  }

  Stream<QuerySnapshot> get paymentsStream {
    return FirebaseFirestore.instance.collection('payments').snapshots();
  }

  Stream<QuerySnapshot> get subscriptionPaymentsStream {
    return FirebaseFirestore.instance
        .collection('subscription_payments')
        .snapshots();
  }

  num toNumber(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  DateTime? toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'No date';

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

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool isPaid(Map<String, dynamic> data) {
    final status = (data['status'] ?? data['paymentStatus'] ?? '')
        .toString()
        .toLowerCase();

    return status.contains('paid') ||
        status.contains('verified') ||
        status.contains('full payment') ||
        status.contains('completed') ||
        status.contains('active');
  }

  List<ClientModel> buildClients(
      List<QueryDocumentSnapshot> clientDocs,
      List<QueryDocumentSnapshot> userDocs,
      ) {
    final clients = <ClientModel>[];

    for (final doc in clientDocs) {
      final data = doc.data() as Map<String, dynamic>;

      clients.add(
        ClientModel(
          id: doc.id,
          name: (data['businessName'] ??
              data['clientBusiness'] ??
              data['companyName'] ??
              data['fullName'] ??
              'Client')
              .toString(),
          email: (data['email'] ?? data['ownerEmail'] ?? '').toString(),
        ),
      );
    }

    if (clients.isEmpty) {
      for (final doc in userDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final role = (data['role'] ?? '').toString().toLowerCase();

        if (role.contains('client')) {
          clients.add(
            ClientModel(
              id: doc.id,
              name: (data['businessName'] ??
                  data['fullName'] ??
                  data['email'] ??
                  'Client')
                  .toString(),
              email: (data['email'] ?? '').toString(),
            ),
          );
        }
      }
    }

    return clients;
  }

  List<ReportRowModel> buildReports({
    required List<ClientModel> clients,
    required List<QueryDocumentSnapshot> appointments,
    required List<QueryDocumentSnapshot> payments,
    required List<QueryDocumentSnapshot> subscriptions,
  }) {
    final reports = <ReportRowModel>[];

    final totalPaymentRevenue = payments.fold<num>(0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      return isPaid(data) ? sum + toNumber(data['amount']) : sum;
    });

    final totalSubscriptionRevenue = subscriptions.fold<num>(0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      return isPaid(data) ? sum + toNumber(data['amount']) : sum;
    });

    final appointmentCount = appointments.length;
    final paymentCount = payments.length + subscriptions.length;

    if (clients.isEmpty) {
      reports.add(
        ReportRowModel(
          clientName: 'System Database',
          clientId: 'SYSTEM',
          reportType: 'Usage Report',
          generatedDate: formatDate(DateTime.now()),
          revenueValue: '₱${(totalPaymentRevenue + totalSubscriptionRevenue).toStringAsFixed(2)}',
          status: ReportStatus.processed,
        ),
      );

      return reports;
    }

    for (final client in clients) {
      final clientAppointments = appointments.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        final clientKey = (data['tenantId'] ??
            data['clientId'] ??
            data['createdBy'] ??
            data['businessId'] ??
            '')
            .toString();

        if (clientKey.isEmpty) return clients.length == 1;
        return clientKey == client.id || clientKey == client.email;
      }).toList();

      final clientPayments = payments.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        final clientKey = (data['tenantId'] ??
            data['clientId'] ??
            data['createdBy'] ??
            data['businessId'] ??
            '')
            .toString();

        if (clientKey.isEmpty) return clients.length == 1;
        return clientKey == client.id || clientKey == client.email;
      }).toList();

      final clientSubscriptions = subscriptions.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        final clientKey =
        (data['clientId'] ?? data['tenantId'] ?? data['userId'] ?? '')
            .toString();

        if (clientKey.isEmpty) return clients.length == 1;
        return clientKey == client.id || clientKey == client.email;
      }).toList();

      final clientRevenue = clientPayments.fold<num>(0, (sum, doc) {
        final data = doc.data() as Map<String, dynamic>;
        return isPaid(data) ? sum + toNumber(data['amount']) : sum;
      }) +
          clientSubscriptions.fold<num>(0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return isPaid(data) ? sum + toNumber(data['amount']) : sum;
          });

      final latestDate = latestDateFor(
        clientAppointments,
        clientPayments,
        clientSubscriptions,
      );

      reports.add(
        ReportRowModel(
          clientName: client.name,
          clientId: client.id,
          reportType: 'Client Revenue Report',
          generatedDate: formatDate(latestDate ?? DateTime.now()),
          revenueValue: '₱${clientRevenue.toStringAsFixed(2)}',
          status: ReportStatus.processed,
        ),
      );

      reports.add(
        ReportRowModel(
          clientName: client.name,
          clientId: client.id,
          reportType: 'Appointment Report',
          generatedDate: formatDate(latestDate ?? DateTime.now()),
          revenueValue: '${clientAppointments.length} bookings',
          status: clientAppointments.isEmpty
              ? ReportStatus.draft
              : ReportStatus.processed,
        ),
      );

      reports.add(
        ReportRowModel(
          clientName: client.name,
          clientId: client.id,
          reportType: 'Subscription Revenue Report',
          generatedDate: formatDate(latestDate ?? DateTime.now()),
          revenueValue:
          '₱${clientSubscriptions.fold<num>(0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return isPaid(data) ? sum + toNumber(data['amount']) : sum;
          }).toStringAsFixed(2)}',
          status: ReportStatus.processed,
        ),
      );
    }

    reports.add(
      ReportRowModel(
        clientName: 'All Network Partners',
        clientId: 'SYSTEM',
        reportType: 'Usage Report',
        generatedDate: formatDate(DateTime.now()),
        revenueValue: '$appointmentCount bookings / $paymentCount payments',
        status: ReportStatus.processed,
      ),
    );

    reports.sort((a, b) => b.generatedDate.compareTo(a.generatedDate));

    return reports;
  }

  DateTime? latestDateFor(
      List<QueryDocumentSnapshot> appointments,
      List<QueryDocumentSnapshot> payments,
      List<QueryDocumentSnapshot> subscriptions,
      ) {
    final dates = <DateTime>[];

    for (final doc in appointments) {
      final data = doc.data() as Map<String, dynamic>;
      final date = toDate(data['updatedAt'] ?? data['createdAt'] ?? data['appointmentDate']);
      if (date != null) dates.add(date);
    }

    for (final doc in payments) {
      final data = doc.data() as Map<String, dynamic>;
      final date = toDate(data['updatedAt'] ?? data['createdAt']);
      if (date != null) dates.add(date);
    }

    for (final doc in subscriptions) {
      final data = doc.data() as Map<String, dynamic>;
      final date = toDate(data['updatedAt'] ?? data['createdAt']);
      if (date != null) dates.add(date);
    }

    if (dates.isEmpty) return null;

    dates.sort((a, b) => b.compareTo(a));
    return dates.first;
  }

  List<ReportRowModel> filterReports(List<ReportRowModel> reports) {
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
    return AdminMainLayout(
      user: widget.user,
      currentRoute: 'View System Reports',
      child: StreamBuilder<QuerySnapshot>(
                    stream: clientsStream,
                    builder: (context, clientSnapshot) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: usersStream,
                        builder: (context, userSnapshot) {
                          return StreamBuilder<QuerySnapshot>(
                            stream: appointmentsStream,
                            builder: (context, appointmentSnapshot) {
                              return StreamBuilder<QuerySnapshot>(
                                stream: paymentsStream,
                                builder: (context, paymentSnapshot) {
                                  return StreamBuilder<QuerySnapshot>(
                                    stream: subscriptionPaymentsStream,
                                    builder: (context, subscriptionSnapshot) {
                                      final isWaiting =
                                          clientSnapshot.connectionState ==
                                              ConnectionState.waiting ||
                                              userSnapshot.connectionState ==
                                                  ConnectionState.waiting ||
                                              appointmentSnapshot
                                                  .connectionState ==
                                                  ConnectionState.waiting ||
                                              paymentSnapshot.connectionState ==
                                                  ConnectionState.waiting ||
                                              subscriptionSnapshot
                                                  .connectionState ==
                                                  ConnectionState.waiting;

                                      if (isWaiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      final clientDocs =
                                          clientSnapshot.data?.docs ?? [];
                                      final userDocs =
                                          userSnapshot.data?.docs ?? [];
                                      final appointmentDocs =
                                          appointmentSnapshot.data?.docs ?? [];
                                      final paymentDocs =
                                          paymentSnapshot.data?.docs ?? [];
                                      final subscriptionDocs =
                                          subscriptionSnapshot.data?.docs ?? [];

                                      final clients = buildClients(
                                        clientDocs,
                                        userDocs,
                                      );

                                      final reports = buildReports(
                                        clients: clients,
                                        appointments: appointmentDocs,
                                        payments: paymentDocs,
                                        subscriptions: subscriptionDocs,
                                      );

                                      final filteredReports =
                                      filterReports(reports);

                                      return SingleChildScrollView(
                                        padding: const EdgeInsets.fromLTRB(
                                          40,
                                          36,
                                          40,
                                          40,
                                        ),
                                        child: _SystemReportsContent(
                                          reports: filteredReports,
                                          totalReports: reports.length,
                                          clients: clients,
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
    );
  }
}

enum ReportStatus {
  processed,
  draft,
}

class ClientModel {
  final String id;
  final String name;
  final String email;

  const ClientModel({
    required this.id,
    required this.name,
    required this.email,
  });
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
  final List<ClientModel> clients;
  final String selectedClient;
  final ValueChanged<String?> onClientChanged;
  final ValueChanged<String> onSearchChanged;

  const _SystemReportsContent({
    required this.reports,
    required this.totalReports,
    required this.clients,
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
        _ReportCategoryCards(onCardTap: onSearchChanged),
        const SizedBox(height: 54),
        _ReportsDataPanel(
          reports: reports,
          totalReports: totalReports,
          clients: clients,
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
            'Access and filter detailed reports across your entire client network using live Firestore data.',
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
  final ValueChanged<String> onCardTap;

  const _ReportCategoryCards({required this.onCardTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ReportCategoryCard(
            icon: Icons.account_balance_wallet,
            title: 'Subscription Revenue Report',
            description:
            'Summary of subscription payments and active billing records.',
            liveView: true,
            onTap: () => onCardTap('Subscription Revenue Report'),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _ReportCategoryCard(
            icon: Icons.storefront,
            title: 'Client Revenue Report',
            description:
            'Breakdown of earnings generated from each spa client account.',
            onTap: () => onCardTap('Client Revenue Report'),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _ReportCategoryCard(
            icon: Icons.calendar_month,
            title: 'Appointment Report',
            description:
            'Network-wide booking statistics and appointment activity.',
            onTap: () => onCardTap('Appointment Report'),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _ReportCategoryCard(
            icon: Icons.insights,
            title: 'Usage Report',
            description:
            'System activity based on bookings, payments, and records.',
            onTap: () => onCardTap('Usage Report'),
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
  final VoidCallback onTap;

  const _ReportCategoryCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.liveView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(28),
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
          ),
        ),
      ),
    );
  }
}

class _ReportsDataPanel extends StatelessWidget {
  final List<ReportRowModel> reports;
  final int totalReports;
  final List<ClientModel> clients;
  final String selectedClient;
  final ValueChanged<String?> onClientChanged;
  final ValueChanged<String> onSearchChanged;

  const _ReportsDataPanel({
    required this.reports,
    required this.totalReports,
    required this.clients,
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
            clients: clients,
            selectedClient: selectedClient,
            onClientChanged: onClientChanged,
            onSearchChanged: onSearchChanged,
            reports: reports,
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
  final List<ClientModel> clients;
  final String selectedClient;
  final ValueChanged<String?> onClientChanged;
  final ValueChanged<String> onSearchChanged;
  final List<ReportRowModel> reports;

  const _ReportsFilterBar({
    required this.clients,
    required this.selectedClient,
    required this.onClientChanged,
    required this.onSearchChanged,
    required this.reports,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ClientDropdown(
            clients: clients,
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
        _ExportButton(reports: reports),
      ],
    );
  }
}

class _ClientDropdown extends StatelessWidget {
  final List<ClientModel> clients;
  final String selectedClient;
  final ValueChanged<String?> onChanged;

  const _ClientDropdown({
    required this.clients,
    required this.selectedClient,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final names = [
      'All Network Partners',
      ...clients.map((client) => client.name),
    ];

    final value = names.contains(selectedClient)
        ? selectedClient
        : 'All Network Partners';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FilterLabel('BY CLIENT'),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down),
          decoration: _fieldDecoration(),
          items: names.map((client) {
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
            hintText: 'Client name, ID, or report type...',
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
  final List<ReportRowModel> reports;

  const _ExportButton({required this.reports});

  Future<void> _exportPDF() async {
    if (reports.isEmpty) return;
    
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Header(level: 0, child: pw.Text('System Reports Data', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Client Name', 'Report Type', 'Date', 'Value', 'Status'],
              data: reports.map((r) {
                final statusString = r.status == ReportStatus.processed ? 'Processed' : 'Draft';
                return [r.clientName, r.reportType, r.generatedDate, r.revenueValue, statusString];
              }).toList(),
            ),
          ];
        },
      ),
    );

    Uint8List bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'system_reports_${DateTime.now().millisecondsSinceEpoch}.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          gradient: reports.isEmpty
              ? null
              : AppColors.primaryGradient,
          color: reports.isEmpty ? AppColors.surfaceContainerHigh : null,
          borderRadius: BorderRadius.circular(9),
          boxShadow: reports.isEmpty
              ? null
              : const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 184, 148, 0.18),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
        ),
        child: TextButton.icon(
          onPressed: reports.isEmpty ? null : _exportPDF,
          icon: Icon(Icons.download, color: reports.isEmpty ? AppColors.secondary : Colors.white),
          label: Text(
            'Export Data',
            style: TextStyle(
              color: reports.isEmpty ? AppColors.secondary : Colors.white,
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
              child: _TableHeaderText('REVENUE / VALUE'),
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
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => _ReportDetailsDialog(report: report),
                );
              },
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


class _ReportDetailsDialog extends StatelessWidget {
  final ReportRowModel report;

  const _ReportDetailsDialog({
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final bool isProcessed = report.status == ReportStatus.processed;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(45, 52, 54, 0.18),
              blurRadius: 32,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    report.reportType,
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
            const SizedBox(height: 26),
            _ReportDetailRow(
              label: 'Client Name',
              value: report.clientName,
            ),
            _ReportDetailRow(
              label: 'Client ID',
              value: report.clientId,
            ),
            _ReportDetailRow(
              label: 'Generated Date',
              value: report.generatedDate,
            ),
            _ReportDetailRow(
              label: 'Revenue / Value',
              value: report.revenueValue,
              isHighlighted: true,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(
                  width: 150,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _ReportStatusBadge(status: report.status),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isProcessed
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isProcessed
                    ? 'This report is generated from your live Firestore database.'
                    : 'This report is still in draft because there are no matching records yet.',
                style: TextStyle(
                  color: isProcessed ? AppColors.primary : AppColors.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _ReportDetailRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isHighlighted ? AppColors.primary : AppColors.onSurface,
                fontSize: 15,
                fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
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
    final fromText = visibleCount == 0 ? '0' : '1';

    return Container(
      color: AppColors.surfaceContainerLow.withValues(alpha: 0.30),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      child: Row(
        children: [
          Text(
            'SHOWING $fromText TO $visibleCount OF $totalReports ENTRIES',
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
