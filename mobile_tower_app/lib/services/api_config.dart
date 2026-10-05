import 'package:shared_preferences/shared_preferences.dart';
import '../config/server_config.dart';

/// Centralized API Configuration for MTMMS.
///
/// Base URL is dynamically resolved at runtime via ServerDiscoveryService
/// or initialized from the active launcher configuration.
class ApiConfig {
  ApiConfig._();

  // Dynamic fallback configured from active launcher
  static String get defaultBaseUrl => GeneratedServerConfig.apiUrl;
  static const String prefBaseUrlKey = 'mtmms_api_base_url';

  static String _currentBaseUrl = GeneratedServerConfig.apiUrl;

  static String get baseUrl => _currentBaseUrl;

  /// Returns the current host IP or domain of the API
  static String get currentHost {
    try {
      final uri = Uri.parse(_currentBaseUrl);
      return uri.host;
    } catch (_) {
      return GeneratedServerConfig.serverIp;
    }
  }

  /// Initialize API base URL from persistent preferences or launcher config
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(prefBaseUrlKey);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _currentBaseUrl = _cleanUrl(savedUrl);
      } else {
        _currentBaseUrl = defaultBaseUrl;
      }
    } catch (_) {
      _currentBaseUrl = defaultBaseUrl;
    }
  }

  /// Clean and standardize URL format (strips trailing slashes, ensures /api suffix)
  static String _cleanUrl(String url) {
    var cleaned = url.trim();
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    if (!cleaned.endsWith('/api')) {
      cleaned = '$cleaned/api';
    }
    return cleaned;
  }

  /// Update the active API Base URL persistently
  static Future<void> setBaseUrl(String url) async {
    final cleaned = _cleanUrl(url);
    _currentBaseUrl = cleaned;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefBaseUrlKey, cleaned);
    } catch (_) {}
  }

  /// Reset base URL to default
  static Future<void> resetToDefault() async {
    await setBaseUrl(defaultBaseUrl);
  }

  // ==========================================================
  // AUTH ENDPOINTS
  // ==========================================================
  static String get login => '$_currentBaseUrl/auth/login';
  static String get logout => '$_currentBaseUrl/auth/logout';
  static String get user => '$_currentBaseUrl/user';

  // ==========================================================
  // DASHBOARD ENDPOINT
  // ==========================================================
  static String get dashboard => '$_currentBaseUrl/dashboard';

  // ==========================================================
  // TOWER ENDPOINTS
  // ==========================================================
  static String get towers => '$_currentBaseUrl/towers';
  static String towerDetails(String id) => '$_currentBaseUrl/towers/$id';
  static String towerRent(String id) => '$_currentBaseUrl/towers/$id/rent';
  static String towerPayments(String id) => '$_currentBaseUrl/towers/$id/payments';
  static String syncTowerOperators(String id) => '$_currentBaseUrl/towers/$id/operators';

  // ==========================================================
  // GEOGRAPHIC / LOCATION HIERARCHY ENDPOINTS
  // ==========================================================
  static String get districts => '$_currentBaseUrl/districts';
  static String districtDetails(String id) => '$_currentBaseUrl/districts/$id';

  static String get constituencies => '$_currentBaseUrl/constituencies';
  static String constituencyDetails(String id) => '$_currentBaseUrl/constituencies/$id';

  static String get talukas => '$_currentBaseUrl/talukas';
  static String talukaDetails(String id) => '$_currentBaseUrl/talukas/$id';

  static String get areas => '$_currentBaseUrl/areas';
  static String areaDetails(String id) => '$_currentBaseUrl/areas/$id';

  // ==========================================================
  // OPERATOR ENDPOINTS
  // ==========================================================
  static String get operators => '$_currentBaseUrl/operators';
  static String operatorDetails(String id) => '$_currentBaseUrl/operators/$id';

  // ==========================================================
  // OWNER ENDPOINTS
  // ==========================================================
  static String get owners => '$_currentBaseUrl/owners';
  static String ownerDetails(String id) => '$_currentBaseUrl/owners/$id';

  // ==========================================================
  // RENT & FINANCIAL ENDPOINTS
  // ==========================================================
  static String get rentPayments => '$_currentBaseUrl/rent-payments';
  static String rentPayment(String id) => '$_currentBaseUrl/rent-payments/$id';

  // ==========================================================
  // AUTHORIZED USERS / PERSONNEL ENDPOINTS
  // ==========================================================
  static String get users => '$_currentBaseUrl/users';
  static String userDetails(String id) => '$_currentBaseUrl/users/$id';

  // ==========================================================
  // REPORTS ENDPOINTS
  // ==========================================================
  static String get reports => '$_currentBaseUrl/reports';
  static String reportType(String type) => '$_currentBaseUrl/reports?type=$type';
}