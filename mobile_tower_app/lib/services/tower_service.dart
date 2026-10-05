import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tower.dart';
import 'api_config.dart';
import 'auth_service.dart';

/// Legacy model adapter service delegating to central ApiConfig & AuthService.
class TowerService {
  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // GET ALL TOWERS
  // ============================================================

  Future<List<Tower>> getTowers() async {
    final headers = await _headers();
    final uri = Uri.parse(ApiConfig.towers).replace(queryParameters: {'all': 'true'});
    final response = await http.get(
      uri,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List towersJson = (data is Map && data['data'] is List)
          ? data['data']
          : (data is Map && data['results'] is List)
              ? data['results']
              : (data is List ? data : []);

      return towersJson.map((tower) => Tower.fromJson(tower)).toList();
    } else {
      throw Exception('Failed to load towers: ${response.statusCode}');
    }
  }

  // ============================================================
  // ADD TOWER
  // ============================================================

  Future<Tower> addTower(Tower tower) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse(ApiConfig.towers),
      headers: headers,
      body: jsonEncode(tower.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Tower.fromJson(data['data'] ?? data);
    } else {
      throw Exception('Failed to add tower: ${response.statusCode}');
    }
  }

  // ============================================================
  // UPDATE TOWER
  // ============================================================

  Future<Tower> updateTower(String id, Tower tower) async {
    final headers = await _headers();
    final response = await http.put(
      Uri.parse(ApiConfig.towerDetails(id)),
      headers: headers,
      body: jsonEncode(tower.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Tower.fromJson(data['data'] ?? data);
    } else {
      throw Exception('Failed to update tower: ${response.statusCode}');
    }
  }

  // ============================================================
  // DELETE TOWER
  // ============================================================

  Future<void> deleteTower(String id) async {
    final headers = await _headers();
    final response = await http.delete(
      Uri.parse(ApiConfig.towerDetails(id)),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete tower: ${response.statusCode}');
    }
  }
}
