import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/government_components.dart';
import '../add_edit_tower_screen.dart';
import '../payment_history_screen.dart';

class TowerDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> tower;

  const TowerDetailsScreen({super.key, required this.tower});

  @override
  State<TowerDetailsScreen> createState() => _TowerDetailsScreenState();
}

class _TowerDetailsScreenState extends State<TowerDetailsScreen> {
  late Map<String, dynamic> _towerData;
  bool _isLoading = false;
  bool _isAdmin = false;
  bool _hasUpdated = false;
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _towerData = Map<String, dynamic>.from(widget.tower);
    _checkRole();
    _fetchDetails();
  }

  Future<void> _checkRole() async {
    final isAdmin = await AuthService.isAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin);
  }

  Future<void> _fetchDetails() async {
    final id = _towerData['dbId'] ?? _towerData['id'];
    if (id == null) return;

    setState(() => _isLoading = true);
    try {
      final details = await ApiService.getTowerDetails(id.toString());
      if (mounted && details != null) {
        setState(() {
          _towerData = details;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
      _fetchPayments();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPayments() async {
    final towerId = _towerData['towerId'] ?? _towerData['id'] ?? '';
    try {
      final payments = await ApiService.getTowerPayments(towerId.toString());
      if (mounted) setState(() => _payments = payments);
    } catch (_) {}
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tower Record'),
        content: Text(
          'Are you sure you want to permanently delete tower "${_towerData['towerId'] ?? _towerData['id']}" from the MTMMS database?',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final id = _towerData['dbId'] ?? _towerData['id'];
        await ApiService.deleteTower(id.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tower record deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showManageOperatorsModal() async {
    final rawTowerDbId = _towerData['dbId'] ?? _towerData['id'];
    if (rawTowerDbId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    List<Map<String, dynamic>> allOps = [];
    try {
      allOps = await ApiService.getOperators();
    } catch (_) {}
    if (mounted) Navigator.pop(context);

    if (!mounted) return;

    final Set<int> selectedIds = {};
    final currentList = _towerData['operators_list'] is List
        ? _towerData['operators_list'] as List
        : (_towerData['operators'] is List ? _towerData['operators'] as List : []);

    for (final op in currentList) {
      final opId = int.tryParse((op['dbId'] ?? op['id'] ?? '').toString());
      if (opId != null) selectedIds.add(opId);
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceBg(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderCol(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Telecom Operators',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context),
                          ),
                        ),
                        Text(
                          'Assign shared infrastructure tenancies',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: AppColors.textSec(context),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: AppColors.dividerCol(context)),
                const SizedBox(height: 12),
                if (allOps.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No registered telecom operators found in database.',
                        style: GoogleFonts.poppins(color: AppColors.textMut(context)),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: allOps.length,
                      itemBuilder: (c, i) {
                        final op = allOps[i];
                        final opId = int.tryParse((op['dbId'] ?? op['id'] ?? '').toString());
                        final name = op['name']?.toString() ?? 'Operator';
                        final shortName = op['shortName']?.toString() ?? name;
                        final isChecked = opId != null && selectedIds.contains(opId);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isChecked
                                ? AppColors.primaryLight.withValues(alpha: 0.1)
                                : AppColors.primarySurf(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isChecked
                                  ? AppColors.primaryLight
                                  : AppColors.borderCol(context),
                            ),
                          ),
                          child: CheckboxListTile(
                            value: isChecked,
                            activeColor: AppColors.primary,
                            title: Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPri(context),
                              ),
                            ),
                            subtitle: Text(
                              'Code: $shortName • Active Tenant',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSec(context),
                              ),
                            ),
                            onChanged: (val) {
                              if (opId == null) return;
                              setModalState(() {
                                if (val == true) {
                                  selectedIds.add(opId);
                                } else {
                                  selectedIds.remove(opId);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      );

                      final ok = await ApiService.syncTowerOperators(
                        rawTowerDbId.toString(),
                        selectedIds.toList(),
                      );
                      if (mounted) Navigator.pop(context);

                      if (ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Operators updated successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _hasUpdated = true;
                        _fetchDetails();
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to update operators'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Save Operators (${selectedIds.length} Selected)',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showRecordPaymentModal() async {
    final rawTowerDbId = _towerData['dbId'] ?? _towerData['id'];
    final towerIdStr = _val('towerId', _val('id', 'TWR-0001'));
    final yearlyRent = double.tryParse(_val('yearly_rent', '60000')) ?? 60000.0;

    final amountCtrl = TextEditingController(text: yearlyRent.toStringAsFixed(0));
    final challanCtrl = TextEditingController(
      text: 'CHL-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}',
    );
    final dateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );
    final remarksCtrl = TextEditingController(text: 'Official lease rent payment');
    String paymentMode = 'Treasury Challan';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceBg(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderCol(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record Rent Payment',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPri(context),
                            ),
                          ),
                          Text(
                            'Tower: $towerIdStr',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: AppColors.dividerCol(context)),
                  const SizedBox(height: 14),

                  Text(
                    'PAYMENT AMOUNT (₹) *',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: AppColors.inputBg(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'CHALLAN / TRANSACTION REFERENCE *',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: challanCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.receipt_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: AppColors.inputBg(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'PAYMENT METHOD',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: paymentMode,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: AppColors.inputBg(context),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Treasury Challan',
                        child: Text('Treasury Challan (Govt Account)'),
                      ),
                      DropdownMenuItem(
                        value: 'NEFT / RTGS',
                        child: Text('NEFT / RTGS Transfer'),
                      ),
                      DropdownMenuItem(
                        value: 'Bank Cheque / DD',
                        child: Text('Bank Cheque / Demand Draft'),
                      ),
                      DropdownMenuItem(
                        value: 'UPI / Online Portal',
                        child: Text('UPI / Online Payment Portal'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => paymentMode = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'REMARKS / OFFICIAL NOTES',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: remarksCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Annual lease rent deposited in Treasury',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: AppColors.inputBg(context),
                    ),
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                        final ref = challanCtrl.text.trim();
                        final tId = int.tryParse(rawTowerDbId.toString());

                        if (tId == null || amt <= 0 || ref.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter valid amount and reference.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        );

                        final ok = await ApiService.createPayment({
                          'tower_id': tId,
                          'amount': amt,
                          'payment_date': dateCtrl.text.trim(),
                          'payment_reference': ref,
                          'payment_method': paymentMode,
                          'payment_status': 'paid',
                          'remarks': remarksCtrl.text.trim(),
                        });

                        if (mounted) Navigator.pop(context);

                        if (ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment recorded and credited successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _hasUpdated = true;
                          _fetchDetails();
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to record payment in database.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Submit Payment Receipt',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _val(String key, [String fallback = '—']) {
    final v = _towerData[key];
    if (v == null || v.toString().trim().isEmpty) return fallback;
    return v.toString();
  }

  String _formatDimension(String key, String fallback) {
    final raw = _val(key, fallback);
    if (raw == '—' || raw.isEmpty) return fallback;
    final cleanStr = raw.replaceAll(RegExp(r'[^\d.]'), '').trim();
    final numVal = double.tryParse(cleanStr);
    if (numVal == null) return raw;

    final lower = raw.toLowerCase();
    if (lower.contains('ft') || lower.contains('feet')) {
      final inMeters = numVal * 0.3048;
      return '${numVal.toStringAsFixed(1)} ft (${inMeters.toStringAsFixed(1)} m)';
    } else {
      final inFeet = numVal * 3.28084;
      return '${numVal.toStringAsFixed(1)} m (${inFeet.toStringAsFixed(1)} ft)';
    }
  }

  String _formatSpace(String key) {
    final raw = _val(key, '2.5');
    if (raw == '—' || raw.isEmpty) return '6 m² (67 sq ft)';
    final cleanStr = raw.replaceAll(RegExp(r'[^\d.]'), '').trim();
    final numVal = double.tryParse(cleanStr) ?? 2.5;
    final sqM = (numVal * numVal).round();
    final sqFt = (sqM * 10.7639).round();
    return '$sqM m² ($sqFt sq ft)';
  }

  @override
  Widget build(BuildContext context) {
    final towerId = _val('towerId', _val('id', 'Tower Details'));
    final isActive = _val('status', 'Active').toLowerCase() == 'active';
    final isGovt = _val('land', 'Government').toLowerCase() == 'government';
    final isRentDue = _val('rent', 'Paid').toLowerCase() == 'due' ||
        _val('rent', 'Paid').toLowerCase() == 'overdue';

    final yearlyRent = double.tryParse(_val('yearly_rent', '60000')) ?? 60000.0;
    final rentCycleYears = int.tryParse(_val('rent_cycle_years', '5')) ?? 5;
    final totalAmount = yearlyRent * rentCycleYears;

    final operatorsList = _towerData['operators_list'] is List
        ? _towerData['operators_list'] as List
        : [];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasUpdated);
      },
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        appBar: MTMMSAppBar(
          title: towerId,
          subtitle: 'Official Infrastructure Specification',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context, _hasUpdated),
          ),
          actions: [
            if (_isAdmin) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Tower',
                onPressed: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditTowerScreen(tower: _towerData),
                    ),
                  );
                  if (updated == true) {
                    _hasUpdated = true;
                    _fetchDetails();
                  }
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete Tower',
              onPressed: _confirmDelete,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _fetchDetails,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                children: [
                  // ── Top Summary Header Card ───────────────────────────
                  MTMMSCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              towerId,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPri(context),
                              ),
                            ),
                            StatusBadge(
                              status: isActive ? 'Active Grid' : 'Inactive',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Owner: ${_val('owner', 'Government of Goa')}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSec(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            StatusBadge(
                              status: isGovt ? 'Government' : 'Private',
                            ),
                            StatusBadge(
                              status: isRentDue ? 'Due' : 'Paid',
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurf(context),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primaryLight
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                '${_formatDimension('height', '30m')} Height',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Unified Tower Owner / Ownership Details ──────────
                  MTMMSCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MTMMSSectionHeader(
                          title: 'TOWER OWNER / OWNERSHIP DETAILS',
                          icon: Icons.business_rounded,
                        ),
                        const SizedBox(height: 8),
                        Divider(height: 1, color: AppColors.dividerCol(context)),
                        const SizedBox(height: 8),
                        _row('Owner Name', _val('owner', 'Government of Goa')),
                        _row('Land Classification', isGovt ? 'Government Land' : 'Private Land'),
                        _row('Contact Phone', _val('owner_phone', '+91 832 2419000')),
                        _row('Official Email', _val('owner_email', 'doit@goa.gov.in')),
                        _row('Owner Address', _val('owner_address', 'Panaji, Goa')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Geographic & Administrative Hierarchy ─────────────
                  MTMMSCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MTMMSSectionHeader(
                          title: 'GEOGRAPHIC & ADMINISTRATIVE LOCATION',
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 8),
                        Divider(height: 1, color: AppColors.dividerCol(context)),
                        const SizedBox(height: 8),
                        _row('District', _val('district', 'North Goa')),
                        _row('Taluka', _val('taluka', 'Tiswadi')),
                        _row('Constituency', _val('constituency', 'Panaji')),
                        _row('Area / Panchayat', _val('area', 'Panaji Market')),
                        _row('Full Site Address', _val('address', 'Goa')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Technical Specifications ──────────────────────────
                  MTMMSCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MTMMSSectionHeader(
                          title: 'TECHNICAL & STRUCTURAL SPECIFICATIONS',
                          icon: Icons.engineering_outlined,
                        ),
                        const SizedBox(height: 8),
                        Divider(height: 1, color: AppColors.dividerCol(context)),
                        const SizedBox(height: 8),
                        _row('Tower Height', _formatDimension('height', '30.0 m (98.4 ft)')),
                        _row('Base Width', _formatDimension('width', '2.5 m (8.2 ft)')),
                        _row('Tower Ground Space', _formatSpace('width')),
                        _row('Operating Frequency', _val('frequency', '1800 MHz')),
                        _row('Total Operators', _val('operators', '1 operator')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Operators Using This Tower ────────────────────────
                  MTMMSCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const MTMMSSectionHeader(
                              title: 'OPERATORS USING THIS TOWER',
                              icon: Icons.cell_wifi_rounded,
                            ),
                            if (_isAdmin)
                              TextButton.icon(
                                icon: const Icon(Icons.edit_note_rounded, size: 16),
                                label: const Text(
                                  'Manage Operators',
                                  style: TextStyle(fontSize: 11.5),
                                ),
                                onPressed: _showManageOperatorsModal,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(height: 1, color: AppColors.dividerCol(context)),
                        const SizedBox(height: 10),
                        if (operatorsList.isEmpty)
                          _row('Primary Operator', _val('operator', 'None'))
                        else
                          Column(
                            children: operatorsList.map((op) {
                              final name = op['name']?.toString() ?? 'Operator';
                              final shortName = op['shortName']?.toString() ?? name;
                              final freq = op['frequency']?.toString() ?? '1800 MHz';
                              final status = op['status']?.toString() ?? 'Active';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurf(context),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.borderCol(context),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.cell_tower_rounded,
                                          size: 16,
                                          color: AppColors.primaryLight,
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    AppColors.textPri(context),
                                              ),
                                            ),
                                            Text(
                                              'Code: $shortName • $freq',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color:
                                                    AppColors.textSec(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    StatusBadge(status: status),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Financial & Rent Specifications (Yearly Rent & Cycles) ──
                  MTMMSCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MTMMSSectionHeader(
                          title: 'FINANCIAL & LEASE TERMS',
                          icon: Icons.currency_rupee_rounded,
                        ),
                        const SizedBox(height: 8),
                        Divider(height: 1, color: AppColors.dividerCol(context)),
                        const SizedBox(height: 8),
                        _row(
                          'Yearly Rent',
                          '₹${yearlyRent.toStringAsFixed(0)}',
                        ),
                        _row(
                          'Selected Rent Cycle',
                          '$rentCycleYears Year${rentCycleYears > 1 ? 's' : ''}',
                        ),
                        _row(
                          'Total Cycle Amount',
                          '₹${totalAmount.toStringAsFixed(0)} (₹${yearlyRent.toStringAsFixed(0)} × $rentCycleYears)',
                        ),
                        _row(
                          'Payment Status',
                          _val('rent', 'Paid'),
                        ),
                        _row(
                          'Next Due Date',
                          _val('rent_due_date', 'Annual'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Payment History & Receipts ────────────────────────
                  MTMMSCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const MTMMSSectionHeader(
                              title: 'PAYMENT HISTORY',
                              icon: Icons.receipt_long_rounded,
                            ),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add_rounded, size: 14),
                                  label: const Text(
                                    'Record Payment',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: _showRecordPaymentModal,
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PaymentHistoryScreen(
                                        towerId: towerId,
                                        owner: _val('owner', 'Government of Goa'),
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'All Receipts →',
                                    style: TextStyle(fontSize: 11.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Divider(height: 1, color: AppColors.dividerCol(context)),
                        const SizedBox(height: 10),
                        if (_payments.isEmpty)
                          Text(
                            'No recorded transactions for this tower yet.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textMut(context),
                            ),
                          )
                        else
                          Column(
                            children: _payments.take(3).map((p) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurf(context),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['receiptNo'] ?? 'Receipt',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPri(context),
                                          ),
                                        ),
                                        Text(
                                          p['date'] ?? '2026-08-21',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: AppColors.textSec(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      p['amount']?.toString() ?? '₹0',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppColors.textSec(context),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
