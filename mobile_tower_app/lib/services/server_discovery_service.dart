import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/server_config.dart';
import 'api_config.dart';

enum DiscoveryStatus {
  idle,
  checkingCached,
  searchingUdp,
  scanningSubnet,
  found,
  failed,
}

class DiscoveredServer {
  final String ip;
  final int port;
  final String apiUrl;
  final String deviceName;

  const DiscoveredServer({
    required this.ip,
    required this.port,
    required this.apiUrl,
    required this.deviceName,
  });

  @override
  String toString() => 'DiscoveredServer($ip:$port -> $apiUrl)';
}

/// Robust Local Network Server Discovery Service for MTMMS.
///
/// Discovers the MTMMS Django backend dynamically across any Wi-Fi/LAN:
/// 1. Tests previously saved server URL via fast /api/health/ probe.
/// 2. Broadcasts UDP discovery probe on port 41588 (to 255.255.255.255 & directed subnet broadcast).
/// 3. Listens for periodic discovery beacons from the MTMMS server.
/// 4. Subnet sweep fallback (scans /24 local subnet if router blocks UDP broadcast).
/// 5. Validates /api/health/ JSON signature ("status": "ok", "service": "MTMMS API").
class ServerDiscoveryService {
  ServerDiscoveryService._();

  static const int discoveryPort = 41588;
  static const int defaultApiPort = 8000;
  static const String prefCachedServerUrlKey = 'mtmms_cached_server_url';
  static const String prefCachedServerIpKey = 'mtmms_cached_server_ip';

  static final ValueNotifier<DiscoveryStatus> statusNotifier =
      ValueNotifier<DiscoveryStatus>(DiscoveryStatus.idle);
  static final ValueNotifier<String> statusMessageNotifier =
      ValueNotifier<String>('Ready');
  static final ValueNotifier<DiscoveredServer?> discoveredServerNotifier =
      ValueNotifier<DiscoveredServer?>(null);

  /// Performs full automated discovery pipeline.
  /// Returns DiscoveredServer on success, or null on failure.
  static Future<DiscoveredServer?> discoverServer({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // ─────────────────────────────────────────────────────────────
    // STEP 1: Verify cached server or compile-time fallback first
    // ─────────────────────────────────────────────────────────────
    if (!forceRefresh) {
      statusNotifier.value = DiscoveryStatus.checkingCached;
      statusMessageNotifier.value = 'Connecting to MTMMS...';

      final cachedUrl = prefs.getString(prefCachedServerUrlKey) ?? ApiConfig.baseUrl;
      if (cachedUrl.isNotEmpty) {
        final verified = await _verifyHealth(cachedUrl, timeoutSeconds: 2);
        if (verified != null) {
          _onServerFound(verified, prefs);
          return verified;
        }
      }

      // Also try the compile-time generated fallback if different
      if (GeneratedServerConfig.apiUrl != cachedUrl) {
        final verifiedGenerated = await _verifyHealth(
          GeneratedServerConfig.apiUrl,
          timeoutSeconds: 2,
        );
        if (verifiedGenerated != null) {
          _onServerFound(verifiedGenerated, prefs);
          return verifiedGenerated;
        }
      }
    }

    // ─────────────────────────────────────────────────────────────
    // STEP 2: UDP Broadcast Discovery & Beacon Listening (Port 41588)
    // ─────────────────────────────────────────────────────────────
    statusNotifier.value = DiscoveryStatus.searchingUdp;
    statusMessageNotifier.value = 'Searching local network for MTMMS Server...';

    DiscoveredServer? server = await _discoverViaUdp(timeout: const Duration(seconds: 3));
    if (server != null) {
      _onServerFound(server, prefs);
      return server;
    }

    // ─────────────────────────────────────────────────────────────
    // STEP 3: Subnet Sweep Fallback (in case router blocks UDP)
    // ─────────────────────────────────────────────────────────────
    statusNotifier.value = DiscoveryStatus.scanningSubnet;
    statusMessageNotifier.value = 'Scanning local Wi-Fi subnet...';

    server = await _sweepLocalSubnet(defaultApiPort);
    if (server != null) {
      _onServerFound(server, prefs);
      return server;
    }

    // ─────────────────────────────────────────────────────────────
    // FAILED: Server not found
    // ─────────────────────────────────────────────────────────────
    statusNotifier.value = DiscoveryStatus.failed;
    statusMessageNotifier.value =
        'MTMMS Server Not Found on local network.\n'
        '• Ensure phone and computer are on the same Wi-Fi.\n'
        '• Ensure Start-Live-System.bat is running on PC.\n'
        '• Check Windows Defender Firewall rules.';
    return null;
  }

  /// Sends UDP broadcast probe and listens for announcements
  static Future<DiscoveredServer?> _discoverViaUdp({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    RawDatagramSocket? socket;
    final completer = Completer<DiscoveredServer?>();

    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final timer = Timer(timeout, () {
        if (!completer.isCompleted) completer.complete(null);
      });

      socket.listen((RawSocketEvent event) async {
        if (event == RawSocketEvent.read) {
          final datagram = socket?.receive();
          if (datagram != null) {
            try {
              final raw = utf8.decode(datagram.data);
              final json = jsonDecode(raw);
              if (json is Map<String, dynamic> && json['service'] == 'MTMMS') {
                final String ip = (json['server_ip'] ?? datagram.address.address).toString();
                final int port = int.tryParse(json['api_port']?.toString() ?? '') ?? 8000;
                final String apiUrl = json['api_url']?.toString() ?? 'http://$ip:$port/api';
                final String name = json['device_name']?.toString() ?? 'MTMMS Server';

                final server = DiscoveredServer(
                  ip: ip,
                  port: port,
                  apiUrl: apiUrl,
                  deviceName: name,
                );

                // Verify health check before accepting
                final verified = await _verifyHealth(server.apiUrl, timeoutSeconds: 2);
                if (verified != null && !completer.isCompleted) {
                  timer.cancel();
                  completer.complete(verified);
                }
              }
            } catch (_) {}
          }
        }
      });

      final probeBytes = utf8.encode('MTMMS_DISCOVER_REQUEST');
      
      // Broadcast to universal broadcast address
      final targetUniversal = InternetAddress('255.255.255.255');
      socket.send(probeBytes, targetUniversal, discoveryPort);

      // Also broadcast to device subnet broadcast address if detectable
      final localIp = await _getLocalIp();
      if (localIp != null) {
        final parts = localIp.split('.');
        if (parts.length == 4) {
          final subnetBroadcast = '${parts[0]}.${parts[1]}.${parts[2]}.255';
          try {
            socket.send(probeBytes, InternetAddress(subnetBroadcast), discoveryPort);
          } catch (_) {}
        }
      }

      // Repeat probe after 1 second
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!completer.isCompleted && socket != null) {
          try {
            socket.send(probeBytes, targetUniversal, discoveryPort);
          } catch (_) {}
        }
      });

