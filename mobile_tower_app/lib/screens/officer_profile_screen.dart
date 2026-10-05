import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/government_components.dart';
import 'authorized_personnel_screen.dart';
import 'login_screen.dart';

class OfficerProfileScreen extends StatefulWidget {
  const OfficerProfileScreen({super.key});

  @override
  State<OfficerProfileScreen> createState() => _OfficerProfileScreenState();
}

class _OfficerProfileScreenState extends State<OfficerProfileScreen> {
  Map<String, dynamic> _profile = {
    'name': 'Administrator',
    'email': 'admin@goa.gov.in',
    'role': 'Administrator',
    'department': 'Department of Information Technology',
    'government': 'Government of Goa',
    'designation': 'Senior IT Systems Officer',
    'phone': '+91 832 2419000',
    'status': 'Active (Authorized)',
  };

  String? _lastLogin;
  bool _biometricEnabled = true;
  bool _hasToken = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await AuthService.getUser();
    final lastLogin = await AuthService.getLastLogin();
    final bioEnabled = await AuthService.isBiometricEnabled();
    final hasTok = await AuthService.hasToken();

    if (mounted) {
      setState(() {
        if (user != null) _profile = {..._profile, ...user};
        _lastLogin = lastLogin;
        _biometricEnabled = bioEnabled;
        _hasToken = hasTok;
      });
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to securely end your officer session in MTMMS?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ApiService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile['name']?.toString() ?? 'Administrator';
    final email = _profile['email']?.toString() ?? 'admin@goa.gov.in';
    final role = _profile['role']?.toString().toUpperCase() ?? 'ADMIN';
    final designation =
        _profile['designation']?.toString() ?? 'Senior Systems Officer';
    final dept = _profile['department']?.toString() ??
        'Department of Information Technology';

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      drawer: const AppDrawer(currentRoute: 'profile'),
      appBar: const MTMMSAppBar(
        title: 'Officer Profile',
        subtitle: 'Official Department Credentials',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Officer Identity Card ─────────────────────────────────
          MTMMSCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'O',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPri(context),
                        ),
                      ),
                      Text(
                        designation,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSec(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurf(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ROLE: $role',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Department & Designation Details ──────────────────────
          MTMMSCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MTMMSSectionHeader(
                  title: 'OFFICIAL JURISDICTION & ASSIGNMENT',
                  icon: Icons.account_balance_rounded,
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: AppColors.dividerCol(context)),
                const SizedBox(height: 8),
                _specRow('Department', dept),
                _specRow('Organization', 'Government of Goa'),
                _specRow('Official Email', email),
                _specRow('Contact Phone', _profile['phone']?.toString() ?? '+91 832 2419000'),
                _specRow('Account Status', 'Active / Authorized Officer'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Authentication & Security Status ──────────────────────
          MTMMSCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MTMMSSectionHeader(
                  title: 'AUTHENTICATION & SECURITY STATUS',
                  icon: Icons.security_rounded,
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: AppColors.dividerCol(context)),
                const SizedBox(height: 8),
                _specRow('Auth Method', 'Laravel Sanctum Bearer Token'),
                _specRow('Token State', _hasToken ? 'Active & Encrypted' : 'Not Loaded'),
                _specRow('Biometric Quick Access', _biometricEnabled ? 'Configured (Hardware)' : 'Disabled'),
                _specRow('Last Access', _lastLogin != null ? _lastLogin!.split('T').first : 'Current Session'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Manage Authorized Personnel Shortcut ──────────────────
          MTMMSCard(
            padding: const EdgeInsets.all(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AuthorizedPersonnelScreen(),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurf(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.group_add_rounded,
                    color: AppColors.primaryLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Authorized Personnel & System Users',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPri(context),
                        ),
                      ),
                      Text(
                        'Manage system officers, roles, and grid permissions',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSec(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Sign Out Button ───────────────────────────────────────
          MTMMSButton(
            text: 'Sign Out from MTMMS',
            icon: Icons.logout_rounded,
            type: MTMMSButtonType.danger,
            onPressed: _confirmLogout,
          ),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSec(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPri(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
