import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'customer_bottom_nav.dart';
import 'customer_landing_page.dart';
import 'customer_book_page.dart';

class CustomerServicesPage extends StatefulWidget {
  const CustomerServicesPage({super.key});

  @override
  State<CustomerServicesPage> createState() => _CustomerServicesPageState();
}

class _CustomerServicesPageState extends State<CustomerServicesPage> {
  String selectedCategory = 'All';
  String searchText = '';

  final categories = const [
    'All',
    'Body Massage',
    'Foot Massage',
    'Face Massage',
  ];

  Stream<QuerySnapshot> get servicesStream {
    return FirebaseFirestore.instance
        .collection('services')
        .where('status', isEqualTo: 'Active')
        .snapshots();
  }

  String getDurationText(Map<String, dynamic> data) {
    final value = data['duration'] ??
        data['durationMinutes'] ??
        data['serviceDuration'] ??
        data['minutes'];

    if (value == null) return 'No duration';

    final text = value.toString();
    if (text.toLowerCase().contains('min')) return text;

    return '$text min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Services',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF161D1F),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: TextField(
                    onChanged: (value) {
                      setState(() => searchText = value.toLowerCase());
                    },
                    decoration: InputDecoration(
                      hintText: 'Search services...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final active = selectedCategory == category;

                      return ChoiceChip(
                        label: Text(category),
                        selected: active,
                        showCheckmark: true,
                        checkmarkColor: Colors.white,
                        onSelected: (_) {
                          setState(() => selectedCategory = category);
                        },
                        selectedColor: const Color(0xFF00B894),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: active ? Colors.white : const Color(0xFF006B55),
                          fontWeight: FontWeight.w900,
                        ),
                        side: BorderSide(
                          color: active
                              ? const Color(0xFF00B894)
                              : Colors.transparent,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 18),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: servicesStream,
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];

                      final filteredDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        final name =
                        (data['name'] ?? data['serviceName'] ?? '').toString();
                        final category = (data['category'] ?? '').toString();

                        final matchesSearch =
                        name.toLowerCase().contains(searchText);

                        final matchesCategory = selectedCategory == 'All' ||
                            category.toLowerCase() ==
                                selectedCategory.toLowerCase();

                        return matchesSearch && matchesCategory;
                      }).toList();

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (filteredDocs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No services found.',
                            style: TextStyle(
                              color: Color(0xFF586062),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: CustomerServiceTile(
                              serviceId: doc.id,
                              serviceData: data,
                              name: data['name'] ?? data['serviceName'] ?? 'Service',
                              category: data['category'] ?? 'Massage Service',
                              duration: getDurationText(data),
                              price: '₱${data['price'] ?? 0}',
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomerBottomNav(activePage: 'services'),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerServiceTile extends StatelessWidget {
  final String serviceId;
  final Map<String, dynamic> serviceData;
  final String name;
  final String category;
  final String duration;
  final String price;

  const CustomerServiceTile({
    super.key,
    required this.serviceId,
    required this.serviceData,
    required this.name,
    required this.category,
    required this.duration,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: const Border(
          top: BorderSide(color: Color(0x3300B894), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F5EF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.spa,
              color: Color(0xFF006B55),
              size: 36,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF161D1F),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF006B55),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 16,
                      color: Color(0xFF586062),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF586062),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        price,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF00A884),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 34,
                      width: 74,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerBookPage(
                                initialServiceId: serviceId,
                                initialService: serviceData,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          backgroundColor: const Color(0xFFEEF5F7),
                          foregroundColor: const Color(0xFF006B55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Book',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}