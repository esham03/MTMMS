import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  Map<String, dynamic> _profile = {
    'name': '',
    'email': '',
    'role': 'Administrator',
    'department': 'Department of Information Technology',
    'government': 'Government of Goa',
    'designation': '',
    'phone': '',
    'employeeId': '',
    'jurisdiction': 'All Goa (North & South Districts)',
  };

  final List<Map<String, dynamic>> _authorizedPersons = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = await AuthService.getUser();
    if (mounted && user != null) {
      setState(() {
        _profile = {..._profile, ...user};
      });
    }
  }

  // -------------------------------------------------------------
  // ADD AUTHORIZED PERSON DIALOG
  // -------------------------------------------------------------
  void _showAddPersonDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pwCtrl = TextEditingController();
    String selectedRole = 'Field Inspector';
    String selectedStatus = 'active';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Add Authorized Person',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogLabel('Full Name *'),
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: const InputDecoration(hintText: 'e.g. Rajesh Naik'),
                ),
                const SizedBox(height: 12),

                _dialogLabel('Email / Username *'),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: const InputDecoration(hintText: 'e.g. rajesh.naik@goa.gov.in'),
                ),
                const SizedBox(height: 12),

                _dialogLabel('Contact Phone'),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: const InputDecoration(hintText: '+91 98221 00000'),
                ),
                const SizedBox(height: 12),

                _dialogLabel('Role / Permissions *'),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'Administrator', child: Text('Administrator')),
                    DropdownMenuItem(value: 'Field Inspector', child: Text('Field Inspector')),
                    DropdownMenuItem(value: 'Audit Officer', child: Text('Audit Officer')),
                    DropdownMenuItem(value: 'Revenue Officer', child: Text('Revenue Officer')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 12),

                _dialogLabel('Initial Security Password *'),
                TextField(
                  controller: pwCtrl,
                  obscureText: true,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: const InputDecoration(hintText: 'Set access password'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;

                setState(() {
                  _authorizedPersons.add({
                    'id': DateTime.now().millisecondsSinceEpoch,
                    'name': nameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'role': selectedRole,
                    'status': selectedStatus,
                    'created_at': DateTime.now().toIso8601String().split('T')[0],
                  });
                });

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Authorized user "${nameCtrl.text.trim()}" added to grid'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Add Authorized Person'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // EDIT AUTHORIZED PERSON DIALOG
  // -------------------------------------------------------------
  void _showEditPersonDialog(Map<String, dynamic> person) {
    final nameCtrl = TextEditingController(text: person['name']);
    final emailCtrl = TextEditingController(text: person['email']);
    final phoneCtrl = TextEditingController(text: person['phone']);
    String selectedRole = person['role'] ?? 'Field Inspector';
    String selectedStatus = person['status'] ?? 'active';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Edit Authorized Person',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogLabel('Full Name *'),
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                const SizedBox(height: 12),

                _dialogLabel('Email / Username *'),
                TextField(
                  controller: emailCtrl,
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                const SizedBox(height: 12),

                _dialogLabel('Phone Number'),
                TextField(
                  controller: phoneCtrl,
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                const SizedBox(height: 12),

                _dialogLabel('Role / Permissions'),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'Administrator', child: Text('Administrator')),
                    DropdownMenuItem(value: 'Field Inspector', child: Text('Field Inspector')),
                    DropdownMenuItem(value: 'Audit Officer', child: Text('Audit Officer')),
                    DropdownMenuItem(value: 'Revenue Officer', child: Text('Revenue Officer')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 12),

                _dialogLabel('Access Status'),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedStatus = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  person['name'] = nameCtrl.text.trim();
                  person['email'] = emailCtrl.text.trim();
                  person['phone'] = phoneCtrl.text.trim();
                  person['role'] = selectedRole;
                  person['status'] = selectedStatus;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Authorized user updated successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // RESET PASSWORD DIALOG
  // -------------------------------------------------------------
  void _showResetPasswordDialog(Map<String, dynamic> person) {
    final pwCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.key_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Reset Password: ${person['name']}',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogLabel('New Security Password *'),
            TextField(
              controller: pwCtrl,
              obscureText: true,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: const InputDecoration(hintText: 'Enter new password'),
            ),
            const SizedBox(height: 12),
            _dialogLabel('Confirm New Password *'),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: const InputDecoration(hintText: 'Confirm new password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pwCtrl.text.isEmpty || pwCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Password successfully reset for ${person['name']}'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  void _deletePerson(Map<String, dynamic> person) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Revoke Access'),
        content: Text('Are you sure you want to revoke access and delete "${person['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _authorizedPersons.removeWhere((p) => p['id'] == person['id']);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Access revoked for ${person['name']}'), backgroundColor: AppColors.error),
              );
            },
            child: const Text('Revoke Access'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPersons = _authorizedPersons.where((p) {
      final q = _searchCtrl.text.toLowerCase();
      if (q.isEmpty) return true;
      return p['name'].toString().toLowerCase().contains(q) ||
          p['email'].toString().toLowerCase().contains(q) ||
          p['role'].toString().toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(currentRoute: 'settings'),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Officer Profile & Authorized Persons',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              'DoIT • Government of Goa',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withValues(alpha: 0.85)),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(icon: Icon(Icons.person_pin_rounded, size: 18), text: 'Officer Profile'),
            Tab(icon: const Icon(Icons.group_outlined, size: 18), text: 'Authorized Persons (${_authorizedPersons.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: OFFICER PROFILE DETAILS ────────────────────────
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _userCard(),
              const SizedBox(height: 18),

              _sectionLabel('OFFICER PROFILE SPECIFICATIONS'),
              const SizedBox(height: 8),
              _card(
                children: [
                  _infoTile('Full Name', _profile['name'] ?? 'Administrator'),
                  const Divider(height: 16),
                  _infoTile('Official Email', _profile['email'] ?? 'admin@goa.gov.in'),
                  const Divider(height: 16),
                  _infoTile('Official Contact Phone', _profile['phone'] ?? '+91 832 2419000'),
                  const Divider(height: 16),
                  _infoTile('Employee ID', _profile['employeeId'] ?? 'GOA-IT-001'),
                  const Divider(height: 16),
                  _infoTile('Designation / Post', _profile['designation'] ?? 'Senior Systems Manager'),
                  const Divider(height: 16),
                  _infoTile('Department', _profile['department'] ?? 'Department of Information Technology'),
                  const Divider(height: 16),
                  _infoTile('Circle Jurisdiction', _profile['jurisdiction'] ?? 'All Goa (North & South)'),
                ],
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                    ).then((_) => _loadProfile());
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Officer Profile'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),

          // ── TAB 2: AUTHORIZED PERSONS DIRECTORY ───────────────────
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AUTHORIZED SYSTEM USERS',
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.8),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddPersonDialog,
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: const Text('Add User', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search authorized persons...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() => _searchCtrl.clear()),
                        )
                      : null,
                ),
              ),
              if (filteredPersons.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.group_outlined, size: 44, color: AppColors.textMuted),
                      const SizedBox(height: 10),
                      Text(
                        'No Authorized Persons Added',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap "Add User" above to grant officer credentials.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: filteredPersons.map((person) {
                  final isActive = person['status'] == 'active';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primarySurface,
                                  child: Text(
                                    person['name'][0].toString().toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      person['name'].toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      person['email'].toString(),
                                      style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  person['status'] = isActive ? 'inactive' : 'active';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.successSurface : AppColors.errorSurface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isActive ? AppColors.successBorder : AppColors.errorBorder,
                                  ),
                                ),
                                child: Text(
                                  isActive ? 'ACTIVE' : 'INACTIVE',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isActive ? AppColors.success : AppColors.error,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Role: ${person['role']}',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryLight,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.key_rounded, size: 18, color: AppColors.primary),
                                  tooltip: 'Reset Password',
                                  onPressed: () => _showResetPasswordDialog(person),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                                  tooltip: 'Edit Details',
                                  onPressed: () => _showEditPersonDialog(person),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                  tooltip: 'Revoke Access',
                                  onPressed: () => _deletePerson(person),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Text(
              _profile['name']?[0] ?? 'A',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile['name'] ?? 'Administrator',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Text(
                  _profile['email'] ?? 'admin@goa.gov.in',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_profile['designation'] ?? 'Senior Systems Manager'} • ${_profile['role'] ?? 'Administrator'}',
                  style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w500, color: AppColors.accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textSecondary)),
        Text(value, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _dialogLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
    );
  }
}
