import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Centralized Geographic & Administrative Hierarchy Service for Goa.
/// Manages cascading relationships: District -> Taluka -> Constituency -> Area / Panchayat.
class LocationService {
  LocationService._();

  // ── Default Districts ───────────────────────────────────────────
  static const List<String> defaultDistricts = [
    'North Goa',
    'South Goa',
  ];

  // ── Default Talukas by District ─────────────────────────────────
  static const Map<String, List<String>> defaultTalukasByDistrict = {
    'North Goa': [
      'Bardez',
      'Bicholim',
      'Pernem',
      'Sattari',
      'Tiswadi',
    ],
    'South Goa': [
      'Canacona',
      'Dharbandora',
      'Mormugao',
      'Ponda',
      'Quepem',
      'Salcete',
      'Sanguem',
    ],
  };

  // ── Default Constituencies by Taluka ────────────────────────────
  static const Map<String, List<String>> defaultConstituenciesByTaluka = {
    'Tiswadi': ['Panaji', 'Taleigao', 'Santa Cruz', 'St. Andre', 'Cumbarjua'],
    'Bardez': ['Mapusa', 'Calangute', 'Saligao', 'Porvorim', 'Aldona', 'Siolim', 'Tivim'],
    'Pernem': ['Pernem', 'Mandrem'],
    'Bicholim': ['Bicholim', 'Mayem', 'Sanquelim'],
    'Sattari': ['Valpoi', 'Poriem'],
    'Salcete': ['Margao', 'Fatorda', 'Navelim', 'Curtorim', 'Benaulim', 'Velim', 'Nuvem', 'Cuncolim'],
    'Mormugao': ['Vasco da Gama', 'Dabolim', 'Cortalim', 'Mormugao'],
    'Ponda': ['Ponda', 'Marcaim', 'Shiroda', 'Priol'],
    'Quepem': ['Quepem', 'Curchorem'],
    'Canacona': ['Canacona'],
    'Sanguem': ['Sanguem'],
    'Dharbandora': ['Sanvordem'],
  };

