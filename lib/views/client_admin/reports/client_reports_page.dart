import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../models/user_model.dart';
import '../widgets/client_main_layout.dart';

class ClientReportsPage extends StatefulWidget {
  final UserModel user;

  const ClientReportsPage({
    super.key,
    required this.user,
  });

  @override
  State<ClientReportsPage> createState() => _ClientReportsPageState();
}

class _ClientReportsPageState extends State<ClientReportsPage> {
  String selectedReportFilter = 'Daily';

  Stream<QuerySnapshot> get appointmentsStream {
    return FirebaseFirestore.instance.collection('appointments').snapshots();
  }

  Stream<QuerySnapshot> get paymentsStream {
    return FirebaseFirestore.instance
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  num toNumber(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  DateTime? getDate(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    final appointmentDate = data['appointmentDate'];
    final updatedAt = data['updatedAt'];

    if (createdAt is Timestamp) return createdAt.toDate();
    if (appointmentDate is Timestamp) return appointmentDate.toDate();
    if (updatedAt is Timestamp) return updatedAt.toDate();

    return null;
  }

  bool inSelectedFilter(Map<String, dynamic> data) {
    final date = getDate(data);
    if (date == null) return true;

    final now = DateTime.now();

    if (selectedReportFilter == 'Daily') {
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }

    if (selectedReportFilter == 'Weekly') {
      return now.difference(date).inDays <= 7;
    }

    if (selectedReportFilter == 'Monthly') {
      return date.year == now.year && date.month == now.month;
    }

    if (selectedReportFilter == 'Yearly') {
      return date.year == now.year;
    }

    return true;
  }

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.month}/${date.day}/${date.year}';
    }

