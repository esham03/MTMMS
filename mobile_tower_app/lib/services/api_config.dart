import 'package:shared_preferences/shared_preferences.dart';
import '../config/server_config.dart';

/// Centralized Dynamic API Configuration for MTMMS.
///
/// Supports seamless connectivity across ANY network:
/// - Local Wi-Fi / Hotspot (fast direct LAN connectivity)
/// - Global Cloud Tunnel (accessible over 4G/5G mobile data / remote networks)
class ApiConfig {
  ApiConfig._();

  static const String prefBaseUrlKey = 'mtmms_api_base_url';
  static const String prefCloudUrlKey = 'mtmms_cloud_url';
  static const String prefLocalUrlKey = 'mtmms_local_url';

  // Dynamic fallback configured from active launcher
  static String get defaultBaseUrl => GeneratedServerConfig.apiUrl;
  static String get defaultTunnelUrl => GeneratedServerConfig.tunnelUrl;

  static String _currentBaseUrl = GeneratedServerConfig.apiUrl;
  static String _currentCloudUrl = GeneratedServerConfig.tunnelUrl;

  static String get baseUrl => _currentBaseUrl;
  static String get cloudUrl => _currentCloudUrl;

  /// Returns True if the active API connection is running over a remote cloud tunnel
  static bool get isCloudActive {
    final lower = _currentBaseUrl.toLowerCase();
    return lower.startsWith('https://') ||
        lower.contains('.loca.lt') ||
        lower.contains('.trycloudflare.com') ||
        lower.contains('.ngrok') ||
        lower.contains('.pagekite.me');
  }

  /// Returns the current host IP or domain of the active API
  static String get currentHost {
    try {
      final uri = Uri.parse(_currentBaseUrl);
      return uri.host;
    } catch (_) {
      return GeneratedServerConfig.serverIp;
    }
  }

  /// Clean and standardize URL format (strips trailing slashes, ensures /api suffix)
  static String cleanUrl(String url) {
    var cleaned = url.trim();
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    if (!cleaned.endsWith('/api')) {
      cleaned = '$cleaned/api';
    }
    return cleaned;
  }

  /// Initialize API base URL from persistent preferences or launcher config
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final savedCloud = prefs.getString(prefCloudUrlKey);
      if (savedCloud != null && savedCloud.trim().isNotEmpty) {
        _currentCloudUrl = cleanUrl(savedCloud);
      } else if (defaultTunnelUrl.isNotEmpty) {
        _currentCloudUrl = cleanUrl(defaultTunnelUrl);
      }

      final savedUrl = prefs.getString(prefBaseUrlKey);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _currentBaseUrl = cleanUrl(savedUrl);
      } else {
        _currentBaseUrl = defaultBaseUrl;
      }
    } catch (_) {
      _currentBaseUrl = defaultBaseUrl;
    }
  }

  /// Update the active API Base URL persistently
  static Future<void> setBaseUrl(String url) async {
    final cleaned = cleanUrl(url);
    _currentBaseUrl = cleaned;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefBaseUrlKey, cleaned);
      if (isCloudActive) {
        await prefs.setString(prefCloudUrlKey, cleaned);
      } else {
        await prefs.setString(prefLocalUrlKey, cleaned);
      }
    } catch (_) {}
  }

  /// Update the known cloud tunnel URL persistently
  static Future<void> setCloudUrl(String url) async {
    if (url.trim().isEmpty) return;
    final cleaned = cleanUrl(url);
    _currentCloudUrl = cleaned;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefCloudUrlKey, cleaned);
    } catch (_) {}
  }

  /// Reset base URL to default launcher configuration
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