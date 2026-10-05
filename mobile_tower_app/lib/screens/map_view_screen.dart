import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import '../services/data_sync_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/government_components.dart';
import 'towers/tower_details_screen.dart';

// High-Precision Real-World Geographic Coordinates for Goa Talukas, Areas & Landmarks
// Exactly synced with Web MapView.jsx
const Map<String, List<double>> kGoaExactCoords = {
  // Specific Landmark Premise Locations
  'ponda police station': [15.40182, 74.01525],
  'inside premise of ponda police station': [15.40182, 74.01525],
  'mapusa market': [15.5925, 73.8120],
  'plot 42, mapusa market road, bardez': [15.5925, 73.8120],
  'patto plaza': [15.4944, 73.8375],
  'dabolim airport': [15.3808, 73.8313],
  'mormugao port': [15.4124, 73.7997],
  'mopa airport': [15.7533, 73.8647],

  // Talukas & Major Municipal Centers
  'bardez': [15.5937, 73.8142],
  'mapusa': [15.5937, 73.8142],
  'mapusa town': [15.5937, 73.8142],
  'tiswadi': [15.4909, 73.8278],
  'panaji': [15.4909, 73.8278],
  'panaji city': [15.4909, 73.8278],
  'salcete': [15.2736, 73.9582],
  'margao': [15.2736, 73.9582],
  'margao city': [15.2736, 73.9582],
  'mormugao': [15.3982, 73.8113],
  'vasco': [15.3982, 73.8113],
  'vasco da gama': [15.3982, 73.8113],
  'ponda': [15.4018, 74.0152],
  'ponda city': [15.4018, 74.0152],
  'bicholim': [15.5947, 73.9536],
  'bicholim town': [15.5947, 73.9536],
  'pernem': [15.7176, 73.7964],
  'pernem town': [15.7176, 73.7964],
  'sattari': [15.5312, 74.1165],
  'valpoi': [15.5312, 74.1165],
  'valpoi town': [15.5312, 74.1165],
  'quepem': [15.2185, 74.0734],
  'quepem town': [15.2185, 74.0734],
  'sanguem': [15.2307, 74.1569],
  'sanguem town': [15.2307, 74.1569],
  'canacona': [14.9998, 74.0537],
  'canacona (chaudi)': [14.9998, 74.0537],
  'dharbandora': [15.3855, 74.1722],
  'dharbandora town': [15.3855, 74.1722],

  // North Goa - Bardez Areas
  'calangute': [15.5439, 73.7554],
  'candolim': [15.5178, 73.7667],
  'porvorim': [15.5348, 73.8294],
  'anjuna': [15.5843, 73.7438],
  'baga': [15.5553, 73.7517],
  'aldona': [15.5898, 73.8732],
  'siolim': [15.6268, 73.7686],
  'saligao': [15.5517, 73.7845],
  'arpora': [15.5683, 73.7645],
  'nerul': [15.5112, 73.7847],
  'penha de franca': [15.5218, 73.8344],
  'pilerne': [15.5322, 73.7997],
  'moira': [15.6025, 73.8504],
  'guirim': [15.5701, 73.8182],

  // North Goa - Tiswadi Areas
  'miramar': [15.4833, 73.8083],
  'caranzalem': [15.4744, 73.8131],
  'dona paula': [15.4578, 73.8056],
  'bambolim': [15.4522, 73.8533],
  'taleigao': [15.4678, 73.8244],
  'santa cruz': [15.4733, 73.8444],
  'ribandar': [15.5033, 73.8644],
  'old goa': [15.5009, 73.9116],
  'corlim': [15.4983, 73.9317],
  'pilar': [15.4417, 73.8967],

  // North Goa - Pernem Areas
  'mandrem': [15.6706, 73.7175],
  'morjim': [15.6247, 73.7317],
  'arambol': [15.6853, 73.7042],
  'ashvem': [15.6583, 73.7194],
  'mopa airport area': [15.7533, 73.8647],
  'dhargal': [15.6983, 73.8317],
  'tuem': [15.6817, 73.7817],

  // North Goa - Bicholim Areas
  'sanquelim': [15.5617, 74.0117],
  'mayem': [15.5783, 73.9533],
  'mulgao': [15.6083, 73.9317],
  'bordem': [15.5983, 73.9617],
  'pale': [15.5183, 74.0517],

  // North Goa - Sattari Areas
  'honda': [15.5417, 74.0617],
  'pissurlem': [15.5217, 74.0917],
  'nagargao': [15.5117, 74.1317],
  'thane sattari': [15.5517, 74.1517],
  'birondem': [15.5317, 74.1017],

  // South Goa - Ponda Areas
  'farmagudi': [15.4217, 73.9983],
  'bandora': [15.4117, 73.9883],
  'curti': [15.4083, 74.0217],
  'kundaim industrial estate': [15.4417, 73.9617],
  'marcaim': [15.4183, 73.9417],
  'shiroda': [15.3417, 74.0617],
  'borim': [15.3617, 74.0317],
  'priol': [15.4483, 73.9817],

  // South Goa - Salcete Areas
  'fatorda': [15.2917, 73.9617],
  'benaulim': [15.2517, 73.9217],
  'nuvem': [15.3117, 73.9417],
  'navelim': [15.2617, 73.9717],
  'curtorim': [15.2817, 74.0117],
  'majorda': [15.3183, 73.9183],
  'betalbatim': [15.2983, 73.9183],
  'varca': [15.2217, 73.9217],
  'cavelossim': [15.1783, 73.9417],
  'raia': [15.3117, 73.9917],
  'loutolim': [15.3317, 73.9817],
  'colva': [15.2800, 73.9200],

  // South Goa - Mormugao Areas
  'dabolim (airport)': [15.3808, 73.8313],
  'cortalim': [15.3983, 73.9117],
  'sancoale industrial estate': [15.3817, 73.8817],
  'chicalim': [15.3917, 73.8417],
  'bogmalo': [15.3517, 73.8317],
  'velsao': [15.3483, 73.8817],
  'mormugao port harbour': [15.4124, 73.7997],

  // South Goa - Quepem Areas
  'curchorem': [15.2583, 74.1117],
  'sanvordem': [15.2617, 74.1217],
  'tilamol': [15.2317, 74.0917],
  'balli': [15.1717, 74.0317],
  'morpirla': [15.1417, 74.0917],

  // South Goa - Sanguem Areas
  'uguem': [15.2117, 74.1617],
  'netravali': [15.0917, 74.2117],
  'rivona': [15.1917, 74.1117],
  'curdi': [15.1617, 74.1817],
  'bhati': [15.1417, 74.1917],

  // South Goa - Canacona Areas
  'palolem': [15.0100, 74.0233],
  'agonda': [15.0450, 73.9883],
  'patnem': [15.0017, 74.0317],
  'poinguinim': [14.9617, 74.0817],
  'loliem': [14.9317, 74.1117],
  'gaondongrem': [15.0217, 74.1117],

  // South Goa - Dharbandora Areas
  'mollem': [15.3817, 74.2217],
  'colem': [15.3517, 74.2417],
  'sacorda': [15.4317, 74.1617],
  'sanjeevani sugar factory area': [15.3917, 74.1417],
};

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen>
    with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _towers = [];
  bool _isLoading = true;
  bool _isSatellite = false;
  Timer? _autoRefreshTimer;

  // Filters (matching Web MapView.jsx)
  String _selectedDistrict = 'All';
  String _selectedStatus = 'All';
  String _selectedLand = 'All';
  String _selectedCompany = 'All';

  // Selected tower for inspection bottom sheet
  Map<String, dynamic>? _selectedTower;

  // Dynamic list of telecom operators and infrastructure companies from loaded towers
  List<String> get _companyOptions {
    final set = <String>{};
    for (final t in _towers) {
      final op = t['operator']?.toString();
      if (op != null && op.isNotEmpty && op != 'None') {
        set.add(op);
      }
      final opList = t['operators_list'];
      if (opList is List) {
        for (final item in opList) {
          if (item is Map) {
            final sName = item['shortName']?.toString();
            final name = item['name']?.toString();
            if (sName != null && sName.isNotEmpty) set.add(sName);
            if (name != null && name.isNotEmpty) set.add(name);
          }
        }
      }
      final rawOps = t['_raw']?['operators'];
      if (rawOps is List) {
        for (final item in rawOps) {
          if (item is Map) {
            final sName = item['short_name']?.toString();
            final name = item['name']?.toString();
            if (sName != null && sName.isNotEmpty) set.add(sName);
            if (name != null && name.isNotEmpty) set.add(name);
          }
        }
      }
      final owner = t['owner']?.toString();
      if (owner != null && owner.isNotEmpty) {
        final low = owner.toLowerCase();
        if (low.contains('infrastructure') ||
            low.contains('telecom') ||
            low.contains('towers') ||
            low.contains('summit') ||
            low.contains('indus') ||
            low.contains('airtel') ||
            low.contains('jio')) {
          set.add(owner);
        }
      }
    }
    final sorted = set.toList()..sort();
    return ['All', ...sorted];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DataSyncService.syncNotifier.addListener(_onDataSyncChanged);
    _loadTowers();
    // 15-second heartbeat
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
    if (mounted) _loadTowers(isSilent: true);
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    DataSyncService.syncNotifier.removeListener(_onDataSyncChanged);
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTowers({bool isSilent = false}) async {
    if (!isSilent && mounted) setState(() => _isLoading = true);
    try {
      final list = await ApiService.getTowers();
      if (mounted) {
        setState(() {
          _towers = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !isSilent) setState(() => _isLoading = false);
    }
  }

  // Derive status and coordinates for each tower
  List<Map<String, dynamic>> get _processedTowers {
    final now = DateTime.now();
    final in30Days = now.add(const Duration(days: 30));

    return _towers.map((t) {
      final item = Map<String, dynamic>.from(t);

      // Status resolution
      String status = 'Paid';
      final dueDateStr = item['rent_due_date']?.toString();
      if (dueDateStr != null && dueDateStr.isNotEmpty) {
        final due = DateTime.tryParse(dueDateStr.split('T').first);
        if (due != null) {
          if (due.isBefore(now)) {
            status = 'Overdue';
          } else if (due.isBefore(in30Days)) {
            status = 'Due Soon';
          }
        }
      } else if (item['rent']?.toString().toLowerCase() == 'due' ||
          item['rent']?.toString().toLowerCase() == 'overdue') {
        status = 'Overdue';
      }
      item['_computedStatus'] = status;

      // Coordinate resolution with exact GPS & landmark matching
      double? lat = double.tryParse(item['latitude']?.toString() ?? '');
      double? lng = double.tryParse(item['longitude']?.toString() ?? '');

      if (lat != null &&
          lng != null &&
          lat >= 14.7 &&
          lat <= 15.9 &&
          lng >= 73.6 &&
          lng <= 74.5) {
        // Valid exact stored GPS coordinates
      } else {
        // Address & area intelligent matching
        final addr = (item['address'] ?? '').toString().toLowerCase().trim();
        final area = (item['area'] ?? '').toString().toLowerCase().trim();
        final taluka = (item['taluka'] ?? '').toString().toLowerCase().trim();

        List<double>? matched;
        for (final entry in kGoaExactCoords.entries) {
          if (entry.key.length > 5 && addr.contains(entry.key)) {
            matched = entry.value;
            break;
          }
        }
        matched ??= kGoaExactCoords[area] ?? kGoaExactCoords[taluka];
        if (matched != null) {
          lat = matched[0];
          lng = matched[1];
        } else {
          // Central Goa reference point (Ponda / Old Goa)
          lat = 15.35;
          lng = 73.95;
        }
      }

      item['_lat'] = lat;
      item['_lng'] = lng;
      return item;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredTowers {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _processedTowers.where((t) {
      // 1. Search Query: Matches ID, Area, Taluka, District, Address, Owner/Infra, or Operator / Company
      final id = (t['towerId'] ?? t['id'] ?? '').toString().toLowerCase();
      final area = (t['area'] ?? '').toString().toLowerCase();
      final taluka = (t['taluka'] ?? '').toString().toLowerCase();
      final district = (t['district'] ?? '').toString().toLowerCase();
      final address = (t['address'] ?? '').toString().toLowerCase();
      final owner = (t['owner'] ?? '').toString().toLowerCase();
      final op = (t['operator'] ?? '').toString().toLowerCase();

      bool matchesCompany = false;
      if (query.isNotEmpty) {
        if (op.contains(query) || owner.contains(query)) {
          matchesCompany = true;
        } else {
          final opList = t['operators_list'];
          if (opList is List) {
            for (final item in opList) {
              if (item is Map) {
                final name =
                    (item['name'] ?? '').toString().toLowerCase();
                final shortName =
                    (item['shortName'] ?? '').toString().toLowerCase();
                if (name.contains(query) || shortName.contains(query)) {
                  matchesCompany = true;
                  break;
                }
              }
            }
          }
          if (!matchesCompany) {
            final rawOps = t['_raw']?['operators'];
            if (rawOps is List) {
              for (final item in rawOps) {
                if (item is Map) {
                  final name =
                      (item['name'] ?? '').toString().toLowerCase();
                  final shortName =
                      (item['short_name'] ?? '').toString().toLowerCase();
                  if (name.contains(query) || shortName.contains(query)) {
                    matchesCompany = true;
                    break;
                  }
                }
              }
            }
          }
        }
      }

      final matchesSearch = query.isEmpty ||
          id.contains(query) ||
          area.contains(query) ||
          taluka.contains(query) ||
          district.contains(query) ||
          address.contains(query) ||
          matchesCompany;

      // 2. Company / Operator Dropdown filter
      bool matchesCompanyFilter = true;
      if (_selectedCompany != 'All') {
        final cLower = _selectedCompany.toLowerCase();
        if (op.contains(cLower) || owner.contains(cLower)) {
          matchesCompanyFilter = true;
        } else {
          matchesCompanyFilter = false;
          final opList = t['operators_list'];
          if (opList is List) {
            for (final item in opList) {
              if (item is Map) {
                final name =
                    (item['name'] ?? '').toString().toLowerCase();
                final shortName =
                    (item['shortName'] ?? '').toString().toLowerCase();
                if (name.contains(cLower) || shortName.contains(cLower)) {
                  matchesCompanyFilter = true;
                  break;
                }
              }
            }
          }
          if (!matchesCompanyFilter) {
            final rawOps = t['_raw']?['operators'];
            if (rawOps is List) {
              for (final item in rawOps) {
                if (item is Map) {
                  final name =
                      (item['name'] ?? '').toString().toLowerCase();
                  final shortName =
                      (item['short_name'] ?? '').toString().toLowerCase();
                  if (name.contains(cLower) || shortName.contains(cLower)) {
                    matchesCompanyFilter = true;
                    break;
                  }
                }
              }
            }
          }
        }
      }

      // 3. District
      final dName = (t['district'] ?? 'North Goa').toString().toLowerCase();
      final matchesDistrict = _selectedDistrict == 'All' ||
          dName.contains(_selectedDistrict.toLowerCase());

      // 4. Land
      final land = (t['land'] ?? 'Government').toString().toLowerCase();
      final matchesLand = _selectedLand == 'All' ||
          land.contains(_selectedLand.toLowerCase());

      // 5. Status
      final status = t['_computedStatus'] as String;
      final matchesStatus = _selectedStatus == 'All' ||
          status.toLowerCase() == _selectedStatus.toLowerCase();

      return matchesSearch &&
          matchesCompanyFilter &&
          matchesDistrict &&
          matchesLand &&
          matchesStatus;
    }).toList();
  }

  void _showTowerModal(Map<String, dynamic> tower) {
    setState(() => _selectedTower = tower);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildTowerSheet(tower),
    ).then((_) {
      if (mounted) setState(() => _selectedTower = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTowers;
    final totalCount = filtered.length;
    final paidCount =
        filtered.where((t) => t['_computedStatus'] == 'Paid').length;
    final dueSoonCount =
        filtered.where((t) => t['_computedStatus'] == 'Due Soon').length;
    final overdueCount =
        filtered.where((t) => t['_computedStatus'] == 'Overdue').length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAEEE6),
      drawer: const AppDrawer(currentRoute: 'map'),
      appBar: MTMMSAppBar(
        title: 'Geospatial Tower Map',
        subtitle: 'Official State Infrastructure & GIS Positioning',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh GIS Layers',
            onPressed: () => _loadTowers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter Controls (Orange & White Theme) ─────────────
          _buildFilterHeader(context),

          // ── Metrics Strip ───────────────────────────────────────────────
          _buildMetricsStrip(
            context,
            total: totalCount,
            paid: paidCount,
            dueSoon: dueSoonCount,
            overdue: overdueCount,
          ),

          // ── Interactive OpenStreetMap Tile Surface ──────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF5100),
                    ),
                  )
                : Stack(
                    children: [
                      // Real-World OpenStreetMap / Satellite Tiles
                      FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: LatLng(15.35, 74.02),
                          initialZoom: 10.2,
                          minZoom: 8.5,
                          maxZoom: 18.0,
                          interactionOptions: InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                        ),
                        children: [
                          // Base Map Tile Layer
                          TileLayer(
                            urlTemplate: _isSatellite
                                ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                                : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.mtmms.mobile_tower_app',
                            maxZoom: 19,
                          ),

                          // Tower Pins Markers Layer
                          MarkerLayer(
                            markers: filtered.map((tower) {
                              final lat = tower['_lat'] as double;
                              final lng = tower['_lng'] as double;
                              final status =
                                  tower['_computedStatus'] as String;
                              final isSelected =
                                  _selectedTower?['id'] == tower['id'];

                              return Marker(
                                point: LatLng(lat, lng),
                                width: 80,
                                height: 70,
                                alignment: Alignment.topCenter,
                                child: _buildTowerPin(
                                  tower,
                                  status: status,
                                  isSelected: isSelected,
                                  onTap: () => _showTowerModal(tower),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),

                      // Floating Map Controls (Layer Switcher, Zoom +, Zoom -, Reset)
                      Positioned(
                        right: 16,
                        bottom: 24,
                        child: Column(
                          children: [
                            // Satellite / Street Layer Switcher
                            _mapActionButton(
                              icon: _isSatellite
                                  ? Icons.map_rounded
                                  : Icons.satellite_alt_rounded,
                              tooltip: _isSatellite
                                  ? 'Street Map View'
                                  : 'Satellite Imagery',
                              isActive: _isSatellite,
                              onTap: () {
                                setState(() => _isSatellite = !_isSatellite);
                              },
                            ),
                            const SizedBox(height: 8),
                            _mapActionButton(
                              icon: Icons.add_rounded,
                              tooltip: 'Zoom In',
                              onTap: () {
                                final currentZoom =
                                    _mapController.camera.zoom;
                                if (currentZoom < 18.0) {
                                  _mapController.move(
                                    _mapController.camera.center,
                                    currentZoom + 1,
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            _mapActionButton(
                              icon: Icons.remove_rounded,
                              tooltip: 'Zoom Out',
                              onTap: () {
                                final currentZoom =
                                    _mapController.camera.zoom;
                                if (currentZoom > 8.5) {
                                  _mapController.move(
                                    _mapController.camera.center,
                                    currentZoom - 1,
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            _mapActionButton(
                              icon: Icons.my_location_rounded,
                              tooltip: 'Recenter Goa',
                              onTap: () {
                                _mapController.move(
                                  const LatLng(15.35, 74.02),
                                  10.2,
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Live Telemetry / Grid Badge
                      Positioned(
                        left: 16,
                        top: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFF5100)
                                  .withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.explore_rounded,
                                size: 15,
                                color: Color(0xFFFF5100),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isSatellite
                                    ? 'ESRI SATELLITE GRID'
                                    : 'GOA OPENSTREETMAP',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0A0F1D),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Filter & Search Header (Orange & White Theme) ──────────────────────────
  Widget _buildFilterHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        children: [
          // Search Input
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF0A0F1D),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search company, operator, tower ID, area...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: Color(0xFFFF5100),
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Company / Operator Filter
                _filterDropdownChip(
                  context,
                  label: 'Company: $_selectedCompany',
                  icon: Icons.cell_tower_rounded,
                  options: _companyOptions,
                  currentVal: _selectedCompany,
                  onSelected: (v) => setState(() => _selectedCompany = v),
                ),
                const SizedBox(width: 8),

                // District Filter
                _filterDropdownChip(
                  context,
                  label: 'District: $_selectedDistrict',
                  icon: Icons.map_outlined,
                  options: ['All', 'North Goa', 'South Goa'],
                  currentVal: _selectedDistrict,
                  onSelected: (v) => setState(() => _selectedDistrict = v),
                ),
                const SizedBox(width: 8),

                // Status Filter
                _filterDropdownChip(
                  context,
                  label: 'Status: $_selectedStatus',
                  icon: Icons.verified_user_outlined,
                  options: ['All', 'Paid', 'Due Soon', 'Overdue'],
                  currentVal: _selectedStatus,
                  onSelected: (v) => setState(() => _selectedStatus = v),
                ),
                const SizedBox(width: 8),

                // Land Classification Filter
                _filterDropdownChip(
                  context,
                  label: 'Land: $_selectedLand',
                  icon: Icons.landscape_outlined,
                  options: ['All', 'Government', 'Private'],
                  currentVal: _selectedLand,
                  onSelected: (v) => setState(() => _selectedLand = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdownChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required List<String> options,
    required String currentVal,
    required ValueChanged<String> onSelected,
  }) {
    final isSelected = currentVal != 'All';
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (ctx) => options.map((opt) {
        return PopupMenuItem(
          value: opt,
          child: Row(
            children: [
              if (opt == currentVal)
                const Icon(Icons.check, size: 16, color: Color(0xFFFF5100))
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(
                opt,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight:
                      opt == currentVal ? FontWeight.w600 : FontWeight.w400,
                  color: opt == currentVal
                      ? const Color(0xFFFF5100)
                      : const Color(0xFF0A0F1D),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF4EC) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF5100)
                : const Color(0xFFCBD5E1),
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? const Color(0xFFFF5100)
                  : const Color(0xFF475569),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFFFF5100)
                    : const Color(0xFF0A0F1D),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isSelected
                  ? const Color(0xFFFF5100)
                  : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  // ── Metrics Strip (Spacious, Clean White Background) ────────────────────────
  Widget _buildMetricsStrip(
    BuildContext context, {
    required int total,
    required int paid,
    required int dueSoon,
    required int overdue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _miniMetric(context, 'Total Mapped', '$total',
                const Color(0xFFFF5100)),
            const SizedBox(width: 20),
            _miniMetric(context, 'Paid / Active', '$paid',
                const Color(0xFF10B981)),
            const SizedBox(width: 20),
            _miniMetric(context, 'Due Soon', '$dueSoon',
                const Color(0xFFF59E0B)),
            const SizedBox(width: 20),
            _miniMetric(context, 'Overdue', '$overdue',
                const Color(0xFFEF4444)),
          ],
        ),
      ),
    );
  }

  Widget _miniMetric(
    BuildContext context,
    String label,
    String count,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  // ── Tower Marker Pin ────────────────────────────────────────────────────────
  Widget _buildTowerPin(
    Map<String, dynamic> tower, {
    required String status,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    Color pinColor = const Color(0xFF10B981);
    if (status == 'Due Soon') {
      pinColor = const Color(0xFFF59E0B);
    } else if (status == 'Overdue') {
      pinColor = const Color(0xFFEF4444);
    }

    final id = (tower['towerId'] ?? tower['id'] ?? 'TWR').toString();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Antenna Marker
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: pinColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: pinColor.withValues(alpha: isSelected ? 0.6 : 0.4),
                  blurRadius: isSelected ? 12 : 6,
                  spreadRadius: isSelected ? 3 : 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.cell_tower_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          // Tag Label underneath
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0F1D),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF5100)
                    : Colors.white.withValues(alpha: 0.2),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Circular Map Action Button ──────────────────────────────────────────────
  Widget _mapActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFF5100) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive
              ? const Color(0xFFFF5100)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? Colors.white : const Color(0xFFFF5100),
          size: 20,
        ),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  // ── Inspection Bottom Sheet (Orange & White Theme) ──────────────────────────
  Widget _buildTowerSheet(Map<String, dynamic> tower) {
    final id = (tower['towerId'] ?? tower['id'] ?? 'TWR-0001').toString();
    final status = tower['_computedStatus'] as String;
    final isGovt =
        (tower['land'] ?? 'Government').toString().toLowerCase() ==
            'government';
    final district = tower['district'] ?? 'North Goa';
    final taluka = tower['taluka'] ?? 'Tiswadi';
    final area = tower['area'] ?? 'Panaji';
    final yearlyRent = tower['yearly_rent']?.toString() ?? '60,000';
    final operator = tower['operator'] ?? 'None Assigned';
    final owner = tower['owner']?.toString() ??
        (isGovt ? 'Government of Goa' : 'Private Landowner');

    // Aggregate all associated telecom operators
    String allOps = operator;
    final opList = tower['operators_list'];
    if (opList is List && opList.isNotEmpty) {
      final names = <String>[];
      for (final item in opList) {
        if (item is Map) {
          final sName = item['shortName']?.toString() ??
              item['name']?.toString() ??
              '';
          if (sName.isNotEmpty && !names.contains(sName)) names.add(sName);
        }
      }
      if (names.isNotEmpty) allOps = names.join(', ');
    } else {
      final rawOps = tower['_raw']?['operators'];
      if (rawOps is List && rawOps.isNotEmpty) {
        final names = <String>[];
        for (final item in rawOps) {
          if (item is Map) {
            final sName = item['short_name']?.toString() ??
                item['name']?.toString() ??
                '';
            if (sName.isNotEmpty && !names.contains(sName)) names.add(sName);
          }
        }
        if (names.isNotEmpty) allOps = names.join(', ');
      }
    }

    Color statusColor = const Color(0xFF10B981);
    Color statusBg = const Color(0xFFEBF8F1);
    if (status == 'Due Soon') {
      statusColor = const Color(0xFFF59E0B);
      statusBg = const Color(0xFFFEF9EC);
    } else if (status == 'Overdue') {
      statusColor = const Color(0xFFEF4444);
      statusBg = const Color(0xFFFDF2F2);
    }

    final heightRaw = tower['height'] ??
        tower['height_meters'] ??
        tower['height_m'] ??
        '30';
    final widthRaw = tower['width'] ??
        tower['width_meters'] ??
        tower['base_width'] ??
        tower['width_m'] ??
        '2.5';
    final heightNum =
        double.tryParse(heightRaw.toString().replaceAll(RegExp(r'[^\d.]'), '')) ??
            30.0;
    final widthNum =
        double.tryParse(widthRaw.toString().replaceAll(RegExp(r'[^\d.]'), '')) ??
            2.5;
    final heightFt = (heightNum * 3.28084).round();
    final widthFt = (widthNum * 3.28084).round();
    final spaceM2 = (widthNum * widthNum).round();
    final spaceSqFt = (spaceM2 * 10.7639).round();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Accent Bar (Web-matched Solar Orange #FF5100)
            Container(
              height: 3.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF5100), Color(0xFFFF7700)],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header with Status Badge & Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '● ${status.toUpperCase()}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            id,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0A0F1D),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Location & Jurisdiction Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: Color(0xFFFF5100),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$area, $taluka',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0A0F1D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.only(left: 22),
                          child: Text(
                            '$district • ${(tower['_lat'] as double).toStringAsFixed(4)}° N, ${(tower['_lng'] as double).toStringAsFixed(4)}° E',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Landlord & Operating Tenant Grid
                  Row(
                    children: [
                      Expanded(
                        child: _sheetInfoTile(
                          context,
                          title: 'LANDLORD / BODY',
                          value: owner,
                          subtitle: isGovt ? 'Government Land' : 'Private Land',
                          icon: Icons.account_balance_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _sheetInfoTile(
                          context,
                          title: 'ANNUAL RENT',
                          value: '₹$yearlyRent',
                          subtitle: 'Due: ${tower['rent_due_date']?.toString().split('T').first ?? '—'}',
                          icon: Icons.currency_rupee_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Operating Telecom Company Card
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4EC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF5100).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cell_tower_rounded,
                          size: 16,
                          color: Color(0xFFFF5100),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TENANT OPERATOR(S)',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFF5100),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                allOps,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0A0F1D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Physical Dimensions
                  Row(
                    children: [
                      Expanded(
                        child: _sheetInfoTile(
                          context,
                          title: 'TOWER HEIGHT',
                          value: '${heightNum.toStringAsFixed(1)}m ($heightFt ft)',
                          subtitle: 'Lattice Structure',
                          icon: Icons.height_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _sheetInfoTile(
                          context,
                          title: 'FOOTPRINT AREA',
                          value: '${spaceM2}m² ($spaceSqFt sq ft)',
                          subtitle: 'Base Width: ${widthNum}m ($widthFt ft)',
                          icon: Icons.square_foot_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Action Button (Solar Orange Gradient)
                  Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5100), Color(0xFFFF7700)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5100)
                              .withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward_rounded,
                          size: 18, color: Colors.white),
                      label: Text(
                        'View Full Tower Dossier',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TowerDetailsScreen(tower: tower),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetInfoTile(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: const Color(0xFFFF5100)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0A0F1D),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
