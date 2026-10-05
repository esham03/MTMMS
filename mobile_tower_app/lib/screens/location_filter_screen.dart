import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/data_sync_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/government_components.dart';
import 'towers/tower_details_screen.dart';

class LocationFilterScreen extends StatefulWidget {
  const LocationFilterScreen({super.key});

  @override
  State<LocationFilterScreen> createState() => _LocationFilterScreenState();
}

class _LocationFilterScreenState extends State<LocationFilterScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  Timer? _autoRefreshTimer;
  List<Map<String, dynamic>> _allTowers = [];

  String? _selectedDistrict;
  String? _selectedTaluka;
  String? _selectedConstituency;
  String? _selectedArea;

  List<String> get _availableDistricts => LocationService.getDistricts();

  List<String> get _availableTalukas {
    final list = LocationService.getTalukas(district: _selectedDistrict);
    final fromTowers = _allTowers
        .where((t) =>
            _selectedDistrict == null ||
            t['district']?.toString().toLowerCase().trim() ==
                _selectedDistrict!.toLowerCase().trim())
        .map((t) => t['taluka']?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty);
    final set = list.toSet()..addAll(fromTowers);
    return set.toList()..sort();
  }

  List<String> get _availableConstituencies {
    final list = LocationService.getConstituencies(
      district: _selectedDistrict,
      taluka: _selectedTaluka,
    );
    final fromTowers = _allTowers
        .where((t) {
          if (_selectedDistrict != null &&
              t['district']?.toString().toLowerCase().trim() !=
                  _selectedDistrict!.toLowerCase().trim()) {
            return false;
          }
          if (_selectedTaluka != null &&
              t['taluka']?.toString().toLowerCase().trim() !=
                  _selectedTaluka!.toLowerCase().trim()) {
            return false;
          }
          return true;
        })
        .map((t) => t['constituency']?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty);
    final set = list.toSet()..addAll(fromTowers);
    return set.toList()..sort();
  }

  List<String> get _availableAreas {
    final list = LocationService.getAreas(
      district: _selectedDistrict,
      taluka: _selectedTaluka,
      constituency: _selectedConstituency,
    );
    final fromTowers = _allTowers
        .where((t) {
          if (_selectedDistrict != null &&
              t['district']?.toString().toLowerCase().trim() !=
                  _selectedDistrict!.toLowerCase().trim()) {
            return false;
          }
          if (_selectedTaluka != null &&
              t['taluka']?.toString().toLowerCase().trim() !=
                  _selectedTaluka!.toLowerCase().trim()) {
            return false;
          }
          if (_selectedConstituency != null &&
              t['constituency']?.toString().toLowerCase().trim() !=
                  _selectedConstituency!.toLowerCase().trim()) {
            return false;
          }
          return true;
        })
        .map((t) => t['area']?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty);
    final set = list.toSet()..addAll(fromTowers);
    return set.toList()..sort();
  }

  void _onDistrictChanged(String? val) {
    setState(() {
      _selectedDistrict = val;
      if (_selectedTaluka != null &&
          !_availableTalukas.any((t) => t.toLowerCase() == _selectedTaluka!.toLowerCase())) {
        _selectedTaluka = null;
      }
      if (_selectedConstituency != null &&
          !_availableConstituencies.any((c) => c.toLowerCase() == _selectedConstituency!.toLowerCase())) {
        _selectedConstituency = null;
      }
      if (_selectedArea != null &&
          !_availableAreas.any((a) => a.toLowerCase() == _selectedArea!.toLowerCase())) {
        _selectedArea = null;
      }
    });
  }

  void _onTalukaChanged(String? val) {
    setState(() {
      _selectedTaluka = val;
      if (val != null) {
        final dist = LocationService.getDistrictForTaluka(val);
        if (dist != null && dist.isNotEmpty) {
          _selectedDistrict = dist;
        }
      }
      if (_selectedConstituency != null &&
          !_availableConstituencies.any((c) => c.toLowerCase() == _selectedConstituency!.toLowerCase())) {
        _selectedConstituency = null;
      }
      if (_selectedArea != null &&
          !_availableAreas.any((a) => a.toLowerCase() == _selectedArea!.toLowerCase())) {
        _selectedArea = null;
      }
    });
  }

  void _onConstituencyChanged(String? val) {
    setState(() {
      _selectedConstituency = val;
      if (val != null) {
        final taluka = LocationService.getTalukaForConstituency(val);
        if (taluka != null && taluka.isNotEmpty) {
          _selectedTaluka = taluka;
          final dist = LocationService.getDistrictForTaluka(taluka);
          if (dist != null && dist.isNotEmpty) {
            _selectedDistrict = dist;
          }
        }
      }
      if (_selectedArea != null &&
          !_availableAreas.any((a) => a.toLowerCase() == _selectedArea!.toLowerCase())) {
        _selectedArea = null;
      }
    });
  }

  void _onAreaChanged(String? val) {
    setState(() {
      _selectedArea = val;
      if (val != null) {
        final constName = LocationService.getConstituencyForArea(val);
        if (constName != null && constName.isNotEmpty) {
          _selectedConstituency = constName;
        }
        final taluka = LocationService.getTalukaForArea(val);
        if (taluka != null && taluka.isNotEmpty) {
          _selectedTaluka = taluka;
          final dist = LocationService.getDistrictForTaluka(taluka);
          if (dist != null && dist.isNotEmpty) {
            _selectedDistrict = dist;
          }
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DataSyncService.syncNotifier.addListener(_onDataSyncChanged);
    _loadTowers();
    // 15-second heartbeat for live backend updates
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadTowers(isSilent: true),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadTowers(isSilent: true);
    }
  }

  void _onDataSyncChanged() {
    if (mounted) {
      _loadTowers(isSilent: true);
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    DataSyncService.syncNotifier.removeListener(_onDataSyncChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadTowers({bool isSilent = false}) async {
    if (!isSilent && mounted) setState(() => _isLoading = true);
    try {
      final list = await ApiService.getTowers();
      await LocationService.loadHierarchy();
      if (mounted) {
        setState(() {
          _allTowers = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !isSilent) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTowers {
    return _allTowers.where((t) {
      if (_selectedDistrict != null &&
          t['district']?.toString().toLowerCase().trim() !=
              _selectedDistrict!.toLowerCase().trim()) {
        return false;
      }
      if (_selectedTaluka != null &&
          t['taluka']?.toString().toLowerCase().trim() !=
              _selectedTaluka!.toLowerCase().trim()) {
        return false;
      }
      if (_selectedConstituency != null &&
          t['constituency']?.toString().toLowerCase().trim() !=
              _selectedConstituency!.toLowerCase().trim()) {
        return false;
      }
      if (_selectedArea != null &&
          t['area']?.toString().toLowerCase().trim() != _selectedArea!.toLowerCase().trim()) {
        return false;
      }
      return true;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _selectedDistrict = null;
      _selectedTaluka = null;
      _selectedConstituency = null;
      _selectedArea = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredTowers;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      drawer: const AppDrawer(currentRoute: 'locations'),
      appBar: MTMMSAppBar(
        title: 'Location Browser',
        subtitle: 'Cascading Geographic Hierarchy',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload Grid',
            onPressed: _loadTowers,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Cascading Filters Panel ───────────────────────────────
          MTMMSCard(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.alt_route_rounded,
                          size: 18,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'GEOGRAPHIC HIERARCHY',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMut(context),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedDistrict != null ||
                        _selectedTaluka != null ||
                        _selectedConstituency != null ||
                        _selectedArea != null)
                      TextButton(
                        onPressed: _resetFilters,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Reset', style: TextStyle(fontSize: 11.5)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // District Selector (Level 1)
                _dropdownField(
                  label: '1. District',
                  value: _selectedDistrict,
                  hint: 'All Districts (North & South Goa)',
                  items: _availableDistricts,
                  onChanged: _onDistrictChanged,
                ),
                const SizedBox(height: 8),

                // Taluka Selector (Level 2)
                _dropdownField(
                  label: '2. Taluka',
                  value: _selectedTaluka,
                  hint: _selectedDistrict == null
                      ? 'Select Taluka (All Districts)'
                      : 'Select Taluka ($_selectedDistrict)',
                  items: _availableTalukas,
                  onChanged: _onTalukaChanged,
                ),
                const SizedBox(height: 8),

                // Constituency Selector (Level 3)
                _dropdownField(
                  label: '3. Constituency',
                  value: _selectedConstituency,
                  hint: _selectedTaluka == null
                      ? 'Select Constituency'
                      : 'Select Constituency ($_selectedTaluka)',
                  items: _availableConstituencies,
                  onChanged: _onConstituencyChanged,
                ),
                const SizedBox(height: 8),

                // Area Selector (Level 4)
                _dropdownField(
                  label: '4. Area / Panchayat',
                  value: _selectedArea,
                  hint: _selectedConstituency != null
                      ? 'Select Area / Panchayat ($_selectedConstituency)'
                      : (_selectedTaluka != null
                          ? 'Select Area / Panchayat ($_selectedTaluka)'
                          : 'Select Area / Village / Panchayat'),
                  items: _availableAreas,
                  onChanged: _onAreaChanged,
                ),
              ],
            ),
          ),

          // ── Hierarchy Results Header ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Matching Towers (${list.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPri(context),
                  ),
                ),
                Text(
                  'District → Taluka → Const. → Area',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textMut(context),
                  ),
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
                              Icons.location_off_rounded,
                              size: 40,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No towers match the selected location.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSec(context),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final item = list[i];
                          final id = item['id']?.toString() ?? 'TWR-0000';
                          final area = item['area']?.toString() ?? 'Goa';
                          final taluka = item['taluka']?.toString() ?? 'Tiswadi';
                          final district = item['district']?.toString() ?? 'North Goa';
                          final owner = item['owner']?.toString() ?? 'Government';
                          final op = item['operator']?.toString() ?? 'None';
                          final rent = item['yearly_rent']?.toString() ?? '60000';

                          return MTMMSCard(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TowerDetailsScreen(tower: item),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        id,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPri(context),
                                        ),
                                      ),
                                      Text(
                                        '$area, $taluka ($district)',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: AppColors.textSec(context),
                                        ),
                                      ),
                                      Text(
                                        'Owner: $owner • Op: $op',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.5,
                                          color: AppColors.textMut(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹$rent/yr',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 12,
                                      color: AppColors.textHint,
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

  Widget _dropdownField({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final validItems = items.toSet().toList();
    final effectiveValue = validItems.any((it) => it.toLowerCase() == (value ?? '').toLowerCase())
        ? validItems.firstWhere((it) => it.toLowerCase() == value!.toLowerCase())
        : null;

    return DropdownButtonFormField<String>(
      key: ValueKey('$label-${effectiveValue ?? "all"}-${validItems.length}'),
      value: effectiveValue,
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryLight,
        ),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 11.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(hint, style: TextStyle(fontSize: 12, color: AppColors.textSec(context))),
        ),
        ...validItems.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: const TextStyle(fontSize: 12)),
          );
        }),
      ],
      onChanged: onChanged,
    );
  }
}
