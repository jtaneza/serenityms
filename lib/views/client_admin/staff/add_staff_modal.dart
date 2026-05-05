import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddStaffModal extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? staffData;

  const AddStaffModal({
    super.key,
    this.docId,
    this.staffData,
  });

  @override
  State<AddStaffModal> createState() => _AddStaffModalState();
}

class _AddStaffModalState extends State<AddStaffModal> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController serviceSearchController = TextEditingController();

  String specialization = 'Body Massage Specialist';
  String staffStatus = 'Active';
  String serviceCategoryFilter = 'All';
  String startTime = '09:00 AM';
  String endTime = '02:00 AM';
  String serviceSearch = '';

  final List<String> selectedServices = [];
  final List<String> selectedDays = ['M', 'T', 'W', 'TH', 'F'];

  bool isSaving = false;

  final List<String> specializations = [
    'Body Massage Specialist',
    'Foot Massage Specialist',
    'Face Massage Specialist',
    'Body and Foot Massage Specialist',
    'Face and Body Massage Specialist',
    'All-Around Massage Therapist',
  ];

  final List<String> staffStatuses = [
    'Active',
    'On Leave',
    'Rest Day',
    'Away',
    'Inactive',
  ];

  final List<String> serviceCategories = [
    'All',
    'Body Massage',
    'Foot Massage',
    'Face Massage',
  ];

  @override
  void initState() {
    super.initState();

    final data = widget.staffData;
    if (data != null) {
      nameController.text = data['name'] ?? '';
      specialization = data['specialization'] ?? specialization;
      staffStatus = data['status'] ?? staffStatus;
      startTime = data['startTime'] ?? startTime;
      endTime = data['endTime'] ?? endTime;

      selectedServices
        ..clear()
        ..addAll(List<String>.from(data['services'] ?? []));

      selectedDays
        ..clear()
        ..addAll(List<String>.from(data['days'] ?? []));
    }

    serviceSearchController.addListener(() {
      setState(() {
        serviceSearch = serviceSearchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    serviceSearchController.dispose();
    super.dispose();
  }

  Future<void> saveStaff() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter full name')),
      );
      return;
    }

    if (selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please assign at least one service')),
      );
      return;
    }

    setState(() => isSaving = true);

    final data = {
      'name': nameController.text.trim(),
      'role': specialization,
      'specialization': specialization,
      'services': selectedServices,
      'days': selectedDays,
      'startTime': startTime,
      'endTime': endTime,
      'schedule': '${selectedDays.join(', ')}, $startTime - $endTime',
      'status': staffStatus,
      'isAway': staffStatus != 'Active',
      'rating': 0,
      'updatedAt': FieldValue.serverTimestamp(),
      if (widget.docId == null) 'createdAt': FieldValue.serverTimestamp(),
    };

    final collection = FirebaseFirestore.instance.collection('staff');

    if (widget.docId == null) {
      await collection.add(data);
    } else {
      await collection.doc(widget.docId).update(data);
    }

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.docId == null
              ? 'Staff member added'
              : 'Staff member updated',
        ),
      ),
    );
  }

  Future<void> pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? const TimeOfDay(hour: 9, minute: 0)
          : const TimeOfDay(hour: 2, minute: 0),
    );

    if (picked == null) return;

    final formatted = picked.format(context);

    setState(() {
      if (isStart) {
        startTime = formatted;
      } else {
        endTime = formatted;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 820,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 64,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 36, 40, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.docId == null
                              ? 'Add New Staff Member'
                              : 'Edit Staff Member',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF161D1F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Register a staff member and assign real services from your service catalog.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF586062),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFE9EFF2),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(40, 10, 40, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ModalSectionTitle(
                      icon: Icons.person_add_alt,
                      title: 'IDENTITY DETAILS',
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _ModalTextField(
                            controller: nameController,
                            label: 'Full Name',
                            hint: 'e.g. Maria Santos',
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _ModalDropdownField(
                            label: 'Specialization',
                            value: specialization,
                            items: specializations,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => specialization = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _ModalDropdownField(
                            label: 'Staff Status',
                            value: staffStatus,
                            items: staffStatuses,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => staffStatus = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    const _ModalSectionTitle(
                      icon: Icons.spa_outlined,
                      title: 'ASSIGNED SERVICES',
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: TextField(
                              controller: serviceSearchController,
                              decoration: InputDecoration(
                                hintText: 'Search services...',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: const Color(0xFFE9EFF2),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 210,
                          child: _ModalDropdownField(
                            label: '',
                            showLabel: false,
                            value: serviceCategoryFilter,
                            items: serviceCategories,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => serviceCategoryFilter = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('services')
                          .where('isArchived', isEqualTo: false)
                          .where('isActive', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        final filteredDocs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name =
                              data['name']?.toString().toLowerCase() ?? '';
                          final category =
                              data['category']?.toString() ?? 'Uncategorized';
                          final categoryLower = category.toLowerCase();

                          final matchesSearch = serviceSearch.isEmpty ||
                              name.contains(serviceSearch) ||
                              categoryLower.contains(serviceSearch);

                          final matchesCategory =
                              serviceCategoryFilter == 'All' ||
                                  category == serviceCategoryFilter;

                          return matchesSearch && matchesCategory;
                        }).toList();

                        if (docs.isEmpty) {
                          return const Text(
                            'No active services yet. Add services first in Service Catalog.',
                            style: TextStyle(color: Color(0xFF586062)),
                          );
                        }

                        if (filteredDocs.isEmpty) {
                          return const Text(
                            'No services match your search/filter.',
                            style: TextStyle(color: Color(0xFF586062)),
                          );
                        }

                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: filteredDocs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final serviceName =
                                data['name'] ?? 'Unnamed Service';
                            final category =
                                data['category'] ?? 'Uncategorized';
                            final selected =
                            selectedServices.contains(serviceName);

                            return _ServiceChip(
                              text: serviceName,
                              category: category,
                              selected: selected,
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    selectedServices.remove(serviceName);
                                  } else {
                                    selectedServices.add(serviceName);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 36),
                    const _ModalSectionTitle(
                      icon: Icons.schedule,
                      title: 'AVAILABILITY SCHEDULE',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF5F7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: const [
                                    'M',
                                    'T',
                                    'W',
                                    'TH',
                                    'F',
                                    'SA',
                                    'SU'
                                  ].map((day) {
                                    return _DayBox(
                                      day,
                                      active: selectedDays.contains(day),
                                      onTap: () {
                                        setState(() {
                                          if (selectedDays.contains(day)) {
                                            selectedDays.remove(day);
                                          } else {
                                            selectedDays.add(day);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Working Schedule',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF161D1F),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${selectedDays.join(', ')}, $startTime - $endTime',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF586062),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _TimeBox(
                                  label: 'START TIME',
                                  value: startTime,
                                  onTap: () => pickTime(true),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: _TimeBox(
                                  label: 'END TIME',
                                  value: endTime,
                                  onTap: () => pickTime(false),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 26),
              decoration: const BoxDecoration(
                color: Color(0x88EEF5F7),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF586062),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  ElevatedButton.icon(
                    onPressed: isSaving ? null : saveStaff,
                    icon: isSaving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.save, size: 18),
                    label: Text(
                      isSaving ? 'Saving...' : 'Save Staff Member',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A884),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 34,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 10,
                      shadowColor: const Color(0xFF00B894).withOpacity(0.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ModalSectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF006B55)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF006B55),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _ModalTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _ModalTextField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFE9EFF2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModalDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool showLabel;

  const _ModalDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(label),
          const SizedBox(height: 10),
        ],
        PopupMenuButton<String>(
          tooltip: '',
          offset: const Offset(0, 56),
          color: Colors.white,
          elevation: 10,
          constraints: const BoxConstraints(
            minWidth: 210,
            maxWidth: 260,
            maxHeight: 260,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onSelected: onChanged,
          itemBuilder: (context) {
            return items.map((item) {
              return PopupMenuItem<String>(
                value: item,
                height: 46,
                child: Text(
                  item,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EFF2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF3C4A44),
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF586062),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String text;
  final String category;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceChip({
    required this.text,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE6F5EF) : const Color(0xFFE9EFF2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF006B55) : Colors.transparent,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF006B55)
                    : const Color(0xFF3C4A44),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF006B55)
                    : const Color(0xFF586062),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayBox extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _DayBox(
      this.text, {
        required this.active,
        required this.onTap,
      });

  @override
  Widget build(BuildContext context) {
    final displayText = text == 'TH'
        ? 'T'
        : text == 'SA' || text == 'SU'
        ? 'S'
        : text;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF006B55) : const Color(0xFFE3E9EC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF6C7A74),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  const SizedBox(height: 6),
                  Text(value),
                ],
              ),
            ),
            const Icon(Icons.access_time, size: 18),
          ],
        ),
      ),
    );
  }
}