import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddServiceModal extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? serviceData;

  const AddServiceModal({
    super.key,
    this.docId,
    this.serviceData,
  });

  @override
  State<AddServiceModal> createState() => _AddServiceModalState();
}

class _AddServiceModalState extends State<AddServiceModal> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final durationController = TextEditingController();
  final priceController = TextEditingController();

  String category = 'Body Massage';
  String status = 'Active';
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    final data = widget.serviceData;
    if (data != null) {
      nameController.text = data['name'] ?? '';
      descriptionController.text = data['description'] ?? '';
      durationController.text = '${data['durationMinutes'] ?? ''}';
      priceController.text = '${data['price'] ?? ''}';
      category = data['category'] ?? 'Body Massage';
      status = data['status'] ?? 'Active';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    durationController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> saveService() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in.')),
      );
      return;
    }

    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service name is required.')),
      );
      return;
    }

    setState(() => isSaving = true);

    final data = {
      'name': nameController.text.trim(),
      'description': descriptionController.text.trim(),
      'durationMinutes': int.tryParse(durationController.text.trim()) ?? 0,
      'price': double.tryParse(priceController.text.trim()) ?? 0,
      'category': category,
      'status': status,
      'isActive': status == 'Active',
      'isArchived': false,
      'createdBy': currentUser.uid,
      'createdByEmail': currentUser.email,
      'updatedAt': FieldValue.serverTimestamp(),
      if (widget.docId == null) 'createdAt': FieldValue.serverTimestamp(),
    };

    final ref = FirebaseFirestore.instance.collection('services');

    if (widget.docId == null) {
      await ref.add(data);
    } else {
      await ref.doc(widget.docId).update(data);
    }

    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.docId == null ? 'Service added.' : 'Service updated.'),
        backgroundColor: const Color(0xFF006B55),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: 500,
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.docId == null ? 'Add New Service' : 'Edit Service',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF161D1F),
                ),
              ),
              const SizedBox(height: 22),
              _field(nameController, 'Service Name'),
              const SizedBox(height: 14),
              _field(descriptionController, 'Description', maxLines: 3),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      durationController,
                      'Duration',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _field(
                      priceController,
                      'Price',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: category,
                decoration: _inputDecoration('Category'),
                items: const [
                  DropdownMenuItem(value: 'Body Massage', child: Text('Body Massage')),
                  DropdownMenuItem(value: 'Foot Massage', child: Text('Foot Massage')),
                  DropdownMenuItem(value: 'Face Massage', child: Text('Face Massage')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => category = value);
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: status,
                decoration: _inputDecoration('Status'),
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => status = value);
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton(
                    onPressed: isSaving ? null : saveService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006B55),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isSaving ? 'Saving...' : 'Save Service'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController controller,
      String label, {
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF4FAFD),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}