  // ── Default Areas / Panchayats by Constituency ──────────────────
  static const Map<String, List<String>> defaultAreasByConstituency = {
    // Tiswadi
    'Panaji': ['Panaji City', 'Altinho', 'Miramar', 'Campal', 'Fontainhas', 'Ribandar', 'Patto Plaza'],
    'Taleigao': ['Taleigao Village', 'Dona Paula', 'Caranzalem', 'Odxel', 'Nagali'],
    'Santa Cruz': ['Santa Cruz Village', 'Merces', 'Chimbel', 'Bambolim', 'Indiranagar'],
    'St. Andre': ['Goa Velha', 'Batim', 'Agassaim', 'Neura', 'Siridao', 'Curca'],
    'Cumbarjua': ['Cumbarjua', 'Corlim', 'Old Goa', 'Carambolim', 'Sao Mathias'],

    // Bardez
    'Mapusa': ['Mapusa Town', 'Khorlim', 'Ganeshpuri', 'Duler', 'Ansabhat', 'Morod'],
    'Calangute': ['Calangute Beach', 'Candolim', 'Arpora', 'Nagoa', 'Baga'],
    'Saligao': ['Saligao Village', 'Sangolda', 'Pilerne', 'Guirim', 'Marra'],
    'Porvorim': ['Porvorim Alto', 'Socorro', 'Salvador do Mundo', 'Penha de Franca'],
    'Aldona': ['Aldona Village', 'Corjuem', 'Moira', 'Nachinola', 'Pomburpa'],
    'Siolim': ['Siolim', 'Anjuna', 'Vagator', 'Oxel', 'Assagao'],
    'Tivim': ['Tivim', 'Colvale', 'Assonora', 'Sirsaim', 'Camurlim'],

    // Pernem
    'Pernem': ['Pernem Town', 'Tuem', 'Dhargal', 'Korgao', 'Torxem', 'Mopa'],
    'Mandrem': ['Mandrem', 'Morjim', 'Arambol', 'Ashwem', 'Keri'],

    // Bicholim
    'Bicholim': ['Bicholim Town', 'Piligao', 'Kudne', 'Shirgao', 'Mulgao'],
    'Mayem': ['Mayem Village', 'Chorao', 'Vanxim', 'Narva'],
    'Sanquelim': ['Sanquelim Town', 'Karapur', 'Sarvona', 'Pale', 'Velguem', 'Amona'],

    // Sattari
    'Valpoi': ['Valpoi Town', 'Honda', 'Thane', 'Massordem', 'Mauxi'],
    'Poriem': ['Poriem', 'Keri', 'Morlem', 'Pissurlem', 'Querim', 'Guleli'],

    // Salcete
    'Margao': ['Margao City', 'Aquem', 'Comba', 'Pajifond', 'Gogol', 'Madgaon'],
    'Fatorda': ['Fatorda Stadium Area', 'Borda', 'Madel', 'Chandrawado', 'Ambaji'],
    'Navelim': ['Navelim', 'Aquem Baixo', 'Telaulim', 'Davorlim', 'Dicarpale'],
    'Curtorim': ['Curtorim', 'Macasana', 'Guirdolim', 'Chandor', 'Maina'],
    'Benaulim': ['Benaulim', 'Colva', 'Seraulim', 'Betalbatim', 'Varca', 'Orlim', 'Cavelossim'],
    'Velim': ['Velim', 'Assolna', 'Ambelim', 'Chinchinim', 'Mobor'],
    'Nuvem': ['Nuvem', 'Majorda', 'Utorda', 'Calata'],
    'Cuncolim': ['Cuncolim Town', 'Balli', 'Fatorpa', 'Ambaulim', 'Panzorconi'],

    // Mormugao
    'Vasco da Gama': ['Vasco City', 'Mhadei', 'Baina', 'Chicalim', 'Bogda', 'Headland Sada'],
    'Dabolim': ['Dabolim', 'Sancoale', 'Bogmalo', 'Airport Area'],
    'Cortalim': ['Cortalim', 'Quelossim', 'Cansaulim', 'Arossim', 'Velsao'],
    'Mormugao': ['Mormugao Harbour', 'Sada', 'Harbour Area'],

    // Ponda
    'Ponda': ['Ponda City', 'Curti', 'Khandepar', 'Tisk', 'Bethora'],
    'Marcaim': ['Marcaim', 'Kundaim', 'Tiwim', 'Borim'],
    'Shiroda': ['Shiroda', 'Panchawadi', 'Nirankal'],
    'Priol': ['Priol', 'Mardol', 'Veling', 'Bandora', 'Mangueshi'],

    // Quepem
    'Quepem': ['Quepem Town', 'Tilamol', 'Paroda', 'Avedem'],
    'Curchorem': ['Curchorem Town', 'Sanvordem', 'Cacora', 'Pontemol'],

    // Canacona
    'Canacona': ['Canacona Town', 'Chaudi', 'Palolem', 'Agonda', 'Poinguinim', 'Loliem'],

    // Sanguem
    'Sanguem': ['Sanguem Town', 'Netravali', 'Rivona', 'Curdi', 'Bhati', 'Uguem'],

    // Dharbandora
    'Sanvordem': ['Sanvordem', 'Dharbandora', 'Colem', 'Mollem', 'Kirlapal'],
  };

  // ── Dynamic State / Cache ───────────────────────────────────────
  static final List<String> _districts = List.from(defaultDistricts);
  static final Map<String, List<String>> _talukasByDistrict =
      defaultTalukasByDistrict.map((k, v) => MapEntry(k, List.from(v)));
  static final Map<String, List<String>> _constituenciesByTaluka =
      defaultConstituenciesByTaluka.map((k, v) => MapEntry(k, List.from(v)));
  static final Map<String, List<String>> _areasByConstituency =
      defaultAreasByConstituency.map((k, v) => MapEntry(k, List.from(v)));

  static List<Map<String, dynamic>> _rawDistricts = [];
  static List<Map<String, dynamic>> _rawTalukas = [];
  static List<Map<String, dynamic>> _rawConstituencies = [];
  static List<Map<String, dynamic>> _rawAreas = [];

