import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_config.dart';
import '../services/auth_service.dart';
import '../services/server_discovery_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _textFadeAnim;
  Timer? _discoveryTimer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnim = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _textFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.9, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Trigger local network discovery after initial frame animation
    _discoveryTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _startDiscovery();
      }
    });
  }

  Future<void> _startDiscovery({bool forceRefresh = false}) async {
    final server = await ServerDiscoveryService.discoverServer(forceRefresh: forceRefresh);
    if (!mounted) return;

    if (server != null) {
      _proceedToApp();
    }
  }

  Future<void> _proceedToApp() async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    // Small delay so user sees "Connected to MTMMS Server (IP)"
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final bool hasToken = await AuthService.hasToken();
    final Widget destination =
        hasToken ? const DashboardScreen() : const LoginScreen();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => destination,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _discoveryTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _showManualConnectModal(BuildContext context) {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    bool testing = false;
    String? testMsg;
    bool testSuccess = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.cloud_sync_rounded,
                      color: Color(0xFFFF5100), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Connect to MTMMS Server',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A0F1D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Enter local Wi-Fi IP (e.g. 172.20.10.3 or 192.168.1.15) OR public cloud URL (e.g. https://...loca.lt) displayed in Start-Live-System.bat.',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: const Color(0xFF0A0F1D)),
                decoration: InputDecoration(
                  labelText: 'Server Host / URL',
                  hintText: 'e.g. 172.20.10.3:8000 or https://xxx.loca.lt',
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  prefixIcon: const Icon(Icons.link_rounded,
                      color: Color(0xFFFF5100)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFFFF5100), width: 1.5),
                  ),
                ),
              ),
              if (testMsg != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      testSuccess
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      size: 16,
                      color: testSuccess
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        testMsg!,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: testSuccess
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5100),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: testing
                          ? null
                          : () async {
                              setModalState(() {
                                testing = true;
                                testMsg = 'Testing connection...';
                                testSuccess = false;
                              });

                              final server = await ServerDiscoveryService.connectToUrl(controller.text);

                              setModalState(() {
                                testing = false;
                                if (server != null) {
                                  testSuccess = true;
                                  testMsg = 'Connected successfully to ${server.ip}!';
                                } else {
                                  testSuccess = false;
                                  testMsg = 'Could not reach MTMMS Server at that address.';
                                }
                              });

                              if (server != null) {
                                await Future.delayed(const Duration(milliseconds: 500));
                                if (ctx.mounted) Navigator.pop(ctx);
                                _proceedToApp();
                              }
                            },
                      child: testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Test & Connect'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Subtle background architectural rings
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -100,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.02),
                  ),
                ),
              ),

              // Main Department Content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Official Government Emblem / Logo
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (_, child) {
                          return FadeTransition(
                            opacity: _fadeAnim,
                            child: ScaleTransition(
                              scale: _scaleAnim,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: 96,
                          height: 96,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.8),
                              width: 2,
                            ),
                          ),
                          child: Image.asset(
                            'assets/images/goa-emblem.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.cell_tower_rounded,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Department Title & System Name
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (_, child) {
                          return Transform.translate(
                            offset: Offset(0, _slideAnim.value),
                            child: FadeTransition(
                              opacity: _textFadeAnim,
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Text(
                              'MTMMS',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mobile Tower Monitoring and Management System',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF38BDF8),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: 50,
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: AppColors.accentGoldGradient,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Department of Information Technology\nGovernment of Goa',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.4,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 50),

                      // Dynamic Server Discovery & Connection State
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (_, _) {
                          return FadeTransition(
                            opacity: _textFadeAnim,
                            child: ValueListenableBuilder<DiscoveryStatus>(
                              valueListenable: ServerDiscoveryService.statusNotifier,
                              builder: (context, status, _) {
                                  if (status == DiscoveryStatus.failed) {
                                    return Container(
                                      width: 330,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F172A).withValues(alpha: 0.90),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.35),
                                            blurRadius: 18,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.wifi_off_rounded,
                                                color: Color(0xFFF87171),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Server Not Connected',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '• On Same Wi-Fi: Run Start-Live-System.bat on PC\n'
                                              '• On 4G/5G / Other Network: Use Cloud Tunnel URL',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.white.withValues(alpha: 0.82),
                                                height: 1.45,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFFF5100),
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  icon: const Icon(Icons.cloud_sync_rounded, size: 16),
                                                  label: Text(
                                                    'Connect Server',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  onPressed: () => _showManualConnectModal(context),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  side: BorderSide(
                                                    color: Colors.white.withValues(alpha: 0.3),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                icon: const Icon(Icons.refresh_rounded, size: 15),
                                                label: Text(
                                                  'Retry',
                                                  style: GoogleFonts.poppins(fontSize: 11),
                                                ),
                                                onPressed: () => _startDiscovery(forceRefresh: true),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                return ValueListenableBuilder<String>(
                                  valueListenable: ServerDiscoveryService.statusMessageNotifier,
                                  builder: (context, msg, _) {
                                    final isFound = status == DiscoveryStatus.found;
                                    return Column(
                                      children: [
                                        SizedBox(
                                          width: 140,
                                          child: isFound
                                              ? const Icon(
                                                  Icons.check_circle_rounded,
                                                  color: Color(0xFF10B981),
                                                  size: 26,
                                                )
                                              : LinearProgressIndicator(
                                                  backgroundColor:
                                                      Colors.white.withValues(alpha: 0.15),
                                                  color: AppColors.cyanAccent,
                                                  minHeight: 3.5,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          msg,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            fontWeight: isFound ? FontWeight.w600 : FontWeight.w400,
                                            color: isFound
                                                ? const Color(0xFF34D399)
                                                : Colors.white.withValues(alpha: 0.75),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Official Security Notice at Bottom
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, child) {
                    return FadeTransition(opacity: _textFadeAnim, child: child);
                  },
                  child: Text(
                    'Restricted Departmental Access • DoIT • Government of Goa',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
