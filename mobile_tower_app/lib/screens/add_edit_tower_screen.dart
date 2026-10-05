import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/government_components.dart';

class AddEditTowerScreen extends StatefulWidget {
  final Map<String, dynamic>? tower;

  const AddEditTowerScreen({super.key, this.tower});

  bool get isEditing => tower != null;

  @override
  State<AddEditTowerScreen> createState() => _AddEditTowerScreenState();
}

class _AddEditTowerScreenState extends State<AddEditTowerScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idCtrl;
  late final TextEditingController _ownerCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _widthCtrl;
  late final TextEditingController _frequencyCtrl;
  late final TextEditingController _yearlyRentCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _latitudeCtrl;
  late final TextEditingController _longitudeCtrl;

  String _selectedDistrict = 'North Goa';
  String _selectedTaluka = 'Tiswadi';
  String _selectedConstituency = 'Panaji';
  String _selectedArea = 'Panaji City';
  String _selectedLandType = 'Government';
  String _selectedStatus = 'Active';
  int _selectedYearCycle = 5; // 1, 5, 10, 15, 20 Years

  List<String> get _availableDistricts => LocationService.getDistricts();

  List<String> get _availableTalukas =>
      LocationService.getTalukas(district: _selectedDistrict);

  List<String> get _availableConstituencies => LocationService.getConstituencies(
        district: _selectedDistrict,
        taluka: _selectedTaluka,
      );

  List<String> get _availableAreas => LocationService.getAreas(
        district: _selectedDistrict,
        taluka: _selectedTaluka,
        constituency: _selectedConstituency,
      );

  void _onDistrictChanged(String? val) {
    if (val == null || val == _selectedDistrict) return;
    setState(() {
      _selectedDistrict = val;

      final talukas = _availableTalukas;
      if (!talukas.any((t) => t.toLowerCase() == _selectedTaluka.toLowerCase())) {
        _selectedTaluka = talukas.isNotEmpty ? talukas.first : '';
      }

      final consts = _availableConstituencies;
      if (!consts.any((c) => c.toLowerCase() == _selectedConstituency.toLowerCase())) {
        _selectedConstituency = consts.isNotEmpty ? consts.first : '';
      }

      final areas = _availableAreas;
      if (!areas.any((a) => a.toLowerCase() == _selectedArea.toLowerCase())) {
        _selectedArea = areas.isNotEmpty ? areas.first : '';
      }
    });
  }

  void _onTalukaChanged(String? val) {
    if (val == null || val == _selectedTaluka) return;
    setState(() {
      _selectedTaluka = val;

      // Auto-sync district if needed
      final dist = LocationService.getDistrictForTaluka(val);
      if (dist != null && dist.isNotEmpty) {
        _selectedDistrict = dist;
      }

      final consts = _availableConstituencies;
      if (!consts.any((c) => c.toLowerCase() == _selectedConstituency.toLowerCase())) {
        _selectedConstituency = consts.isNotEmpty ? consts.first : '';
      }

      final areas = _availableAreas;
      if (!areas.any((a) => a.toLowerCase() == _selectedArea.toLowerCase())) {
        _selectedArea = areas.isNotEmpty ? areas.first : '';
      }
    });
  }

  void _onConstituencyChanged(String? val) {
    if (val == null || val == _selectedConstituency) return;
    setState(() {
      _selectedConstituency = val;

      final areas = _availableAreas;
      if (!areas.any((a) => a.toLowerCase() == _selectedArea.toLowerCase())) {
        _selectedArea = areas.isNotEmpty ? areas.first : '';
      }
    });
  }

  void _onAreaChanged(String? val) {
    if (val == null || val == _selectedArea) return;
    setState(() {
      _selectedArea = val;
    });
  }

  List<Map<String, dynamic>> _allOperators = [
    {'id': 1, 'name': 'Reliance Jio Infocomm', 'code': 'JIO'},
    {'id': 2, 'name': 'Bharti Airtel Limited', 'code': 'AIRTEL'},
    {'id': 3, 'name': 'Vodafone Idea Limited', 'code': 'VI'},
    {'id': 4, 'name': 'BSNL Goa Circle', 'code': 'BSNL'},
  ];
  final List<int> _selectedOperatorIds = [];

  String _heightUnit = 'm'; // 'm' | 'ft'
  String _widthUnit = 'm';  // 'm' | 'ft'
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.tower;

    _idCtrl = TextEditingController(text: t?['id']?.toString() ?? '');
    _ownerCtrl = TextEditingController(text: t?['owner']?.toString() ?? 'Government of Goa');
    _heightCtrl = TextEditingController(text: _stripUnit(t?['height'] ?? '30'));
    _widthCtrl = TextEditingController(text: _stripUnit(t?['width'] ?? '2.5'));
    _frequencyCtrl = TextEditingController(text: t?['frequency']?.toString() ?? '1800 MHz');
    _yearlyRentCtrl = TextEditingController(text: t?['yearly_rent']?.toString() ?? '60000');
    _addressCtrl = TextEditingController(text: t?['address']?.toString() ?? '');
    _latitudeCtrl = TextEditingController(text: t?['latitude']?.toString() ?? '');
    _longitudeCtrl = TextEditingController(text: t?['longitude']?.toString() ?? '');

    _yearlyRentCtrl.addListener(() {
      setState(() {});
    });

    if (t != null) {
      if (t['land']?.toString().toLowerCase() == 'private') _selectedLandType = 'Private';
      if (t['status']?.toString().toLowerCase() == 'inactive') _selectedStatus = 'Inactive';
      if (t['district'] != null) _selectedDistrict = t['district'];
      if (t['taluka'] != null) _selectedTaluka = t['taluka'];
      if (t['constituency'] != null) _selectedConstituency = t['constituency'];
      if (t['area'] != null) _selectedArea = t['area'];
      if (t['rent_cycle_years'] != null) {
        _selectedYearCycle = int.tryParse(t['rent_cycle_years'].toString()) ?? 5;
      }
      if (t['operator_ids'] is List) {
        _selectedOperatorIds.addAll(List<int>.from(t['operator_ids']));
      }
      if (t['height_unit'] != null) {
        _heightUnit = t['height_unit'].toString().toLowerCase() == 'ft' ? 'ft' : 'm';
      }
      if (t['width_unit'] != null) {
        _widthUnit = t['width_unit'].toString().toLowerCase() == 'ft' ? 'ft' : 'm';
      }
    }

    _loadHierarchy();
  }

  String _stripUnit(dynamic val) {
    if (val == null) return '';
    return val.toString().replaceAll(' m', '').replaceAll('m', '').trim();
  }

  Future<void> _loadHierarchy() async {
    try {
      await LocationService.loadHierarchy();
      final ops = await ApiService.getOperators();

      if (mounted) {
        setState(() {
          if (ops.isNotEmpty) {
            _allOperators = ops.map((op) => {
              'id': op['id'] is int
                  ? op['id'] as int
                  : int.tryParse(op['id'].toString()) ?? 0,
              'name': op['name']?.toString() ?? 'Operator',
              'code': op['code']?.toString() ?? 'OP',
            }).toList();
          }

          final dists = _availableDistricts;
          if (!dists.any((d) => d.toLowerCase() == _selectedDistrict.toLowerCase()) && dists.isNotEmpty) {
            _selectedDistrict = dists.first;
          }

          final tals = _availableTalukas;
          if (!tals.any((t) => t.toLowerCase() == _selectedTaluka.toLowerCase()) && tals.isNotEmpty) {
            _selectedTaluka = tals.first;
          }

          final consts = _availableConstituencies;
          if (!consts.any((c) => c.toLowerCase() == _selectedConstituency.toLowerCase()) && consts.isNotEmpty) {
            _selectedConstituency = consts.first;
          }

          final areas = _availableAreas;
          if (!areas.any((a) => a.toLowerCase() == _selectedArea.toLowerCase()) && areas.isNotEmpty) {
            _selectedArea = areas.first;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _ownerCtrl.dispose();
    _heightCtrl.dispose();
    _widthCtrl.dispose();
    _frequencyCtrl.dispose();
    _yearlyRentCtrl.dispose();
    _addressCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    super.dispose();
  }

  void _toggleOperator(int opId) {
    setState(() {
      if (_selectedOperatorIds.contains(opId)) {
        _selectedOperatorIds.remove(opId);
      } else {
        _selectedOperatorIds.add(opId);
      }
    });
  }

  void _setHeightUnit(String newUnit) {
    if (_heightUnit == newUnit) return;
    final currentVal = double.tryParse(_heightCtrl.text.trim());
    if (currentVal != null) {
      if (newUnit == 'ft') {
        final inFeet = currentVal * 3.28084;
        _heightCtrl.text = inFeet.toStringAsFixed(1);
      } else {
        final inMeters = currentVal * 0.3048;
        _heightCtrl.text = inMeters.toStringAsFixed(1);
      }
    }
    setState(() => _heightUnit = newUnit);
  }

  void _setWidthUnit(String newUnit) {
    if (_widthUnit == newUnit) return;
    final currentVal = double.tryParse(_widthCtrl.text.trim());
    if (currentVal != null) {
      if (newUnit == 'ft') {
        final inFeet = currentVal * 3.28084;
        _widthCtrl.text = inFeet.toStringAsFixed(1);
      } else {
        final inMeters = currentVal * 0.3048;
        _widthCtrl.text = inMeters.toStringAsFixed(1);
      }
    }
    setState(() => _widthUnit = newUnit);
  }

  double _calculateTotalAmount() {
    final yearly = double.tryParse(_yearlyRentCtrl.text) ?? 0.0;
    return yearly * _selectedYearCycle;
  }

  void _autoFillCoordinates() {
    final coords = LocationService.findExactCoordinates(
      area: _selectedArea,
      address: _addressCtrl.text,
      taluka: _selectedTaluka,
    );
    if (coords != null && coords.length >= 2) {
      setState(() {
        _latitudeCtrl.text = coords[0].toStringAsFixed(6);
        _longitudeCtrl.text = coords[1].toStringAsFixed(6);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coordinates auto-filled: ${coords[0]}°N, ${coords[1]}°E'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No exact GPS match found for this location. Please enter manually.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    int? areaId = LocationService.getAreaId(_selectedArea);

    final rawHeight = double.tryParse(_heightCtrl.text.trim()) ?? 0.0;
    final heightInMeters = _heightUnit == 'ft' ? (rawHeight * 0.3048) : rawHeight;
    final rawWidth = double.tryParse(_widthCtrl.text.trim()) ?? 0.0;
    final widthInMeters = _widthUnit == 'ft' ? (rawWidth * 0.3048) : rawWidth;

    final payload = {
      'id': _idCtrl.text.trim(),
      'tower_unique_id': _idCtrl.text.trim(),
      'owner': _ownerCtrl.text.trim(),
      'district': _selectedDistrict,
      'taluka': _selectedTaluka,
      'constituency': _selectedConstituency,
      'area': _selectedArea,
      'area_id': areaId,
      'land': _selectedLandType,
      'height': heightInMeters.toStringAsFixed(1),
      'height_meters': heightInMeters.toStringAsFixed(1),
      'height_unit': _heightUnit,
      'width': widthInMeters.toStringAsFixed(1),
      'width_meters': widthInMeters.toStringAsFixed(1),
      'width_unit': _widthUnit,
      'frequency': _frequencyCtrl.text.trim(),
      'status': _selectedStatus.toLowerCase(),
      'yearly_rent': _yearlyRentCtrl.text.trim(),
      'rent_cycle_years': _selectedYearCycle,
      'total_amount': _calculateTotalAmount(),
      'operator_ids': _selectedOperatorIds,
      'address': _addressCtrl.text.trim(),
      'latitude': double.tryParse(_latitudeCtrl.text.trim()),
      'longitude': double.tryParse(_longitudeCtrl.text.trim()),
    };

    final dbId = widget.tower?['dbId']?.toString() ??
        widget.tower?['id']?.toString() ??
        '';

    final result = await ApiService.saveTowerWithResult(
      payload,
      isEditing: widget.isEditing,
      id: dbId,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing
              ? 'Tower updated in MTMMS database'
              : 'Tower registered in MTMMS database'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      final msg = result['message']?.toString() ??
          'Failed to save tower. Please verify connection and fields.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _calculateTotalAmount();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: MTMMSAppBar(
        title: widget.isEditing ? 'Edit Tower Record' : 'Register New Tower',
        subtitle: 'Official Telecom Infrastructure Portal',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // ── Section: Identification & Owner ─────────────────────
            _formSection(
              title: 'TOWER IDENTIFICATION & OWNERSHIP',
              icon: Icons.business_rounded,
              children: [
                _label('Tower ID / UID *'),
                TextFormField(
                  controller: _idCtrl,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'e.g. MTMMS-001 or TWR-1048',
                    prefixIcon: Icon(Icons.qr_code_rounded, size: 18),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Tower ID is required' : null,
                ),
                const SizedBox(height: 14),

                _label('Tower Owner / Ownership Name *'),
                TextFormField(
                  controller: _ownerCtrl,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Government of Goa / Info Tech Corp',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Owner name is required' : null,
                ),
                const SizedBox(height: 14),

                _label('Land Classification *'),
                DropdownButtonFormField<String>(
                  value: _selectedLandType,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.landscape_rounded, size: 18),
                  ),
                  items: const [
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
                    if (val != null) setState(() => _selectedLandType = val);
                  },
                ),
                const SizedBox(height: 14),

                _label('Operational Grid Status *'),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.power_settings_new_rounded, size: 18),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Active', child: Text('Active Grid Node')),
                    DropdownMenuItem(value: 'Inactive', child: Text('Inactive Node')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Section: Geographic Hierarchy ───────────────────────
            _formSection(
              title: 'GEOGRAPHIC & ADMINISTRATIVE LOCATION',
              icon: Icons.location_on_outlined,
              children: [
                _label('District *'),
                Builder(
                  builder: (context) {
                    final items = _availableDistricts;
                    final effective = items.any((d) => d.toLowerCase() == _selectedDistrict.toLowerCase())
                        ? items.firstWhere((d) => d.toLowerCase() == _selectedDistrict.toLowerCase())
                        : (_selectedDistrict.isNotEmpty ? _selectedDistrict : (items.isNotEmpty ? items.first : 'North Goa'));
                    final allItems = items.contains(effective) ? items : [effective, ...items];
                    return DropdownButtonFormField<String>(
                      key: ValueKey('district_$effective'),
                      value: effective,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.map_outlined, size: 18),
                      ),
                      items: allItems
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: _onDistrictChanged,
                    );
                  },
                ),
                const SizedBox(height: 14),

                _label('Taluka *'),
                Builder(
                  builder: (context) {
                    final items = _availableTalukas;
                    final effective = items.any((t) => t.toLowerCase() == _selectedTaluka.toLowerCase())
                        ? items.firstWhere((t) => t.toLowerCase() == _selectedTaluka.toLowerCase())
                        : (_selectedTaluka.isNotEmpty ? _selectedTaluka : (items.isNotEmpty ? items.first : 'Tiswadi'));
                    final allItems = items.contains(effective) ? items : [effective, ...items];
                    return DropdownButtonFormField<String>(
                      key: ValueKey('taluka_${_selectedDistrict}_$effective'),
                      value: effective,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.explore_outlined, size: 18),
                      ),
                      items: allItems
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: _onTalukaChanged,
                    );
                  },
                ),
                const SizedBox(height: 14),

                _label('Constituency *'),
                Builder(
                  builder: (context) {
                    final items = _availableConstituencies;
                    final effective = items.any((c) => c.toLowerCase() == _selectedConstituency.toLowerCase())
                        ? items.firstWhere((c) => c.toLowerCase() == _selectedConstituency.toLowerCase())
                        : (_selectedConstituency.isNotEmpty ? _selectedConstituency : (items.isNotEmpty ? items.first : 'Panaji'));
                    final allItems = items.contains(effective) ? items : [effective, ...items];
                    return DropdownButtonFormField<String>(
                      key: ValueKey('constituency_${_selectedTaluka}_$effective'),
                      value: effective,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.how_to_vote_outlined, size: 18),
                      ),
                      items: allItems
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: _onConstituencyChanged,
                    );
                  },
                ),
                const SizedBox(height: 14),

                _label('Area / Panchayat *'),
                Builder(
                  builder: (context) {
                    final items = _availableAreas;
                    final effective = items.any((a) => a.toLowerCase() == _selectedArea.toLowerCase())
                        ? items.firstWhere((a) => a.toLowerCase() == _selectedArea.toLowerCase())
                        : (_selectedArea.isNotEmpty ? _selectedArea : (items.isNotEmpty ? items.first : 'Panaji City'));
                    final allItems = items.contains(effective) ? items : [effective, ...items];
                    return DropdownButtonFormField<String>(
                      key: ValueKey('area_${_selectedConstituency}_$effective'),
                      value: effective,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.pin_drop_outlined, size: 18),
                      ),
                      items: allItems
                          .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: _onAreaChanged,
                    );
                  },
                ),
                const SizedBox(height: 14),

                _label('Full Site Address / Landmark *'),
                TextFormField(
                  controller: _addressCtrl,
                  maxLines: 2,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Enter complete installation site address',
                    prefixIcon: Icon(Icons.home_work_outlined, size: 18),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Address is required' : null,
                ),
                const SizedBox(height: 14),

                // ── Exact GIS Map Coordinates Section (Matching Web Towers.jsx) ──
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Exact GIS Coordinates (GPS)',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.my_location, size: 13, color: AppColors.primary),
                            label: Text(
                              'Auto-fill from Area/Address',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            onPressed: _autoFillCoordinates,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Latitude (°N)'),
                                TextFormField(
                                  controller: _latitudeCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. 15.40182',
                                    prefixIcon: Icon(Icons.explore_outlined, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Longitude (°E)'),
                                TextFormField(
                                  controller: _longitudeCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. 74.01525',
                                    prefixIcon: Icon(Icons.explore_outlined, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Section: Technical Specifications ───────────────────
            _formSection(
              title: 'TECHNICAL SPECIFICATIONS',
              icon: Icons.engineering_outlined,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _labelWithUnit(
                            label: 'Height *',
                            currentUnit: _heightUnit,
                            onUnitChanged: _setHeightUnit,
                          ),
                          TextFormField(
                            controller: _heightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.poppins(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: _heightUnit == 'm' ? 'e.g. 35.0' : 'e.g. 114.8',
                              suffixText: _heightUnit,
                              suffixStyle: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: AppColors.cyanAccent,
                              ),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Height is required'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _labelWithUnit(
                            label: 'Width / Base *',
                            currentUnit: _widthUnit,
                            onUnitChanged: _setWidthUnit,
                          ),
                          TextFormField(
                            controller: _widthCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.poppins(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: _widthUnit == 'm' ? 'e.g. 2.5' : 'e.g. 8.2',
                              suffixText: _widthUnit,
                              suffixStyle: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: AppColors.cyanAccent,
                              ),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Width is required'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _label('Operating Frequency Bands *'),
                TextFormField(
                  controller: _frequencyCtrl,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 1800 MHz, 2100 MHz, 5G Sub-6',
                    prefixIcon: Icon(Icons.wifi_tethering_rounded, size: 18),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Frequency band is required'
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Section: Financial & Rent Terms (Yearly & Cycles) ───
            _formSection(
              title: 'FINANCIAL & LEASE TERMS (YEARLY RENT)',
              icon: Icons.currency_rupee_rounded,
              children: [
                _label('Yearly Rent Amount (₹) *'),
                TextFormField(
                  controller: _yearlyRentCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 60000',
                    prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Yearly rent is required'
                      : null,
                ),
                const SizedBox(height: 14),

                _label('Rent Cycle Selection *'),
                DropdownButtonFormField<int>(
                  value: _selectedYearCycle,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 Year Cycle')),
                    DropdownMenuItem(value: 5, child: Text('5 Years Cycle')),
                    DropdownMenuItem(value: 10, child: Text('10 Years Cycle')),
                    DropdownMenuItem(value: 15, child: Text('15 Years Cycle')),
                    DropdownMenuItem(value: 20, child: Text('20 Years Cycle')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedYearCycle = val);
                  },
                ),
                const SizedBox(height: 12),

                // Calculated Total Cycle Amount Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurf(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calculated Total Amount',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSec(context),
                            ),
                          ),
                          Text(
                            'Yearly Rent × $_selectedYearCycle Years',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: AppColors.textMut(context),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${totalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Section: Operators Using Tower ──────────────────────
            _formSection(
              title: 'OPERATORS USING THIS TOWER',
              icon: Icons.cell_wifi_rounded,
              children: [
                Text(
                  'Select all licensed telecom operators sharing this tower node:',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: AppColors.textSec(context),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allOperators.map((op) {
                    final id = op['id'] as int;
                    final name = op['name'] as String;
                    final isSelected = _selectedOperatorIds.contains(id);

                    return FilterChip(
                      selected: isSelected,
                      label: Text(name),
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : AppColors.textPri(context),
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.cardBg(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.borderCol(context),
                        ),
                      ),
                      onSelected: (_) => _toggleOperator(id),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Submit Button ───────────────────────────────────────
            MTMMSButton(
              text: widget.isEditing ? 'Save Changes' : 'Register Tower in Grid',
              icon: Icons.check_circle_outline_rounded,
              isLoading: _isSaving,
              onPressed: _save,
              height: 50,
            ),
          ],
        ),
      ),
    );
  }

  Widget _formSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return MTMMSCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MTMMSSectionHeader(title: title, icon: icon),
          const SizedBox(height: 8),
          Divider(height: 1, color: AppColors.dividerCol(context)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPri(context),
        ),
      ),
    );
  }

  Widget _labelWithUnit({
    required String label,
    required String currentUnit,
    required Function(String) onUnitChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPri(context),
            ),
          ),
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderCol(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _unitButton(
                  title: 'm',
                  isSelected: currentUnit == 'm',
                  onTap: () => onUnitChanged('m'),
                ),
                Container(
                  width: 1,
                  height: 14,
                  color: AppColors.borderCol(context),
                ),
                _unitButton(
                  title: 'ft',
                  isSelected: currentUnit == 'ft',
                  onTap: () => onUnitChanged('ft'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyanAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.black87 : AppColors.textSec(context),
          ),
        ),
      ),
    );
  }
}
