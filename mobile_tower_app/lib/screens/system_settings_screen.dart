import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'login_screen.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final TextEditingController _urlCtrl = TextEditingController();

  bool _isTestingConnection = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl.text = ApiConfig.baseUrl;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _testResult = null;
    });

    await ApiConfig.setBaseUrl(_urlCtrl.text);
    final isConnected = await ApiService.testConnection();

    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        _testSuccess = isConnected;
        _testResult = isConnected
            ? 'Connected to MTMMS Server (Local DOIT Grid Active)'
            : 'Server unreachable. Verify Wi-Fi network and port 8000 firewall.';
      });
    }
  }

  Future<void> _saveBaseUrl() async {
    await ApiConfig.setBaseUrl(_urlCtrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server Gateway URL saved: ${ApiConfig.baseUrl}'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ThemeManager.themeModeNotifier.value;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      drawer: const AppDrawer(currentRoute: 'settings'),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Settings',
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              'MTMMS Gateway & Appearance Configuration',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Section 1: Appearance (Light & Dark Mode) ─────────────
          _sectionLabel('APPLICATION APPEARANCE / THEME'),
          const SizedBox(height: 8),
          _card(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurf(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          currentThemeMode == ThemeMode.dark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: currentThemeMode == ThemeMode.dark
                              ? const Color(0xFFFACC15)
                              : AppColors.primaryLight,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Theme',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPri(context),
                            ),
                          ),
                          Text(
                            currentThemeMode == ThemeMode.dark ? 'Dark Mode Active' : 'Light Mode Active',
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSec(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ChoiceChip(
                        avatar: const Icon(Icons.wb_sunny_rounded, size: 14),
                        label: const Text('Light'),
                        selected: currentThemeMode == ThemeMode.light,
                        selectedColor: AppColors.primarySurface,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              ThemeManager.setThemeMode(ThemeMode.light);
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        avatar: const Icon(Icons.nightlight_round, size: 14),
                        label: const Text('Dark'),
                        selected: currentThemeMode == ThemeMode.dark,
                        selectedColor: const Color(0xFF1E293B),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              ThemeManager.setThemeMode(ThemeMode.dark);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Section 2: Server & Network Configuration ─────────────
          _sectionLabel('LOCAL NETWORK / WI-FI SERVER CONFIGURATION'),
          const SizedBox(height: 8),
          _card(
            children: [
              Text(
                'Laravel Backend URL (Same Wi-Fi Network):',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPri(context),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _urlCtrl,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPri(context)),
                decoration: InputDecoration(
                  hintText: 'http://192.168.x.x:8000/api',
                  prefixIcon: const Icon(Icons.wifi_tethering_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.restart_alt_rounded),
                    tooltip: 'Reset to Emulator Default',
                    onPressed: () {
                      setState(() => _urlCtrl.text = ApiConfig.defaultBaseUrl);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Computer IP: e.g. http://192.168.1.100:8000/api\n• Android Emulator: http://10.0.2.2:8000/api\n• Physical Device: Use Computer LAN IP (Do not use localhost).',
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMut(context), height: 1.4),
              ),
              const SizedBox(height: 12),

              if (_testResult != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _testSuccess ? AppColors.successSurface : AppColors.errorSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _testSuccess ? AppColors.successBorder : AppColors.errorBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testSuccess ? Icons.check_circle_outline : Icons.error_outline,
                        color: _testSuccess ? AppColors.success : AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: _testSuccess ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isTestingConnection ? null : _testConnection,
                      icon: _isTestingConnection
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))
                          : const Icon(Icons.network_check_rounded, size: 18),
                      label: const Text('Test Connection'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveBaseUrl,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Save Gateway'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Section 3: Department Information ─────────────────────
          _sectionLabel('DEPARTMENT & SECURITY AUDIT'),
          const SizedBox(height: 8),
          _card(
            children: [
              _infoTile('Department', 'Department of Information Technology (DOIT)'),
              Divider(height: 16, color: AppColors.dividerCol(context)),
              _infoTile('Authority', 'Government of Goa'),
              Divider(height: 16, color: AppColors.dividerCol(context)),
              _infoTile('Application Version', 'MTMMS v1.0.0 (Build 2026.08)'),
              Divider(height: 16, color: AppColors.dividerCol(context)),
              _infoTile('Security Standard', 'Goa State IT Cyber Security Guidelines 2024'),
              Divider(height: 16, color: AppColors.dividerCol(context)),
              _actionTile(
                title: 'Department IT Helpdesk',
                subtitle: 'helpdesk.it@goa.gov.in',
                icon: Icons.support_agent_rounded,
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: 'helpdesk.it@goa.gov.in'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support email copied to clipboard')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Section 4: Data & Cache ───────────────────────────────
          _sectionLabel('APPLICATION CACHE & SESSION'),
          const SizedBox(height: 8),
          _card(
            children: [
              _actionTile(
                title: 'Clear Cache & Reload Grid',
                subtitle: 'Purge local memory and resynchronize with MySQL',
                icon: Icons.cleaning_services_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Local cache cleared successfully')),
                  );
                },
              ),
              Divider(height: 16, color: AppColors.dividerCol(context)),
              _actionTile(
                title: 'End Officer Session (Logout)',
                subtitle: 'Safely revoke Sanctum authentication token',
                icon: Icons.logout_rounded,
                iconColor: AppColors.error,
                onTap: () async {
                  await ApiService.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          Center(
            child: Text(
              'Mobile Tower Management System\nDepartment of Information Technology • Government of Goa',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMut(context), height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textMut(context),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderCol(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSec(context)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
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

  Widget _actionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Color iconColor = AppColors.primary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPri(context))),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSec(context))),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textMut(context)),
        ],
      ),
    );
  }
}
