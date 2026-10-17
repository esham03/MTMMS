import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/server_discovery_service.dart';
import '../theme/app_theme.dart';
import '../widgets/government_components.dart';
import '../widgets/tower_canvas_animation.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? initialEmail;

  const LoginScreen({super.key, this.initialEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _loginSuccess = false;
  bool _loginFailure = false;
  String? _errorMessage;
  String _statusText = 'INITIALIZING TOWER GRID...';

  int _animationPhase = 1; // 1 to 7
  Timer? _phaseTimer;
  bool _hasBiometrics = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _usernameCtrl.text = widget.initialEmail!;
    }
    _loadInitialState();
    _startAnimationSequence();
  }

  Future<void> _loadInitialState() async {
    final canBio = await AuthService.canCheckBiometrics();
    if (mounted) {
      setState(() => _hasBiometrics = canBio);
    }
  }

  void _startAnimationSequence() {
    // 7-Phase non-blocking activation sequence (2.5 seconds total)
    _phaseTimer = Timer.periodic(const Duration(milliseconds: 380), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_animationPhase < 7) {
        setState(() {
          _animationPhase++;
          switch (_animationPhase) {
            case 2:
              _statusText = 'BEACON ACTIVATED';
              break;
            case 3:
              _statusText = 'ANTENNAS ILLUMINATED';
              break;
            case 4:
              _statusText = 'TRANSMITTING SIGNAL...';
              break;
            case 5:
              _statusText = 'ESTABLISHING GRID BEAM...';
              break;
            case 6:
              _statusText = 'PANEL CONNECTED';
              break;
            case 7:
              _statusText = 'MTMMS NETWORK READY';
              timer.cancel();
              break;
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _executeLogin(String email, String password) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _loginSuccess = false;
      _loginFailure = false;
      _errorMessage = null;
      _statusText = 'CONNECTING TO MTMMS...';
    });

    try {
      setState(() => _statusText = 'AUTHENTICATING...');

      // Call the REAL Laravel REST API
      await ApiService.login(email.trim(), password);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loginSuccess = true;
        _loginFailure = false;
        _statusText = 'CONNECTION ESTABLISHED';
      });

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const DashboardScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loginSuccess = false;
        _loginFailure = true;
        _statusText = 'AUTHENTICATION FAILED';
        _errorMessage = e.toString().replaceAll('Exception: ', '').trim();
      });
    }
  }

  void _onSignInPressed() {
    if (!_formKey.currentState!.validate()) return;
    _executeLogin(_usernameCtrl.text, _passwordCtrl.text);
  }

  // -------------------------------------------------------------
  // BIOMETRIC AUTHENTICATION FLOW
  // -------------------------------------------------------------
  Future<void> _handleBiometricLogin() async {
    final hasToken = await AuthService.hasToken();

    if (!hasToken) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please sign in with your official credentials first to enable biometric access.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final authenticated = await AuthService.authenticateWithBiometrics(
      reason: 'Verify officer identity to access MTMMS Government Portal',
    );

    if (authenticated && mounted) {
      setState(() {
        _isLoading = true;
        _statusText = 'VERIFYING SESSION...';
      });

      // Validate session with backend
      final isAlive = await ApiService.testConnection();

      if (mounted) {
        if (isAlive) {
          setState(() {
            _isLoading = false;
            _loginSuccess = true;
            _statusText = 'BIOMETRIC VERIFIED';
          });
          await Future.delayed(const Duration(milliseconds: 600));
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else {
          setState(() {
            _isLoading = false;
            _loginFailure = true;
            _statusText = 'SESSION EXPIRED';
            _errorMessage = 'Session expired. Please sign in with password.';
          });
        }
      }
    }
  }

  // -------------------------------------------------------------
  // IDENTITY / PHOTO VERIFICATION DIALOG
  // -------------------------------------------------------------
  void _showPhotoVerificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF5100), width: 1.2),
        ),
        title: Text(
          'Officer Identity Verification',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0A0F1D),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFFFF4EC),
                border: Border.all(color: const Color(0xFFFF5100), width: 1.5),
              ),
              child: const Icon(
                Icons.badge_outlined,
                size: 54,
                color: Color(0xFFFF5100),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Identity Verification Flow',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A0F1D),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Official Department of Information Technology personnel identity check. Verification is performed in accordance with Goa IT Security guidelines.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: const Color(0xFFFF5100),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SERVER CONFIGURATION MODAL (FOR SAME-WIFI TESTING)
  // -------------------------------------------------------------
  void _showServerConfigModal() {
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
                  const Icon(Icons.dns_rounded,
                      color: Color(0xFFFF5100), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'MTMMS API Host Configuration',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A0F1D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ApiConfig.isCloudActive
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFFF5100).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ApiConfig.isCloudActive ? 'Cloud Tunnel (Any Network)' : 'Local Wi-Fi',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: ApiConfig.isCloudActive ? const Color(0xFF10B981) : const Color(0xFFFF5100),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Host: ${ApiConfig.currentHost}',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF5100),
                        side: const BorderSide(color: Color(0xFFFF5100), width: 1.1),
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.wifi_find_rounded, size: 16),
                      label: const Text('Wi-Fi Auto-Discover', style: TextStyle(fontSize: 11)),
                      onPressed: testing
                          ? null
                          : () async {
                              setModalState(() {
                                testing = true;
                                testMsg = 'Searching local Wi-Fi network...';
                                testSuccess = false;
                              });
                              final discovered = await ServerDiscoveryService.discoverServer(forceRefresh: true);
                              setModalState(() {
                                testing = false;
                                if (discovered != null) {
                                  controller.text = discovered.apiUrl;
                                  testSuccess = true;
                                  testMsg = 'Discovered MTMMS at ${discovered.ip}';
                                } else {
                                  testSuccess = false;
                                  testMsg = 'No server discovered on Wi-Fi.';
                                }
                              });
                            },
                    ),
                  ),
                  if (ApiConfig.cloudUrl.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          side: const BorderSide(color: Color(0xFF10B981), width: 1.1),
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.cloud_rounded, size: 16),
                        label: const Text('Use Cloud URL', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          controller.text = ApiConfig.cloudUrl;
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: const Color(0xFF0A0F1D)),
                decoration: InputDecoration(
                  labelText: 'MTMMS API Base URL',
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  prefixIcon: const Icon(Icons.link_rounded,
                      color: Color(0xFFFF5100)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFFFF5100), width: 1.8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (testMsg != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: testSuccess
                        ? AppColors.successSurface
                        : AppColors.errorSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: testSuccess
                          ? AppColors.successBorder
                          : AppColors.errorBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        testSuccess
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        color: testSuccess ? AppColors.success : AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          testMsg!,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: testSuccess
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF5100),
                        side: const BorderSide(color: Color(0xFFFF5100)),
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
                                testMsg = null;
                              });
                              await ApiConfig.setBaseUrl(controller.text);
                              final ok = await ApiService.testConnection();
                              setModalState(() {
                                testing = false;
                                testSuccess = ok;
                                testMsg = ok
                                    ? 'Connected successfully to MTMMS backend'
                                    : 'Server unreachable at this URL';
                              });
                            },
                      child: testing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFF5100),
                              ),
                            )
                          : const Text('Test Connection'),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                      onPressed: () async {
                        await ApiConfig.setBaseUrl(controller.text);
                        if (ctx.mounted) Navigator.pop(ctx);
                        setState(() {});
                      },
                      child: const Text('Save & Apply'),
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
      backgroundColor: const Color(0xFFFAEEE6),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFAEEE6),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFDFC),
              Color(0xFFFAEEE6),
              Color(0xFFF6E4D6),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Atmospheric solar orange ambient glow orbs in background (matches web --bg-canvas-mesh)
            Positioned(
              top: -60,
              left: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF5100).withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              top: 140,
              right: -70,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF7700).withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF5100).withValues(alpha: 0.08),
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ── Top Bar with Host Switcher & Official Goa Emblem ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFF5100)
                                    .withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5100)
                                      .withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/goa-emblem.png',
                                  width: 18,
                                  height: 18,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.shield_outlined,
                                    size: 14,
                                    color: Color(0xFFFF5100),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'DoIT • Government of Goa',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    color: const Color(0xFF1E293B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFF5100)
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5100)
                                      .withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.settings_ethernet_rounded,
                                color: Color(0xFFFF5100),
                                size: 19,
                              ),
                              tooltip: 'API Server Host',
                              onPressed: _showServerConfigModal,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Animated Telecommunications Tower Experience ────────
                    TelecomTowerExperience(
                      phase: _animationPhase,
                      isAuthenticating: _isLoading,
                      isSuccess: _loginSuccess,
                      isFailure: _loginFailure,
                      height: 200,
                    ),

                    // ── Live Network Status Badge ───────────────────────────
                    SecureStatusIndicator(
                      label: _statusText,
                      isSecure: !_loginFailure,
                    ),

                    const SizedBox(height: 12),

                    // ── Official Branding Header ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            'MTMMS',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0A0F1D),
                              letterSpacing: 2.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Mobile Tower Monitoring and Management System',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Sign In Card ────────────────────────────────────────
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _loginSuccess
                                  ? const Color(0xFF10B981)
                                      .withValues(alpha: 0.6)
                                  : (_loginFailure
                                      ? const Color(0xFFEF4444)
                                          .withValues(alpha: 0.6)
                                      : const Color(0xFFFF5100)
                                          .withValues(alpha: 0.35)),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _loginSuccess
                                    ? const Color(0xFF10B981)
                                        .withValues(alpha: 0.22)
                                    : (_loginFailure
                                        ? const Color(0xFFEF4444)
                                            .withValues(alpha: 0.22)
                                        : const Color(0xFFFF5100)
                                            .withValues(alpha: 0.16)),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22.5),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Top Accent Bar matching web app's `border-top: 3px solid #ff5100`
                                Container(
                                  height: 3.5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _loginSuccess
                                            ? const Color(0xFF10B981)
                                            : (_loginFailure
                                                ? const Color(0xFFEF4444)
                                                : const Color(0xFFFF5100)),
                                        _loginSuccess
                                            ? const Color(0xFF34D399)
                                            : (_loginFailure
                                                ? const Color(0xFFF87171)
                                                : const Color(0xFFFF7700)),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Sign In',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 19,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF0A0F1D),
                                                  ),
                                                ),
                                                Text(
                                                  'Authorized personnel only',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11.5,
                                                    color: const Color(0xFF64748B),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(7),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Color(0xFFFFF4EC),
                                                    Color(0xFFFFEAD9),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: const Color(0xFFFF5100)
                                                      .withValues(alpha: 0.35),
                                                  width: 1.2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFFFF5100)
                                                        .withValues(alpha: 0.15),
                                                    blurRadius: 6,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.lock_outline_rounded,
                                                size: 18,
                                                color: Color(0xFFFF5100),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),

                                        // Error message if any
                                        if (_errorMessage != null)
                                          Container(
                                            padding: const EdgeInsets.all(11),
                                            margin: const EdgeInsets.only(
                                                bottom: 14),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFDF2F2),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(0xFFF5B7B1),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.error_outline_rounded,
                                                  color: Color(0xFFEF4444),
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _errorMessage!,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11.5,
                                                      color: const Color(
                                                          0xFFB91C1C),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                        // Official Email / Username Field
                                        Text(
                                          'Official Email / Username',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF0A0F1D),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _usernameCtrl,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: const Color(0xFF0A0F1D),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: InputDecoration(
                                            hintText:
                                                'Enter official email or username',
                                            hintStyle: const TextStyle(
                                                color: Color(0xFF94A3B8)),
                                            prefixIcon: const Icon(
                                              Icons.person_outline_rounded,
                                              color: Color(0xFFFF5100),
                                              size: 20,
                                            ),
                                            filled: true,
                                            fillColor: const Color(0xFFF8FAFC),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFFCBD5E1)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFFCBD5E1)),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFFF5100),
                                                width: 1.8,
                                              ),
                                            ),
                                          ),
                                          validator: (v) {
                                            if (v == null ||
                                                v.trim().isEmpty) {
                                              return 'Please enter official username or email';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),

                                        // Security Password Field
                                        Text(
                                          'Security Password',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF0A0F1D),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _passwordCtrl,
                                          obscureText: _obscurePassword,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: const Color(0xFF0A0F1D),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter password',
                                            hintStyle: const TextStyle(
                                                color: Color(0xFF94A3B8)),
                                            prefixIcon: const Icon(
                                              Icons.key_rounded,
                                              color: Color(0xFFFF5100),
                                              size: 20,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons
                                                        .visibility_off_outlined
                                                    : Icons
                                                        .visibility_outlined,
                                                color: const Color(0xFF64748B),
                                                size: 18,
                                              ),
                                              onPressed: () => setState(
                                                () => _obscurePassword =
                                                    !_obscurePassword,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: const Color(0xFFF8FAFC),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFFCBD5E1)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFFCBD5E1)),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFFF5100),
                                                width: 1.8,
                                              ),
                                            ),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) {
                                              return 'Please enter security password';
                                            }
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: 20),

                                        // Sign In Button (Solar Orange Gradient)
                                        Container(
                                          width: double.infinity,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFFFF5100),
                                                Color(0xFFFF7700),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFF5100)
                                                    .withValues(alpha: 0.38),
                                                blurRadius: 16,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor:
                                                  Colors.transparent,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: _isLoading
                                                ? null
                                                : _onSignInPressed,
                                            child: _isLoading
                                                ? Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                  Color>(
                                                            Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        'Authenticating...',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 13.5,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Text(
                                                    'Sign In',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 0.4,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                          ),
                                        ),

                                        // Quick Biometric Sign In (if supported on device)
                                        if (_hasBiometrics) ...[
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            child: BiometricButton(
                                              onTap: _handleBiometricLogin,
                                              label:
                                                  'Quick Biometric Sign In',
                                            ),
                                          ),
                                        ],

                                        const SizedBox(height: 14),

                                        // Identity Verification & Support Links
                                        Center(
                                          child: TextButton.icon(
                                            onPressed:
                                                _showPhotoVerificationDialog,
                                            icon: const Icon(
                                              Icons.verified_user_outlined,
                                              size: 15,
                                              color: Color(0xFFFF5100),
                                            ),
                                            label: Text(
                                              'Identity Verification Protocol',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: const Color(0xFF64748B),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Footer Copyright ───────────────────────────────────
                    Text(
                      'Department of Information Technology • Government of Goa',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
