import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/data_sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/government_components.dart';
import 'payment_history_screen.dart';

class RentManagementScreen extends StatefulWidget {
  const RentManagementScreen({super.key});

  @override
  State<RentManagementScreen> createState() => _RentManagementScreenState();
}

class _RentManagementScreenState extends State<RentManagementScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _rents = [];
  bool _isLoading = true;
  Timer? _autoRefreshTimer;
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DataSyncService.syncNotifier.addListener(_onDataSyncChanged);
    _loadRentData();
    // 15-second heartbeat for live backend updates
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadRentData(isSilent: true),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadRentData(isSilent: true);
    }
  }

  void _onDataSyncChanged() {
    if (mounted) {
      _loadRentData(isSilent: true);
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

  Future<void> _loadRentData({bool isSilent = false}) async {
    if (!isSilent && mounted) setState(() => _isLoading = true);
    try {
      final list = await ApiService.getRents();
      if (mounted) {
        setState(() {
          _rents = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !isSilent) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredRents {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _rents.where((r) {
      final matchesSearch = query.isEmpty ||
          r['towerId'].toString().toLowerCase().contains(query) ||
          r['owner'].toString().toLowerCase().contains(query) ||
          r['district'].toString().toLowerCase().contains(query) ||
          r['operator'].toString().toLowerCase().contains(query);

      final matchesStatus = _selectedStatusFilter == 'All' ||
          r['status'].toString().toLowerCase() ==
              _selectedStatusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // All 12 Statutory Talukas of Goa
  static const List<String> kAllGoaTalukas = [
    'Bardez',
    'Bicholim',
    'Canacona',
    'Dharbandora',
    'Mormugao',
    'Pernem',
    'Ponda',
    'Quepem',
    'Salcete',
    'Sanguem',
    'Sattari',
    'Tiswadi',
  ];

  static const Map<String, String> kGoaLocationTalukaMap = {
    'ponda': 'Ponda',
    'curti': 'Ponda',
    'shiroda': 'Ponda',
    'marcaim': 'Ponda',
    'priol': 'Ponda',
    'khandepar': 'Ponda',
    'bandora': 'Ponda',
    'usgao': 'Ponda',
    'borim': 'Ponda',
    'kundaim': 'Ponda',
    'bethora': 'Ponda',
    'panaji': 'Tiswadi',
    'patto': 'Tiswadi',
    'miramar': 'Tiswadi',
    'caranzalem': 'Tiswadi',
    'taleigao': 'Tiswadi',
    'santa cruz': 'Tiswadi',
    'bambolim': 'Tiswadi',
    'ribandar': 'Tiswadi',
    'old goa': 'Tiswadi',
    'chimbel': 'Tiswadi',
    'corlim': 'Tiswadi',
    'merces': 'Tiswadi',
    'mapusa': 'Bardez',
    'calangute': 'Bardez',
    'candolim': 'Bardez',
    'porvorim': 'Bardez',
    'baga': 'Bardez',
    'anjuna': 'Bardez',
    'vagator': 'Bardez',
    'arpora': 'Bardez',
    'siolim': 'Bardez',
    'saligao': 'Bardez',
    'guirim': 'Bardez',
    'aldona': 'Bardez',
    'colvale': 'Bardez',
    'margao': 'Salcete',
    'madgaon': 'Salcete',
    'colva': 'Salcete',
    'benaulim': 'Salcete',
    'fatorda': 'Salcete',
    'navelim': 'Salcete',
    'cansaulim': 'Salcete',
    'curtorim': 'Salcete',
    'nuvem': 'Salcete',
    'raia': 'Salcete',
    'varca': 'Salcete',
    'cavelossim': 'Salcete',
    'mormugao': 'Mormugao',
    'vasco': 'Mormugao',
    'vasco da gama': 'Mormugao',
    'dabolim': 'Mormugao',
    'chicalim': 'Mormugao',
    'sancoale': 'Mormugao',
    'cortalim': 'Mormugao',
    'bogmalo': 'Mormugao',
    'pernem': 'Pernem',
    'arambol': 'Pernem',
    'mandrem': 'Pernem',
    'morjim': 'Pernem',
    'ashvem': 'Pernem',
    'mopa': 'Pernem',
    'bicholim': 'Bicholim',
    'sanquelim': 'Bicholim',
    'mayem': 'Bicholim',
    'sattari': 'Sattari',
    'valpoi': 'Sattari',
    'honda': 'Sattari',
    'quepem': 'Quepem',
    'curchorem': 'Quepem',
    'sanvordem': 'Quepem',
    'cuncolim': 'Quepem',
    'sanguem': 'Sanguem',
    'netravali': 'Sanguem',
    'canacona': 'Canacona',
    'palolem': 'Canacona',
    'chaudi': 'Canacona',
    'agonda': 'Canacona',
    'dharbandora': 'Dharbandora',
    'mollem': 'Dharbandora',
    'collem': 'Dharbandora',
  };

  static String autoDetectTaluka(Map<String, dynamic> item) {
    final talukaRaw = item['taluka']?.toString() ?? item['taluka_name']?.toString() ?? '';
    if (talukaRaw.isNotEmpty && talukaRaw.toLowerCase() != 'null') {
      for (final tk in kAllGoaTalukas) {
        if (talukaRaw.toLowerCase().contains(tk.toLowerCase())) return tk;
      }
    }
    final areaStr = (item['area'] ?? item['area_name'] ?? '').toString().toLowerCase();
    if (areaStr.isNotEmpty) {
      if (kGoaLocationTalukaMap.containsKey(areaStr)) return kGoaLocationTalukaMap[areaStr]!;
      for (final entry in kGoaLocationTalukaMap.entries) {
        if (areaStr.contains(entry.key)) return entry.value;
      }
    }
    final addrStr = (item['address'] ?? '').toString().toLowerCase();
    if (addrStr.isNotEmpty) {
      for (final entry in kGoaLocationTalukaMap.entries) {
        if (addrStr.contains(entry.key)) return entry.value;
      }
    }
    return 'Tiswadi';
  }

  void _showRentDemandNoticeDialog(Map<String, dynamic> item) {
    final towerId = item['towerId']?.toString() ?? 'TWR-0001';
    final owner = item['owner']?.toString() ?? 'Government of Goa';
    final district = item['district']?.toString() ?? 'North Goa';
    final op = item['operator']?.toString() ?? 'Airtel';
    final yearlyRent = item['yearlyRent']?.toString() ?? '60,000';
    final nextDue = item['nextDue']?.toString() ?? '2027-08-21';
    final refNo = 'DOIT/MTMMS/DEMAND/2026/${towerId.replaceAll('TWR-', '')}';
    final noticeDate = DateTime.now().toIso8601String().split('T').first;

    String selectedTaluka = autoDetectTaluka(item);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final noticeText = '''GOVERNMENT OF GOA
DEPARTMENT OF INFORMATION TECHNOLOGY
3rd Floor, Alcon Construction Complex, Panaji, Goa - 403001

OFFICIAL RENT DEMAND NOTICE
Ref: $refNo
Date: $noticeDate

To:
Estate Owner: $owner
Active Operator / Infrastructure Provider: $op
Jurisdiction: Taluka: $selectedTaluka, District: $district, Goa

SUBJECT: DEMAND NOTICE FOR REMITTANCE OF GROUND LEASE RENT FOR TELECOMMUNICATION TOWER $towerId

Sir / Madam,

It is observed from the records of the Mobile Tower Monitoring and Management System (MTMMS) that the annual ground rent for the telecommunication tower structure erected under UID $towerId is due for settlement.

1. Tower Unique Identification: $towerId
2. Statutory Jurisdiction: Taluka: $selectedTaluka, District: $district
3. Primary Network Tenant: $op
4. Annual Lease Demand Amount: ₹$yearlyRent
5. Specified Settlement Due Date: $nextDue

You are hereby notified and directed to credit the outstanding ground rent into the designated State Treasury account via valid Treasury Challan or official NEFT/RTGS payment portal within 15 (fifteen) days from the receipt of this notice, failing which regulatory statutory compliance proceedings shall be initiated as per the Goa Telecom Infrastructure Policy.

Issued under the authority of Director (IT), Government of Goa.''';

          return AlertDialog(
            backgroundColor: AppColors.surfaceBg(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.borderCol(context)),
            ),
            contentPadding: EdgeInsets.zero,
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                maxWidth: 420,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'assets/images/goa-emblem.png',
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.account_balance_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'GOVERNMENT OF GOA',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'OFFICIAL RENT DEMAND NOTICE',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Ref: $refNo',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.warningSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: AppColors.warning, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Formal Statutory Notice issued under the Goa Telecom Infrastructure Guidelines.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.textPri(context),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _noticeField('Tower UID', towerId),
                          _noticeField('Estate Owner', owner),
                          _noticeField('Network Tenant', op),

                          // Automatically Selected Taluka with Interactive Dropdown
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Taluka Jurisdiction',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    color: AppColors.textSec(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurf(context),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedTaluka,
                                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                                      dropdownColor: AppColors.surfaceBg(context),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryLight,
                                      ),
                                      items: kAllGoaTalukas.map((t) {
                                        return DropdownMenuItem(
                                          value: t,
                                          child: Text(t),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setDialogState(() => selectedTaluka = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _noticeField('District / Location', district),
                          _noticeField('Settlement Due Date', nextDue),
                          const SizedBox(height: 8),
                          Divider(color: AppColors.dividerCol(context)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Outstanding Lease Demand:',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPri(context),
                                ),
                              ),
                              Text(
                                '₹$yearlyRent',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.error,
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
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy Notice Text'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: noticeText));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Official Rent Demand Notice copied to clipboard!'),
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
          );
        },
      ),
    );
  }

  Widget _noticeField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 11.5, color: AppColors.textSec(context)),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPri(context)),
          ),
        ],
      ),
    );
  }

  void _showQuickRecordPayment(Map<String, dynamic> item) {
    final rawTowerDbId = item['id'] ?? item['dbId'];
    final towerId = item['towerId']?.toString() ?? 'TWR-0001';
    final yearlyRent = item['yearlyRent']?.toString() ?? '60000';

    final amountCtrl = TextEditingController(text: yearlyRent);
    final challanCtrl = TextEditingController(
      text: 'CHL-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}',
    );
    final dateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );
    final remarksCtrl = TextEditingController(text: 'Lease rent settlement');
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
                            'Tower: $towerId',
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
                      prefixIcon:
                          const Icon(Icons.currency_rupee_rounded, size: 18),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
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
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
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
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
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
                        final amt =
                            double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                        final ref = challanCtrl.text.trim();
                        final tId = int.tryParse(rawTowerDbId.toString());

                        if (tId == null || amt <= 0 || ref.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Please enter valid amount and reference.'),
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
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
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
                              content: Text('Payment recorded successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _loadRentData();
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Failed to record payment in database.'),
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

  @override
  Widget build(BuildContext context) {
    final list = _filteredRents;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      drawer: const AppDrawer(currentRoute: 'rent'),
      appBar: MTMMSAppBar(
        title: 'Rent & Lease Management',
        subtitle: 'State Telecom Revenue & Lease Portfolio',
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'All Payment Records',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PaymentHistoryScreen(
                  towerId: '',
                  owner: 'All State Towers',
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Records',
            onPressed: _loadRentData,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter Bar ───────────────────────────────────
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
                    hintText: 'Search by Tower ID, Owner, District...',
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
                      '${list.length} rent record${list.length == 1 ? '' : 's'}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppColors.textSec(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Status: ',
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
                            DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                            DropdownMenuItem(value: 'Due', child: Text('Rent Due')),
                            DropdownMenuItem(
                              value: 'Pending',
                              child: Text('Pending'),
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

          // ── Rent Records List ─────────────────────────────────────
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
                              Icons.currency_rupee_rounded,
                              size: 48,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No rent records found.',
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
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final towerId =
                              item['towerId']?.toString() ?? 'TWR-0001';
                          final owner = item['owner']?.toString() ??
                              'Government of Goa';
                          final district =
                              item['district']?.toString() ?? 'North Goa';
                          final op = item['operator']?.toString() ?? 'Airtel';
                          final yearlyRent =
                              item['yearlyRent']?.toString() ?? '60000';
                          final status = item['status']?.toString() ?? 'Paid';
                          final lastPayment =
                              item['lastPayment']?.toString() ?? '2026-08-21';
                          final nextDue =
                              item['nextDue']?.toString() ?? '2027-08-21';

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
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors.primarySurf(context),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.receipt_rounded,
                                            color: AppColors.primaryLight,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              towerId,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    AppColors.textPri(context),
                                              ),
                                            ),
                                            Text(
                                              '$district • $op',
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
                                          'Tower Owner',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: AppColors.textMut(context),
                                          ),
                                        ),
                                        Text(
                                          owner,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPri(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Yearly Rent',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: AppColors.textMut(context),
                                          ),
                                        ),
                                        Text(
                                          '₹$yearlyRent/yr',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Last: $lastPayment  •  Due: $nextDue',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppColors.textMut(context),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PaymentHistoryScreen(
                                            towerId: towerId,
                                            owner: owner,
                                          ),
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                      ),
                                      child: const Text(
                                        'Receipts →',
                                        style: TextStyle(fontSize: 11.5),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Divider(height: 1, color: AppColors.dividerCol(context)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.description_outlined, size: 14),
                                      label: const Text(
                                        'Demand Notice',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.warning,
                                        side: const BorderSide(color: AppColors.warning),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      onPressed: () => _showRentDemandNoticeDialog(item),
                                    ),
                                    const SizedBox(width: 8),
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
                                      onPressed: () => _showQuickRecordPayment(item),
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
