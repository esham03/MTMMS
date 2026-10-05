import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/data_sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/government_components.dart';
import 'add_edit_tower_screen.dart';
import 'location_filter_screen.dart';
import 'towers/tower_details_screen.dart';

class TowerManagementScreen extends StatefulWidget {
  final String? initialLandType;
  final String? initialDistrict;

  const TowerManagementScreen({
    super.key,
    this.initialLandType,
    this.initialDistrict,
  });

  @override
  State<TowerManagementScreen> createState() => _TowerManagementScreenState();
}

class _TowerManagementScreenState extends State<TowerManagementScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedDistrict = 'All Districts';
  String _selectedLandType = 'All Land Types';
  String _selectedStatus = 'All Status';
  String _selectedOperator = 'All Operators';
  String _sortBy = 'id'; // 'id', 'rent', 'height'

  bool _isAdmin = true;
  bool _isLoading = false;
  Timer? _autoRefreshTimer;
  List<Map<String, dynamic>> _towers = [];
  List<String> _operatorsList = ['All Operators'];
  List<String> _districtsList = ['All Districts', 'North Goa', 'South Goa'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DataSyncService.syncNotifier.addListener(_onDataSyncChanged);
    if (widget.initialLandType != null) {
      _selectedLandType = widget.initialLandType!;
    }
    if (widget.initialDistrict != null) {
      _selectedDistrict = widget.initialDistrict!;
    }
    _loadData();
    // 15-second heartbeat for live backend updates
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadData(isSilent: true),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadData(isSilent: true);
    }
  }

  void _onDataSyncChanged() {
    if (mounted) {
      _loadData(isSilent: true);
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

  Future<void> _loadData({bool isSilent = false}) async {
    if (!isSilent && mounted) setState(() => _isLoading = true);
    try {
      final towersData = await ApiService.getTowers();
      final operatorsData = await ApiService.getOperators();
      final districtsData = await ApiService.getDistricts();
      final isAdmin = await AuthService.isAdmin();

      final ops = <String>{'All Operators'};
      for (final op in operatorsData) {
        final name =
            op['shortName']?.toString() ?? op['name']?.toString() ?? '';
        if (name.isNotEmpty) ops.add(name);
      }

      final dists = <String>{'All Districts'};
      dists.addAll(districtsData);

      if (mounted) {
        setState(() {
          _towers = towersData;
          _districtsList = dists.toList();
          _operatorsList = ops.toList();
          _isAdmin = isAdmin;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !isSilent) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTowers {
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = _towers.where((tower) {
      bool matchesOperatorOrCompany = false;
      if (query.isNotEmpty) {
        if (tower['operators_list'] is List) {
          for (final op in tower['operators_list']) {
            if (op is Map) {
              final opName = op['name']?.toString().toLowerCase() ?? '';
              final opShort = op['shortName']?.toString().toLowerCase() ?? '';
              if (opName.contains(query) || opShort.contains(query)) {
                matchesOperatorOrCompany = true;
                break;
              }
            }
          }
        }
        if (!matchesOperatorOrCompany && tower['_raw'] != null && tower['_raw'] is Map) {
          final rawOps = tower['_raw']['operators'];
          if (rawOps is List) {
            for (final op in rawOps) {
              if (op is Map) {
                final n = op['name']?.toString().toLowerCase() ?? '';
                final sn = op['short_name']?.toString().toLowerCase() ?? '';
                if (n.contains(query) || sn.contains(query)) {
                  matchesOperatorOrCompany = true;
                  break;
                }
              }
            }
          }
        }
      }

      final matchesSearch = query.isEmpty ||
          tower['id'].toString().toLowerCase().contains(query) ||
          tower['owner'].toString().toLowerCase().contains(query) ||
          tower['area'].toString().toLowerCase().contains(query) ||
          tower['taluka'].toString().toLowerCase().contains(query) ||
          tower['district'].toString().toLowerCase().contains(query) ||
          tower['operator'].toString().toLowerCase().contains(query) ||
          matchesOperatorOrCompany;

      final matchesDistrict = _selectedDistrict == 'All Districts' ||
          tower['district']?.toString().toLowerCase() ==
              _selectedDistrict.toLowerCase();

      final matchesLand = _selectedLandType == 'All Land Types' ||
          tower['land']?.toString().toLowerCase() ==
              _selectedLandType.toLowerCase();

      final matchesStatus = _selectedStatus == 'All Status' ||
          tower['status']?.toString().toLowerCase() ==
              _selectedStatus.toLowerCase();

      bool matchesOperator = _selectedOperator == 'All Operators';
      if (!matchesOperator) {
        final sel = _selectedOperator.toLowerCase();
        if (tower['operator']?.toString().toLowerCase() == sel) {
          matchesOperator = true;
        } else if (tower['operators_list'] is List) {
          for (final op in tower['operators_list']) {
            if (op is Map) {
              final n = op['name']?.toString().toLowerCase() ?? '';
              final sn = op['shortName']?.toString().toLowerCase() ?? '';
              if (n == sel || sn == sel) {
                matchesOperator = true;
                break;
              }
            }
          }
        }
      }

      return matchesSearch &&
          matchesDistrict &&
          matchesLand &&
          matchesStatus &&
          matchesOperator;
    }).toList();

    // Sorting
    filtered.sort((a, b) {
      if (_sortBy == 'rent') {
        final rentA = num.tryParse(a['yearly_rent']?.toString() ?? '0') ?? 0;
        final rentB = num.tryParse(b['yearly_rent']?.toString() ?? '0') ?? 0;
        return rentB.compareTo(rentA);
      } else if (_sortBy == 'height') {
        final hA = num.tryParse(
                a['height']?.toString().replaceAll('m', '').trim() ?? '0') ??
            0;
        final hB = num.tryParse(
                b['height']?.toString().replaceAll('m', '').trim() ?? '0') ??
            0;
        return hB.compareTo(hA);
      }
      return (a['id']?.toString() ?? '').compareTo(b['id']?.toString() ?? '');
    });

    return filtered;
  }

  void _showFilterModal() {
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Tower Grid',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedDistrict = 'All Districts';
                        _selectedLandType = 'All Land Types';
                        _selectedStatus = 'All Status';
                        _selectedOperator = 'All Operators';
                      });
                      setState(() {});
                    },
                    child: const Text('Reset All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // District Filter
              _filterLabel('DISTRICT'),
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                isExpanded: true,
                items: _districtsList.map((d) {
                  return DropdownMenuItem(value: d, child: Text(d));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => _selectedDistrict = val);
                    setState(() {});
                  }
                },
              ),
              const SizedBox(height: 12),

              // Land Type Filter
              _filterLabel('LAND CLASSIFICATION'),
              DropdownButtonFormField<String>(
                value: _selectedLandType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'All Land Types',
                    child: Text('All Land Types'),
                  ),
                  DropdownMenuItem(
                    value: 'Government',
                    child: Text('Government Land'),
                  ),
                  DropdownMenuItem(
                    value: 'Private',
                    child: Text('Private Land'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => _selectedLandType = val);
                    setState(() {});
                  }
                },
              ),
              const SizedBox(height: 12),

              // Status Filter
              _filterLabel('OPERATIONAL STATUS'),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'All Status',
                    child: Text('All Status'),
                  ),
                  DropdownMenuItem(value: 'Active', child: Text('Active Grid')),
                  DropdownMenuItem(
                    value: 'Inactive',
                    child: Text('Inactive Grid'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => _selectedStatus = val);
                    setState(() {});
                  }
                },
              ),
              const SizedBox(height: 12),

              // Operator Filter
              _filterLabel('TELECOM OPERATOR'),
              DropdownButtonFormField<String>(
                value: _selectedOperator,
                isExpanded: true,
                items: _operatorsList.map((op) {
                  return DropdownMenuItem(value: op, child: Text(op));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => _selectedOperator = val);
                    setState(() {});
                  }
                },
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textMut(context),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredTowers;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      drawer: const AppDrawer(currentRoute: 'towers'),
      appBar: MTMMSAppBar(
        title: 'Tower Management',
        subtitle: 'State Infrastructure Inventory',
        actions: [
          IconButton(
            icon: const Icon(Icons.travel_explore_rounded),
            tooltip: 'Location Browser',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LocationFilterScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload Towers',
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Add Tower',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditTowerScreen(),
                  ),
                );
                if (created == true) _loadData();
              },
            )
          : null,
      body: Column(
        children: [
          // ── Search & Filter Controls ──────────────────────────────
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.poppins(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search Tower ID, Owner, Area, Operator...',
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
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: (_selectedDistrict != 'All Districts' ||
                                _selectedLandType != 'All Land Types' ||
                                _selectedStatus != 'All Status' ||
                                _selectedOperator != 'All Operators')
                            ? AppColors.primarySurf(context)
                            : AppColors.bg(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderCol(context)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.filter_list_rounded),
                        color: AppColors.primaryLight,
                        tooltip: 'Filter List',
                        onPressed: _showFilterModal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${list.length} tower record${list.length == 1 ? '' : 's'} found',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppColors.textSec(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Sort: ',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textMut(context),
                          ),
                        ),
                        DropdownButton<String>(
                          value: _sortBy,
                          underline: const SizedBox(),
                          isDense: true,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryLight,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'id', child: Text('ID')),
                            DropdownMenuItem(
                              value: 'rent',
                              child: Text('Yearly Rent'),
                            ),
                            DropdownMenuItem(
                              value: 'height',
                              child: Text('Height'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _sortBy = val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Tower List View ───────────────────────────────────────
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
                              Icons.cell_tower_rounded,
                              size: 48,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No tower records found.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSec(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try adjusting your search query or filters.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textMut(context),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];
                            return _buildTowerCard(item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTowerCard(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? 'TWR-0000';
    final owner = item['owner']?.toString() ?? 'Government of Goa';
    final district = item['district']?.toString() ?? 'North Goa';
    final taluka = item['taluka']?.toString() ?? 'Tiswadi';
    final area = item['area']?.toString() ?? 'Panaji';
    final land = item['land']?.toString() ?? 'Government';
    final operatorName = item['operator']?.toString() ?? 'None';
    final operators = item['operators']?.toString() ?? '1 operator';
    final status = item['status']?.toString() ?? 'active';
    final rentStatus = item['rent']?.toString() ?? 'Paid';
    final height = item['height']?.toString() ?? '30m';
    final yearlyRent = item['yearly_rent']?.toString() ?? '60000';

    final isGovt = land.toLowerCase() == 'government';

    return MTMMSCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      onTap: () async {
        final updated = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => TowerDetailsScreen(tower: item),
          ),
        );
        if (updated == true) _loadData();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurf(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.cell_tower_rounded,
                      color: AppColors.primaryLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        id,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPri(context),
                        ),
                      ),
                      Text(
                        '$area, $taluka ($district)',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: AppColors.textSec(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              StatusBadge(status: status == 'active' ? 'Active' : 'Inactive'),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.dividerCol(context)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Owner / Land Type',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: AppColors.textMut(context),
                    ),
                  ),
                  Text(
                    '$owner • $land',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPri(context),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Yearly Rent',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: AppColors.textMut(context),
                    ),
                  ),
                  Text(
                    '₹$yearlyRent/yr',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              StatusBadge(status: isGovt ? 'Government' : 'Private'),
              StatusBadge(status: rentStatus),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.primarySurf(context),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '$operatorName ($operators)',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.primarySurf(context),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  height,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
