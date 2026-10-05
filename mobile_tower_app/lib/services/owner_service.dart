import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import 'data_sync_service.dart';

/// Dedicated service for Owner Management operations.
class OwnerService {
  OwnerService._();

  static const Duration timeoutDuration = Duration(seconds: 10);

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Map<String, dynamic>>> getOwners() async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse(ApiConfig.owners).replace(queryParameters: {'all': 'true'});
      final response = await http
          .get(uri, headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = (decoded is Map && decoded['data'] is List)
            ? decoded['data'] as List
            : (decoded is Map && decoded['results'] is List)
                ? decoded['results'] as List
                : (decoded is List ? decoded : []);

        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      debugPrint('OwnerService.getOwners error: $e');
    }
    return [];
  }

  static Future<bool> createOwner({
    required String name,
    String? phone,
    String? email,
    String? address,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .post(
            Uri.parse(ApiConfig.owners),
            headers: headers,
            body: jsonEncode({
              'name': name,
              'phone': phone,
              'email': email,
              'address': address,
            }),
          )
          .timeout(timeoutDuration);

      final success = response.statusCode == 200 || response.statusCode == 201;
      if (success) DataSyncService.notifyDataChanged();
      return success;
    } catch (e) {
      debugPrint('OwnerService.createOwner error: $e');
      return false;
    }
  }

  static Future<bool> updateOwner({
    required String id,
    required String name,
    String? phone,
    String? email,
    String? address,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .put(
            Uri.parse(ApiConfig.ownerDetails(id)),
            headers: headers,
            body: jsonEncode({
              'name': name,
              'phone': phone,
              'email': email,
              'address': address,
            }),
          )
          .timeout(timeoutDuration);

      final success = response.statusCode == 200;
      if (success) DataSyncService.notifyDataChanged();
      return success;
    } catch (e) {
      debugPrint('OwnerService.updateOwner error: $e');
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
      debugPrint('OwnerService.deleteOwner error: $e');
      return false;
    }
  }
}
