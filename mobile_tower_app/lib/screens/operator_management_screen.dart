import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/data_sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/government_components.dart';
import 'tower_management_screen.dart';

class OperatorManagementScreen extends StatefulWidget {
  const OperatorManagementScreen({super.key});

  @override
  State<OperatorManagementScreen> createState() =>
      _OperatorManagementScreenState();
}

class _OperatorManagementScreenState extends State<OperatorManagementScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _operators = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  Timer? _autoRefreshTimer;
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DataSyncService.syncNotifier.addListener(_onDataSyncChanged);
    _checkRole();
    _loadOperators();
    // 15-second heartbeat for live backend updates
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadOperators(isSilent: true),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadOperators(isSilent: true);
    }
  }

  void _onDataSyncChanged() {
    if (mounted) {
      _loadOperators(isSilent: true);
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    DataSyncService.syncNotifier.removeListener(_onDataSyncChanged);
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkRole() async {
    final isAdmin = await AuthService.isAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin);
  }

  Future<void> _loadOperators({bool isSilent = false}) async {
    if (!isSilent && mounted) setState(() => _isLoading = true);
    try {
      final list = await ApiService.getOperators();
      if (mounted) {
        setState(() {
          _operators = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !isSilent) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredOperators {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _operators.where((op) {
      final matchesSearch = query.isEmpty ||
          op['name'].toString().toLowerCase().contains(query) ||
          op['shortName'].toString().toLowerCase().contains(query) ||
          op['email'].toString().toLowerCase().contains(query) ||
          op['contact'].toString().toLowerCase().contains(query);

      final matchesStatus = _selectedStatusFilter == 'All' ||
          op['status'].toString().toLowerCase() ==
              _selectedStatusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _showAddOperatorDialog([Map<String, dynamic>? op]) {
    final isEdit = op != null;
    final nameCtrl = TextEditingController(text: op?['name']?.toString() ?? '');
    final shortNameCtrl =
        TextEditingController(text: op?['shortName']?.toString() ?? '');
    final contactCtrl =
        TextEditingController(text: op?['contact']?.toString() ?? '');
    final emailCtrl =
        TextEditingController(text: op?['email']?.toString() ?? '');
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEdit ? 'Edit Operator Record' : 'Register Network Operator',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogLabel('Full Operator Name *'),
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Bharti Airtel Limited',
                  ),
                ),
                const SizedBox(height: 12),
                _dialogLabel('Short Code / Brand *'),
                TextField(
                  controller: shortNameCtrl,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'e.g. AIRTEL',
                  ),
                ),
                const SizedBox(height: 12),
                _dialogLabel('Contact Phone / Officer'),
                TextField(
                  controller: contactCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'e.g. +91 9822000000',
                  ),
                ),
                const SizedBox(height: 12),
                _dialogLabel('Official Email'),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'e.g. nodal.goa@airtel.in',
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
                      if (nameCtrl.text.trim().isEmpty) return;
                      setDialogState(() => isSubmitting = true);

                      final data = {
                        'name': nameCtrl.text.trim(),
                        'shortName': shortNameCtrl.text.trim().toUpperCase(),
                        'contact': contactCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                      };

                      final success = await ApiService.saveOperator(
                        data,
                        isEditing: isEdit,
                        id: op?['dbId']?.toString(),
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit
                                  ? 'Operator details updated'
                                  : 'Operator registered successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _loadOperators();
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
                  : Text(isEdit ? 'Update' : 'Register'),
            ),
          ],
        ),
      ),
    );
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
    final list = _filteredOperators;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      drawer: const AppDrawer(currentRoute: 'operators'),
      appBar: MTMMSAppBar(
        title: 'Network Operators',
        subtitle: 'Authorized Telecom Service Providers',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Operators',
            onPressed: _loadOperators,
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Add Operator',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              onPressed: () => _showAddOperatorDialog(),
            )
          : null,
      body: Column(
        children: [
          // ── Search & Filters ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              border: Border(
                bottom: BorderSide(color: AppColors.borderCol(context)),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search operators by name, short code, email...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.primaryLight,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${list.length} registered operator${list.length == 1 ? '' : 's'}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppColors.textSec(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Filter: ',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textMut(context),
                          ),
                        ),
                        DropdownButton<String>(
                          value: _selectedStatusFilter,
                          underline: const SizedBox(),
                          isDense: true,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryLight,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All')),
                            DropdownMenuItem(
                              value: 'Active',
                              child: Text('Active'),
                            ),
                            DropdownMenuItem(
                              value: 'Inactive',
                              child: Text('Inactive'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedStatusFilter = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Operators Grid / List ─────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cell_wifi_rounded,
                              size: 48,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No network operators found.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSec(context),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final op = list[index];
                          final name = op['name']?.toString() ?? 'Operator';
                          final shortName = op['shortName']?.toString() ?? '';
                          final contact = op['contact']?.toString() ?? '—';
                          final email = op['email']?.toString() ?? '—';
                          final towers = op['towers']?.toString() ?? '0';
                          final status = op['status']?.toString() ?? 'Active';
                          final freq = op['frequency']?.toString() ?? '1800 MHz';

                          return MTMMSCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.primarySurf(context),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Center(
                                            child: Text(
                                              shortName.isNotEmpty
                                                  ? shortName.substring(
                                                      0,
                                                      shortName.length >= 2
                                                          ? 2
                                                          : 1,
                                                    )
                                                  : 'OP',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primaryLight,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPri(context),
                                              ),
                                            ),
                                            Text(
                                              'Brand: $shortName • $freq',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: AppColors.textSec(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    StatusBadge(status: status),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Divider(
                                  height: 1,
                                  color: AppColors.dividerCol(context),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Nodal Contact',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: AppColors.textMut(context),
                                          ),
                                        ),
                                        Text(
                                          '$contact • $email',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            color: AppColors.textPri(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const TowerManagementScreen(),
                                        ),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySurf(context),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '$towers Tower Nodes →',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryLight,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
