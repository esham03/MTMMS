import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';
import 'data_sync_service.dart';
import 'server_discovery_service.dart';

/// Comprehensive, robust API Service for MTMMS (Government of Goa).
///
/// Communicates with the Laravel backend using Sanctum Bearer tokens.
/// All methods return clean, normalized data structures with structured error handling.
class ApiService {
  ApiService._();

  static const Duration timeoutDuration = Duration(seconds: 12);

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Constructs headers with Sanctum Bearer token if logged in.
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // ERROR FORMATTER
  // ============================================================

  static String _formatException(dynamic error) {
    if (error is SocketException) {
      ServerDiscoveryService.checkOrRediscover();
      return 'Unable to connect to the MTMMS server. Please verify you are connected to the same Wi-Fi network.';
    } else if (error is TimeoutException) {
      ServerDiscoveryService.checkOrRediscover();
      return 'Connection timed out. MTMMS server took too long to respond.';
    } else if (error is HttpException) {
      return 'MTMMS server is currently unavailable.';
    } else if (error is FormatException) {
      return 'Invalid server response format.';
    }
    return error.toString();
  }

  // ============================================================
  // 1. AUTHENTICATION (LOGIN / LOGOUT)
  // ============================================================

  /// Calls POST /api/auth/login with real Laravel backend.
  static Future<Map<String, dynamic>> login(
    String emailOrUsername,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.login),
            headers: defaultHeaders,
            body: jsonEncode({
              'email': emailOrUsername.trim(),
              'password': password,
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final token = decoded['token'] as String?;
        final user = decoded['user'] as Map<String, dynamic>?;

        if (token != null) {
          await AuthService.saveToken(token);
          if (user != null) {
            await AuthService.saveUser(user);
          }
          return decoded;
        }
      }

      // Parse validation error or custom error message
      if (response.statusCode == 422 || response.statusCode == 401) {
        try {
          final body = jsonDecode(response.body);
          if (body['errors'] is Map && (body['errors'] as Map).isNotEmpty) {
            final firstList = (body['errors'] as Map).values.first;
            if (firstList is List && firstList.isNotEmpty) {
              throw firstList.first.toString();
            }
          }
          if (body['message'] != null) {
            throw body['message'].toString();
          }
        } catch (e) {
          if (e is String) rethrow;
        }
        throw 'Invalid credentials. Please verify your official email/username and password.';
      }

      if (response.statusCode >= 500) {
        throw 'An unexpected server error occurred (${response.statusCode}). Please contact IT Administrator.';
      }

      throw 'Login failed with status code ${response.statusCode}.';
    } catch (e) {
      if (e is String) rethrow;
      throw _formatException(e);
    }
  }

  /// Calls POST /api/auth/logout to revoke the Sanctum token.
  static Future<void> logout() async {
    try {
      final headers = await _authHeaders();
      await http
          .post(Uri.parse(ApiConfig.logout), headers: headers)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
    } finally {
      await AuthService.logout();
    }
  }

  // ============================================================
  // 2. CONNECTIVITY TEST
  // ============================================================

  /// Tests connectivity to the MTMMS server without hanging.
  static Future<bool> testConnection() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.dashboard), headers: headers)
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200 ||
          response.statusCode == 401 ||
          response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // 3. DASHBOARD
  // GET /api/dashboard
  // ============================================================

  static Future<Map<String, dynamic>> getDashboard() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.dashboard), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final rawData = decoded['data'] ?? decoded;

          if (rawData is Map<String, dynamic>) {
            final districtWise = rawData['district_wise'];

            int northGoaTowers = 0;
            int southGoaTowers = 0;

            if (districtWise is List) {
              for (final item in districtWise) {
                if (item is Map) {
                  final district =
                      item['district']?.toString().toLowerCase() ?? '';
                  final count = (item['tower_count'] as num?)?.toInt() ?? 0;

                  if (district.contains('north')) {
                    northGoaTowers += count;
                  } else if (district.contains('south')) {
                    southGoaTowers += count;
                  }
                }
              }
            }

            return {
              'totalTowers': (rawData['total_towers'] as num?)?.toInt() ?? 0,
              'govtTowers':
                  (rawData['government_towers'] as num?)?.toInt() ?? 0,
              'governmentTowers':
                  (rawData['government_towers'] as num?)?.toInt() ?? 0,
              'privateTowers': (rawData['private_towers'] as num?)?.toInt() ?? 0,
              'activeTowers': (rawData['active_towers'] as num?)?.toInt() ?? 0,
              'inactiveTowers':
                  (rawData['inactive_towers'] as num?)?.toInt() ?? 0,
              'totalOperators':
                  (rawData['total_operators'] as num?)?.toInt() ?? 0,
              'rentDue': (rawData['rent_due'] as num?)?.toInt() ?? 0,
              'rentCollected':
                  (rawData['rent_collected'] as num?)?.toDouble() ?? 0.0,
              'pendingPayments':
                  (rawData['pending_payments'] as num?)?.toInt() ?? 0,
              'northGoaTowers': northGoaTowers,
              'southGoaTowers': southGoaTowers,
              'districtWise': districtWise ?? [],
              'talukaWise': rawData['taluka_wise'] ?? [],
              'operatorWise': rawData['operator_wise'] ?? [],
            };
          }
        }
      }
    } catch (e) {
      debugPrint('ApiService.getDashboard error: $e');
    }

    return {
      'totalTowers': 0,
      'govtTowers': 0,
      'governmentTowers': 0,
      'privateTowers': 0,
      'activeTowers': 0,
      'inactiveTowers': 0,
      'totalOperators': 0,
      'rentDue': 0,
      'rentCollected': 0.0,
      'pendingPayments': 0,
      'northGoaTowers': 0,
      'southGoaTowers': 0,
      'districtWise': [],
      'talukaWise': [],
      'operatorWise': [],
    };
  }

  // ============================================================
  // 4. TOWERS
  // GET /api/towers
  // ============================================================

  static Future<List<Map<String, dynamic>>> getTowers({
    String? search,
    String? districtId,
    String? constituencyId,
    String? talukaId,
    String? areaId,
    String? landType,
    String? status,
    String? operatorId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (districtId != null && districtId.isNotEmpty) {
        queryParams['district_id'] = districtId;
      }
      if (constituencyId != null && constituencyId.isNotEmpty) {
        queryParams['constituency_id'] = constituencyId;
      }
      if (talukaId != null && talukaId.isNotEmpty) {
        queryParams['taluka_id'] = talukaId;
      }
      if (areaId != null && areaId.isNotEmpty) {
        queryParams['area_id'] = areaId;
      }
      if (landType != null && landType.isNotEmpty && landType != 'All' && landType != 'All Land Types') {
        queryParams['land_type'] = landType.toLowerCase();
      }
      if (status != null && status.isNotEmpty && status != 'All' && status != 'All Status') {
        queryParams['status'] = status.toLowerCase();
      }
      if (operatorId != null && operatorId.isNotEmpty && operatorId != 'All' && operatorId != 'All Operators') {
        queryParams['operator_id'] = operatorId;
      }
      queryParams['all'] = 'true';

      final uri = Uri.parse(ApiConfig.towers).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final headers = await _authHeaders();
      final response = await http.get(uri, headers: headers).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final raw = _extractList(decoded);
        return raw.map((t) => _normaliseTower(t)).toList();
      }
    } catch (e) {
      debugPrint('ApiService.getTowers error: $e');
    }

    return [];
  }

  /// Normalises a raw Laravel Tower entity into standard UI fields.
  static Map<String, dynamic> _normaliseTower(Map<String, dynamic> t) {
    // ── Location Hierarchy ────────────────────────────────────
    final area = t['area'] as Map?;
    final taluka = area?['taluka'] as Map? ??
        (t['taluka'] is Map ? t['taluka'] as Map : null);
    final constituency = taluka?['constituency'] as Map? ??
        (t['constituency'] is Map ? t['constituency'] as Map : null);
    final district = constituency?['district'] as Map? ??
        (t['district'] is Map ? t['district'] as Map : null);

    final areaName = area?['name']?.toString() ??
        (t['area'] is String ? t['area'].toString() : null) ??
        t['address']?.toString() ??
        'Panaji';
    final talukaName = taluka?['name']?.toString() ??
        (t['taluka'] is String ? t['taluka'].toString() : null) ??
        'Tiswadi';
    final constituencyName = constituency?['name']?.toString() ??
        (t['constituency'] is String ? t['constituency'].toString() : null) ??
        'Panaji';
    final districtName = district?['name']?.toString() ??
        (t['district'] is String ? t['district'].toString() : null) ??
        'North Goa';

    // ── Unified Owner ─────────────────────────────────────────
    final owner = t['owner'] as Map?;
    final ownerName = owner?['name']?.toString() ??
        (t['owner'] is String ? t['owner'].toString() : null) ??
        'Government of Goa';
    final ownerPhone = owner?['phone']?.toString() ??
        (t['owner_phone']?.toString() ?? '—');
    final ownerEmail = owner?['email']?.toString() ??
        (t['owner_email']?.toString() ?? '—');
    final ownerAddress = owner?['address']?.toString() ??
        (t['owner_address']?.toString() ?? 'Goa');

    // ── Operators ─────────────────────────────────────────────
    final opsList = t['operators'];
    String operatorDisplay = 'None';
    String operatorsCount = '0';
    final List<Map<String, dynamic>> operatorsDetails = [];

    if (opsList is List && opsList.isNotEmpty) {
      final names = <String>[];
      for (final op in opsList) {
        if (op is Map) {
          final sName = op['short_name']?.toString() ??
              op['name']?.toString() ??
              '';
          if (sName.isNotEmpty) names.add(sName);
          operatorsDetails.add({
            'name': op['name']?.toString() ?? 'Operator',
            'shortName': sName,
            'frequency': op['frequency']?.toString() ?? '1800 MHz',
            'status': op['status']?.toString() ?? 'Active',
          });
        } else if (op is String && op.isNotEmpty) {
          names.add(op);
        }
      }

      operatorDisplay = names.isNotEmpty ? names.first : 'None';
      operatorsCount =
          '${names.isNotEmpty ? names.length : opsList.length} operator${(names.length == 1 || opsList.length == 1) ? '' : 's'}';
    } else if (t['operator'] != null && t['operator'].toString().isNotEmpty) {
      operatorDisplay = t['operator'].toString();
      operatorsCount = '1 operator';
    }

    // ── Land type ─────────────────────────────────────────────
    final rawLand = t['land_type']?.toString() ??
        t['land']?.toString() ??
        'government';
    final land = rawLand.isNotEmpty
        ? rawLand[0].toUpperCase() + rawLand.substring(1).toLowerCase()
        : 'Government';

    // ── Rent & Financial Terms ────────────────────────────────
    final yearlyRentNum = (t['yearly_rent'] as num?)?.toDouble() ??
        double.tryParse(t['yearly_rent']?.toString() ?? '') ??
        (t['yearlyRent'] as num?)?.toDouble() ??
        double.tryParse(t['yearlyRent']?.toString() ?? '') ??
        60000.0;

    final rentCycleYears = (t['rent_cycle_years'] as num?)?.toInt() ??
        int.tryParse(t['rent_cycle_years']?.toString() ?? '5') ??
        5;

    final totalCycleAmount = yearlyRentNum * rentCycleYears;

    // ── Status / Rent badge ───────────────────────────────────
    final rawStatus = t['status']?.toString().toLowerCase() ?? 'active';
    String rentStatus = 'Paid';
    final rentDueDateStr = t['rent_due_date']?.toString();
    if (rentDueDateStr != null && rentDueDateStr.isNotEmpty) {
      try {
        final dueDate = DateTime.parse(rentDueDateStr);
        if (dueDate.isBefore(DateTime.now())) {
          rentStatus = 'Due';
        }
      } catch (_) {}
    }
    if (rawStatus == 'inactive') rentStatus = 'Inactive';
    if (t['rent'] != null) {
      final rStr = t['rent'].toString();
      if (rStr.toLowerCase() == 'due' || rStr.toLowerCase() == 'overdue') {
        rentStatus = 'Due';
      }
    }

    // ── Dimensions ────────────────────────────────────────────
    final height = t['height']?.toString() ?? '30';
    final width = t['width']?.toString() ?? '2.5';
    final frequency = t['frequency']?.toString() ?? '1800 MHz';

    return {
      'id': t['tower_unique_id']?.toString() ??
          (t['id'] != null ? 'TWR-${t['id'].toString().padLeft(4, '0')}' : 'TWR-0000'),
      'towerId': t['tower_unique_id']?.toString() ??
          (t['id'] != null ? 'TWR-${t['id'].toString().padLeft(4, '0')}' : 'TWR-0000'),
      'dbId': t['id']?.toString() ?? '',
      'area': areaName,
      'taluka': talukaName,
      'constituency': constituencyName,
      'district': districtName,
      'owner': ownerName,
      'owner_phone': ownerPhone,
      'owner_email': ownerEmail,
      'owner_address': ownerAddress,
      'operator': operatorDisplay,
      'operators': operatorsCount,
      'operators_list': operatorsDetails,
      'land': land,
      'height': height.endsWith('m') ? height : '${height}m',
      'width': width.endsWith('m') ? width : '${width}m',
      'frequency': frequency,
      'status': rawStatus,
      'rent': rentStatus,
      'yearly_rent': yearlyRentNum.toStringAsFixed(0),
      'yearlyRent': yearlyRentNum.toStringAsFixed(0),
      'rent_cycle_years': rentCycleYears,
      'total_amount': totalCycleAmount.toStringAsFixed(0),
      'rent_due_date': t['rent_due_date']?.toString() ?? '',
      'address': t['address']?.toString() ?? areaName,
      '_raw': t,
    };
  }

  // ============================================================
  // 5. GET SINGLE TOWER DETAILS
  // GET /api/towers/{id}
  // ============================================================

  static Future<Map<String, dynamic>?> getTowerDetails(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.towerDetails(id)), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is Map) {
            return _normaliseTower(Map<String, dynamic>.from(decoded['data']));
          }
          return _normaliseTower(decoded);
        }
      }
    } catch (e) {
      debugPrint('ApiService.getTowerDetails error: $e');
    }
    return null;
  }

  // ============================================================
  // 6. SAVE TOWER (CREATE OR UPDATE)
  // POST /api/towers or PUT /api/towers/{id}
  // ============================================================

  // ============================================================
  // 6. SAVE TOWER (CREATE OR UPDATE)
  // POST /api/towers or PUT /api/towers/{id}
  // ============================================================

  static Future<Map<String, dynamic>> saveTowerWithResult(
    Map<String, dynamic> towerData, {
    bool isEditing = false,
    String? id,
  }) async {
    try {
      final headers = await _authHeaders();
      final url = (isEditing && id != null && id.isNotEmpty)
          ? ApiConfig.towerDetails(id)
          : ApiConfig.towers;

      // Extract or resolve numeric area_id
      dynamic areaId = towerData['area_id'];
      if (areaId == null || areaId.toString().isEmpty) {
        final areaName = towerData['area']?.toString().toLowerCase().trim() ?? '';
        final areasList = await getAreasRaw();
        final match = areasList.firstWhere(
          (a) =>
              a['name']?.toString().toLowerCase().trim() == areaName ||
              a['name']?.toString().toLowerCase().contains(areaName) == true,
          orElse: () => areasList.isNotEmpty ? areasList.first : {'id': 1},
        );
        areaId = match['id'] ?? 1;
      }

      // Extract numeric owner_id if possible
      dynamic ownerId = towerData['owner_id'];
      if (ownerId == null && towerData['owner'] != null) {
        final ownerName =
            towerData['owner']?.toString().toLowerCase().trim() ?? '';
        if (ownerName.isNotEmpty) {
          final ownersList = await getOwners();
          final match = ownersList.firstWhere(
            (o) => o['name']?.toString().toLowerCase().trim() == ownerName,
            orElse: () => <String, dynamic>{},
          );
          if (match.isNotEmpty && match['id'] != null) {
            ownerId = match['id'] is int
                ? match['id']
                : int.tryParse(match['id'].toString());
          }
        }
      }

      // Calculate rent
      final yearlyRent = double.tryParse(
            (towerData['yearlyRent'] ?? towerData['yearly_rent'] ?? '60000')
                .toString()
                .replaceAll('₹', '')
                .replaceAll(',', '')
                .trim(),
          ) ??
          60000.0;
      final monthlyRent = (yearlyRent / 12.0).roundToDouble();

      final rentCycleYears = int.tryParse(
            (towerData['rent_cycle_years'] ?? '5').toString(),
          ) ??
          5;

      final height = double.tryParse(
            (towerData['height'] ?? '30')
                .toString()
                .replaceAll(' m', '')
                .replaceAll('m', '')
                .trim(),
          ) ??
          30.0;

      final width = double.tryParse(
            (towerData['width'] ?? '2.5')
                .toString()
                .replaceAll(' m', '')
                .replaceAll('m', '')
                .trim(),
          ) ??
          2.5;

      // Unique Tower ID
      String towerUid = towerData['tower_unique_id']?.toString() ??
          towerData['id']?.toString() ??
          '';
      if (towerUid.trim().isEmpty) {
        final rand = (DateTime.now().millisecondsSinceEpoch % 9000) + 1000;
        towerUid = 'TWR-GOA-$rand';
      }

      final bodyMap = <String, dynamic>{
        'tower_unique_id': towerUid,
        'area_id': areaId is int ? areaId : (int.tryParse(areaId.toString()) ?? 1),
        if (ownerId != null)
          'owner_id': ownerId is int
              ? ownerId
              : (int.tryParse(ownerId.toString()) ?? 1),
        'land_type': (towerData['land']?.toString().toLowerCase() == 'private')
            ? 'private'
            : 'government',
        'height': height,
        'width': width,
        'frequency': towerData['frequency']?.toString().isNotEmpty == true
            ? towerData['frequency'].toString()
            : '1800 MHz',
        'status': towerData['status']?.toString().toLowerCase() ?? 'active',
        'monthly_rent': monthlyRent,
        'yearly_rent': yearlyRent,
        'rent_cycle_years': rentCycleYears,
        'address': (towerData['address'] != null &&
                towerData['address'].toString().trim().isNotEmpty)
            ? towerData['address'].toString().trim()
            : (towerData['area']?.toString() ?? 'Goa'),
      };

      if (towerData['operator_ids'] is List) {
        bodyMap['operator_ids'] = (towerData['operator_ids'] as List)
            .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
            .where((e) => e > 0)
            .toList();
      }

      final body = jsonEncode(bodyMap);

      final response = isEditing
          ? await http
              .put(Uri.parse(url), headers: headers, body: body)
              .timeout(timeoutDuration)
          : await http
              .post(Uri.parse(url), headers: headers, body: body)
              .timeout(timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        DataSyncService.notifyDataChanged();
        return {'success': true, 'message': 'Tower saved successfully'};
      } else {
        String errorMsg = 'Failed to save tower (Status: ${response.statusCode})';
        try {
          final resData = jsonDecode(response.body);
          if (resData['message'] != null) {
            errorMsg = resData['message'].toString();
          }
          if (resData['errors'] is Map) {
            final errs = (resData['errors'] as Map)
                .values
                .map((v) => v is List ? v.join(', ') : v.toString())
                .join('\n');
            if (errs.isNotEmpty) errorMsg = errs;
          }
        } catch (_) {}
        debugPrint(
            'ApiService.saveTower failed: ${response.statusCode} - ${response.body}');
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      debugPrint('ApiService.saveTower error: $e');
      return {'success': false, 'message': _formatException(e)};
    }
  }

  static Future<bool> saveTower(
    Map<String, dynamic> towerData, {
    bool isEditing = false,
    String? id,
  }) async {
    final result = await saveTowerWithResult(
      towerData,
      isEditing: isEditing,
      id: id,
    );
    return result['success'] == true;
  }

  // ============================================================
  // 7. DELETE TOWER
  // DELETE /api/towers/{id}
  // ============================================================

  static Future<bool> deleteTower(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .delete(Uri.parse(ApiConfig.towerDetails(id)), headers: headers)
          .timeout(timeoutDuration);

      final success = response.statusCode == 200 || response.statusCode == 204;
      if (success) DataSyncService.notifyDataChanged();
      return success;
    } catch (e) {
      debugPrint('ApiService.deleteTower error: $e');
      return false;
    }
  }

  // ============================================================
  // 8. LOCATION HIERARCHY (DISTRICTS / CONSTITUENCIES / TALUKAS / AREAS)
  // ============================================================

  static Future<List<Map<String, dynamic>>> getDistrictsRaw() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.districts), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return _extractList(decoded);
      }
    } catch (e) {
      debugPrint('ApiService.getDistrictsRaw error: $e');
    }
    return [];
  }

  static Future<List<String>> getDistricts() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.districts), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = _extractStringList(decoded);
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('ApiService.getDistricts error: $e');
    }
    return ['North Goa', 'South Goa'];
  }

  static Future<List<Map<String, dynamic>>> getConstituenciesRaw() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.constituencies), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return _extractList(decoded);
      }
    } catch (e) {
      debugPrint('ApiService.getConstituenciesRaw error: $e');
    }
    return [];
  }

  static Future<List<String>> getConstituencies() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.constituencies), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = _extractStringList(decoded);
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('ApiService.getConstituencies error: $e');
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getTalukasRaw() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.talukas), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return _extractList(decoded);
      }
    } catch (e) {
      debugPrint('ApiService.getTalukasRaw error: $e');
    }
    return [];
  }

  static Future<List<String>> getTalukas() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.talukas), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = _extractStringList(decoded);
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('ApiService.getTalukas error: $e');
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getAreasRaw() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.areas), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return _extractList(decoded);
      }
    } catch (e) {
      debugPrint('ApiService.getAreasRaw error: $e');
    }
    return [];
  }

  static Future<List<String>> getAreas() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.areas), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = _extractStringList(decoded);
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('ApiService.getAreas error: $e');
    }
    return [];
  }

  // ============================================================
  // 9. OPERATORS
  // GET /api/operators
  // ============================================================

  static Future<List<Map<String, dynamic>>> getOperators() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.operators), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final raw = _extractList(decoded);
        return raw.map((op) => _normaliseOperator(op)).toList();
      }
    } catch (e) {
      debugPrint('ApiService.getOperators error: $e');
    }
    return [];
  }

  static Map<String, dynamic> _normaliseOperator(Map<String, dynamic> op) {
    final towersCount = (op['towers_count'] as num?)?.toInt() ??
        (op['towers'] is List ? (op['towers'] as List).length : null) ??
        (op['towers'] is num ? (op['towers'] as num).toInt() : 0);

    final rawStatus = op['status']?.toString() ?? 'active';
    final status = rawStatus.isNotEmpty
        ? rawStatus[0].toUpperCase() + rawStatus.substring(1).toLowerCase()
        : 'Active';

    return {
      'id': op['id'] != null
          ? 'OPR-${op['id'].toString().padLeft(3, '0')}'
          : (op['shortName']?.toString() ?? 'OPR-001'),
      'dbId': op['id']?.toString() ?? '',
      'name': op['name']?.toString() ?? '',
      'shortName': op['short_name']?.toString() ??
          op['shortName']?.toString() ??
          '',
      'contact': op['phone']?.toString() ??
          op['contact_person']?.toString() ??
          op['contact']?.toString() ??
          '—',
      'email': op['email']?.toString() ?? '—',
      'towers': towersCount,
      'status': status,
      'frequency': op['frequency']?.toString() ?? '900/1800/2100 MHz',
      'type': op['type']?.toString() ?? 'Telecom Operator',
      'license': op['license']?.toString() ?? 'DOIT Category-A',
      'since': op['since']?.toString() ??
          (op['created_at']?.toString().split('T').first ?? '2024-01-01'),
      '_raw': op,
    };
  }

  static Future<bool> saveOperator(
    Map<String, dynamic> operatorData, {
    bool isEditing = false,
    String? id,
  }) async {
    try {
      final headers = await _authHeaders();
      final url = (isEditing && id != null && id.isNotEmpty)
          ? ApiConfig.operatorDetails(id)
          : ApiConfig.operators;

      final body = jsonEncode({
        'name': operatorData['name'],
        'short_name': operatorData['shortName'] ?? operatorData['short_name'],
        'contact_person': operatorData['contact'],
        'phone': operatorData['contact'],
        'email': operatorData['email'],
      });

      final response = isEditing
          ? await http
              .put(Uri.parse(url), headers: headers, body: body)
              .timeout(timeoutDuration)
          : await http
              .post(Uri.parse(url), headers: headers, body: body)
              .timeout(timeoutDuration);

      final success = response.statusCode == 200 || response.statusCode == 201;
      if (success) DataSyncService.notifyDataChanged();
      return success;
    } catch (e) {
      debugPrint('ApiService.saveOperator error: $e');
      return false;
    }
  }

  static Future<bool> deleteOperator(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .delete(Uri.parse(ApiConfig.operatorDetails(id)), headers: headers)
          .timeout(timeoutDuration);

      final success = response.statusCode == 200 || response.statusCode == 204;
      if (success) DataSyncService.notifyDataChanged();
      return success;
    } catch (e) {
      debugPrint('ApiService.deleteOperator error: $e');
      return false;
    }
  }

  // ============================================================
  // 10. OWNERS
  // GET /api/owners
  // ============================================================

  static Future<List<Map<String, dynamic>>> getOwners() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.owners), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final raw = _extractList(decoded);
        return raw.map((o) => _normaliseOwner(o)).toList();
      }
    } catch (e) {
      debugPrint('ApiService.getOwners error: $e');
    }
    return [];
  }

  static Map<String, dynamic> _normaliseOwner(Map<String, dynamic> o) {
    final towersList = o['towers'] is List ? (o['towers'] as List) : [];
    final towersCount = (o['towers_count'] as num?)?.toInt() ?? towersList.length;

    return {
      'id': o['id'] != null ? 'OWN-${o['id'].toString().padLeft(3, '0')}' : 'OWN-001',
      'dbId': o['id']?.toString() ?? '',
      'name': o['name']?.toString() ?? 'Government of Goa',
      'phone': o['phone']?.toString() ?? '—',
      'email': o['email']?.toString() ?? '—',
      'address': o['address']?.toString() ?? 'Goa',
      'towersCount': towersCount,
      'towers': towersList,
      '_raw': o,
    };
  }

  static Future<bool> saveOwner(
    Map<String, dynamic> ownerData, {
    bool isEditing = false,
    String? id,
  }) async {
    try {
      final headers = await _authHeaders();
      final url = (isEditing && id != null && id.isNotEmpty)
          ? ApiConfig.ownerDetails(id)
          : ApiConfig.owners;

      final body = jsonEncode({
        'name': ownerData['name'],
        'phone': ownerData['phone'],
        'email': ownerData['email'],
        'address': ownerData['address'],
      });

      final response = isEditing
          ? await http
              .put(Uri.parse(url), headers: headers, body: body)
              .timeout(timeoutDuration)
          : await http
              .post(Uri.parse(url), headers: headers, body: body)
              .timeout(timeoutDuration);

      final success = response.statusCode == 200 || response.statusCode == 201;
      if (success) DataSyncService.notifyDataChanged();
      return success;
    } catch (e) {
      debugPrint('ApiService.saveOwner error: $e');
      return false;
    }
  }

  static Future<bool> deleteOwner(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .delete(Uri.parse(ApiConfig.ownerDetails(id)), headers: headers)
          .timeout(timeoutDuration);

      final success = response.statusCode == 200 || response.statusCode == 204;
      if (success) DataSyncService.notifyDataChanged();
      return success;
    } catch (e) {
      debugPrint('ApiService.deleteOwner error: $e');
      return false;
    }
  }

  // ============================================================
  // 11. RENT PAYMENTS & HISTORY
  // GET /api/rent-payments
  // ============================================================

  static Future<List<Map<String, dynamic>>> getRents() async {
    final List<Map<String, dynamic>> results = [];

    // 1. Fetch direct payments if available
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.rentPayments), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final raw = _extractList(decoded);
        for (final r in raw) {
          results.add(_normaliseRentRecord(r));
        }
      }
    } catch (e) {
      debugPrint('ApiService.getRents error: $e');
    }

    // 2. Also fetch all registered towers to ensure rent ledger reflects all active towers
    try {
      final towers = await getTowers();
      final existingTowerIds =
          results.map((r) => r['towerId']?.toString()).toSet();

      for (final t in towers) {
        final tId = t['id']?.toString() ?? t['towerId']?.toString() ?? '';
        if (tId.isNotEmpty && !existingTowerIds.contains(tId)) {
          final yearlyRent =
              int.tryParse(t['yearly_rent']?.toString() ?? '60000') ?? 60000;
          final isRentDue = t['rent']?.toString().toLowerCase() == 'due' ||
              t['rent']?.toString().toLowerCase() == 'overdue';

          results.add({
            'id': t['dbId'] ?? tId,
            'towerId': tId,
            'tower_id': tId,
            'owner': t['owner'] ?? 'Government of Goa',
            'district': t['district'] ?? 'North Goa',
            'operator': t['operator'] ?? 'Airtel',
            'yearlyRent': yearlyRent,
            'yearly_rent': yearlyRent,
            'rent_cycle_years': t['rent_cycle_years'] ?? 5,
            'total_amount': t['total_amount'] ?? '${yearlyRent * 5}',
            'status': isRentDue
                ? 'Due'
                : (t['status']?.toString().toLowerCase() == 'inactive'
                    ? 'Inactive'
                    : 'Paid'),
            'payment_status': isRentDue ? 'Due' : 'Paid',
            'lastPayment': t['rent_due_date']?.toString().split('T').first ??
                '2026-08-25',
            'nextDue': t['rent_due_date']?.toString().split('T').first ??
                '2027-08-25',
            '_raw': t,
          });
        }
      }
    } catch (e) {
      debugPrint('ApiService.getRents tower fallback error: $e');
    }

    return results;
  }

  static Future<List<Map<String, dynamic>>> getRentPayments() async {
    return getRents();
  }

  static Map<String, dynamic> _normaliseRentRecord(Map<String, dynamic> r) {
    final tower = r['tower'] as Map?;
    final rawTowerId = tower?['tower_unique_id']?.toString() ??
        r['tower_unique_id']?.toString() ??
        (r['tower_id'] != null
            ? 'TWR-${r['tower_id'].toString().padLeft(4, '0')}'
            : (r['towerId']?.toString() ?? 'TWR-0001'));

    final amount = (r['amount'] as num?)?.toInt() ??
        (r['yearly_rent'] as num?)?.toInt() ??
        (r['yearlyRent'] as num?)?.toInt() ??
        60000;

    final rawStatus = r['payment_status']?.toString().toLowerCase() ??
        r['status']?.toString().toLowerCase() ??
        'paid';

    final status = rawStatus == 'paid'
        ? 'Paid'
        : (rawStatus == 'due' || rawStatus == 'overdue' ? 'Due' : 'Pending');

    return {
      'id': r['id']?.toString() ?? '',
      'towerId': rawTowerId,
      'tower_id': rawTowerId,
      'owner': tower?['owner']?['name']?.toString() ??
          r['owner']?.toString() ??
          'Government of Goa',
      'district': tower?['area']?['taluka']?['constituency']?['district']?['name']
              ?.toString() ??
          r['district']?.toString() ??
          'North Goa',
      'operator': tower?['operators'] != null &&
              (tower!['operators'] as List).isNotEmpty
          ? (tower['operators'][0]['short_name'] ??
              tower['operators'][0]['name'] ??
              'Airtel')
          : (r['operator']?.toString() ?? 'Vi'),
      'yearlyRent': amount,
      'yearly_rent': amount,
      'status': status,
      'payment_status': status,
      'lastPayment': r['payment_date']?.toString().split('T').first ??
          r['lastPayment']?.toString() ??
          '2026-08-21',
      'nextDue': r['period_end']?.toString().split('T').first ??
          r['nextDue']?.toString() ??
          '2027-08-21',
      '_raw': r,
    };
  }

  static Future<Map<String, dynamic>?> getTowerRent(String towerId) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.towerRent(towerId)), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          if (decoded['data'] is Map) {
            return Map<String, dynamic>.from(decoded['data'] as Map);
          }
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (e) {
      debugPrint('ApiService.getTowerRent error: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getTowerPayments(
    String towerId,
  ) async {
    try {
      final url = towerId.isNotEmpty
          ? ApiConfig.towerPayments(towerId)
          : ApiConfig.rentPayments;

      final headers = await _authHeaders();
      final response = await http.get(Uri.parse(url), headers: headers).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = _extractList(decoded);
        return list.map((p) => _normalisePaymentRecord(p)).toList();
      }
    } catch (e) {
      debugPrint('ApiService.getTowerPayments error: $e');
    }
    return [];
  }

  static Map<String, dynamic> _normalisePaymentRecord(Map<String, dynamic> p) {
    final tower = p['tower'] as Map?;
    final rawTowerId = tower?['tower_unique_id']?.toString() ??
        p['tower_unique_id']?.toString() ??
        (p['tower_id'] != null
            ? 'TWR-${p['tower_id'].toString().padLeft(4, '0')}'
            : (p['towerId']?.toString() ?? 'TWR-0001'));

    final rawAmount = p['amount'] != null
        ? (p['amount'] is num
            ? (p['amount'] as num).toInt()
            : int.tryParse(p['amount'].toString().replaceAll(',', '')) ?? 0)
        : 60000;

    final dateStr = p['payment_date']?.toString().split('T').first ??
        p['date']?.toString() ??
        '2026-08-21';

    final periodStart =
        p['period_start']?.toString().split('T').first ?? '2026-08-21';
    final periodEnd =
        p['period_end']?.toString().split('T').first ?? '2027-08-20';

    final rawStatus = p['payment_status']?.toString().toLowerCase() ??
        p['status']?.toString().toLowerCase() ??
        'paid';

    final status = rawStatus == 'paid'
        ? 'Paid'
        : (rawStatus == 'due' || rawStatus == 'overdue' ? 'Overdue' : 'Pending');

    return {
      'id': p['id']?.toString() ?? '',
      'receiptNo': p['payment_reference']?.toString() ??
          p['receiptNo']?.toString() ??
          'RCP-2026-${(p['id'] ?? 1).toString().padLeft(3, '0')}',
      'date': dateStr,
      'period': p['period']?.toString() ?? '$periodStart to $periodEnd',
      'amount':
          '₹${rawAmount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
      'rawAmount': rawAmount,
      'mode': p['payment_method']?.toString() ??
          p['mode']?.toString() ??
          'NEFT / RTGS (Govt Account)',
      'status': status,
      'towerId': rawTowerId,
      'owner': tower?['owner']?['name']?.toString() ??
          p['owner']?.toString() ??
          'Government of Goa',
      'remarks': p['remarks']?.toString() ?? '',
      '_raw': p,
    };
  }

  static Future<bool> recordPayment({
    required int towerId,
    required double amount,
    required String paymentDate,
    required String paymentReference,
    required String paymentMethod,
    String? periodStart,
    String? periodEnd,
    String? remarks,
  }) async {
    try {
      final headers = await _authHeaders();
      final payload = <String, dynamic>{
        'tower_id': towerId,
        'amount': amount,
        'payment_date': paymentDate,
        'payment_reference': paymentReference,
        'payment_status': 'paid',
        'payment_method': paymentMethod,
      };
      if (periodStart != null) payload['period_start'] = periodStart;
      if (periodEnd != null) payload['period_end'] = periodEnd;
      if (remarks != null) payload['remarks'] = remarks;

      final response = await http
          .post(
            Uri.parse(ApiConfig.rentPayments),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(timeoutDuration);

      final success = response.statusCode == 200 || response.statusCode == 201;
      if (success) DataSyncService.notifyDataChanged();
      return success;
    } catch (e) {
      debugPrint('ApiService.recordPayment error: $e');
      return false;
    }
  }

  /// Create payment with arbitrary map payload matching Laravel API
  static Future<bool> createPayment(Map<String, dynamic> payload) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .post(
            Uri.parse(ApiConfig.rentPayments),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(timeoutDuration);

      final success = response.statusCode == 200 || response.statusCode == 201;
      if (success) DataSyncService.notifyDataChanged();
      return success;
    } catch (e) {
      debugPrint('ApiService.createPayment error: $e');
      return false;
    }
  }

  /// Delete a payment record
  static Future<bool> deletePayment(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .delete(Uri.parse(ApiConfig.rentPayment(id)), headers: headers)
          .timeout(timeoutDuration);

      final success = response.statusCode == 200 || response.statusCode == 204;
      if (success) DataSyncService.notifyDataChanged();
      return success;
    } catch (e) {
      debugPrint('ApiService.deletePayment error: $e');
      return false;
    }
  }

  /// Synchronize telecom operators assigned to a specific tower
  static Future<bool> syncTowerOperators(
    String towerId,
    List<dynamic> operatorIds,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .post(
            Uri.parse(ApiConfig.syncTowerOperators(towerId)),
            headers: headers,
            body: jsonEncode({'operator_ids': operatorIds}),
          )
          .timeout(timeoutDuration);

      final success = response.statusCode == 200 || response.statusCode == 201;
      if (success) DataSyncService.notifyDataChanged();
      return success;
    } catch (e) {
      debugPrint('ApiService.syncTowerOperators error: $e');
      return false;
    }
  }

  // ============================================================
  // 12. AUTHORIZED PERSONNEL / USERS
  // GET /api/users, POST /api/users
  // ============================================================

  static Future<List<Map<String, dynamic>>> getAuthorizedPersonnel() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.users), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = _extractList(decoded);
        return list.map((u) => _normaliseUser(u)).toList();
      }
    } catch (e) {
      debugPrint('ApiService.getAuthorizedPersonnel error: $e');
    }
    return [];
  }

  static Map<String, dynamic> _normaliseUser(Map<String, dynamic> u) {
    return {
      'id': u['id']?.toString() ?? '',
      'name': u['name']?.toString() ?? 'Officer',
      'email': u['email']?.toString() ?? '',
      'designation': u['designation']?.toString() ?? 'Systems Officer',
      'department': u['department']?.toString() ?? 'Department of Information Technology',
      'role': u['role']?.toString() ?? 'Officer',
      'status': u['status']?.toString() ?? 'Active',
      'phone': u['phone']?.toString() ?? '—',
      'last_login': u['last_login']?.toString() ?? '—',
      '_raw': u,
    };
  }

  static Future<Map<String, dynamic>> createAuthorizedPerson(Map<String, dynamic> userData) async {
    try {
      final headers = await _authHeaders();
      final payload = Map<String, dynamic>.from(userData);
      if (payload['role'] != null) {
        String r = payload['role'].toString().toLowerCase().trim();
        if (r == 'administrator') r = 'admin';
        payload['role'] = r;
      }
      final response = await http
          .post(
            Uri.parse(ApiConfig.users),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(timeoutDuration);

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        DataSyncService.notifyDataChanged();
        return {'success': true, 'data': decoded['data'] ?? decoded};
      }

      String errorMsg = 'Failed to create user.';
      if (decoded is Map) {
        if (decoded['errors'] is Map && (decoded['errors'] as Map).isNotEmpty) {
          final first = (decoded['errors'] as Map).values.first;
          if (first is List && first.isNotEmpty) {
            errorMsg = first.first.toString();
          }
        } else if (decoded['message'] != null) {
          errorMsg = decoded['message'].toString();
        }
      }
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      debugPrint('ApiService.createAuthorizedPerson error: $e');
      return {'success': false, 'message': e.toString().replaceAll('Exception: ', '')};
    }
  }

  static Future<Map<String, dynamic>> updateAuthorizedPerson(String id, Map<String, dynamic> userData) async {
    try {
      final headers = await _authHeaders();
      final payload = Map<String, dynamic>.from(userData);
      if (payload['role'] != null) {
        String r = payload['role'].toString().toLowerCase().trim();
        if (r == 'administrator') r = 'admin';
        payload['role'] = r;
      }
      final response = await http
          .put(
            Uri.parse(ApiConfig.userDetails(id)),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(timeoutDuration);

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 204) {
        DataSyncService.notifyDataChanged();
        return {'success': true, 'data': decoded['data'] ?? decoded};
      }

      String errorMsg = 'Failed to update user.';
      if (decoded is Map) {
        if (decoded['errors'] is Map && (decoded['errors'] as Map).isNotEmpty) {
          final first = (decoded['errors'] as Map).values.first;
          if (first is List && first.isNotEmpty) {
            errorMsg = first.first.toString();
          }
        } else if (decoded['message'] != null) {
          errorMsg = decoded['message'].toString();
        }
      }
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      debugPrint('ApiService.updateAuthorizedPerson error: $e');
      return {'success': false, 'message': e.toString().replaceAll('Exception: ', '')};
    }
  }

  static Future<Map<String, dynamic>> deleteAuthorizedPerson(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .delete(
            Uri.parse(ApiConfig.userDetails(id)),
            headers: headers,
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 204) {
        DataSyncService.notifyDataChanged();
        return {'success': true};
      }

      final decoded = jsonDecode(response.body);
      String errorMsg = 'Failed to delete user.';
      if (decoded is Map && decoded['message'] != null) {
        errorMsg = decoded['message'].toString();
      }
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      debugPrint('ApiService.deleteAuthorizedPerson error: $e');
      return {'success': false, 'message': e.toString().replaceAll('Exception: ', '')};
    }
  }

  // ============================================================
  // CONVENIENCE ALIAS METHODS
  // ============================================================

  static Future<Map<String, dynamic>> getDashboardStats() => getDashboard();

  static Future<Map<String, dynamic>?> getTower(dynamic id) =>
      getTowerDetails(id.toString());

  static Future<List<Map<String, dynamic>>> getPaymentHistory({String? towerId}) =>
      getTowerPayments(towerId ?? '');

  static Future<List<Map<String, dynamic>>> getRentRecords() => getRents();

  static Future<bool> createOperator(Map<String, dynamic> data) =>
      saveOperator(data);

  static Future<bool> updateOperator(dynamic id, Map<String, dynamic> data) =>
      saveOperator(data, isEditing: true, id: id.toString());

  // ============================================================
  // 13. REPORTS (CONSOLIDATED)
  // GET /api/reports?type={type}
  // ============================================================

  static Future<Map<String, dynamic>> getReports([String type = 'all']) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.reportType(type)), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          if (decoded['data'] is Map) {
            return Map<String, dynamic>.from(decoded['data'] as Map);
          }
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (e) {
      debugPrint('ApiService.getReports error: $e');
    }
    return {};
  }

  // ============================================================
  // UTILITY PARSERS
  // ============================================================

  static List<Map<String, dynamic>> _extractList(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (decoded is Map) {
      final data = decoded['data'] ?? decoded['results'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      if (data is Map) {
        final nestedData = data['data'] ?? data['results'];
        if (nestedData is List) {
          return nestedData
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
    }

    return [];
  }

  static List<String> _extractStringList(dynamic decoded) {
    dynamic data = decoded;
    if (decoded is Map) {
      data = decoded['data'] ?? decoded;
    }

    if (data is! List) return [];

    return data.map<String>((item) {
      if (item is Map && item['name'] != null) {
        return item['name'].toString();
      }
      return item.toString();
    }).toList();
  }

  static Map<String, dynamic> normaliseUser(Map<String, dynamic> raw) {
    return {
      'id': raw['id']?.toString() ?? '',
      'name': raw['name']?.toString() ?? 'Officer',
      'email': raw['email']?.toString() ?? '',
      'role': raw['role']?.toString() ?? 'Officer',
      'designation': raw['designation']?.toString() ?? 'Systems Officer',
      'department': raw['department']?.toString() ??
          'Department of Information Technology',
      'status': raw['status']?.toString() ?? 'Active',
    };
  }
}
