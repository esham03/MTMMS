import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/data_sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/government_components.dart';
import 'login_screen.dart';

class AuthorizedPersonnelScreen extends StatefulWidget {
  const AuthorizedPersonnelScreen({super.key});

  @override
  State<AuthorizedPersonnelScreen> createState() =>
      _AuthorizedPersonnelScreenState();
}

class _AuthorizedPersonnelScreenState extends State<AuthorizedPersonnelScreen>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> _personnel = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;
  bool _isAdmin = false;
  Timer? _autoRefreshTimer;
  String? _endpointNotice;
  Map<String, dynamic>? _lastCreatedOfficer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DataSyncService.syncNotifier.addListener(_onDataSyncChanged);
    _checkRole();
    _loadPersonnel();
    // 15-second heartbeat for live backend updates
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadPersonnel(isSilent: true),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadPersonnel(isSilent: true);
    }
  }

  void _onDataSyncChanged() {
    if (mounted) {
      _loadPersonnel(isSilent: true);
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    DataSyncService.syncNotifier.removeListener(_onDataSyncChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkRole() async {
    final isAdmin = await AuthService.isAdmin();
    final user = await AuthService.getUser();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
        _currentUser = user;
      });
    }
  }

  Future<void> _loadPersonnel({bool isSilent = false}) async {
    if (!isSilent && mounted) {
      setState(() {
        _isLoading = true;
        _endpointNotice = null;
      });
    }

    try {
      final list = await ApiService.getAuthorizedPersonnel();
      final current = await AuthService.getUser();
      if (mounted) {
        setState(() {
          _currentUser = current;
          _personnel = list;
          _isLoading = false;
          _endpointNotice = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _endpointNotice = 'Backend user management endpoint not currently available.';
        });
      }
    }
  }

  // -------------------------------------------------------------
  // ADD AUTHORIZED PERSON DIALOG
  // -------------------------------------------------------------
  void _showAddPersonDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final designationCtrl = TextEditingController(text: 'Field Inspector');
    final deptCtrl = TextEditingController(
      text: 'Department of Information Technology',
    );
    final pwCtrl = TextEditingController();
    String selectedRole = 'officer';
    bool isSubmitting = false;
    bool obscurePw = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceBg(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Add Authorised Person',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPri(context),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogLabel('Full Name *'),
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPri(context)),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Officer Rajesh Vernekar',
                  ),
                ),
                const SizedBox(height: 10),

                _dialogLabel('Official Email (Username for Login) *'),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPri(context)),
                  decoration: const InputDecoration(
                    hintText: 'e.g. rajesh.vernekar@goa.gov.in',
                  ),
                ),
                const SizedBox(height: 10),

                _dialogLabel('Login Password * (Min 6 characters)'),
                TextField(
                  controller: pwCtrl,
                  obscureText: obscurePw,
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPri(context)),
                  decoration: InputDecoration(
                    hintText: 'Set secure login password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePw ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 18,
                        color: AppColors.textMut(context),
                      ),
                      onPressed: () => setDialogState(() => obscurePw = !obscurePw),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                _dialogLabel('Role / Authorization Level *'),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  dropdownColor: AppColors.surfaceBg(context),
                  items: [
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Administrator (Full Access)', style: GoogleFonts.poppins(fontSize: 12.5)),
                    ),
                    DropdownMenuItem(
                      value: 'officer',
                      child: Text('Field Officer (Standard)', style: GoogleFonts.poppins(fontSize: 12.5)),
                    ),
                    DropdownMenuItem(
                      value: 'inspector',
                      child: Text('Site Inspector', style: GoogleFonts.poppins(fontSize: 12.5)),
                    ),
                    DropdownMenuItem(
                      value: 'viewer',
                      child: Text('Auditor / Viewer (Read Only)', style: GoogleFonts.poppins(fontSize: 12.5)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 10),

                _dialogLabel('Department'),
                TextField(
                  controller: deptCtrl,
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPri(context)),
                  decoration: const InputDecoration(
                    hintText: 'Department of Information Technology',
                  ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      final pw = pwCtrl.text;

                      if (name.isEmpty || email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please provide both name and official email.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      if (pw.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password must be at least 6 characters in length.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      final payload = {
                        'name': name,
                        'email': email,
                        'designation': designationCtrl.text.trim(),
                        'department': deptCtrl.text.trim(),
                        'role': selectedRole,
                        'password': pw,
                      };

                      final result = await ApiService.createAuthorizedPerson(payload);

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (mounted) {
                        if (result['success'] == true) {
                          setState(() {
                            _lastCreatedOfficer = {
                              'name': name,
                              'email': email,
                              'role': selectedRole,
                            };
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Authorized officer "$name" created with active login access!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _loadPersonnel();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Failed to register officer credentials.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create Officer'),
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
    final id = person['id']?.toString() ?? '';
    final nameCtrl = TextEditingController(text: person['name']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: person['email']?.toString() ?? '');
    final deptCtrl = TextEditingController(
      text: person['department']?.toString() ?? 'Department of Information Technology',
    );
    final pwCtrl = TextEditingController();
    String selectedRole = (person['role']?.toString().toLowerCase() ?? 'officer');
    if (!['admin', 'officer', 'inspector', 'viewer'].contains(selectedRole)) {
      selectedRole = 'officer';
    }
    bool isSubmitting = false;
    bool obscurePw = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceBg(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Edit Authorised Person',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPri(context),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogLabel('Full Name *'),
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPri(context)),
                ),
                const SizedBox(height: 10),

                _dialogLabel('Official Email *'),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPri(context)),
                ),
                const SizedBox(height: 10),

                _dialogLabel('Role / Authorization Level'),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  dropdownColor: AppColors.surfaceBg(context),
                  items: [
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Administrator (Full Access)', style: GoogleFonts.poppins(fontSize: 12.5)),
                    ),
                    DropdownMenuItem(
                      value: 'officer',
                      child: Text('Field Officer (Standard)', style: GoogleFonts.poppins(fontSize: 12.5)),
                    ),
                    DropdownMenuItem(
                      value: 'inspector',
                      child: Text('Site Inspector', style: GoogleFonts.poppins(fontSize: 12.5)),
                    ),
                    DropdownMenuItem(
                      value: 'viewer',
                      child: Text('Auditor / Viewer (Read Only)', style: GoogleFonts.poppins(fontSize: 12.5)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 10),

                _dialogLabel('Department'),
                TextField(
                  controller: deptCtrl,
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPri(context)),
                ),
                const SizedBox(height: 10),

                _dialogLabel('Reset Password (Optional)'),
                TextField(
                  controller: pwCtrl,
                  obscureText: obscurePw,
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPri(context)),
                  decoration: InputDecoration(
                    hintText: 'Leave blank to retain current password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePw ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 18,
                        color: AppColors.textMut(context),
                      ),
                      onPressed: () => setDialogState(() => obscurePw = !obscurePw),
                    ),
                  ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      final pw = pwCtrl.text;

                      if (name.isEmpty || email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please provide both name and official email.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      if (pw.isNotEmpty && pw.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New password must be at least 6 characters in length.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      final payload = {
                        'name': name,
                        'email': email,
                        'department': deptCtrl.text.trim(),
                        'role': selectedRole,
                      };
                      if (pw.isNotEmpty) {
                        payload['password'] = pw;
                      }

                      final result = await ApiService.updateAuthorizedPerson(id, payload);

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (mounted) {
                        if (result['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Officer "$name" updated successfully.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _loadPersonnel();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Failed to update officer.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // DELETE / REVOKE AUTHORIZED PERSON
  // -------------------------------------------------------------
  Future<void> _confirmDeletePerson(Map<String, dynamic> person) async {
    final id = person['id']?.toString() ?? '';
    final name = person['name']?.toString() ?? 'Officer';

    final isSelf = _currentUser != null &&
        (_currentUser!['id']?.toString() == id ||
            _currentUser!['email']?.toString().toLowerCase() ==
                person['email']?.toString().toLowerCase());

    if (isSelf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot revoke your own active login session.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Revoke Authorization'),
        content: Text(
          'Are you sure you want to deactivate authorization for "$name"? Their login access to MTMMS will be permanently revoked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revoke Access'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final res = await ApiService.deleteAuthorizedPerson(id);
      if (mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authorization for "$name" revoked.'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadPersonnel();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Failed to revoke authorization.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  // -------------------------------------------------------------
  // SWITCH USER / LOG IN AS OFFICER
  // -------------------------------------------------------------
  Future<void> _switchToOfficer(Map<String, dynamic> person) async {
    final name = person['name']?.toString() ?? 'Officer';
    final email = person['email']?.toString() ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Switch Account'),
        content: Text(
          'Log out of your current session and open login portal for "$name" ($email)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Proceed to Login'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ApiService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginScreen(initialEmail: email),
          ),
          (_) => false,
        );
      }
    }
  }

  Widget _dialogLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textPri(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: MTMMSAppBar(
        title: 'Authorized Personnel',
        subtitle: 'System User Administration',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Personnel',
            onPressed: _loadPersonnel,
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(
                'Add Person',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              onPressed: _showAddPersonDialog,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
              children: [
                // ── Newly Created Officer Celebration Banner ───────────
                if (_lastCreatedOfficer != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.success.withValues(alpha: 0.15),
                          AppColors.primaryLight.withValues(alpha: 0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'New Authorized Officer Created & Ready to Log In',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _lastCreatedOfficer = null),
                              child: const Icon(Icons.close, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_lastCreatedOfficer!['name']} (${_lastCreatedOfficer!['email']}) • Role: ${_lastCreatedOfficer!['role'].toString().toUpperCase()}',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: AppColors.textSec(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          icon: const Icon(Icons.login_rounded, size: 14),
                          label: Text(
                            'Log In as ${_lastCreatedOfficer!['name']}',
                            style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () async {
                            final email = _lastCreatedOfficer!['email'];
                            await ApiService.logout();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => LoginScreen(initialEmail: email),
                                ),
                                (_) => false,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                if (_endpointNotice != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.infoSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.info,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _endpointNotice!,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_personnel.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,
                            size: 48,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No authorized personnel found.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSec(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._personnel.map((u) {
                    final id = u['id']?.toString() ?? '';
                    final name = u['name']?.toString() ?? 'Officer';
                    final email = u['email']?.toString() ?? '—';
                    final role = u['role']?.toString().toUpperCase() ?? 'OFFICER';
                    final designation = u['designation']?.toString() ?? 'Systems Officer';
                    final dept = u['department']?.toString() ??
                        'Department of Information Technology';

                    final isSelf = _currentUser != null &&
                        (_currentUser!['id']?.toString() == id ||
                            _currentUser!['email']?.toString().toLowerCase() ==
                                email.toLowerCase());

                    return MTMMSCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: isSelf
                                      ? LinearGradient(colors: [AppColors.success, AppColors.success.withValues(alpha: 0.7)])
                                      : AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty
                                        ? name.substring(0, 1).toUpperCase()
                                        : 'O',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPri(context),
                                            ),
                                          ),
                                        ),
                                        StatusBadge(status: role),
                                      ],
                                    ),
                                    if (isSelf)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          '(Current Active Session)',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 2),
                                    Text(
                                      designation,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                    Text(
                                      '$dept • $email',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppColors.textSec(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Actions Row
                          const SizedBox(height: 10),
                          Divider(height: 1, color: AppColors.dividerCol(context)),
                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit Officer Details',
                                color: AppColors.textSec(context),
                                onPressed: () => _showEditPersonDialog(u),
                              ),
                              if (!isSelf)
                                IconButton(
                                  icon: const Icon(Icons.login_rounded, size: 18),
                                  tooltip: 'Log In as $name',
                                  color: AppColors.primaryLight,
                                  onPressed: () => _switchToOfficer(u),
                                ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: isSelf ? AppColors.textHint : AppColors.error,
                                ),
                                tooltip: isSelf ? 'Cannot revoke active session' : 'Revoke Access',
                                onPressed: isSelf ? null : () => _confirmDeletePerson(u),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
