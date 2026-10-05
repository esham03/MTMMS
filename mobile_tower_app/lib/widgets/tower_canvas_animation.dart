import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Interactive & Cinematic Telecommunications Tower Canvas Animation
/// for MTMMS Government of Goa authentication experience.
///
/// Features:
/// - Realistic steel lattice truss tower with cross-bracing
/// - Sector panel antennas with cyan/sky illumination
/// - Flashing red aviation warning beacon on the apex
/// - Concentric pulsed RF signal waves
/// - Network signal trajectory beam
/// - Ambient particle field
/// - Support for 7-phase startup sequence & authenticating state
class TelecomTowerExperience extends StatefulWidget {
  final int phase; // 0 to 7
  final bool isAuthenticating;
  final bool isSuccess;
  final bool isFailure;
  final double height;
  final VoidCallback? onNetworkReady;

  const TelecomTowerExperience({
    super.key,
    required this.phase,
    this.isAuthenticating = false,
    this.isSuccess = false,
    this.isFailure = false,
    this.height = 240,
    this.onNetworkReady,
  });

  @override
  State<TelecomTowerExperience> createState() => _TelecomTowerExperienceState();
}

class _TelecomTowerExperienceState extends State<TelecomTowerExperience>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _beaconController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _beaconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant TelecomTowerExperience oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAuthenticating != oldWidget.isAuthenticating) {
      if (widget.isAuthenticating) {
        _waveController.duration = const Duration(milliseconds: 1000);
        _waveController.repeat();
      } else {
        _waveController.duration = const Duration(milliseconds: 2200);
        _waveController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _beaconController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _waveController,
          _beaconController,
          _particleController,
        ]),
        builder: (context, _) {
          return CustomPaint(
            painter: _TowerPainter(
              waveProgress: _waveController.value,
              beaconProgress: _beaconController.value,
              particleProgress: _particleController.value,
              phase: widget.phase,
              isAuthenticating: widget.isAuthenticating,
              isSuccess: widget.isSuccess,
              isFailure: widget.isFailure,
            ),
          );
        },
      ),
    );
  }
}

class _TowerPainter extends CustomPainter {
  final double waveProgress;
  final double beaconProgress;
  final double particleProgress;
  final int phase;
  final bool isAuthenticating;
  final bool isSuccess;
  final bool isFailure;

