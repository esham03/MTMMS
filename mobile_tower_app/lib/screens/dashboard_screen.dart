import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/data_sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/government_components.dart';
import 'add_edit_tower_screen.dart';
import 'location_filter_screen.dart';
import 'map_view_screen.dart';
import 'operator_management_screen.dart';
import 'owners/owner_management_screen.dart';
import 'payment_history_screen.dart';
import 'rent_management_screen.dart';
import 'reports_screen.dart';
import 'tower_management_screen.dart';
import 'officer_profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  Timer? _autoRefreshTimer;
  Map<String, dynamic> _stats = {
    'totalTowers': 0,
    'totalOperators': 0,
    'govtTowers': 0,
    'governmentTowers': 0,
    'privateTowers': 0,
    'rentCollected': 0.0,
    'rentDue': 0,
    'pendingPayments': 0,
    'northGoaTowers': 0,
    'southGoaTowers': 0,
    'districtWise': [],
    'talukaWise': [],
    'operatorWise': [],
  };
  List<Map<String, dynamic>> _rentNotifications = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DataSyncService.syncNotifier.addListener(_onDataSyncChanged);
    _loadDashboardData();
    // 15-second heartbeat for live backend updates
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadDashboardData(isSilent: true),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadDashboardData(isSilent: true);
    }
  }

  void _onDataSyncChanged() {
    if (mounted) {
      _loadDashboardData(isSilent: true);
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    DataSyncService.syncNotifier.removeListener(_onDataSyncChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadDashboardData({bool isSilent = false}) async {
    if (!isSilent && mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getDashboardStats(),
        ApiService.getTowers().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      final stats = results[0] as Map<String, dynamic>;
      final towers = results[1] as List<Map<String, dynamic>>;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final in7 = today.add(const Duration(days: 7));
      final in30 = today.add(const Duration(days: 30));

      final notifications = <Map<String, dynamic>>[];
      for (final t in towers) {
        final dueDateStr = t['rent_due_date']?.toString();
        if (dueDateStr == null || dueDateStr.isEmpty) continue;
        final dueDate = DateTime.tryParse(dueDateStr);
        if (dueDate == null) continue;
        final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

        String? status;
        if (dueDay.isBefore(today)) {
          status = 'overdue';
        } else if (!dueDay.isAfter(in7)) {
          status = 'critical';
        } else if (!dueDay.isAfter(in30)) {
          status = 'upcoming';
        }

        if (status != null) {
          notifications.add({
            ...t,
            '_dueDate': dueDate,
            '_status': status,
            '_daysLeft': dueDay.difference(today).inDays,
          });
        }
      }

      notifications.sort((a, b) =>
          (a['_dueDate'] as DateTime).compareTo(b['_dueDate'] as DateTime));

      if (mounted) {
        setState(() {
          _stats = stats;
          _rentNotifications = notifications.take(10).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !isSilent) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹ 0';
    final val = double.tryParse(amount.toString()) ?? 0.0;
    if (val >= 10000000) {
      return '₹ ${(val / 10000000).toStringAsFixed(2)} Cr';
    } else if (val >= 100000) {
      return '₹ ${(val / 100000).toStringAsFixed(2)} L';
    } else if (val >= 1000) {
      return '₹ ${(val / 1000).toStringAsFixed(1)} K';
    }
    return '₹ ${val.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final totalTowers = _stats['totalTowers'] ?? 0;
    final totalOperators = _stats['totalOperators'] ?? 0;
    final govtTowers = _stats['govtTowers'] ?? _stats['governmentTowers'] ?? 0;
    final privateTowers = _stats['privateTowers'] ?? 0;
    final rentCollected = _stats['rentCollected'] ?? 0.0;
    final rentDue = _stats['rentDue'] ?? 0;
    final pendingPayments = _stats['pendingPayments'] ?? 0;
    final northGoa = _stats['northGoaTowers'] ?? 0;
    final southGoa = _stats['southGoaTowers'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      drawer: const AppDrawer(currentRoute: 'dashboard'),
      appBar: MTMMSAppBar(
        title: 'MTMMS Dashboard',
        subtitle: 'DoIT • Government of Goa',
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Interactive GIS Map',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapViewScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Grid Data',
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Officer Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OfficerProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading)
                const LinearProgressIndicator(
                  minHeight: 2.5,
                  color: AppColors.cyanAccent,
                  backgroundColor: AppColors.primary,
                ),

              // ── Key Department Metric Cards ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MTMMSSectionHeader(
                      title: 'STATE TELECOMMUNICATIONS INFRASTRUCTURE',
                      icon: Icons.hub_rounded,
                    ),
                    const SizedBox(height: 12),

                    // First Row: Total Towers & Operators
                    Row(
                      children: [
                        Expanded(
                          child: MTMMSStatCard(
                            title: 'TOTAL TOWERS',
                            value: '$totalTowers',
                            subtitle: 'Registered Active Nodes',
                            icon: Icons.cell_tower_rounded,
                            iconColor: AppColors.primary,
                            badgeText: 'Live Grid',
                            badgeColor: AppColors.success,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TowerManagementScreen(),
                                ),
                              );
                              if (mounted) _loadDashboardData(isSilent: true);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MTMMSStatCard(
                            title: 'NETWORK OPERATORS',
                            value: '$totalOperators',
                            subtitle: 'Active Telecom Agencies',
                            icon: Icons.cell_wifi_rounded,
                            iconColor: const Color(0xFF0284C7),
                            badgeText: 'DOIT Approved',
                            badgeColor: const Color(0xFF0284C7),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const OperatorManagementScreen(),
                                ),
                              );
                              if (mounted) _loadDashboardData(isSilent: true);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Second Row: Land Classification
                    Row(
                      children: [
                        Expanded(
                          child: MTMMSStatCard(
                            title: 'GOVERNMENT LAND',
                            value: '$govtTowers',
                            subtitle: 'State Owned Properties',
                            icon: Icons.account_balance_rounded,
                            iconColor: AppColors.primaryLight,
                            badgeText:
                                '${totalTowers > 0 ? ((govtTowers / totalTowers) * 100).toStringAsFixed(1) : '0'}%',
                            badgeColor: AppColors.primaryLight,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TowerManagementScreen(
                                    initialLandType: 'Government',
                                  ),
                                ),
                              );
                              if (mounted) _loadDashboardData(isSilent: true);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MTMMSStatCard(
                            title: 'PRIVATE LAND',
                            value: '$privateTowers',
                            subtitle: 'Private Lease Agreements',
                            icon: Icons.landscape_rounded,
                            iconColor: const Color(0xFF7C3AED),
                            badgeText:
                                '${totalTowers > 0 ? ((privateTowers / totalTowers) * 100).toStringAsFixed(1) : '0'}%',
                            badgeColor: const Color(0xFF7C3AED),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TowerManagementScreen(
                                    initialLandType: 'Private',
                                  ),
                                ),
                              );
                              if (mounted) _loadDashboardData(isSilent: true);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Third Row: Towers with Rent Due (5th KPI Stat Card from web Dashboard)
                    MTMMSStatCard(
                      title: 'TOWERS WITH RENT DUE',
                      value: '$rentDue',
                      subtitle: 'Pending rent cycle payments across state',
                      icon: Icons.currency_rupee_rounded,
                      iconColor: AppColors.error,
                      badgeText: rentDue > 0 ? '$rentDue Pending' : 'All Clear',
                      badgeColor: rentDue > 0 ? AppColors.error : AppColors.success,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RentManagementScreen(),
                          ),
                        );
                        if (mounted) _loadDashboardData(isSilent: true);
                      },
                    ),

                    const SizedBox(height: 12),

                    // Financial Revenue Card
                    MTMMSCard(
                      padding: const EdgeInsets.all(16),
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
                                      color: AppColors.successSurface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.currency_rupee_rounded,
                                      color: AppColors.success,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'RENT & REVENUE STATUS',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textMut(context),
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      Text(
                                        _formatCurrency(rentCollected),
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPri(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const RentManagementScreen(),
                                    ),
                                  );
                                  if (mounted) _loadDashboardData(isSilent: true);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Manage Rent',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(height: 1, color: AppColors.dividerCol(context)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _financialMiniStat(
                                label: 'Towers with Rent Due',
                                value: '$rentDue towers',
                                isAlert: rentDue > 0,
                              ),
                              _financialMiniStat(
                                label: 'Pending Collections',
                                value: '$pendingPayments records',
                                isAlert: pendingPayments > 0,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── District Distribution (North vs South Goa) ──────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: MTMMSCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.map_outlined,
                                size: 18,
                                color: AppColors.primaryLight,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'DISTRICT-WISE DISTRIBUTION',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPri(context),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LocationFilterScreen(),
                                ),
                              );
                              if (mounted) _loadDashboardData(isSilent: true);
                            },
                            child: const Text(
                              'Location Browser →',
                              style: TextStyle(fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _districtCard(
                              title: 'North Goa',
                              count: northGoa,
                              percentage: totalTowers > 0
                                  ? (northGoa / totalTowers) * 100
                                  : 0,
                              color: AppColors.primaryLight,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TowerManagementScreen(
                                      initialDistrict: 'North Goa',
                                    ),
                                  ),
                                );
                                if (mounted) _loadDashboardData(isSilent: true);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _districtCard(
                              title: 'South Goa',
                              count: southGoa,
                              percentage: totalTowers > 0
                                  ? (southGoa / totalTowers) * 100
                                  : 0,
                              color: const Color(0xFF0284C7),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TowerManagementScreen(
                                      initialDistrict: 'South Goa',
                                    ),
                                  ),
                                );
                                if (mounted) _loadDashboardData(isSilent: true);
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_stats['talukaWise'] is List && (_stats['talukaWise'] as List).isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Divider(height: 1, color: AppColors.dividerCol(context)),
                        const SizedBox(height: 10),
                        Text(
                          'TOP TALUKAS BY TOWER COUNT',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMut(context),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: (_stats['talukaWise'] as List).take(6).map((t) {
                            final name = t['taluka'] ?? 'Taluka';
                            final count = t['tower_count'] ?? 0;
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LocationFilterScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurf(context),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.borderCol(context)),
                                ),
                                child: Text(
                                  '$name: $count',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPri(context),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Licensed Telecom Operators Section ─────────────────
              if (_stats['operatorWise'] is List && (_stats['operatorWise'] as List).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: MTMMSCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.cell_wifi_rounded,
                                  size: 18,
                                  color: AppColors.primaryLight,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'LICENSED TELECOM OPERATORS',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPri(context),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OperatorManagementScreen(),
                                  ),
                                );
                                if (mounted) _loadDashboardData(isSilent: true);
                              },
                              child: const Text(
                                'Manage Operators →',
                                style: TextStyle(fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: (_stats['operatorWise'] as List).map((op) {
                            final name = op['operator']?.toString() ?? 'Operator';
                            final shortName = op['short_name']?.toString() ??
                                (name.length > 3 ? name.substring(0, 3).toUpperCase() : name);
                            final towerCount = op['tower_count'] ?? 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurf(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderCol(context)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      shortName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPri(context),
                                          ),
                                        ),
                                        Text(
                                          '$towerCount Connected Towers',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: AppColors.textSec(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.cyanAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$towerCount Sites',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.cyanAccent,
                                      ),
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
                ),

              // ── Rent Notifications Panel ───────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: MTMMSCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notifications_active_outlined,
                                size: 18,
                                color: _rentNotifications.any((n) => n['_status'] == 'overdue')
                                    ? AppColors.error
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'RENT NOTIFICATIONS',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPri(context),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RentManagementScreen(),
                                ),
                              );
                              if (mounted) _loadDashboardData(isSilent: true);
                            },
                            child: const Text(
                              'View All →',
                              style: TextStyle(fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Legend Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _legendChip(
                              label: 'Overdue',
                              color: AppColors.error,
                              count: _rentNotifications.where((n) => n['_status'] == 'overdue').length,
                            ),
                            const SizedBox(width: 8),
                            _legendChip(
                              label: 'Due ≤ 7 Days',
                              color: AppColors.warning,
                              count: _rentNotifications.where((n) => n['_status'] == 'critical').length,
                            ),
                            const SizedBox(width: 8),
                            _legendChip(
                              label: 'Due ≤ 30 Days',
                              color: AppColors.cyanAccent,
                              count: _rentNotifications.where((n) => n['_status'] == 'upcoming').length,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_rentNotifications.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'All rents are up to date — no pending dues.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textSec(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: _rentNotifications.map((t) {
                            final status = t['_status'] as String? ?? 'upcoming';
                            final daysLeft = t['_daysLeft'] as int? ?? 0;
                            final towerUid = t['tower_unique_id'] ?? t['towerId'] ?? t['id'] ?? 'TWR';
                            final area = t['area'] is Map ? t['area']['name'] : t['area'] ?? t['district'] ?? '';
                            final owner = t['owner'] ?? 'Government of Goa';
                            final yearlyRent = double.tryParse(t['yearly_rent']?.toString() ?? '60000') ?? 60000.0;

                            final color = status == 'overdue'
                                ? AppColors.error
                                : (status == 'critical' ? AppColors.warning : AppColors.cyanAccent);
                            final statusLabel = status == 'overdue'
                                ? 'OVERDUE'
                                : (status == 'critical' ? 'DUE SOON' : 'UPCOMING');
                            final dueLabel = status == 'overdue'
                                ? '${daysLeft.abs()} days ago'
                                : (daysLeft == 0 ? 'Today' : 'In $daysLeft days');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: color.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        status == 'overdue'
                                            ? Icons.error_outline_rounded
                                            : (status == 'critical'
                                                ? Icons.warning_amber_rounded
                                                : Icons.schedule_rounded),
                                        color: color,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  towerUid.toString(),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPri(context),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: color.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    statusLabel,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w800,
                                                      color: color,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '$area • $owner',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: AppColors.textSec(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${yearlyRent.toStringAsFixed(0)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPri(context),
                                            ),
                                          ),
                                          Text(
                                            dueLabel,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (status == 'overdue')
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.warning,
                                              side: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            icon: const Icon(Icons.print_outlined, size: 14),
                                            label: const Text('Demand Notice', style: TextStyle(fontSize: 11)),
                                            onPressed: () => _showRentDemandNoticeDialog(t),
                                          ),
                                        ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        icon: const Icon(Icons.payment_rounded, size: 14),
                                        label: const Text('Record Payment', style: TextStyle(fontSize: 11)),
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PaymentHistoryScreen(
                                                towerId: t['id']?.toString() ?? '',
                                                owner: owner.toString(),
                                              ),
                                            ),
                                          );
                                          if (mounted) _loadDashboardData(isSilent: true);
                                        },
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
                ),
              ),

              // ── Quick Operations Grid ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MTMMSSectionHeader(
                      title: 'OPERATIONAL SHORTCUTS',
                      icon: Icons.flash_on_rounded,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _shortcutButton(
                            icon: Icons.add_circle_outline_rounded,
                            label: 'Register Tower',
                            onTap: () async {
                              final registered = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddEditTowerScreen(),
                                ),
                              );
                              if (registered == true || mounted) {
                                _loadDashboardData(isSilent: true);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _shortcutButton(
                            icon: Icons.map_outlined,
                            label: 'GIS Map View',
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MapViewScreen(),
                                ),
                              );
                              if (mounted) _loadDashboardData(isSilent: true);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _shortcutButton(
                            icon: Icons.apartment_rounded,
                            label: 'Tower Owners',
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OwnerManagementScreen(),
                                ),
                              );
                              if (mounted) _loadDashboardData(isSilent: true);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _shortcutButton(
                            icon: Icons.travel_explore_rounded,
                            label: 'Location Filter',
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LocationFilterScreen(),
                                ),
                              );
                              if (mounted) _loadDashboardData(isSilent: true);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _shortcutButton(
                            icon: Icons.receipt_long_outlined,
                            label: 'Payments',
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PaymentHistoryScreen(
                                    towerId: '',
                                    owner: 'All State Towers',
                                  ),
                                ),
                              );
                              if (mounted) _loadDashboardData(isSilent: true);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _shortcutButton(
                            icon: Icons.summarize_outlined,
                            label: 'Audit Reports',
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ReportsScreen(),
                                ),
                              );
                              if (mounted) _loadDashboardData(isSilent: true);
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
        ),
      ),
    );
  }

  Widget _financialMiniStat({
    required String label,
    required String value,
    required bool isAlert,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textSec(context),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (isAlert) ...[
              const Icon(
                Icons.circle,
                size: 6,
                color: AppColors.warning,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isAlert ? AppColors.warning : AppColors.textPri(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _districtCard({
    required String title,
    required int count,
    required double percentage,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primarySurf(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPri(context),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$count towers',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMut(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.black.withValues(alpha: 0.08),
                color: color,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shortcutButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderCol(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.primaryLight),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPri(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendChip({
    required String label,
    required Color color,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$count $label',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  String _autoDetectTaluka(Map<String, dynamic> tower) {
    final talukaRaw = tower['taluka']?.toString() ?? tower['taluka_name']?.toString() ?? '';
    if (talukaRaw.isNotEmpty && talukaRaw.toLowerCase() != 'null') {
      for (final tk in [
        'Bardez', 'Bicholim', 'Canacona', 'Dharbandora', 'Mormugao',
        'Pernem', 'Ponda', 'Quepem', 'Salcete', 'Sanguem', 'Sattari', 'Tiswadi'
      ]) {
        if (talukaRaw.toLowerCase().contains(tk.toLowerCase())) return tk;
      }
    }
    final areaStr = (tower['area'] ?? tower['area_name'] ?? '').toString().toLowerCase();
    if (areaStr.contains('ponda') || areaStr.contains('curti') || areaStr.contains('shiroda')) return 'Ponda';
    if (areaStr.contains('panaji') || areaStr.contains('miramar') || areaStr.contains('patto')) return 'Tiswadi';
    if (areaStr.contains('mapusa') || areaStr.contains('calangute') || areaStr.contains('candolim')) return 'Bardez';
    if (areaStr.contains('margao') || areaStr.contains('colva') || areaStr.contains('benaulim')) return 'Salcete';
    if (areaStr.contains('vasco') || areaStr.contains('mormugao') || areaStr.contains('dabolim')) return 'Mormugao';
    if (areaStr.contains('pernem') || areaStr.contains('arambol') || areaStr.contains('morjim')) return 'Pernem';
    if (areaStr.contains('bicholim') || areaStr.contains('sanquelim')) return 'Bicholim';
    if (areaStr.contains('valpoi') || areaStr.contains('sattari')) return 'Sattari';
    if (areaStr.contains('quepem') || areaStr.contains('curchorem')) return 'Quepem';
    if (areaStr.contains('canacona') || areaStr.contains('palolem')) return 'Canacona';
    if (areaStr.contains('sanguem')) return 'Sanguem';
    if (areaStr.contains('dharbandora') || areaStr.contains('mollem')) return 'Dharbandora';

    final addrStr = (tower['address'] ?? '').toString().toLowerCase();
    if (addrStr.contains('ponda')) return 'Ponda';
    if (addrStr.contains('panaji')) return 'Tiswadi';
    if (addrStr.contains('mapusa')) return 'Bardez';
    if (addrStr.contains('margao')) return 'Salcete';
    if (addrStr.contains('vasco')) return 'Mormugao';
    return 'Tiswadi';
  }

  void _showRentDemandNoticeDialog(Map<String, dynamic> tower) {
    final towerId = tower['tower_unique_id'] ?? tower['towerId'] ?? tower['id'] ?? 'TWR-GOA';
    final owner = tower['owner'] ?? 'State Estate';
    final op = tower['operator'] ?? tower['primary_operator'] ?? 'Registered Telecom Provider';
    final district = tower['district'] ?? 'Goa';
    final nextDue = tower['rent_due_date']?.toString().split('T').first ?? 'Immediate';
    final monthlyRent = double.tryParse(tower['monthly_rent']?.toString() ?? '5000') ?? 5000.0;
    const overdueMonths = 3;
    final arrearsAmount = monthlyRent * overdueMonths;
    final totalPayable = arrearsAmount + (arrearsAmount * 0.18);
    final refNo = 'GOA/DMA/TWR-RENT/$towerId/${DateTime.now().year}';

    String selectedTaluka = _autoDetectTaluka(tower);

    const allTalukas = [
      'Bardez', 'Bicholim', 'Canacona', 'Dharbandora', 'Mormugao',
      'Pernem', 'Ponda', 'Quepem', 'Salcete', 'Sanguem', 'Sattari', 'Tiswadi'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      _noticeField('Tower UID', towerId.toString()),
                      _noticeField('Estate Owner', owner.toString()),
                      _noticeField('Network Tenant', op.toString()),

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
                                  items: allTalukas.map((t) {
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

                      _noticeField('District / Location', district.toString()),
                      _noticeField('Settlement Due Date', nextDue.toString()),
                    const SizedBox(height: 8),
                    Divider(color: AppColors.dividerCol(context)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL ARREARS DEMAND:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.textPri(context),
                          ),
                        ),
                        Text(
                          '₹${totalPayable.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copy Notice'),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notice reference and terms copied'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
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
              fontSize: 11.5,
              color: AppColors.textSec(context),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPri(context),
            ),
          ),
        ],
      ),
    );
  }
}
