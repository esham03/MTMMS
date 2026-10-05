import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/data_sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/government_components.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String towerId;
  final String owner;

  const PaymentHistoryScreen({
    super.key,
    required this.towerId,
    required this.owner,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _allTowers = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DataSyncService.syncNotifier.addListener(_onDataSyncChanged);
    _checkRole();
    _loadPayments();
    _loadTowers();
    // 15-second heartbeat for live backend updates
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadPayments(isSilent: true),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadPayments(isSilent: true);
    }
  }

  void _onDataSyncChanged() {
    if (mounted) _loadPayments(isSilent: true);
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
    if (mounted) setState(() => _isAdmin = isAdmin);
  }

  Future<void> _loadTowers() async {
    try {
      final list = await ApiService.getTowers();
      if (mounted) setState(() => _allTowers = list);
    } catch (_) {}
  }

  Future<void> _loadPayments({bool isSilent = false}) async {
    if (!isSilent && mounted) setState(() => _isLoading = true);
    try {
      final list = await ApiService.getPaymentHistory(
        towerId: widget.towerId.isNotEmpty ? widget.towerId : null,
      );
      if (mounted) {
        setState(() {
          _payments = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !isSilent) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePayment(String paymentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment Record'),
        content: const Text(
          'Are you sure you want to permanently delete this payment transaction? This will adjust financial balances.',
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
      final ok = await ApiService.deletePayment(paymentId);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment transaction deleted successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadPayments();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete payment transaction.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showRecordPaymentModal() {
    int? selectedTowerDbId;
    if (widget.towerId.isNotEmpty) {
      final match = _allTowers.firstWhere(
        (t) =>
            (t['towerId'] ?? t['id'] ?? '').toString().toLowerCase() ==
            widget.towerId.toLowerCase(),
        orElse: () => {},
      );
      selectedTowerDbId = int.tryParse((match['dbId'] ?? match['id'] ?? '').toString());
    } else if (_allTowers.isNotEmpty) {
      selectedTowerDbId = int.tryParse(
        (_allTowers[0]['dbId'] ?? _allTowers[0]['id'] ?? '').toString(),
      );
    }

    final amountCtrl = TextEditingController(text: '60000');
    final challanCtrl = TextEditingController(
      text: 'CHL-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}',
    );
    final dateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );
    final remarksCtrl = TextEditingController(text: 'Official lease rent payment');
    String paymentMode = 'Treasury Challan';

    showModalBottomSheet(
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
                            'Treasury Challan & Direct Account Deposit',
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
                  const SizedBox(height: 14),

                  // Tower Selection Dropdown
                  Text(
                    'SELECT TOWER INFRASTRUCTURE *',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_allTowers.isEmpty)
                    Text(
                      'Loading towers...',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMut(context)),
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue: selectedTowerDbId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: AppColors.inputBg(context),
                      ),
                      items: _allTowers.map((t) {
                        final dbId = int.tryParse((t['dbId'] ?? t['id'] ?? '').toString()) ?? 0;
                        final tUid = t['towerId'] ?? t['id'] ?? 'TWR';
                        final area = t['area'] ?? t['district'] ?? '';
                        return DropdownMenuItem<int>(
                          value: dbId,
                          child: Text(
                            '$tUid ($area)',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedTowerDbId = val);
                          // Auto set yearly rent if known
                          final t = _allTowers.firstWhere(
                            (item) => (item['dbId'] ?? item['id']).toString() == val.toString(),
                            orElse: () => {},
                          );
                          if (t['yearly_rent'] != null) {
                            amountCtrl.text = t['yearly_rent'].toString();
                          }
                        }
                      },
                    ),
                  const SizedBox(height: 12),

                  // Amount
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

                  // Challan / Reference #
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

                  // Payment Method
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

                  // Remarks
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

                  // Submit Button
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

                        if (selectedTowerDbId == null || amt <= 0 || ref.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a tower, amount, and reference.'),
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
                          'tower_id': selectedTowerDbId,
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
                              content: Text('Payment transaction recorded successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _loadPayments();
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
                        'Submit Payment Record',
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

  void _showReceiptDialog(Map<String, dynamic> p) {
    final receiptNo = p['receiptNo'] ?? 'RCP-2026-001';
    final towerId = p['towerId'] ?? widget.towerId;
    final date = p['date'] ?? '2026-08-21';
    final amount = p['amount']?.toString() ?? '₹60,000';
    final mode = p['mode'] ?? 'Treasury Challan';
    final owner = p['owner'] ?? widget.owner;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceBg(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderCol(context)),
        ),
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Receipt Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.success,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Payment Voucher / Receipt',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Department of Information Technology\nGovernment of Goa',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Receipt Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _receiptRow('Receipt / Challan No.', receiptNo),
                    _receiptRow('Tower UID', towerId),
                    _receiptRow('Estate Owner', owner),
                    _receiptRow('Payment Date', date),
                    _receiptRow('Coverage Period', p['period'] ?? 'Annual Cycle'),
                    _receiptRow('Payment Mode', mode),
                    _receiptRow('Compliance Status', p['status'] ?? 'Paid'),
                    if (p['remarks'] != null && p['remarks'].toString().isNotEmpty)
                      _receiptRow('Remarks', p['remarks'].toString()),
                    const SizedBox(height: 12),
                    Divider(color: AppColors.dividerCol(context)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount Credited',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPri(context),
                          ),
                        ),
                        Text(
                          amount,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryLight,
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
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Details'),
            onPressed: () {
              final text =
                  'MTMMS Payment Receipt\nReceipt: $receiptNo\nTower: $towerId\nDate: $date\nAmount: $amount\nMode: $mode\nStatus: Paid';
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Receipt details copied to clipboard!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSec(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPri(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.towerId.isNotEmpty
        ? 'Receipts: ${widget.towerId}'
        : 'Payment Records & Challans';

    final isTopLevel = widget.towerId.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      drawer: isTopLevel ? const AppDrawer(currentRoute: 'payments') : null,
      appBar: MTMMSAppBar(
        title: title,
        subtitle: widget.owner.isNotEmpty ? widget.owner : 'Department of IT • Revenue Registry',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Receipts',
            onPressed: _loadPayments,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Record Payment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        onPressed: _showRecordPaymentModal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        size: 48,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No payment records found.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSec(context),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        label: Text(
                          'Record First Payment',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _showRecordPaymentModal,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                  itemCount: _payments.length,
                  itemBuilder: (ctx, i) {
                    final p = _payments[i];
                    final paymentDbId = p['id']?.toString() ?? '';
                    final receiptNo = p['receiptNo'] ?? 'RCP-2026-001';
                    final date = p['date'] ?? '2026-08-21';
                    final period = p['period'] ?? '2026-08-21 to 2027-08-20';
                    final amount = p['amount']?.toString() ?? '₹60,000';
                    final status = p['status'] ?? 'Paid';
                    final mode = p['mode'] ?? 'Treasury Challan';
                    final towerId = p['towerId'] ?? widget.towerId;

                    return MTMMSCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      onTap: () => _showReceiptDialog(p),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.receipt_rounded,
                                    size: 18,
                                    color: AppColors.primaryLight,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    receiptNo,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPri(context),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  StatusBadge(status: status),
                                  if (_isAdmin && paymentDbId.isNotEmpty) ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      tooltip: 'Delete Payment',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _deletePayment(paymentDbId),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(height: 1, color: AppColors.dividerCol(context)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tower: $towerId',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPri(context),
                                      ),
                                    ),
                                    Text(
                                      'Period: $period',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppColors.textSec(context),
                                      ),
                                    ),
                                    Text(
                                      'Mode: $mode  •  Date: $date',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        color: AppColors.textMut(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                amount,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
