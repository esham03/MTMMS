import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/authorized_personnel_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/location_filter_screen.dart';
import '../screens/login_screen.dart';
import '../screens/map_view_screen.dart';
import '../screens/officer_profile_screen.dart';
import '../screens/operator_management_screen.dart';
import '../screens/owners/owner_management_screen.dart';
import '../screens/payment_history_screen.dart';
import '../screens/rent_management_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/tower_management_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatefulWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Map<String, dynamic> _user = {
    'name': 'Administrator',
    'role': 'Admin',
    'department': 'Department of Information Technology',
  };

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (mounted && user != null) {
      setState(() {
        _user = {..._user, ...user};
      });
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to securely end your officer session in the MTMMS Official Portal?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = _user['role']?.toString().toUpperCase() ?? 'ADMIN';
    final name = _user['name']?.toString() ?? 'Administrator';

    return Drawer(
      backgroundColor: AppColors.surfaceBg(context),
      child: Column(
        children: [
          // ── Official Government Header (Deep Navy, matching web sidebar) ──
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.sidebarGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primary, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/goa-emblem.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.account_balance_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4ADE80),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  role,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Department of Information Technology\nGovernment of Goa',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Orange accent strip at bottom of header (matches web sidebar)
                Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                ),
              ],
            ),
          ),

          // ── Streamlined Navigation list ──────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _sectionLabel('INFRASTRUCTURE'),
                _navItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'MTMMS Dashboard',
                  route: 'dashboard',
                  onTap: () => _navigate(
                    context,
                    'dashboard',
                    const DashboardScreen(),
                  ),
                ),
                _navItem(
                  context,
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map_rounded,
                  label: 'Interactive Map View',
                  route: 'map',
                  onTap: () => _navigate(
                    context,
                    'map',
                    const MapViewScreen(),
                  ),
                ),
                _navItem(
                  context,
                  icon: Icons.cell_tower_outlined,
                  activeIcon: Icons.cell_tower_rounded,
                  label: 'Tower Management',
                  route: 'towers',
                  onTap: () => _navigate(
                    context,
                    'towers',
                    const TowerManagementScreen(),
                  ),
                ),
                _navItem(
                  context,
                  icon: Icons.apartment_outlined,
                  activeIcon: Icons.apartment_rounded,
                  label: 'Tower Owners (Estate)',
                  route: 'owners',
                  onTap: () => _navigate(
                    context,
                    'owners',
                    const OwnerManagementScreen(),
                  ),
                ),
                _navItem(
                  context,
                  icon: Icons.travel_explore_rounded,
                  activeIcon: Icons.travel_explore_rounded,
                  label: 'Location Browser',
                  route: 'locations',
                  onTap: () => _navigate(
                    context,
                    'locations',
                    const LocationFilterScreen(),
                  ),
                ),
                _navItem(
                  context,
                  icon: Icons.cell_wifi_outlined,
                  activeIcon: Icons.cell_wifi_rounded,
                  label: 'Network Operators',
                  route: 'operators',
                  onTap: () => _navigate(
                    context,
                    'operators',
                    const OperatorManagementScreen(),
                  ),
                ),

                const Divider(height: 16),
                _sectionLabel('FINANCE & REVENUE'),

                _navItem(
                  context,
                  icon: Icons.currency_rupee_rounded,
                  activeIcon: Icons.currency_rupee_rounded,
                  label: 'Rent & Lease Terms',
                  route: 'rent',
                  onTap: () => _navigate(
                    context,
                    'rent',
                    const RentManagementScreen(),
                  ),
                ),
                _navItem(
                  context,
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Payment Records',
                  route: 'payments',
                  onTap: () => _navigate(
                    context,
                    'payments',
                    const PaymentHistoryScreen(
                      towerId: '',
                      owner: 'All State Towers',
                    ),
                  ),
                ),
                _navItem(
                  context,
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics_rounded,
                  label: 'Official Reports & Analytics',
                  route: 'reports',
                  onTap: () => _navigate(
                    context,
                    'reports',
                    const ReportsScreen(),
                  ),
                ),

                const Divider(height: 16),
                _sectionLabel('ADMINISTRATION & ACCESS'),

                _navItem(
                  context,
                  icon: Icons.badge_outlined,
                  activeIcon: Icons.badge_rounded,
                  label: 'Officer Profile',
                  route: 'profile',
                  onTap: () => _navigate(
                    context,
                    'profile',
                    const OfficerProfileScreen(),
                  ),
                ),
                _navItem(
                  context,
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  label: 'Authorized Personnel',
                  route: 'personnel',
                  onTap: () => _navigate(
                    context,
                    'personnel',
                    const AuthorizedPersonnelScreen(),
                  ),
                ),
              ],
            ),
          ),

          // ── Theme Mode Toggle & Logout ─────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderCol(context)),
              ),
            ),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeManager.themeModeNotifier,
              builder: (context, currentMode, _) {
                final isDark = currentMode == ThemeMode.dark;
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: isDark
                          ? const Color(0xFFFACC15)
                          : AppColors.primary,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    isDark ? 'Dark Theme Active' : 'Light Theme Active',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Tap to switch mode',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  trailing: Switch.adaptive(
                    value: isDark,
                    activeColor: AppColors.primary,
                    onChanged: (val) => ThemeManager.toggleTheme(),
                  ),
                  onTap: () => ThemeManager.toggleTheme(),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderCol(context)),
              ),
            ),
            child: ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 18,
                ),
              ),
              title: Text(
                'Sign Out',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
              subtitle: Text(
                'End secure officer session',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  color: AppColors.textMut(context),
                ),
              ),
              onTap: () => _confirmLogout(context),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textMut(context),
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
    required VoidCallback onTap,
  }) {
    final bool isSelected = widget.currentRoute == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1.5),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primarySurf(context)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        leading: Icon(
          isSelected ? activeIcon : icon,
          size: 20,
          color: isSelected ? AppColors.primary : AppColors.textSec(context),
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textPri(context),
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 3.5,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  void _navigate(BuildContext context, String route, Widget screen) {
    Navigator.pop(context);
    if (widget.currentRoute == route) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
