import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../widgets/client_main_layout.dart';
import 'add_service_modal.dart';

class ClientServicesPage extends StatefulWidget {
  final UserModel user;

  const ClientServicesPage({
    super.key,
    required this.user,
  });

  @override
  State<ClientServicesPage> createState() => _ClientServicesPageState();
}

class _ClientServicesPageState extends State<ClientServicesPage> {
  String selectedCategory = 'All Services';
  String searchQuery = '';

  void _openAddServiceDialog() {
    showDialog(
      context: context,
      builder: (_) => const AddServiceModal(),
    );
  }

  void _openEditServiceDialog(String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AddServiceModal(
        docId: docId,
        serviceData: data,
      ),
    );
  }

  Future<void> _archiveService(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Archive Service',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Are you sure you want to archive this service? It will be moved to the Archive page.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A884),
              foregroundColor: Colors.white,
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final serviceRef =
    FirebaseFirestore.instance.collection('services').doc(docId);
    final serviceSnap = await serviceRef.get();

    if (!serviceSnap.exists) return;

    final serviceData = serviceSnap.data() as Map<String, dynamic>;

    await FirebaseFirestore.instance.collection('archives').add({
      ...serviceData,
      'dataType': 'Archived Service',
      'collectionName': 'services',
      'originalDocId': docId,
      'targetName': serviceData['name'] ?? 'Unnamed Service',
      'tenantId': serviceData['tenantId'] ?? widget.user.tenantId,
      'archivedAt': FieldValue.serverTimestamp(),
      'archivedBy': widget.user.uid,
      'archivedByName': widget.user.fullName,
      'archivedByRole': 'client_admin',
      'restored': false,
      'status': 'archived',
    });

    await serviceRef.update({
      'isArchived': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Service archived.'),
        backgroundColor: Color(0xFF00A884),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    if (category == 'Body Massage') return Icons.spa_outlined;
    if (category == 'Foot Massage') return Icons.directions_walk_outlined;
    if (category == 'Face Massage') return Icons.face_outlined;
    return Icons.spa_outlined;
  }

  List<QueryDocumentSnapshot> _filterDocs(List<QueryDocumentSnapshot> docs) {
    final query = searchQuery.trim().toLowerCase();

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final category = data['category']?.toString() ?? '';
      final name = data['name']?.toString().toLowerCase() ?? '';
      final description = data['description']?.toString().toLowerCase() ?? '';
      final status = data['status']?.toString().toLowerCase() ?? '';

      final matchesCategory =
          selectedCategory == 'All Services' || category == selectedCategory;

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          description.contains(query) ||
          category.toLowerCase().contains(query) ||
          status.contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return ClientMainLayout(
      user: widget.user,
      currentRoute: 'services',
      child: Container(
        color: const Color(0xFFF4FAFD),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('services')
              .where('isArchived', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final filteredDocs = _filterDocs(docs);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ServicesHeader(),
                  const SizedBox(height: 34),
                  _ServiceToolbar(
                    selectedCategory: selectedCategory,
                    onCategoryChanged: (value) {
                      setState(() => selectedCategory = value);
                    },
                    onSearchChanged: (value) {
                      setState(() => searchQuery = value);
                    },
                    onAddService: _openAddServiceDialog,
                  ),
                  const SizedBox(height: 24),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    _ServicesTable(
                      docs: filteredDocs,
                      totalServices: docs.length,
                      iconForCategory: _iconForCategory,
                      onEdit: _openEditServiceDialog,
                      onArchive: _archiveService,
                    ),
                  const SizedBox(height: 56),
                  const _ServicesAnalytics(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ServicesHeader extends StatelessWidget {
  const _ServicesHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 820),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Catalog',
            style: TextStyle(
              color: Color(0xFF161D1F),
              fontSize: 44,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: -1.4,
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Manage and refine your clinical offerings. Set pricing, duration, and visibility for every treatment within the Sanctuary.',
            style: TextStyle(
              color: Color(0xFF586062),
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

class _ServiceToolbar extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddService;

  const _ServiceToolbar({
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onSearchChanged,
    required this.onAddService,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 200,
          child: _ServiceCategoryDropdown(
            selectedCategory: selectedCategory,
            onChanged: onCategoryChanged,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _ServiceSearchBox(onChanged: onSearchChanged),
        ),
        const SizedBox(width: 18),
        _AddServiceButton(onPressed: onAddService),
      ],
    );
  }
}

class _ServiceCategoryDropdown extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onChanged;

  const _ServiceCategoryDropdown({
    required this.selectedCategory,
    required this.onChanged,
  });

  static const List<String> categories = [
    'All Services',
    'Body Massage',
    'Foot Massage',
    'Face Massage',
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 52),
      color: Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      onSelected: onChanged,
      itemBuilder: (context) {
        return categories.map((category) {
          return PopupMenuItem<String>(
            value: category,
            height: 48,
            child: Text(
              category,
              style: TextStyle(
                color: const Color(0xFF586062),
                fontSize: 13,
                fontWeight:
                category == selectedCategory ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE3E9EC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedCategory,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF586062),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF586062)),
          ],
        ),
      ),
    );
  }
}

class _ServiceSearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _ServiceSearchBox({
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search services...',
          prefixIcon: const Icon(Icons.search, color: Color(0x99586062)),
          filled: true,
          fillColor: const Color(0xFFEEF5F7),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _AddServiceButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddServiceButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 24),
        label: const Text('Add New Service'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A884),
          foregroundColor: Colors.white,
          elevation: 10,
          shadowColor: const Color(0x33006B55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ServicesTable extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final int totalServices;
  final IconData Function(String category) iconForCategory;
  final void Function(String docId, Map<String, dynamic> data) onEdit;
  final void Function(String docId) onArchive;

  const _ServicesTable({
    required this.docs,
    required this.totalServices,
    required this.iconForCategory,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      minWidth: 720,
      child: Column(
        children: [
          const _ServicesTableHeader(),
          if (docs.isEmpty)
            const _EmptyServicesRow()
          else
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return _ServiceTableRow(
                data: data,
                icon: iconForCategory(data['category'] ?? ''),
                showBorder: doc != docs.last,
                onEdit: () => onEdit(doc.id, data),
                onArchive: () => onArchive(doc.id),
              );
            }),
          _ServicesTableFooter(
            showingCount: docs.length,
            totalCount: totalServices,
          ),
        ],
      ),
    );
  }
}

class _ServicesTableHeader extends StatelessWidget {
  const _ServicesTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      color: const Color(0xFFEEF5F7),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: const Row(
        children: [
          Expanded(
            flex: 26,
            child: Row(
              children: [
                SizedBox(width: 58),
                Expanded(child: _TableHeaderText('SERVICE NAME')),
              ],
            ),
          ),
          Expanded(
            flex: 34,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TableHeaderText('DESCRIPTION'),
            ),
          ),
          Expanded(
            flex: 16,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TableHeaderText('DURATION'),
            ),
          ),
          Expanded(
            flex: 14,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TableHeaderText('PRICE'),
            ),
          ),
          Expanded(
            flex: 16,
            child: Align(
              alignment: Alignment.center,
              child: _TableHeaderText('STATUS'),
            ),
          ),
          Expanded(
            flex: 16,
            child: Align(
              alignment: Alignment.center,
              child: _TableHeaderText('ACTIONS'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTableRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final IconData icon;
  final bool showBorder;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _ServiceTableRow({
    required this.data,
    required this.icon,
    required this.showBorder,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unnamed Service';
    final description = data['description'] ?? '';
    final duration = data['durationMinutes'] ?? 0;
    final price = data['price'] ?? 0;
    final status = data['status'] ?? 'Draft';
    final isActive = data['isActive'] == true;

    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: showBorder
              ? const BorderSide(color: Color(0xFFE9EFF2))
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 26,
            child: Row(
              children: [
                _ServiceIconBox(icon: icon, active: isActive),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Color(0xFF161D1F),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 34,
            child: Text(
              description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF586062)),
            ),
          ),
          Expanded(
            flex: 16,
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Color(0x99586062), size: 16),
                const SizedBox(width: 7),
                Text('$duration mins'),
              ],
            ),
          ),
          Expanded(
            flex: 14,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '₱${double.tryParse(price.toString())?.toStringAsFixed(2) ?? price}',
                style: const TextStyle(
                  color: Color(0xFF161D1F),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 16,
            child: Center(
              child: _ServiceStatusBadge(status: status, active: isActive),
            ),
          ),
          Expanded(
            flex: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TableActionButton(
                  icon: Icons.edit,
                  tooltip: 'Edit',
                  onTap: onEdit,
                ),
                const SizedBox(width: 12),
                _TableActionButton(
                  icon: Icons.archive,
                  tooltip: 'Archive',
                  onTap: onArchive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyServicesRow extends StatelessWidget {
  const _EmptyServicesRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      color: Colors.white,
      alignment: Alignment.center,
      child: const Text(
        'No services found. Click Add New Service to create one.',
        style: TextStyle(color: Color(0xFF586062)),
      ),
    );
  }
}

class _ServicesTableFooter extends StatelessWidget {
  final int showingCount;
  final int totalCount;

  const _ServicesTableFooter({
    required this.showingCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      color: const Color(0xFFEEF5F7),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      alignment: Alignment.centerLeft,
      child: Text(
        'Showing $showingCount of $totalCount clinical services',
        style: const TextStyle(
          color: Color(0xFF586062),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TableShell extends StatelessWidget {
  final double minWidth;
  final Widget child;

  const _TableShell({
    required this.minWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(minWidth, constraints.maxWidth);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D2D3436),
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: tableWidth, child: child),
          ),
        );
      },
    );
  }
}

class _ServiceIconBox extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _ServiceIconBox({
    required this.icon,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE6FAF3) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: active ? const Color(0xFF00A884) : const Color(0xFF94A3B8),
      ),
    );
  }
}

class _ServiceStatusBadge extends StatelessWidget {
  final String status;
  final bool active;

  const _ServiceStatusBadge({
    required this.status,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFD8F8EA) : const Color(0xFFE3E9EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: active ? const Color(0xFF006B55) : const Color(0xFF586062),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TableActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _TableActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: const Color(0xFF586062), size: 22),
        ),
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
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF586062),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
      ),
    );
  }
}

class _ServicesAnalytics extends StatelessWidget {
  const _ServicesAnalytics();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}