import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/data_sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  bool _isLoading = true;
  Timer? _autoRefreshTimer;
  Map<String, dynamic> _reports = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DataSyncService.syncNotifier.addListener(_onDataSyncChanged);
    _tabController = TabController(length: 5, vsync: this);
    _loadReports();
    // 15-second heartbeat for live backend updates
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadReports(isSilent: true),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadReports(isSilent: true);
    }
  }

  void _onDataSyncChanged() {
    if (mounted) {
      _loadReports(isSilent: true);
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    DataSyncService.syncNotifier.removeListener(_onDataSyncChanged);
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports({bool isSilent = false}) async {
    if (!isSilent && mounted) setState(() => _isLoading = true);
    try {
      final data = await ApiService.getReports();
      if (mounted) {
        setState(() {
          _reports = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !isSilent) setState(() => _isLoading = false);
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.file_download_outlined, color: AppColors.primaryLight),
            const SizedBox(width: 8),
            Text(
              'Export Official Reports',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate authenticated Department of IT reports:',
              style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textSec(context)),
            ),
            const SizedBox(height: 14),
            _exportOptionTile(
              icon: Icons.table_chart_outlined,
              title: 'Export Full Tower Registry (.CSV)',
              subtitle: 'Comprehensive inventory of all registered mobile towers',
              onTap: () {
                Navigator.pop(ctx);
                _downloadFile('csv');
              },
            ),
            const SizedBox(height: 8),
            _exportOptionTile(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Export Department Summary (.PDF)',
              subtitle: 'District, Taluka and Revenue distribution breakdown',
              onTap: () {
                Navigator.pop(ctx);
                _downloadFile('pdf');
              },
            ),
            const SizedBox(height: 8),
            _exportOptionTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Export Rent Collection Audit (.CSV)',
              subtitle: 'Complete financial status and due schedule log',
              onTap: () {
                Navigator.pop(ctx);
                _downloadFile('revenue_csv');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _downloadFile(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $format report from DOIT central server...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _exportOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderCol(context)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPri(context)),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.textSec(context)),
                  ),
                ],
              ),
            ),
            Icon(Icons.download_rounded, size: 18, color: AppColors.textMut(context)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      drawer: const AppDrawer(currentRoute: 'reports'),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports & Analytics',
              style: GoogleFonts.poppins(fontSize: 16.5, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              'DoIT • Government of Goa',
              style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.85)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Report',
            onPressed: _showExportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadReports,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Districts'),
            Tab(text: 'Talukas'),
            Tab(text: 'Operators'),
            Tab(text: 'Land Classification'),
            Tab(text: 'Revenue & Rent'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _districtTab(),
                _talukaTab(),
                _operatorTab(),
                _landTab(),
                _revenueTab(),
              ],
            ),
    );
  }

  Widget _districtTab() {
    final distList = _reports['district_wise'] is List ? (_reports['district_wise'] as List) : [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summaryCard(
          title: 'DISTRICT-WISE DISTRIBUTION',
          subtitle: 'North Goa vs South Goa Infrastructure Allocation',
          children: distList.map((d) {
            final dist = d['district'] ?? 'Goa';
            final total = d['total_towers'] ?? 0;
            final govt = d['government_towers'] ?? 0;
            final priv = d['private_towers'] ?? 0;
            final active = d['active_towers'] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
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
                      Text(dist, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPri(context))),
                      Text('$total Towers', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryLight)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Govt Land: $govt', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSec(context))),
                      Text('Private: $priv', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSec(context))),
                      Text('Active: $active', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _talukaTab() {
    final talukaList = _reports['taluka_wise'] is List ? (_reports['taluka_wise'] as List) : [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summaryCard(
          title: 'TALUKA INFRASTRUCTURE BREAKDOWN',
          subtitle: 'Tower Distribution across all 12 Talukas of Goa',
          children: talukaList.map((t) {
            final taluka = t['taluka'] ?? 'Taluka';
            final count = t['tower_count'] ?? 0;
            final active = t['active_count'] ?? count;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primarySurf(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(taluka, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPri(context))),
                  Row(
                    children: [
                      Text('$count towers', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryLight)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successSurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('$active active', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _operatorTab() {
    final opsList = _reports['operator_wise'] is List ? (_reports['operator_wise'] as List) : [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summaryCard(
          title: 'OPERATOR TENANCY & SHARE',
          subtitle: 'Telecom Service Providers on State Towers',
          children: opsList.map((op) {
            final name = op['name'] ?? 'Operator';
            final shortName = op['short_name'] ?? name;
            final count = op['tower_count'] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurf(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shortName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPri(context))),
                      Text(name, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSec(context))),
                    ],
                  ),
                  Text('$count Towers', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryLight)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _landTab() {
    final land = _reports['land_type'] as Map?;
    final govt = land?['government'] as Map?;
    final priv = land?['private'] as Map?;

    final govtCount = govt?['count'] ?? 0;
    final privCount = priv?['count'] ?? 0;
    final govtRent = (govt?['yearly_rent'] as num?)?.toDouble() ?? 0.0;
    final privRent = (priv?['yearly_rent'] as num?)?.toDouble() ?? 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summaryCard(
          title: 'LAND CLASSIFICATION SUMMARY',
          subtitle: 'Government Property vs Private Leaseholds',
          children: [
            _landMetricRow('Government Land Towers', '$govtCount towers', '₹${govtRent.toInt()}/yr', AppColors.primaryLight),
            const SizedBox(height: 10),
            _landMetricRow('Private Land Towers', '$privCount towers', '₹${privRent.toInt()}/yr', const Color(0xFFA78BFA)),
          ],
        ),
      ],
    );
  }

  Widget _landMetricRow(String title, String count, String rent, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySurf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderCol(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPri(context))),
              Text('Annual Yield: $rent', style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSec(context))),
            ],
          ),
          Text(count, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _revenueTab() {
    final collection = _reports['rent_collection'] as Map?;
    final collected = (collection?['total_collected'] as num?)?.toDouble() ?? 0.0;
    final pending = (collection?['total_pending'] as num?)?.toDouble() ?? 0.0;
    final paidCount = collection?['paid_count'] ?? 0;
    final pendingCount = collection?['pending_count'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summaryCard(
          title: 'REVENUE & COLLECTION STATUS',
          subtitle: 'Department of IT Treasury Realization',
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.successBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL REALIZED', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)),
                        const SizedBox(height: 4),
                        Text('₹${collected.toInt()}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Text('$paidCount payments cleared', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warningSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warningBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('OUTSTANDING', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warning)),
                        const SizedBox(height: 4),
                        Text('₹${pending.toInt()}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Text('$pendingCount pending dues', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
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
          Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryLight)),
          Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSec(context))),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.dividerCol(context)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
