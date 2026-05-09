import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/user_model.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/admin_sidebar.dart';
import '../../services/client_auth_service.dart';

class ClientManagementPage extends StatelessWidget {
  final UserModel user;

  const ClientManagementPage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          AdminSidebar(
            user: user,
            selectedMenu: 'Client Management',
          ),
          Expanded(
            child: Column(
              children: [
                AdminHeader(user: user),
                const Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(40, 36, 40, 40),
                    child: _ClientManagementContent(),
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

enum ClientStatus {
  active,
  expired,
  pending,
  archived,
}

extension ClientStatusExtension on ClientStatus {
  String get label {
    switch (this) {
      case ClientStatus.active:
        return 'Active';
      case ClientStatus.expired:
        return 'Expired';
      case ClientStatus.pending:
        return 'Pending';
      case ClientStatus.archived:
        return 'Archived';
    }
  }

  String get value {
    switch (this) {
      case ClientStatus.active:
        return 'active';
      case ClientStatus.expired:
        return 'expired';
      case ClientStatus.pending:
        return 'pending';
      case ClientStatus.archived:
        return 'archived';
    }
  }

  static ClientStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return ClientStatus.active;
      case 'expired':
        return ClientStatus.expired;
      case 'pending':
        return ClientStatus.pending;
      case 'archived':
        return ClientStatus.archived;
      default:
        return ClientStatus.pending;
    }
  }
}

class ClientEntityModel {
  final String id;
  final String businessName;
  final String adminName;
  final String email;
  final ClientStatus status;
  final int branches;

  const ClientEntityModel({
    required this.id,
    required this.businessName,
    required this.adminName,
    required this.email,
    required this.status,
    required this.branches,
  });

  factory ClientEntityModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data() ?? {};

    return ClientEntityModel(
      id: document.id,
      businessName: (data['businessName'] ?? '').toString(),
      adminName: (data['adminName'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      status: ClientStatusExtension.fromString(
        (data['status'] ?? 'pending').toString(),
      ),
      branches: data['branches'] is int
          ? data['branches'] as int
          : int.tryParse((data['branches'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'adminName': adminName,
      'email': email,
      'status': status.value,
      'branches': branches,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  IconData get icon {
    switch (status) {
      case ClientStatus.active:
        return Icons.spa;
      case ClientStatus.expired:
        return Icons.water_drop;
      case ClientStatus.pending:
        return Icons.self_improvement;
      case ClientStatus.archived:
        return Icons.archive;
    }
  }

  Color get iconColor {
    switch (status) {
      case ClientStatus.active:
        return AppColors.primary;
      case ClientStatus.expired:
        return AppColors.error;
      case ClientStatus.pending:
        return AppColors.secondary;
      case ClientStatus.archived:
        return AppColors.secondary;
    }
  }
}

class _ClientManagementContent extends StatefulWidget {
  const _ClientManagementContent();

  @override
  State<_ClientManagementContent> createState() =>
      _ClientManagementContentState();
}

class _ClientManagementContentState extends State<_ClientManagementContent> {
  final CollectionReference<Map<String, dynamic>> clientsCollection =
  FirebaseFirestore.instance.collection('clients');

  String searchQuery = '';

  List<ClientEntityModel> filterClients(List<ClientEntityModel> clients) {
    final visibleClients = clients
        .where((client) => client.status != ClientStatus.archived)
        .toList();

    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return visibleClients;
    }

    return visibleClients.where((client) {
      return client.businessName.toLowerCase().contains(query) ||
          client.adminName.toLowerCase().contains(query) ||
          client.email.toLowerCase().contains(query) ||
          client.status.label.toLowerCase().contains(query) ||
          client.branches.toString().contains(query);
    }).toList();
  }

  Future<void> createClient(ClientEntityModel client) async {
    await clientsCollection.add({
      ...client.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'archivedAt': null,
    });
  }

  Future<void> updateClient(ClientEntityModel client) async {
    await clientsCollection.doc(client.id).update(client.toMap());
  }

  Future<void> archiveClient(ClientEntityModel client) async {
    await clientsCollection.doc(client.id).update({
      'status': ClientStatus.archived.value,
      'archivedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> showClientDialog({
    ClientEntityModel? existingClient,
  }) async {
    final formKey = GlobalKey<FormState>();

    final businessController = TextEditingController(
      text: existingClient?.businessName ?? '',
    );
    final adminController = TextEditingController(
      text: existingClient?.adminName ?? '',
    );
    final emailController = TextEditingController(
      text: existingClient?.email ?? '',
    );
    final branchesController = TextEditingController(
      text: existingClient?.branches.toString() ?? '1',
    );
    final passwordController = TextEditingController();

    ClientStatus selectedStatus = existingClient?.status ?? ClientStatus.active;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24),
              child: Container(
                width: 560,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.15),
                      blurRadius: 60,
                      offset: Offset(0, 28),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 6,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(44, 42, 44, 36),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              existingClient == null
                                  ? 'Create Client Account'
                                  : 'Edit Client Account',
                              style: const TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              existingClient == null
                                  ? 'Configure a new institutional gateway.'
                                  : 'Update this client account information.',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 34),
                            _DialogTextField(
                              label: 'Business Name',
                              controller: businessController,
                              hintText: 'e.g. Serenity Springs Clinic',
                              icon: Icons.domain,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Business name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _DialogTextField(
                              label: 'Owner/Admin Name',
                              controller: adminController,
                              hintText: 'Full Name',
                              icon: Icons.person,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Admin name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _DialogTextField(
                              label: 'Email Address',
                              controller: emailController,
                              hintText: 'admin@business.com',
                              icon: Icons.mail,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!email.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _DialogTextField(
                                    label: 'Branches',
                                    controller: branchesController,
                                    hintText: '1',
                                    icon: Icons.business,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      final branches =
                                      int.tryParse(value?.trim() ?? '');
                                      if (branches == null || branches < 0) {
                                        return 'Invalid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const _DialogLabel('Status'),
                                      DropdownButtonFormField<ClientStatus>(
                                        value: selectedStatus,
                                        decoration: _dialogInputDecoration(),
                                        items: const [
                                          DropdownMenuItem(
                                            value: ClientStatus.active,
                                            child: Text('Active'),
                                          ),
                                          DropdownMenuItem(
                                            value: ClientStatus.pending,
                                            child: Text('Pending'),
                                          ),
                                          DropdownMenuItem(
                                            value: ClientStatus.expired,
                                            child: Text('Expired'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setDialogState(() {
                                            selectedStatus = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (existingClient == null) ...[
                              const SizedBox(height: 20),
                              _DialogTextField(
                                label: 'Password',
                                controller: passwordController,
                                hintText: 'Temporary password',
                                icon: Icons.lock,
                                obscureText: true,
                                validator: (value) {
                                  if (existingClient != null) return null;
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Temporary password is required';
                                  }
                                  if (value.trim().length < 6) {
                                    return 'Use at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Note: This demo saves the client profile to Firestore. For real login accounts, create Firebase Auth users with a secure Cloud Function, not by storing plain passwords.',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 11,
                                  height: 1.35,
                                ),
                              ),
                            ],
                            const SizedBox(height: 34),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 58,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: const [
                                        BoxShadow(
                                          color:
                                          Color.fromRGBO(0, 184, 148, 0.16),
                                          blurRadius: 24,
                                          offset: Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: TextButton(
                                      onPressed: () async {
                                        if (!formKey.currentState!.validate()) {
                                          return;
                                        }

                                        final messenger = ScaffoldMessenger.of(this.context);

                                        try {
                                          if (existingClient == null) {
                                            await ClientAuthService.createClientAccount(
                                              businessName: businessController.text.trim(),
                                              adminName: adminController.text.trim(),
                                              email: emailController.text.trim(),
                                              password: passwordController.text.trim(),
                                              status: selectedStatus.value,
                                              branches: int.parse(branchesController.text.trim()),
                                            );

                                            if (!dialogContext.mounted) return;
                                            Navigator.pop(dialogContext);

                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text('Client account created successfully'),
                                                backgroundColor: AppColors.primary,
                                              ),
                                            );
                                          } else {
                                            final client = ClientEntityModel(
                                              id: existingClient.id,
                                              businessName: businessController.text.trim(),
                                              adminName: adminController.text.trim(),
                                              email: emailController.text.trim(),
                                              status: selectedStatus,
                                              branches: int.parse(branchesController.text.trim()),
                                            );

                                            await updateClient(client);

                                            if (!dialogContext.mounted) return;
                                            Navigator.pop(dialogContext);

                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text('Client account updated successfully'),
                                                backgroundColor: AppColors.primary,
                                              ),
                                            );
                                          }
                                        } catch (error) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text('Firebase error: $error'),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      },
                                      child: Text(
                                        existingClient == null
                                            ? 'Create Account'
                                            : 'Save Changes',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SizedBox(
                                    height: 58,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.pop(dialogContext);
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor:
                                        AppColors.surfaceContainerHigh,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: AppColors.onSurface,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    businessController.dispose();
    adminController.dispose();
    emailController.dispose();
    branchesController.dispose();
    passwordController.dispose();
  }

  Future<void> confirmArchive(ClientEntityModel client) async {
    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Archive Client?'),
          content: Text(
            'Are you sure you want to archive ${client.businessName}? It will be hidden from the active client table.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );

    if (shouldArchive != true) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await archiveClient(client);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${client.businessName} archived'),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Firebase error: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: clientsCollection.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        if (snapshot.hasError) {
          return _ErrorState(
            message: 'Firebase error: ${snapshot.error}',
          );
        }

        final allClients = snapshot.data?.docs
            .map((doc) => ClientEntityModel.fromFirestore(doc))
            .toList() ??
            [];

        final visibleClients = allClients
            .where((client) => client.status != ClientStatus.archived)
            .toList();

        final filteredClients = filterClients(allClients);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ClientHeroSection(),
            const SizedBox(height: 52),
            _CreateClientButtonRow(
              onPressed: () => showClientDialog(),
            ),
            const SizedBox(height: 34),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              _EntityRegistryTable(
                clients: filteredClients,
                totalCount: visibleClients.length,
                onSearchChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                onEdit: (client) {
                  showClientDialog(existingClient: client);
                },
                onArchive: confirmArchive,
              ),
          ],
        );
      },
    );
  }
}

class _ClientHeroSection extends StatelessWidget {
  const _ClientHeroSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manage Client Accounts',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 52,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Institutional oversight of spa business entities.',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 20,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _CreateClientButtonRow extends StatelessWidget {
  final VoidCallback onPressed;

  const _CreateClientButtonRow({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 34),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 184, 148, 0.18),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.add_circle, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Create Client Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EntityRegistryTable extends StatelessWidget {
  final List<ClientEntityModel> clients;
  final int totalCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ClientEntityModel> onEdit;
  final ValueChanged<ClientEntityModel> onArchive;

  const _EntityRegistryTable({
    required this.clients,
    required this.totalCount,
    required this.onSearchChanged,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(45, 52, 54, 0.05),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          _RegistryHeader(onSearchChanged: onSearchChanged),
          const _TableHeader(),
          if (clients.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Text(
                'No clients found',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...clients.map(
                  (client) => _ClientTableRow(
                client: client,
                onEdit: onEdit,
                onArchive: onArchive,
              ),
            ),
          _RegistryFooter(
            visibleCount: clients.length,
            totalCount: totalCount,
          ),
        ],
      ),
    );
  }
}

class _RegistryHeader extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;

  const _RegistryHeader({
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.35),
        border: const Border(
          bottom: BorderSide(color: AppColors.surfaceContainer),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          const Text(
            'Entity Registry',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 360,
            height: 42,
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search client, admin, email, or status...',
                hintStyle: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.secondary,
                  size: 20,
                ),
                filled: true,
                fillColor: AppColors.surfaceContainer,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const _FilterChip(label: 'SORT BY: NEWEST'),
          const SizedBox(width: 8),
          const _FilterChip(label: 'FILTER: ALL STATUS'),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;

  const _FilterChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.secondary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLow.withValues(alpha: 0.50),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: const Row(
        children: [
          Expanded(flex: 4, child: _HeaderText('BUSINESS NAME')),
          Expanded(flex: 3, child: _HeaderText('ADMIN')),
          Expanded(flex: 2, child: _HeaderText('STATUS')),
          Expanded(flex: 1, child: Center(child: _HeaderText('BRANCHES'))),
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

class _HeaderText extends StatelessWidget {
  final String text;

  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.secondary,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _ClientTableRow extends StatelessWidget {
  final ClientEntityModel client;
  final ValueChanged<ClientEntityModel> onEdit;
  final ValueChanged<ClientEntityModel> onArchive;

  const _ClientTableRow({
    required this.client,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.surfaceContainer),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    client.icon,
                    color: client.iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    client.businessName,
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
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.adminName,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  client.email,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusBadge(status: client.status),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              client.branches.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: _ActionButtons(
                onEdit: () => onEdit(client),
                onArchive: () => onArchive(client),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ClientStatus status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final Color bg;

    switch (status) {
      case ClientStatus.active:
        color = AppColors.primary;
        bg = AppColors.primary.withValues(alpha: 0.10);
        break;
      case ClientStatus.expired:
        color = AppColors.error;
        bg = AppColors.errorContainer.withValues(alpha: 0.22);
        break;
      case ClientStatus.pending:
        color = AppColors.secondary;
        bg = AppColors.surfaceContainerHigh.withValues(alpha: 0.45);
        break;
      case ClientStatus.archived:
        color = AppColors.secondary;
        bg = AppColors.surfaceContainerHigh.withValues(alpha: 0.45);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _ActionButtons({
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Edit Account',
          onPressed: onEdit,
          icon: const Icon(
            Icons.edit,
            color: AppColors.secondary,
            size: 22,
          ),
        ),
        IconButton(
          tooltip: 'Archive Account',
          onPressed: onArchive,
          icon: const Icon(
            Icons.archive,
            color: AppColors.secondary,
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _RegistryFooter extends StatelessWidget {
  final int visibleCount;
  final int totalCount;

  const _RegistryFooter({
    required this.visibleCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.25),
        border: const Border(
          top: BorderSide(color: AppColors.surfaceContainer),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      child: Row(
        children: [
          Text(
            'Showing $visibleCount of $totalCount institutions',
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHigh,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Previous',
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Next',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;

  const _DialogTextField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DialogLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: _dialogInputDecoration().copyWith(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppColors.outlineVariant,
              fontSize: 15,
            ),
            suffixIcon: Icon(
              icon,
              color: AppColors.outlineVariant,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}
// Put this function in your Super Admin Client Management page.
// Call this when the super admin clicks Archive/Delete client.

Future<void> archiveClient({
  required String clientDocId,
  required Map<String, dynamic> clientData,
  required String superAdminUid,
  required String superAdminName,
}) async {
  final firestore = FirebaseFirestore.instance;

  final batch = firestore.batch();

  final clientRef = firestore.collection('clients').doc(clientDocId);
  final archiveRef = firestore.collection('archives').doc();

  batch.set(archiveRef, {
    'dataType': 'Archived Client',
    'collectionName': 'clients',
    'originalDocId': clientDocId,
    'data': {
      ...clientData,
      'status': clientData['status'] ?? 'active',
      'isArchived': false,
    },
    'originalCreatedAt': clientData['createdAt'] ?? FieldValue.serverTimestamp(),
    'archivedAt': FieldValue.serverTimestamp(),
    'archivedBy': superAdminUid,
    'archivedByName': superAdminName,
    'restored': false,
    'status': 'archived',
  });

  batch.set(clientRef, {
    'isArchived': true,
    'status': 'archived',
    'archivedAt': FieldValue.serverTimestamp(),
    'archivedBy': superAdminUid,
    'archivedByName': superAdminName,
  }, SetOptions(merge: true));

  await batch.commit();
}

class _DialogLabel extends StatelessWidget {
  final String text;

  const _DialogLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.secondary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

InputDecoration _dialogInputDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: AppColors.surfaceContainerLow,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.primaryContainer,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.error,
        width: 1,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.error,
        width: 2,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 18,
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}