      return await completer.future;
    } catch (_) {
      return null;
    } finally {
      socket?.close();
    }
  }

  /// Scans the local /24 subnet for the MTMMS health check endpoint
  static Future<DiscoveredServer?> _sweepLocalSubnet(int port) async {
    try {
      final localIp = await _getLocalIp();
      if (localIp == null) return null;

      final parts = localIp.split('.');
      if (parts.length != 4) return null;
      final subnetPrefix = '${parts[0]}.${parts[1]}.${parts[2]}';

      // Scan candidate IPs concurrently in batches of 32
      final List<String> candidateIps = [];
      for (int i = 1; i <= 254; i++) {
        candidateIps.add('$subnetPrefix.$i');
      }

      const int batchSize = 32;
      for (int i = 0; i < candidateIps.length; i += batchSize) {
        final chunk = candidateIps.sublist(
          i,
          (i + batchSize > candidateIps.length) ? candidateIps.length : i + batchSize,
        );

        final futures = chunk.map((ip) async {
          final url = 'http://$ip:$port/api';
          return await _verifyHealth(url, timeoutSeconds: 1);
        });

        final results = await Future.wait(futures);
        for (final res in results) {
          if (res != null) return res;
        }
      }
    } catch (_) {}

    return null;
  }

  /// Helper to get primary non-loopback local IPv4 address
  static Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (!ip.startsWith('127.') && !ip.startsWith('169.254.')) {
            return ip;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Verifies health check endpoint returns 200 OK and "service": "MTMMS API"
  static Future<DiscoveredServer?> _verifyHealth(
    String candidateApiUrl, {
    int timeoutSeconds = 2,
  }) async {
    try {
      var base = candidateApiUrl.trim();
      while (base.endsWith('/')) {
        base = base.substring(0, base.length - 1);
      }
      final healthUri = Uri.parse('$base/health/');

      final response = await http
          .get(healthUri, headers: {'Accept': 'application/json'})
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> &&
            body['status'] == 'ok' &&
            body['service']?.toString().contains('MTMMS') == true) {
          final uri = Uri.parse(base);
          return DiscoveredServer(
            ip: uri.host,
            port: uri.port,
            apiUrl: base,
            deviceName: 'MTMMS Server',
          );
        }
      }
    } catch (_) {}

    return null;
  }

  /// Self-healing re-discovery trigger:
  /// Verifies if active server is alive; if not, triggers background rediscovery.
  static Future<bool> checkOrRediscover() async {
    final verified = await _verifyHealth(ApiConfig.baseUrl, timeoutSeconds: 1);
    if (verified != null) return true;

    final discovered = await discoverServer(forceRefresh: true);
    return discovered != null;
  }

  static void _onServerFound(DiscoveredServer server, SharedPreferences prefs) {
    discoveredServerNotifier.value = server;
    statusNotifier.value = DiscoveryStatus.found;
    statusMessageNotifier.value = 'Connected to MTMMS Server (${server.ip})';

    // Persist discovered server
    prefs.setString(prefCachedServerUrlKey, server.apiUrl);
    prefs.setString(prefCachedServerIpKey, server.ip);

    // Update active ApiConfig
    ApiConfig.setBaseUrl(server.apiUrl);
  }
}