  _TowerPainter({
    required this.waveProgress,
    required this.beaconProgress,
    required this.particleProgress,
    required this.phase,
    required this.isAuthenticating,
    required this.isSuccess,
    required this.isFailure,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final bottomY = size.height - 12;
    final topY = size.height * 0.15;
    final towerHeight = bottomY - topY;

    // 1. Draw Ambient Particles in background (Phase >= 1)
    _drawParticles(canvas, size);

    // 2. Draw Ground Equipment Cabinet and Concrete Base
    _drawBaseAndCabinet(canvas, centerX, bottomY);

    // 3. Draw Steel Lattice Structure (Legs, Horizontal Girders, X-bracing)
    _drawLatticeTower(canvas, centerX, topY, bottomY, towerHeight);

    // 4. Draw Sector Antennas & Triangular Mount (Phase >= 3)
    _drawSectorAntennas(canvas, centerX, topY);

    // 5. Draw Flashing Aviation Red Warning Beacon on Summit (Phase >= 2)
    _drawAviationBeacon(canvas, centerX, topY);

    // 6. Draw Concentric Signal Waves (Phase >= 4)
    if (phase >= 4 || isAuthenticating || isSuccess) {
      _drawSignalWaves(canvas, centerX, topY);
    }

    // 7. Draw Network Beam traveling towards login container (Phase >= 5)
    if (phase >= 5 || isAuthenticating || isSuccess) {
      _drawNetworkBeam(canvas, centerX, topY, size);
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    final particlePaint = Paint()
      ..color = const Color(0xFFFF5100).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    const particleCount = 18;
    for (int i = 0; i < particleCount; i++) {
      final seed = i * 137.5;
      final px = ((math.sin(seed) * 0.5 + 0.5) * size.width +
              particleProgress * 40 * ((i % 2 == 0) ? 1 : -1)) %
          size.width;
      final py = ((math.cos(seed) * 0.5 + 0.5) * size.height +
              particleProgress * 30 * ((i % 3 == 0) ? -1 : 1)) %
          size.height;
      final radius = (i % 3 == 0) ? 1.8 : 1.2;
      canvas.drawCircle(Offset(px, py), radius, particlePaint);
    }
  }

  void _drawBaseAndCabinet(Canvas canvas, double centerX, double bottomY) {
    // Concrete Base Slab (Clean ceramic plinth)
    final basePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    final baseBorder = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final baseRect = Rect.fromCenter(
      center: Offset(centerX, bottomY + 4),
      width: 140,
      height: 12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(3)),
      basePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(3)),
      baseBorder,
    );

    // Equipment Shelter Cabinet
    final cabPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    final cabBorder = Paint()
      ..color = (phase >= 3)
          ? const Color(0xFFFF5100).withValues(alpha: 0.7)
          : const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final cabRect = Rect.fromLTWH(centerX + 22, bottomY - 26, 32, 26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabRect, const Radius.circular(3)),
      cabPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabRect, const Radius.circular(3)),
      cabBorder,
    );

    // Cabinet Status LED
    final ledPaint = Paint()
      ..color = (phase >= 6 || isSuccess)
          ? const Color(0xFF10B981)
          : (phase >= 3 ? const Color(0xFFFF5100) : const Color(0xFF94A3B8))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX + 30, bottomY - 18), 2.5, ledPaint);
  }

  void _drawLatticeTower(
    Canvas canvas,
    double centerX,
    double topY,
    double bottomY,
    double towerHeight,
  ) {
    final halfBaseWidth = 38.0;
    final halfTopWidth = 7.0;

    final towerColor = (phase >= 3 || isAuthenticating || isSuccess)
        ? const Color(0xFF1E293B)
        : const Color(0xFF475569);

    final linePaint = Paint()
      ..color = towerColor
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = (isAuthenticating || isSuccess)
          ? const Color(0xFFFF5100).withValues(alpha: 0.35)
          : const Color(0xFFFF5100).withValues(alpha: 0.12)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    // Main 2 Structural Truss Legs
    final pLeftTop = Offset(centerX - halfTopWidth, topY);
    final pRightTop = Offset(centerX + halfTopWidth, topY);
    final pLeftBottom = Offset(centerX - halfBaseWidth, bottomY);
    final pRightBottom = Offset(centerX + halfBaseWidth, bottomY);

    if (phase >= 3 || isAuthenticating) {
      canvas.drawLine(pLeftTop, pLeftBottom, glowPaint);
      canvas.drawLine(pRightTop, pRightBottom, glowPaint);
    }
    canvas.drawLine(pLeftTop, pLeftBottom, linePaint);
    canvas.drawLine(pRightTop, pRightBottom, linePaint);

    // Lattice Sections (Tiers with Horizontal Bracing & Diagonal X-Braces)
    const tiers = 6;
    final bracePaint = Paint()
      ..color = towerColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= tiers; i++) {
      final t = i / tiers;
      final curY = bottomY - towerHeight * t;
      final curHalfWidth = halfBaseWidth - (halfBaseWidth - halfTopWidth) * t;

      final pLeft = Offset(centerX - curHalfWidth, curY);
      final pRight = Offset(centerX + curHalfWidth, curY);

      // Horizontal Girders
      canvas.drawLine(pLeft, pRight, linePaint);

      // Diagonal X Braces
      if (i < tiers) {
        final nextT = (i + 1) / tiers;
        final nextY = bottomY - towerHeight * nextT;
        final nextHalfWidth =
            halfBaseWidth - (halfBaseWidth - halfTopWidth) * nextT;

        final nextLeft = Offset(centerX - nextHalfWidth, nextY);
        final nextRight = Offset(centerX + nextHalfWidth, nextY);

        canvas.drawLine(pLeft, nextRight, bracePaint);
        canvas.drawLine(pRight, nextLeft, bracePaint);
      }
    }

    // Center Vertical Mast / Feed line
    final mastPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(centerX, topY - 14),
      Offset(centerX, bottomY),
      mastPaint,
    );
  }

  void _drawSectorAntennas(Canvas canvas, double centerX, double topY) {
    final antennaIlluminated = phase >= 3 || isAuthenticating || isSuccess;

    final mountPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.8;

    // Triangular Mount Arms
    canvas.drawLine(
      Offset(centerX - 18, topY + 4),
      Offset(centerX + 18, topY + 4),
      mountPaint,
    );
    canvas.drawLine(
      Offset(centerX - 22, topY + 18),
      Offset(centerX + 22, topY + 18),
      mountPaint,
    );

    // Left, Center & Right Sector Antennas (Directional Panels)
    final antPaint = Paint()
      ..color = antennaIlluminated
          ? const Color(0xFFFF5100)
          : const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;

    final antBorder = Paint()
      ..color = antennaIlluminated
          ? const Color(0xFFFF7700)
          : const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final antGlow = Paint()
      ..color = const Color(0xFFFF5100).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final antennas = [
      Rect.fromCenter(center: Offset(centerX - 18, topY + 4), width: 5, height: 22),
      Rect.fromCenter(center: Offset(centerX, topY - 2), width: 5, height: 26),
      Rect.fromCenter(center: Offset(centerX + 18, topY + 4), width: 5, height: 22),
      // Lower Tier Sector Panels
      Rect.fromCenter(center: Offset(centerX - 22, topY + 18), width: 5, height: 18),
      Rect.fromCenter(center: Offset(centerX + 22, topY + 18), width: 5, height: 18),
    ];

    for (final rect in antennas) {
      if (antennaIlluminated) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          antGlow,
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        antPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        antBorder,
      );
    }
  }

  void _drawAviationBeacon(Canvas canvas, double centerX, double topY) {
    final apexY = topY - 14;

    // Lightning rod tip
    canvas.drawLine(
      Offset(centerX, topY - 2),
      Offset(centerX, apexY),
      Paint()
        ..color = const Color(0xFF1E293B)
        ..strokeWidth = 1.5,
    );

    if (phase >= 2) {
      final intensity = 0.4 + beaconProgress * 0.6;

      // Outer Warning Beacon Flare
      final flarePaint = Paint()
        ..color = Color.fromRGBO(239, 68, 68, intensity * 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(centerX, apexY), 10 * intensity, flarePaint);

      // Inner Red Beacon Bulb
      final beaconPaint = Paint()
        ..color = Color.fromRGBO(239, 68, 68, intensity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(centerX, apexY), 3.2, beaconPaint);

      // Core Highlight
      canvas.drawCircle(
        Offset(centerX, apexY),
        1.2,
        Paint()..color = Colors.white,
      );
    }
  }

  void _drawSignalWaves(Canvas canvas, double centerX, double topY) {
    final waveOrigin = Offset(centerX, topY);
    const waveCount = 3;

    for (int i = 0; i < waveCount; i++) {
      final progress = (waveProgress + i / waveCount) % 1.0;
      final radius = 24.0 + progress * 90.0;
      final opacity = (1.0 - progress).clamp(0.0, 1.0) *
          (isAuthenticating ? 0.85 : 0.55);

      final wavePaint = Paint()
        ..color = (isSuccess
                ? const Color(0xFF10B981)
                : (isFailure
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFFF5100)))
            .withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2.5 * (1.0 - progress * 0.5)).clamp(1.0, 2.5);

      // Draw Arc Waves radiating left, right, and upwards
      canvas.drawArc(
        Rect.fromCircle(center: waveOrigin, radius: radius),
        -math.pi * 0.85,
        math.pi * 1.7,
        false,
        wavePaint,
      );
    }
  }

  void _drawNetworkBeam(
    Canvas canvas,
    double centerX,
    double topY,
    Size size,
  ) {
    final targetY = size.height;
    final beamProgress = isAuthenticating ? 1.0 : (waveProgress % 1.0);

    final beamPaint = Paint()
      ..color = (isSuccess ? const Color(0xFF10B981) : const Color(0xFFFF5100))
          .withValues(alpha: 0.45)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = (isSuccess ? const Color(0xFF10B981) : const Color(0xFFFF7700))
          .withValues(alpha: 0.20)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final start = Offset(centerX, topY + 20);
    final end = Offset(centerX, targetY);

    canvas.drawLine(start, end, glowPaint);
    canvas.drawLine(start, end, beamPaint);

    // Traveling Data Packet Pulse
    final pulseY = start.dy + (end.dy - start.dy) * beamProgress;
    final packetPaint = Paint()
      ..color = isSuccess ? const Color(0xFF10B981) : const Color(0xFFFF5100)
      ..style = PaintingStyle.fill;
    final packetGlow = Paint()
      ..color = (isSuccess ? const Color(0xFF10B981) : const Color(0xFFFF7700))
          .withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(Offset(centerX, pulseY), 4, packetGlow);
    canvas.drawCircle(Offset(centerX, pulseY), 2.5, packetPaint);
  }

  @override
  bool shouldRepaint(covariant _TowerPainter oldDelegate) {
    return oldDelegate.waveProgress != waveProgress ||
        oldDelegate.beaconProgress != beaconProgress ||
        oldDelegate.particleProgress != particleProgress ||
        oldDelegate.phase != phase ||
        oldDelegate.isAuthenticating != isAuthenticating ||
        oldDelegate.isSuccess != isSuccess ||
        oldDelegate.isFailure != isFailure;
  }
}
