import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../services/data_sync_service.dart';
import '../../services/owner_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../tower_management_screen.dart';

class OwnerManagementScreen extends StatefulWidget {
  const OwnerManagementScreen({super.key});

  @override
  State<OwnerManagementScreen> createState() => _OwnerManagementScreenState();
}

class _OwnerManagementScreenState extends State<OwnerManagementScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _owners = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DataSyncService.syncNotifier.addListener(_onDataSyncChanged);
    _checkRole();
    _loadOwners();
    // 15-second heartbeat for live backend updates
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadOwners(isSilent: true),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadOwners(isSilent: true);
    }
  }

  void _onDataSyncChanged() {
    if (mounted) {
      _loadOwners(isSilent: true);
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

  Future<void> _loadOwners({bool isSilent = false}) async {
    if (!isSilent && mounted) setState(() => _isLoading = true);
    try {
      final list = await OwnerService.getOwners();
      if (mounted) {
        setState(() {
          _owners = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !isSilent) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredOwners {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _owners;
    return _owners.where((o) {
      final name = (o['name'] ?? '').toString().toLowerCase();
      final phone = (o['phone'] ?? '').toString().toLowerCase();
      final email = (o['email'] ?? '').toString().toLowerCase();
      final address = (o['address'] ?? '').toString().toLowerCase();
      return name.contains(q) || phone.contains(q) || email.contains(q) || address.contains(q);
    }).toList();
  }

  void _showAddEditOwnerModal([Map<String, dynamic>? owner]) {
    final isEditing = owner != null;
    final nameCtrl = TextEditingController(text: owner?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: owner?['phone'] ?? '');
    final emailCtrl = TextEditingController(text: owner?['email'] ?? '');
    final addressCtrl = TextEditingController(text: owner?['address'] ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Land / Tower Owner' : 'Register Tower Owner',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPri(context),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Divider(height: 16, color: AppColors.dividerCol(context)),

              Text('Owner / Authority Name *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPri(context))),
              const SizedBox(height: 4),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPri(context)),
                decoration: const InputDecoration(hintText: 'e.g. Directorate of Transport / Private Landlord'),
              ),
              const SizedBox(height: 12),

              Text('Phone Number', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPri(context))),
              const SizedBox(height: 4),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPri(context)),
                decoration: const InputDecoration(hintText: '+91 832 200 0000'),
              ),
              const SizedBox(height: 12),

              Text('Email Address', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPri(context))),
              const SizedBox(height: 4),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPri(context)),
                decoration: const InputDecoration(hintText: 'owner@goa.gov.in'),
              ),
              const SizedBox(height: 12),

              Text('Address / Office Location', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPri(context))),
              const SizedBox(height: 4),
              TextField(
                controller: addressCtrl,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPri(context)),
                decoration: const InputDecoration(hintText: 'Panaji, Goa'),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          setModalState(() => isSaving = true);

                          final dbId = owner?['dbId']?.toString() ?? owner?['id']?.toString() ?? '';
                          final success = isEditing
                              ? await OwnerService.updateOwner(
                                  id: dbId,
                                  name: nameCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  email: emailCtrl.text.trim(),
                                  address: addressCtrl.text.trim(),
                                )
                              : await OwnerService.createOwner(
                                  name: nameCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  email: emailCtrl.text.trim(),
                                  address: addressCtrl.text.trim(),
                                );

                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'Owner saved successfully'
                                    : 'Failed to save owner'),
                                backgroundColor: success ? AppColors.success : AppColors.error,
                              ),
                            );
                            _loadOwners();
                          }
                        },
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(isEditing ? 'Update Owner' : 'Register Owner'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredOwners;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      drawer: const AppDrawer(currentRoute: 'owners'),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tower Owners & Authorities',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Land & Property Lease Holders',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadOwners,
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditOwnerModal(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Add Owner',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surfaceBg(context),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.poppins(fontSize: 13.5, color: AppColors.textPri(context)),
              decoration: InputDecoration(
                hintText: 'Search owners by name, phone, address...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : list.isEmpty
                    ? Center(
                        child: Text(
                          'No owners found in database.',
                          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMut(context)),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOwners,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (ctx, index) {
                            final o = list[index];
                            final name = o['name'] ?? 'Government Authority';
                            final phone = o['phone'] ?? '—';
                            final email = o['email'] ?? '—';
                            final address = o['address'] ?? 'Goa';
                            final towersCount = o['towersCount'] ?? 0;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.borderCol(context)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.primarySurf(context),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.business_outlined,
                                              color: AppColors.primaryLight,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPri(context),
                                                ),
                                              ),
                                              Text(
                                                address,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11.5,
                                                  color: AppColors.textSec(context),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (_isAdmin)
                                        IconButton(
                                          icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.textSec(context)),
                                          tooltip: 'Edit Owner',
                                          onPressed: () => _showAddEditOwnerModal(o),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Divider(height: 1, color: AppColors.dividerCol(context)),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.phone_outlined, size: 14, color: AppColors.textMut(context)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Phone: $phone',
                                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSec(context)),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.email_outlined, size: 14, color: AppColors.textMut(context)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Email: $email',
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSec(context)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySurf(context),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$towersCount Associated Towers',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryLight,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const TowerManagementScreen(),
                                            ),
                                          );
                                        },
                                        child: const Text('View Towers →', style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
