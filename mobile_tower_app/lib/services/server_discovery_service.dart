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
  final bool isCloud;

  const DiscoveredServer({
    required this.ip,
    required this.port,
    required this.apiUrl,
    required this.deviceName,
    this.isCloud = false,
  });

  @override
  String toString() => 'DiscoveredServer($ip:$port -> $apiUrl, isCloud: $isCloud)';
}

/// Robust Universal Network Server Discovery Service for MTMMS.
///
/// Seamlessly connects to the MTMMS Django backend across ANY available network:
/// 1. Tests previously verified local & cloud URLs via fast /api/health/ probe.
/// 2. Probes compile-time candidate IPs and Cloud Tunnel URLs.
/// 3. Broadcasts UDP discovery probe on port 41588 across all Wi-Fi subnet broadcasts.
/// 4. Concurrent Wi-Fi / Hotspot subnet sweep (prioritizing wlan interfaces over cellular).
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

  /// Performs full automated discovery pipeline across local network and cloud.
  static Future<DiscoveredServer?> discoverServer({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // ─────────────────────────────────────────────────────────────
    // STEP 1: Fast Probe Cached Server & Cloud Tunnel
    // ─────────────────────────────────────────────────────────────
    if (!forceRefresh) {
      statusNotifier.value = DiscoveryStatus.checkingCached;
      statusMessageNotifier.value = 'Connecting to MTMMS...';

      // 1a. Test last cached URL
      final cachedUrl = prefs.getString(prefCachedServerUrlKey) ?? ApiConfig.baseUrl;
      if (cachedUrl.isNotEmpty) {
        final verified = await _verifyHealth(cachedUrl, timeoutSeconds: 2);
        if (verified != null) {
          _onServerFound(verified, prefs);
          return verified;
        }
      }

      // 1b. Test saved Cloud Tunnel URL (for 4G/5G mobile data / remote network)
      final savedCloud = prefs.getString(ApiConfig.prefCloudUrlKey);
      if (savedCloud != null && savedCloud.isNotEmpty && savedCloud != cachedUrl) {
        final verifiedCloud = await _verifyHealth(savedCloud, timeoutSeconds: 2);
        if (verifiedCloud != null) {
          _onServerFound(verifiedCloud, prefs);
          return verifiedCloud;
        }
      }

      // 1c. Test compile-time generated fallback
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

      // 1d. Test compile-time generated tunnel URL
      if (GeneratedServerConfig.tunnelUrl.isNotEmpty &&
          GeneratedServerConfig.tunnelUrl != cachedUrl) {
        final verifiedTunnel = await _verifyHealth(
          GeneratedServerConfig.tunnelUrl,
          timeoutSeconds: 2,
        );
        if (verifiedTunnel != null) {
          _onServerFound(verifiedTunnel, prefs);
          return verifiedTunnel;
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
    // STEP 3: Multi-Interface Subnet Sweep
    // ─────────────────────────────────────────────────────────────
    statusNotifier.value = DiscoveryStatus.scanningSubnet;
    statusMessageNotifier.value = 'Scanning local Wi-Fi / Hotspot subnet...';

    server = await _sweepLocalSubnet(defaultApiPort);
    if (server != null) {
      _onServerFound(server, prefs);
      return server;
    }

    // ─────────────────────────────────────────────────────────────
    // STEP 4: Fallback Check on Configured Cloud Tunnel
    // ─────────────────────────────────────────────────────────────
    final savedCloud = prefs.getString(ApiConfig.prefCloudUrlKey) ?? GeneratedServerConfig.tunnelUrl;
    if (savedCloud.isNotEmpty) {
      statusMessageNotifier.value = 'Connecting to MTMMS Cloud Tunnel...';
      final verifiedCloud = await _verifyHealth(savedCloud, timeoutSeconds: 3);
      if (verifiedCloud != null) {
        _onServerFound(verifiedCloud, prefs);
        return verifiedCloud;
      }
    }

    // ─────────────────────────────────────────────────────────────
    // FAILED: Server not found
    // ─────────────────────────────────────────────────────────────
    statusNotifier.value = DiscoveryStatus.failed;
    statusMessageNotifier.value =
        'MTMMS Server Not Found.\n'
        '• Connect to the same Wi-Fi as your computer, OR\n'
        '• Connect via Cloud Tunnel / enter the Server IP manually.';
    return null;
  }

  /// Manually tests and applies a server IP or full URL.
  static Future<DiscoveredServer?> connectToUrl(String rawInput) async {
    final prefs = await SharedPreferences.getInstance();
    var cleaned = rawInput.trim();
    if (cleaned.isEmpty) return null;

    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      if (!cleaned.contains(':')) {
        cleaned = 'http://$cleaned:8000/api';
      } else {
        cleaned = 'http://$cleaned/api';
      }
    } else {
      cleaned = ApiConfig.cleanUrl(cleaned);
    }

    final verified = await _verifyHealth(cleaned, timeoutSeconds: 4);
    if (verified != null) {
      _onServerFound(verified, prefs);
      return verified;
    }
    return null;
  }

  /// Sends UDP broadcast probe across universal and directed subnet addresses
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
                final String? tunnelUrl = json['tunnel_url']?.toString();

                if (tunnelUrl != null && tunnelUrl.isNotEmpty) {
                  ApiConfig.setCloudUrl(tunnelUrl);
                }

                final server = DiscoveredServer(
                  ip: ip,
                  port: port,
                  apiUrl: apiUrl,
                  deviceName: name,
                  isCloud: false,
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
      final targetUniversal = InternetAddress('255.255.255.255');
      
      try {
        socket.send(probeBytes, targetUniversal, discoveryPort);
      } catch (_) {}

      // Broadcast across all detected local subnets
      final localIps = await _getAllLocalIps();
      for (final localIp in localIps) {
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

  /// Scans local Wi-Fi and hotspot subnets with smart priority (hotspot gateways first)
  static Future<DiscoveredServer?> _sweepLocalSubnet(int port) async {
    try {
      final localIps = await _getAllLocalIps();
      final Set<String> prefixes = {};

      for (final ip in localIps) {
        final parts = ip.split('.');
        if (parts.length == 4) {
          prefixes.add('${parts[0]}.${parts[1]}.${parts[2]}');
        }
      }

      // Add standard hotspot subnets as fallback if none or few detected
      prefixes.add('172.20.10');   // iPhone Hotspot
      prefixes.add('192.168.43');  // Android Hotspot

      // Priority 1: Fast test common hotspot gateway/host IPs (.1, .2, .3, .100)
      final List<String> fastTargets = [];
      for (final prefix in prefixes) {
        fastTargets.add('$prefix.1');
        fastTargets.add('$prefix.2');
        fastTargets.add('$prefix.3');
        fastTargets.add('$prefix.100');
        fastTargets.add('$prefix.15');
        fastTargets.add('$prefix.25');
      }

      for (final candidateIp in GeneratedServerConfig.allServerIps) {
        if (!fastTargets.contains(candidateIp)) {
          fastTargets.insert(0, candidateIp);
        }
      }

      final fastFutures = fastTargets.map((ip) => _verifyHealth('http://$ip:$port/api', timeoutSeconds: 1));
      final fastResults = await Future.wait(fastFutures);
      for (final res in fastResults) {
        if (res != null) return res;
      }

      // Priority 2: Concurrent sweep across primary detected subnets
      for (final prefix in prefixes) {
        final List<String> candidateIps = [];
        for (int i = 1; i <= 254; i++) {
          final ip = '$prefix.$i';
          if (!fastTargets.contains(ip)) {
            candidateIps.add(ip);
          }
        }

        const int batchSize = 40;
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
      }
    } catch (_) {}

    return null;
  }

  /// Collects all non-loopback local IPv4 addresses, prioritizing Wi-Fi/LAN over cellular
  static Future<List<String>> _getAllLocalIps() async {
    final List<String> wifiIps = [];
    final List<String> otherIps = [];

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();
        final isWifiOrLan = name.contains('wlan') ||
            name.contains('eth') ||
            name.contains('en') ||
            name.contains('wifi') ||
            name.contains('tiwlan');

        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (!ip.startsWith('127.') && !ip.startsWith('169.254.')) {
            if (isWifiOrLan) {
              wifiIps.add(ip);
            } else {
              otherIps.add(ip);
            }
          }
        }
      }
    } catch (_) {}

    return [...wifiIps, ...otherIps];
  }

  /// Verifies health check endpoint returns 200 OK and "service": "MTMMS"
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
          .get(
            healthUri,
            headers: {
              'Accept': 'application/json',
              'bypass-tunnel-reminder': 'true',
            },
          )
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> &&
            body['status'] == 'ok' &&
            body['service']?.toString().contains('MTMMS') == true) {
          final uri = Uri.parse(base);
          final bool isCloud = base.startsWith('https://') ||
              base.contains('.loca.lt') ||
              base.contains('.trycloudflare.com') ||
              base.contains('.ngrok');

          // If server advertises a tunnel URL, capture it
          if (body['tunnel_url'] != null && body['tunnel_url'].toString().isNotEmpty) {
            ApiConfig.setCloudUrl(body['tunnel_url'].toString());
          }

          return DiscoveredServer(
            ip: uri.host,
            port: uri.port,
            apiUrl: base,
            deviceName: 'MTMMS Server',
            isCloud: isCloud,
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
    statusMessageNotifier.value = server.isCloud
        ? 'Connected to MTMMS Cloud (${server.ip})'
        : 'Connected to MTMMS Local (${server.ip})';

    // Persist discovered server
    prefs.setString(prefCachedServerUrlKey, server.apiUrl);
    prefs.setString(prefCachedServerIpKey, server.ip);

    // Update active ApiConfig
    ApiConfig.setBaseUrl(server.apiUrl);
  }
}