    return 'No date';
  }

  String formatTime(Map<String, dynamic> data) {
    return (data['appointmentTime'] ?? '').toString();
  }

  bool isFullPayment(Map<String, dynamic> data) {
    final status = (data['status'] ?? data['paymentStatus'] ?? '')
        .toString()
        .toLowerCase();

    return status.contains('full payment') ||
        status.contains('paid') ||
        status.contains('verified');
  }

  Future<void> downloadReportPdf({
    required List<Map<String, dynamic>> salesRecords,
    required List<Map<String, dynamic>> appointmentRecords,
    required num totalSales,
  }) async {
    final bytes = await _buildReportPdf(
      businessName: widget.user.businessName.isEmpty
          ? 'Serenity Management Suite'
          : widget.user.businessName,
      adminName: widget.user.fullName,
      filter: selectedReportFilter,
      salesRecords: salesRecords,
      appointmentRecords: appointmentRecords,
      totalSales: totalSales,
    );

    final fileName =
        'report_${selectedReportFilter.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
    );
  }

  Future<Uint8List> _buildReportPdf({
    required String businessName,
    required String adminName,
    required String filter,
    required List<Map<String, dynamic>> salesRecords,
    required List<Map<String, dynamic>> appointmentRecords,
    required num totalSales,
  }) async {
    final pdf = pw.Document();

    String pdfDate(dynamic value) {
      if (value is Timestamp) {
        final date = value.toDate();
        return '${date.month}/${date.day}/${date.year}';
      }

      return 'No date';
    }

    String pdfTime(Map<String, dynamic> data) {
      return (data['appointmentTime'] ?? '').toString();
    }

    String money(dynamic value) {
      return 'PHP ${toNumber(value).toStringAsFixed(2)}';
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(28),
        ),
        build: (context) {
          return [
            pw.Text(
              '$businessName Report',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text('$filter Summary Report'),
            pw.Text('Prepared by: $adminName'),
            pw.Text('Generated: ${DateTime.now()}'),
            pw.SizedBox(height: 18),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Sales: ${money(totalSales)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Sales Records: ${salesRecords.length}'),
                  pw.Text('Appointments: ${appointmentRecords.length}'),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Text(
              'Sales Report',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            if (salesRecords.isEmpty)
              pw.Text('No full payment records for this filter.')
            else
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Date',
                  'Service',
                  'Customer',
                  'Method',
                  'Reference',
                  'Amount',
                  'Status',
                ],
                data: salesRecords.map((data) {
                  return [
                    pdfDate(data['createdAt']),
                    (data['serviceName'] ?? data['service'] ?? 'Service')
                        .toString(),
                    (data['customerName'] ?? 'Customer').toString(),
                    (data['paymentMethod'] ?? data['method'] ?? '').toString(),
                    (data['gcashReferenceNumber'] ??
                        data['referenceNumber'] ??
                        data['reference'] ??
                        '-')
                        .toString(),
                    money(data['amount']),
                    (data['status'] ?? 'Full Payment').toString(),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            pw.SizedBox(height: 22),
            pw.Text(
              'Appointment Report',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            if (appointmentRecords.isEmpty)
              pw.Text('No appointment records for this filter.')
            else
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Date',
                  'Time',
                  'Customer',
                  'Service',
                  'Therapist',
                  'Status',
                ],
                data: appointmentRecords.map((data) {
                  return [
                    pdfDate(data['appointmentDate']),
                    pdfTime(data),
                    (data['customerName'] ?? 'Customer').toString(),
                    (data['serviceName'] ?? 'Service').toString(),
                    (data['staffName'] ??
                        data['therapistName'] ??
                        'Any available therapist')
                        .toString(),
                    (data['status'] ?? 'Pending').toString(),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return ClientMainLayout(
      user: widget.user,
      currentRoute: 'reports',
      child: Container(
        color: const Color(0xFFF4FAFD),
        child: StreamBuilder<QuerySnapshot>(
          stream: appointmentsStream,
          builder: (context, appointmentSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: paymentsStream,
              builder: (context, paymentSnapshot) {
                if (appointmentSnapshot.connectionState ==
                    ConnectionState.waiting ||
                    paymentSnapshot.connectionState ==
                        ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final appointmentDocs = appointmentSnapshot.data?.docs ?? [];
                final paymentDocs = paymentSnapshot.data?.docs ?? [];

                final allAppointments = appointmentDocs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .toList();

                final filteredAppointments =
                allAppointments.where(inSelectedFilter).toList();

                final salesRecords = paymentDocs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .where((data) => isFullPayment(data))
                    .where(inSelectedFilter)
                    .toList();

                final totalSales = salesRecords.fold<num>(
                  0,
                      (sum, data) => sum + toNumber(data['amount']),
                );

                final completedCount = filteredAppointments.where((data) {
                  return (data['status'] ?? '').toString().toLowerCase() ==
                      'completed';
                }).length;

                final completionRate = filteredAppointments.isEmpty
                    ? 0
                    : ((completedCount / filteredAppointments.length) * 100)
                    .round();

                final pendingCount = filteredAppointments.where((data) {
                  return (data['status'] ?? '').toString().toLowerCase() ==
                      'pending';
                }).length;

                return SingleChildScrollView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 42),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reports',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF161D1F),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'View sales and appointment reports from your booking database.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF586062),
                        ),
                      ),
                      const SizedBox(height: 42),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'Total Sales',
                              value: '₱${totalSales.toStringAsFixed(2)}',
                              subtitle:
                              '$selectedReportFilter full payment records',
                              icon: Icons.payments_outlined,
                            ),
                          ),
                          const SizedBox(width: 28),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Total Appointments',
                              value: '${filteredAppointments.length}',
                              subtitle: '$completionRate% Completion Rate',
                              icon: Icons.calendar_month_outlined,
                            ),
                          ),
                          const SizedBox(width: 28),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Pending Requests',
                              value: '$pendingCount',
                              subtitle: 'Waiting for approval',
                              icon: Icons.pending_actions_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: _SectionHeader(
                              title: 'Sales Report',
                              subtitle:
                              'Full payment records from payment history.',
                            ),
                          ),
                          _SalesFilterDropdown(
                            value: selectedReportFilter,
                            onChanged: (value) {
                              setState(() => selectedReportFilter = value);
                            },
                          ),
                          const SizedBox(width: 12),
                          _DownloadReportButton(
                            onPressed: () {
                              downloadReportPdf(
                                salesRecords: salesRecords,
                                appointmentRecords: filteredAppointments,
                                totalSales: totalSales,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _SalesReportTable(
                        records: salesRecords,
                        formatDate: formatDate,
                        toNumber: toNumber,
                      ),
                      const SizedBox(height: 42),
                      const _SectionHeader(
                        title: 'Appointment Report',
                        subtitle:
                        'Real-time status tracking for all scheduled sessions.',
                      ),
                      const SizedBox(height: 18),
                      _AppointmentReportTable(
                        records: filteredAppointments,
                        formatDate: formatDate,
                        formatTime: formatTime,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DownloadReportButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DownloadReportButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.download, size: 18),
        label: const Text('Download Report'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A884),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _SalesFilterDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SalesFilterDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const items = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 48),
      color: Colors.white,
      elevation: 10,
      onSelected: onChanged,
      itemBuilder: (context) {
        return items.map((item) {
          return PopupMenuItem<String>(
            value: item,
            height: 46,
            child: Text(item),
          );
        }).toList();
      },
      child: Container(
        width: 160,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE9EFF2)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(value)),
            const Icon(Icons.keyboard_arrow_down, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 155,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          top: BorderSide(color: Color(0xFF00B894), width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -12,
            child: Icon(
              icon,
              size: 92,
              color: const Color(0xFF00B894).withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF586062),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF161D1F),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF006B55),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF161D1F),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF586062),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _SalesReportTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final String Function(dynamic value) formatDate;
  final num Function(dynamic value) toNumber;

  const _SalesReportTable({
    required this.records,
    required this.formatDate,
    required this.toNumber,
  });

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      child: Column(
        children: [
          const _TableHeader(
            columns: [
              'DATE',
              'SERVICE',
              'CUSTOMER',
              'METHOD',
              'REFERENCE',
              'AMOUNT',
              'STATUS',
            ],
            flexes: [2, 3, 3, 2, 3, 2, 2],
          ),
          if (records.isEmpty)
            const _EmptyRow(text: 'No full payment records for this filter.')
          else
            ...records.map((data) {
              return _TableRowShell(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      formatDate(data['createdAt']),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      data['serviceName'] ?? data['service'] ?? 'Service',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      data['customerName'] ?? 'Customer',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      data['paymentMethod'] ?? data['method'] ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      (data['gcashReferenceNumber'] ??
                          data['referenceNumber'] ??
                          data['reference'] ??
                          '-')
                          .toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₱${toNumber(data['amount']).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _StatusText(status: data['status'] ?? 'Full Payment'),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _AppointmentReportTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final String Function(dynamic value) formatDate;
  final String Function(Map<String, dynamic> data) formatTime;

  const _AppointmentReportTable({
    required this.records,
    required this.formatDate,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      child: Column(
        children: [
          const _TableHeader(
            columns: [
              'DATE / TIME',
              'CUSTOMER',
              'SERVICE',
              'THERAPIST',
              'STATUS',
            ],
            flexes: [2, 3, 3, 3, 2],
          ),
          if (records.isEmpty)
            const _EmptyRow(text: 'No appointment records for this filter.')
          else
            ...records.map((data) {
              return _TableRowShell(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDate(data['appointmentDate']),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          formatTime(data),
                          style: const TextStyle(
                            color: Color(0xFF586062),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(data['customerName'] ?? 'Customer'),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(data['serviceName'] ?? 'Service'),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      data['staffName'] ??
                          data['therapistName'] ??
                          'Any available therapist',
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _StatusText(status: data['status'] ?? 'Pending'),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _TableShell extends StatelessWidget {
  final Widget child;

  const _TableShell({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}

class _TableHeader extends StatelessWidget {
  final List<String> columns;
  final List<int> flexes;

  const _TableHeader({
    required this.columns,
    required this.flexes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEF5F7),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
      child: Row(
        children: List.generate(columns.length, (index) {
          return Expanded(
            flex: flexes[index],
            child: Text(
              columns[index],
              style: const TextStyle(
                color: Color(0xFF586062),
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.8,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TableRowShell extends StatelessWidget {
  final List<Widget> children;

  const _TableRowShell({
    required this.children,
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
      child: Row(children: children),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String text;

  const _EmptyRow({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF586062)),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  final String status;

  const _StatusText({
    required this.status,
  });

  Color get color {
    final value = status.toLowerCase();

    if (value.contains('full') ||
        value.contains('paid') ||
        value.contains('verified') ||
        value == 'approved' ||
        value == 'completed') {
      return const Color(0xFF006B55);
    }

    if (value == 'cancelled' || value == 'declined') {
      return const Color(0xFFE53935);
    }

    if (value == 'rescheduled') {
      return const Color(0xFF1565C0);
    }

    return const Color(0xFF9A6B00);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            status,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