  static List<Map<String, dynamic>> get rawDistricts => _rawDistricts;
  static List<Map<String, dynamic>> get rawTalukas => _rawTalukas;
  static List<Map<String, dynamic>> get rawConstituencies => _rawConstituencies;
  static List<Map<String, dynamic>> get rawAreas => _rawAreas;

  static bool _isLoaded = false;
  static bool get isLoaded => _isLoaded;

  /// Loads hierarchy from backend API and merges it seamlessly with static data.
  static Future<void> loadHierarchy() async {
    try {
      final results = await Future.wait([
        ApiService.getDistrictsRaw(),
        ApiService.getTalukasRaw(),
        ApiService.getConstituenciesRaw(),
        ApiService.getAreasRaw(),
      ]);

      final dists = results[0];
      final tals = results[1];
      final consts = results[2];
      final ars = results[3];

      if (dists.isNotEmpty || tals.isNotEmpty || consts.isNotEmpty || ars.isNotEmpty) {
        setHierarchy(
          rawDistricts: dists,
          rawTalukas: tals,
          rawConstituencies: consts,
          rawAreas: ars,
        );
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('LocationService.loadHierarchy error: $e');
    }
  }

  /// Sets raw hierarchy data and re-indexes maps.
  static void setHierarchy({
    List<Map<String, dynamic>>? rawDistricts,
    List<Map<String, dynamic>>? rawTalukas,
    List<Map<String, dynamic>>? rawConstituencies,
    List<Map<String, dynamic>>? rawAreas,
  }) {
    if (rawDistricts != null && rawDistricts.isNotEmpty) {
      _rawDistricts = rawDistricts;
      final distNames = rawDistricts
          .map((d) => d['name']?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      for (final d in distNames) {
        if (!_districts.any((x) => x.toLowerCase() == d.toLowerCase())) {
          _districts.add(d);
        }
      }
    }

    if (rawTalukas != null && rawTalukas.isNotEmpty) {
      _rawTalukas = rawTalukas;
      for (final t in rawTalukas) {
        final tName = t['name']?.toString().trim() ?? '';
        final dName = t['district_name']?.toString().trim() ?? '';
        if (tName.isEmpty) continue;

        String targetDist = _matchDistrict(dName) ?? getDistrictForTaluka(tName) ?? 'North Goa';
        _talukasByDistrict.putIfAbsent(targetDist, () => []);
        if (!_talukasByDistrict[targetDist]!.any((x) => x.toLowerCase() == tName.toLowerCase())) {
          _talukasByDistrict[targetDist]!.add(tName);
        }
      }
    }

    if (rawConstituencies != null && rawConstituencies.isNotEmpty) {
      _rawConstituencies = rawConstituencies;
      for (final c in rawConstituencies) {
        final cName = c['name']?.toString().trim() ?? '';
        if (cName.isEmpty) continue;

        String? taluka = getTalukaForConstituency(cName);
        if (taluka != null) {
          _constituenciesByTaluka.putIfAbsent(taluka, () => []);
          if (!_constituenciesByTaluka[taluka]!.any((x) => x.toLowerCase() == cName.toLowerCase())) {
            _constituenciesByTaluka[taluka]!.add(cName);
          }
        }
      }
    }

    if (rawAreas != null && rawAreas.isNotEmpty) {
      _rawAreas = rawAreas;
      for (final a in rawAreas) {
        final aName = a['name']?.toString().trim() ?? '';
        final tName = a['taluka_name']?.toString().trim() ??
            (a['taluka'] is Map ? a['taluka']['name']?.toString().trim() : '') ??
            '';
        if (aName.isEmpty) continue;

        // Try mapping area into its constituency or taluka
        String? targetConstituency;
        if (tName.isNotEmpty) {
          final consts = _constituenciesByTaluka[tName] ?? [];
          if (consts.isNotEmpty) {
            targetConstituency = consts.first;
          }
        }
        targetConstituency ??= getConstituencyForArea(aName) ?? 'Panaji';

        _areasByConstituency.putIfAbsent(targetConstituency, () => []);
        if (!_areasByConstituency[targetConstituency]!.any((x) => x.toLowerCase() == aName.toLowerCase())) {
          _areasByConstituency[targetConstituency]!.add(aName);
        }
      }
    }
  }

  // ── Query Methods ───────────────────────────────────────────────

  /// Gets list of districts.
  static List<String> getDistricts() {
    return List.unmodifiable(_districts);
  }

  /// Gets talukas filtered by district.
  static List<String> getTalukas({String? district}) {
    if (district == null || district.trim().isEmpty) {
      final all = <String>{};
      for (final list in _talukasByDistrict.values) {
        all.addAll(list);
      }
      return all.toList()..sort();
    }

    final matchedKey = _talukasByDistrict.keys.firstWhere(
      (k) => k.toLowerCase() == district.toLowerCase().trim(),
      orElse: () => '',
    );
    if (matchedKey.isNotEmpty) {
      return List.from(_talukasByDistrict[matchedKey] ?? [])..sort();
    }

    return [];
  }

  /// Gets constituencies filtered by district and/or taluka.
  static List<String> getConstituencies({String? district, String? taluka}) {
    if (taluka != null && taluka.trim().isNotEmpty) {
      final matchedKey = _constituenciesByTaluka.keys.firstWhere(
        (k) => k.toLowerCase() == taluka.toLowerCase().trim(),
        orElse: () => '',
      );
      if (matchedKey.isNotEmpty) {
        return List.from(_constituenciesByTaluka[matchedKey] ?? [])..sort();
      }
      return [];
    }

    if (district != null && district.trim().isNotEmpty) {
      final talukasInDistrict = getTalukas(district: district);
      final results = <String>{};
      for (final t in talukasInDistrict) {
        final list = _constituenciesByTaluka[t] ?? [];
        results.addAll(list);
      }
      return results.toList()..sort();
    }

    final all = <String>{};
    for (final list in _constituenciesByTaluka.values) {
      all.addAll(list);
    }
    return all.toList()..sort();
  }

  /// Gets areas/panchayats filtered by district, taluka, and/or constituency.
  static List<String> getAreas({String? district, String? taluka, String? constituency}) {
    if (constituency != null && constituency.trim().isNotEmpty) {
      final matchedKey = _areasByConstituency.keys.firstWhere(
        (k) => k.toLowerCase() == constituency.toLowerCase().trim(),
        orElse: () => '',
      );
      if (matchedKey.isNotEmpty) {
        return List.from(_areasByConstituency[matchedKey] ?? [])..sort();
      }
    }

    if (taluka != null && taluka.trim().isNotEmpty) {
      final constsInTaluka = getConstituencies(taluka: taluka);
      final results = <String>{};
      for (final c in constsInTaluka) {
        final list = _areasByConstituency[c] ?? [];
        results.addAll(list);
      }
      // Also check raw areas for direct taluka match
      for (final a in _rawAreas) {
        final tName = a['taluka_name']?.toString() ??
            (a['taluka'] is Map ? a['taluka']['name']?.toString() : '');
        if (tName != null && tName.toLowerCase().trim() == taluka.toLowerCase().trim()) {
          final name = a['name']?.toString();
          if (name != null && name.isNotEmpty) results.add(name);
        }
      }
      if (results.isNotEmpty) return results.toList()..sort();
    }

    if (district != null && district.trim().isNotEmpty) {
      final talukasInDistrict = getTalukas(district: district);
      final results = <String>{};
      for (final t in talukasInDistrict) {
        final areas = getAreas(taluka: t);
        results.addAll(areas);
      }
      if (results.isNotEmpty) return results.toList()..sort();
    }

    final all = <String>{};
    for (final list in _areasByConstituency.values) {
      all.addAll(list);
    }
    for (final a in _rawAreas) {
      final name = a['name']?.toString();
      if (name != null && name.isNotEmpty) all.add(name);
    }
    return all.toList()..sort();
  }

  // ── Reverse Resolution Helpers ─────────────────────────────────

  /// Resolves district for a given taluka.
  static String? getDistrictForTaluka(String taluka) {
    final lower = taluka.toLowerCase().trim();
    // 1. Check raw talukas from API
    for (final t in _rawTalukas) {
      if (t['name']?.toString().toLowerCase().trim() == lower) {
        final d = t['district_name']?.toString();
        if (d != null && d.isNotEmpty) return d;
      }
    }
    // 2. Check static hierarchy
    for (final entry in _talukasByDistrict.entries) {
      if (entry.value.any((t) => t.toLowerCase() == lower)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Resolves taluka for a given constituency.
  static String? getTalukaForConstituency(String constituency) {
    final lower = constituency.toLowerCase().trim();
    for (final entry in _constituenciesByTaluka.entries) {
      if (entry.value.any((c) => c.toLowerCase() == lower)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Resolves constituency for a given area.
  static String? getConstituencyForArea(String area) {
    final lower = area.toLowerCase().trim();
    for (final entry in _areasByConstituency.entries) {
      if (entry.value.any((a) => a.toLowerCase() == lower || lower.contains(a.toLowerCase()))) {
        return entry.key;
      }
    }
    return null;
  }

  /// Resolves taluka for a given area.
  static String? getTalukaForArea(String area) {
    final lower = area.toLowerCase().trim();
    // 1. Check raw areas from API
    for (final a in _rawAreas) {
      if (a['name']?.toString().toLowerCase().trim() == lower) {
        final t = a['taluka_name']?.toString() ??
            (a['taluka'] is Map ? a['taluka']['name']?.toString() : null);
        if (t != null && t.isNotEmpty) return t;
      }
    }
    // 2. Check via constituency
    final constituency = getConstituencyForArea(area);
    if (constituency != null) {
      return getTalukaForConstituency(constituency);
    }
    return null;
  }

  /// Finds database ID for an area name.
  static int? getAreaId(String areaName) {
    if (areaName.trim().isEmpty) return null;
    final lower = areaName.toLowerCase().trim();
    for (final a in _rawAreas) {
      final name = a['name']?.toString().toLowerCase().trim();
      if (name == lower) {
        final id = a['id'];
        return id is int ? id : int.tryParse(id.toString());
      }
    }
    // Substring fallback
    for (final a in _rawAreas) {
      final name = a['name']?.toString().toLowerCase().trim();
      if (name != null && (name.contains(lower) || lower.contains(name))) {
        final id = a['id'];
        return id is int ? id : int.tryParse(id.toString());
      }
    }
    return null;
  }

  static String? _matchDistrict(String name) {
    final lower = name.toLowerCase().trim();
    for (final d in _districts) {
      if (d.toLowerCase() == lower) return d;
    }
    if (lower.contains('north')) return 'North Goa';
    if (lower.contains('south')) return 'South Goa';
    return null;
  }

  // ── High-Precision Real-World Geographic Coordinates for Goa ──
  static const Map<String, List<double>> kGoaExactLocationCoords = {
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

  /// High-precision coordinate resolution for any given area, address, or taluka.
  static List<double>? findExactCoordinates({
    String? area,
    String? address,
    String? taluka,
  }) {
    final addrLower = (address ?? '').toLowerCase().trim();
    final areaLower = (area ?? '').toLowerCase().trim();
    final talukaLower = (taluka ?? '').toLowerCase().trim();

    // 1. Check detailed address against premise keys
    if (addrLower.isNotEmpty) {
      for (final entry in kGoaExactLocationCoords.entries) {
        if (entry.key.length > 5 && addrLower.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    // 2. Check area name directly
    if (areaLower.isNotEmpty && kGoaExactLocationCoords.containsKey(areaLower)) {
      return kGoaExactLocationCoords[areaLower];
    }

    // 3. Substring match on area name
    if (areaLower.isNotEmpty) {
      for (final entry in kGoaExactLocationCoords.entries) {
        if (areaLower.contains(entry.key) || entry.key.contains(areaLower)) {
          return entry.value;
        }
      }
    }

    // 4. Fallback to taluka
    if (talukaLower.isNotEmpty && kGoaExactLocationCoords.containsKey(talukaLower)) {
      return kGoaExactLocationCoords[talukaLower];
    }

    return null;
  }
}
