import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
                                    width: 320,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 16,
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
                                              'MTMMS Server Not Found',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Make sure:\n'
                                            '• Your phone is connected to Wi-Fi\n'
                                            '• Your computer is connected to the SAME Wi-Fi\n'
                                            '• Start-Live-System.bat is running on PC',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.white.withValues(alpha: 0.8),
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
                                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                                label: Text(
                                                  'Retry Discovery',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                onPressed: () => _startDiscovery(forceRefresh: true),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.white.withValues(alpha: 0.7),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              ),
                                              onPressed: () {
                                                Navigator.of(context).pushReplacement(
                                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                                );
                                              },
                                              child: Text(
                                                'Manual IP',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  decoration: TextDecoration.underline,
                                                ),
                                              ),
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
