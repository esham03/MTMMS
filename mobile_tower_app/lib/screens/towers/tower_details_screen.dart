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
  List<Map<String, dynamic>> _renewals = [];

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
      _fetchRenewals();
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

  Future<void> _fetchRenewals() async {
    final id = _towerData['dbId'] ?? _towerData['id'];
    if (id == null) return;
    try {
      final renewals = await ApiService.getTowerRenewals(id.toString());
      if (mounted) setState(() => _renewals = renewals);
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

  Future<void> _showAdjustRateDialog() async {
    final rawTowerDbId = _towerData['dbId'] ?? _towerData['id'];
    if (rawTowerDbId == null) return;

    final initialEscEnabled = (_val('escalation_enabled', 'true').toLowerCase() == 'true' || _val('escalation_enabled', 'true') == '1');
    final initialEscPct = double.tryParse(_val('escalation_percentage', '10.0')) ?? 10.0;
    final currentRent = double.tryParse(_val('yearly_rent', '60000')) ?? 60000.0;

    bool escalationEnabled = initialEscEnabled;
    final rateCtrl = TextEditingController(text: initialEscPct.toStringAsFixed(1).replaceAll('.0', ''));
    bool isSaving = false;
    String? errorMsg;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final rateVal = double.tryParse(rateCtrl.text.trim()) ?? 0.0;
            final incVal = escalationEnabled ? (currentRent * rateVal / 100.0) : 0.0;
            final projNextRent = currentRent + incVal;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceBg(ctx),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.dividerCol(ctx),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurf(ctx),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.trending_up_rounded, color: AppColors.primaryLight, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ADJUST ESCALATION RATE',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPri(ctx),
                                  ),
                                ),
                                Text(
                                  _val('towerId', _val('id', 'TWR')),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.textSec(ctx),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    Divider(height: 16, color: AppColors.dividerCol(ctx)),
                    if (errorMsg != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          errorMsg!,
                          style: GoogleFonts.poppins(color: AppColors.error, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg(ctx),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderCol(ctx)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Automatic Rent Escalation',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPri(ctx),
                                ),
                              ),
                              Text(
                                escalationEnabled ? 'Enabled on renewal' : 'Disabled (fixed rent)',
                                style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.textSec(ctx)),
                              ),
                            ],
                          ),
                          Switch(
                            value: escalationEnabled,
                            activeColor: AppColors.primaryLight,
                            onChanged: (val) {
                              setModalState(() => escalationEnabled = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    if (escalationEnabled) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: rateCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          labelText: 'Escalation Percentage (%) *',
                          suffixText: '%',
                          prefixIcon: Icon(Icons.percent_rounded, size: 18),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [5.0, 8.0, 10.0, 12.0, 15.0, 20.0].map((rate) {
                          final isSelected = double.tryParse(rateCtrl.text.trim()) == rate;
                          return ChoiceChip(
                            label: Text('${rate.toInt()}%'),
                            labelStyle: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textPri(ctx),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceBg(ctx),
                            onSelected: (_) {
                              setModalState(() => rateCtrl.text = rate.toInt().toString());
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurf(ctx),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ESCALATION PROJECTION',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Current Rent:', style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSec(ctx))),
                                Text('₹${currentRent.toStringAsFixed(0)} / yr', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Increase Amount:', style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSec(ctx))),
                                Text('+₹${incVal.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.success)),
                              ],
                            ),
                            Divider(height: 12, color: AppColors.dividerCol(ctx)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Projected Next Rent:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
                                Text('₹${projNextRent.toStringAsFixed(0)} / yr', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryLight)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            icon: isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: Text(isSaving ? 'Saving...' : 'Save Escalation Rate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final pct = double.tryParse(rateCtrl.text.trim());
                                    if (escalationEnabled && (pct == null || pct < 0 || pct > 100)) {
                                      setModalState(() => errorMsg = 'Please enter a valid rate between 0% and 100%');
                                      return;
                                    }
                                    setModalState(() {
                                      isSaving = true;
                                      errorMsg = null;
                                    });

                                    final ok = await ApiService.updateTowerEscalation(
                                      rawTowerDbId.toString(),
                                      {
                                        'escalation_enabled': escalationEnabled,
                                        'escalation_percentage': pct ?? 0.0,
                                      },
                                    );

                                    if (!mounted) return;
                                    if (sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                    }

                                    if (ok) {
                                      _hasUpdated = true;
                                      _fetchDetails();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Escalation configuration updated successfully to ${pct ?? 0}%!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Failed to update escalation rate.'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showRenewalDialog() async {
    final rawTowerDbId = _towerData['dbId'] ?? _towerData['id'];
    if (rawTowerDbId == null) return;

    final currentCycleYears = int.tryParse(_val('rent_cycle_years', '5')) ?? 5;
    int selectedCycle = currentCycleYears > 0 ? currentCycleYears : 5;

    String defaultStartDate = _val('next_renewal_date');
    if (defaultStartDate == '—' || defaultStartDate.isEmpty) {
      defaultStartDate = _val('agreement_end_date');
    }
    if (defaultStartDate == '—' || defaultStartDate.isEmpty) {
      defaultStartDate = DateTime.now().toIso8601String().substring(0, 10);
    }

    DateTime parsedStart = DateTime.tryParse(defaultStartDate) ?? DateTime.now();
    DateTime parsedEnd = DateTime(parsedStart.year + selectedCycle, parsedStart.month, parsedStart.day);

    String startDateStr = defaultStartDate;
    String endDateStr = parsedEnd.toIso8601String().substring(0, 10);

    bool isManualOverride = false;
    final overrideRentCtrl = TextEditingController();
    final overrideReasonCtrl = TextEditingController();

    final initialEscEnabled = (_val('escalation_enabled', 'true').toLowerCase() == 'true' || _val('escalation_enabled', 'true') == '1');
    final initialEscPct = double.tryParse(_val('escalation_percentage', '10.0')) ?? 10.0;
    bool escalationEnabled = initialEscEnabled;
    final escalationRateCtrl = TextEditingController(text: initialEscPct.toStringAsFixed(1).replaceAll('.0', ''));

    bool isPreviewLoading = true;
    bool isSubmitting = false;
    Map<String, dynamic>? previewData;
    String? previewError;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void loadPreview() async {
              setModalState(() {
                isPreviewLoading = true;
                previewError = null;
              });
              try {
                final customPct = double.tryParse(escalationRateCtrl.text.trim());
                final preview = await ApiService.previewRenewal(
                  rawTowerDbId.toString(),
                  cycleYears: selectedCycle,
                  newStartDate: startDateStr,
                  newEndDate: endDateStr,
                  customPercentage: customPct,
                  escalationEnabled: escalationEnabled,
                );
                setModalState(() {
                  previewData = preview;
                  isPreviewLoading = false;
                  if (!isManualOverride && preview['proposed_new_annual_rent'] != null) {
                    overrideRentCtrl.text = preview['proposed_new_annual_rent'].toString();
                  }
                });
              } catch (e) {
                setModalState(() {
                  previewError = e.toString().replaceAll('Exception: ', '');
                  isPreviewLoading = false;
                });
              }
            }

            if (previewData == null && isPreviewLoading && previewError == null) {
              loadPreview();
            }

            final prevRent = previewData?['previous_annual_rent'] ?? _val('yearly_rent', '60000');
            final escRate = previewData?['escalation_percentage'] ?? _val('escalation_percentage', '10');
            final incAmount = previewData?['increase_amount'] ?? 0;
            final propRent = previewData?['proposed_new_annual_rent'] ?? previewData?['new_annual_rent'] ?? prevRent;
            final isEscEnabled = previewData?['is_escalation_enabled'] ?? (_val('escalation_enabled', 'true').toLowerCase() == 'true');

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.88,
              decoration: BoxDecoration(
                color: AppColors.surfaceBg(ctx),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.dividerCol(ctx),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurf(ctx),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.autorenew_rounded, color: AppColors.primaryLight, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RENEW LEASE AGREEMENT',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPri(ctx),
                                  ),
                                ),
                                Text(
                                  'Statutory Rent Escalation Workflow',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.textSec(ctx),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.dividerCol(ctx)),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurf(ctx),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _val('towerId', _val('id', 'TWR')),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPri(ctx),
                                    ),
                                  ),
                                  StatusBadge(
                                    status: isEscEnabled ? 'Escalation Active ($escRate%)' : 'Escalation Disabled',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Location: ${_val('area')}, ${_val('taluka')}, ${_val('district')}',
                                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSec(ctx)),
                              ),
                              Text(
                                'Owner: ${_val('owner')} • Operator: ${_val('operator')}',
                                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSec(ctx)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'RENEWAL DURATION & SCHEDULE',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: selectedCycle,
                          decoration: const InputDecoration(
                            labelText: 'Renewal Agreement Duration',
                            prefixIcon: Icon(Icons.timelapse_rounded, size: 18),
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1 Year Cycle')),
                            DropdownMenuItem(value: 2, child: Text('2 Years Cycle')),
                            DropdownMenuItem(value: 3, child: Text('3 Years Cycle')),
                            DropdownMenuItem(value: 5, child: Text('5 Years Cycle (Standard)')),
                            DropdownMenuItem(value: 10, child: Text('10 Years Cycle')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              selectedCycle = val;
                              final s = DateTime.tryParse(startDateStr) ?? DateTime.now();
                              final e = DateTime(s.year + selectedCycle, s.month, s.day);
                              endDateStr = e.toIso8601String().substring(0, 10);
                              loadPreview();
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final cur = DateTime.tryParse(startDateStr) ?? DateTime.now();
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: cur,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2050),
                                  );
                                  if (picked != null) {
                                    startDateStr = picked.toIso8601String().substring(0, 10);
                                    final e = DateTime(picked.year + selectedCycle, picked.month, picked.day);
                                    endDateStr = e.toIso8601String().substring(0, 10);
                                    loadPreview();
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Start Date',
                                    prefixIcon: Icon(Icons.calendar_today_rounded, size: 16),
                                  ),
                                  child: Text(
                                    startDateStr,
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final cur = DateTime.tryParse(endDateStr) ?? DateTime.now();
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: cur,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2050),
                                  );
                                  if (picked != null) {
                                    endDateStr = picked.toIso8601String().substring(0, 10);
                                    loadPreview();
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'End Date',
                                    prefixIcon: Icon(Icons.event_available_rounded, size: 16),
                                  ),
                                  child: Text(
                                    endDateStr,
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'RENT ESCALATION RATE SETTINGS',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg(ctx),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderCol(ctx)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Apply Automatic Escalation',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPri(ctx),
                                        ),
                                      ),
                                      Text(
                                        escalationEnabled ? 'Compound rent on renewal' : 'Fixed rent renewal (0% increase)',
                                        style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.textSec(ctx)),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: escalationEnabled,
                                    activeColor: AppColors.primaryLight,
                                    onChanged: (val) {
                                      setModalState(() {
                                        escalationEnabled = val;
                                        loadPreview();
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (escalationEnabled) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: escalationRateCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                                        decoration: const InputDecoration(
                                          labelText: 'Escalation Rate (%)',
                                          suffixText: '%',
                                          prefixIcon: Icon(Icons.percent_rounded, size: 16),
                                        ),
                                        onChanged: (_) => loadPreview(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    ...[5.0, 8.0, 10.0, 12.0, 15.0, 20.0].map((rate) {
                                      final isSelected = double.tryParse(escalationRateCtrl.text.trim()) == rate;
                                      return ChoiceChip(
                                        label: Text('${rate.toInt()}%'),
                                        labelStyle: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? Colors.white : AppColors.textPri(ctx),
                                        ),
                                        selected: isSelected,
                                        selectedColor: AppColors.primary,
                                        backgroundColor: AppColors.surfaceBg(ctx),
                                        onSelected: (_) {
                                          setModalState(() {
                                            escalationRateCtrl.text = rate.toInt().toString();
                                            loadPreview();
                                          });
                                        },
                                      );
                                    }),
                                    ActionChip(
                                      label: Text('Reset (${initialEscPct.toInt()}%)'),
                                      labelStyle: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSec(ctx)),
                                      backgroundColor: AppColors.surfaceBg(ctx),
                                      onPressed: () {
                                        setModalState(() {
                                          escalationRateCtrl.text = initialEscPct.toStringAsFixed(1).replaceAll('.0', '');
                                          loadPreview();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (isPreviewLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                          )
                        else if (previewError != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Preview Calculation Error: $previewError',
                              style: GoogleFonts.poppins(color: AppColors.error, fontSize: 12),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg(ctx),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderCol(ctx)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'RENT REVISION SUMMARY',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryLight,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    StatusBadge(
                                      status: isEscEnabled ? '+$escRate% Increase' : 'Flat Rent Renewal',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Divider(height: 1, color: AppColors.dividerCol(ctx)),
                                const SizedBox(height: 8),
                                _summaryRow(ctx, 'Previous Annual Rent', '₹$prevRent / yr'),
                                _summaryRow(
                                  ctx,
                                  'Escalation Percentage',
                                  isEscEnabled ? '$escRate%' : '0.00% (Disabled)',
                                ),
                                _summaryRow(
                                  ctx,
                                  'Calculated Increase Amount',
                                  '+₹$incAmount / yr',
                                  highlightColor: AppColors.success,
                                ),
                                Divider(height: 14, color: AppColors.dividerCol(ctx)),
                                _summaryRow(
                                  ctx,
                                  'Proposed New Annual Rent',
                                  '₹$propRent / yr',
                                  isBold: true,
                                  highlightColor: AppColors.primaryLight,
                                ),
                                _summaryRow(ctx, 'Effective Period', '$startDateStr to $endDateStr ($selectedCycle Yrs)'),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (_isAdmin)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isManualOverride
                                  ? AppColors.warning.withValues(alpha: 0.08)
                                  : AppColors.primarySurf(ctx),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isManualOverride
                                    ? AppColors.warning.withValues(alpha: 0.4)
                                    : AppColors.borderCol(ctx),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Manual Rent Override (Admin Discretion)',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPri(ctx),
                                            ),
                                          ),
                                          Text(
                                            'Override automatically calculated escalation with custom rent',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10.5,
                                              color: AppColors.textSec(ctx),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: isManualOverride,
                                      activeColor: AppColors.warning,
                                      onChanged: (val) {
                                        setModalState(() {
                                          isManualOverride = val;
                                          if (val && overrideRentCtrl.text.isEmpty && previewData != null) {
                                            overrideRentCtrl.text = propRent.toString();
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                if (isManualOverride) ...[
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: overrideRentCtrl,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.poppins(fontSize: 13),
                                    decoration: const InputDecoration(
                                      labelText: 'Custom Annual Rent (₹) *',
                                      prefixIcon: Icon(Icons.currency_rupee_rounded, size: 16),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: overrideReasonCtrl,
                                    maxLines: 2,
                                    style: GoogleFonts.poppins(fontSize: 12.5),
                                    decoration: const InputDecoration(
                                      labelText: 'Mandatory Justification / Order Reference *',
                                      hintText: 'e.g. Special administrative waiver as per Order #DOIT-2026/84',
                                      prefixIcon: Icon(Icons.edit_note_rounded, size: 18),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                icon: isSubmitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.check_circle_outline_rounded, size: 18),
                                label: Text(isSubmitting ? 'Confirming...' : 'Confirm Renewal'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: isSubmitting || isPreviewLoading
                                    ? null
                                    : () async {
                                        if (isManualOverride) {
                                          final customVal = double.tryParse(overrideRentCtrl.text.trim());
                                          if (customVal == null || customVal <= 0) {
                                            ScaffoldMessenger.of(ctx).showSnackBar(
                                              const SnackBar(
                                                content: Text('Please enter a valid positive manual rent amount.'),
                                                backgroundColor: AppColors.error,
                                              ),
                                            );
                                            return;
                                          }
                                          if (overrideReasonCtrl.text.trim().length < 3) {
                                            ScaffoldMessenger.of(ctx).showSnackBar(
                                              const SnackBar(
                                                content: Text('A valid justification reason is mandatory for manual override.'),
                                                backgroundColor: AppColors.error,
                                              ),
                                            );
                                            return;
                                          }
                                        }

                                        setModalState(() => isSubmitting = true);
                                        try {
                                          final payload = <String, dynamic>{
                                            'renewal_cycle_years': selectedCycle,
                                            'new_agreement_start_date': startDateStr,
                                            'new_agreement_end_date': endDateStr,
                                            'is_manual_override': isManualOverride,
                                            'escalation_enabled': escalationEnabled,
                                            'escalation_percentage': double.tryParse(escalationRateCtrl.text.trim()) ?? initialEscPct,
                                          };
                                          if (isManualOverride) {
                                            payload['manual_new_rent'] = double.parse(overrideRentCtrl.text.trim());
                                            payload['override_reason'] = overrideReasonCtrl.text.trim();
                                          }

                                          final resp = await ApiService.confirmRenewal(
                                            rawTowerDbId.toString(),
                                            payload,
                                          );

                                          if (!mounted) return;
                                          if (sheetContext.mounted) {
                                            Navigator.pop(sheetContext);
                                          }
                                          _hasUpdated = true;
                                          _fetchDetails();
                                          _fetchRenewals();

                                          final newRentDisp = resp['data']?['new_annual_rent'] ??
                                              resp['new_annual_rent'] ??
                                              propRent;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Agreement renewed successfully! Revised Rent: ₹$newRentDisp / year',
                                              ),
                                              backgroundColor: AppColors.success,
                                              duration: const Duration(seconds: 4),
                                            ),
                                          );
                                        } catch (e) {
                                          setModalState(() => isSubmitting = false);
                                          if (ctx.mounted) {
                                            ScaffoldMessenger.of(ctx).showSnackBar(
                                              SnackBar(
                                                content: Text(e.toString().replaceAll('Exception: ', '')),
                                                backgroundColor: AppColors.error,
                                              ),
                                            );
                                          }
                                        }
                                      },
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
          },
        );
      },
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? highlightColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSec(context),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: highlightColor ?? AppColors.textPri(context),
            ),
          ),
        ],
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

                  // ── Rent Escalation Configuration ────────────────────
                  MTMMSCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const MTMMSSectionHeader(
                              title: 'RENT ESCALATION CONFIGURATION',
                              icon: Icons.trending_up_rounded,
                            ),
                            StatusBadge(
                              status: (_val('escalation_enabled', 'true').toLowerCase() == 'true' ||
                                      _val('escalation_enabled', 'true') == '1')
                                  ? 'Escalation Active'
                                  : 'Escalation Disabled',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(height: 1, color: AppColors.dividerCol(context)),
                        const SizedBox(height: 8),

                        _row(
                          'Automatic Escalation',
                          (_val('escalation_enabled', 'true').toLowerCase() == 'true' ||
                                  _val('escalation_enabled', 'true') == '1')
                              ? 'Enabled (Automatic on Renewal)'
                              : 'Disabled (Fixed Rent on Renewal)',
                        ),
                        _row(
                          'Current Yearly Rent',
                          '₹${yearlyRent.toStringAsFixed(2)} / year',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 140,
                                child: Text(
                                  'Escalation Percentage',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    color: AppColors.textSec(context),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${double.tryParse(_val('escalation_percentage', '10.0'))?.toStringAsFixed(2) ?? '10.00'}%',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppColors.primaryLight,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (_isAdmin)
                                      InkWell(
                                        onTap: _showAdjustRateDialog,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.primarySurf(context),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            'Adjust',
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
                              ),
                            ],
                          ),
                        ),
                        _row(
                          'Agreement Duration',
                          '$rentCycleYears Year${rentCycleYears > 1 ? 's' : ''}',
                        ),
                        _row(
                          'Agreement Start Date',
                          _val('agreement_start_date', _val('rent_start_date', '—')),
                        ),
                        _row(
                          'Agreement End Date',
                          _val('agreement_end_date', _val('next_renewal_date', '—')),
                        ),
                        _row(
                          'Next Renewal Date',
                          _val('next_renewal_date', _val('agreement_end_date', '—')),
                        ),
                        _row(
                          'Last Revised Rent',
                          _val('last_revised_rent') != '—'
                              ? '₹${_val('last_revised_rent')} / year'
                              : '₹${yearlyRent.toStringAsFixed(2)} (Initial)',
                        ),
                        _row(
                          'Last Escalation Date',
                          _val('last_escalation_date', 'Initial Agreement'),
                        ),

                        const SizedBox(height: 10),

                        // Live Compounding Escalation Preview Card
                        Builder(
                          builder: (ctx) {
                            final isEscEnabled = (_val('escalation_enabled', 'true').toLowerCase() == 'true' ||
                                _val('escalation_enabled', 'true') == '1');
                            final escPct = double.tryParse(_val('escalation_percentage', '10.0')) ?? 10.0;
                            final incAmount = isEscEnabled ? (yearlyRent * escPct / 100.0) : 0.0;
                            final nextRent = yearlyRent + incAmount;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isEscEnabled
                                    ? AppColors.primarySurf(context)
                                    : AppColors.warning.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isEscEnabled
                                      ? AppColors.primaryLight.withValues(alpha: 0.3)
                                      : AppColors.warning.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isEscEnabled ? Icons.insights_rounded : Icons.info_outline_rounded,
                                    size: 20,
                                    color: isEscEnabled ? AppColors.primaryLight : AppColors.warning,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isEscEnabled
                                              ? 'Next Renewal Projection: +$escPct% Escalation'
                                              : 'Automatic Rent Escalation Disabled',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: isEscEnabled ? AppColors.primaryLight : AppColors.warning,
                                          ),
                                        ),
                                        Text(
                                          isEscEnabled
                                              ? '₹${yearlyRent.toStringAsFixed(0)} + ₹${incAmount.toStringAsFixed(0)} = ₹${nextRent.toStringAsFixed(0)} / yr'
                                              : 'Rent will remain ₹${yearlyRent.toStringAsFixed(0)} / yr on agreement renewal.',
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
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // Action Buttons: Renew Agreement + Adjust Escalation Rate
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.autorenew_rounded, size: 18),
                                label: const Text('Renew Agreement'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: _showRenewalDialog,
                              ),
                            ),
                            if (_isAdmin) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.tune_rounded, size: 16),
                                  label: const Text('Adjust Rate'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _showAdjustRateDialog,
                                ),
                              ),
                            ],
                          ],
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

                  const SizedBox(height: 14),

                  // ── Rent Revision & Agreement Renewal History ─────────
                  MTMMSCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const MTMMSSectionHeader(
                              title: 'AGREEMENT RENEWAL & REVISION HISTORY',
                              icon: Icons.history_edu_rounded,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurf(context),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_renewals.length} Event${_renewals.length == 1 ? '' : 's'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(height: 1, color: AppColors.dividerCol(context)),
                        const SizedBox(height: 10),

                        if (_renewals.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Text(
                                'No prior agreement renewals recorded yet.\nCurrent terms active from initial registration.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textMut(context),
                                ),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: _renewals.map((r) {
                              final ref = r['reference_number'] ?? 'REN-000';
                              final renDate = r['renewal_date'] ?? '';
                              final oldRent = double.tryParse(r['previous_annual_rent']?.toString() ?? '0') ?? 0.0;
                              final newRent = double.tryParse(r['new_annual_rent']?.toString() ?? '0') ?? 0.0;
                              final inc = double.tryParse(r['increase_amount']?.toString() ?? '0') ?? 0.0;
                              final pct = double.tryParse(r['escalation_percentage']?.toString() ?? '0') ?? 0.0;
                              final isOverride = r['is_manual_override'] == true || r['is_manual_override'].toString() == '1';
                              final reason = r['override_reason']?.toString() ?? '';
                              final approver = r['approved_by'] is Map
                                  ? (r['approved_by']['name'] ?? 'Admin')
                                  : (r['approved_by_name'] ?? 'Admin');
                              final cycle = r['renewal_cycle_years'] ?? 5;
                              final start = r['new_agreement_start_date'] ?? '';
                              final end = r['new_agreement_end_date'] ?? '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurf(context),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.borderCol(context)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          ref,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPri(context),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            if (isOverride)
                                              Container(
                                                margin: const EdgeInsets.only(right: 6),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.warning.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Manual Override',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.warning,
                                                  ),
                                                ),
                                              ),
                                            StatusBadge(status: 'Approved'),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '₹${oldRent.toStringAsFixed(0)} → ₹${newRent.toStringAsFixed(0)} / yr',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryLight,
                                          ),
                                        ),
                                        Text(
                                          inc > 0 ? '+₹${inc.toStringAsFixed(0)} ($pct%)' : 'Flat Renewal',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: inc > 0 ? AppColors.success : AppColors.textSec(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Period: $start to $end ($cycle Yrs) • $renDate',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppColors.textSec(context),
                                      ),
                                    ),
                                    Text(
                                      'Approved by: $approver',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        color: AppColors.textMut(context),
                                      ),
                                    ),
                                    if (isOverride && reason.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceBg(context),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Justification: $reason',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10.5,
                                            fontStyle: FontStyle.italic,
                                            color: AppColors.textPri(context),
                                          ),
                                        ),
                                      ),
                                    ],
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
