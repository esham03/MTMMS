import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ============================================================
// OFFICIAL MTMMS APP BAR
// ============================================================
class MTMMSAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  const MTMMSAppBar({
    super.key,
    required this.title,
    this.subtitle = 'DoIT • Government of Goa',
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + 3 + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final titleColor = isDark ? Colors.white : const Color(0xFF0A0F1D);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.70)
        : const Color(0xFFFF5100);
    final iconColor = isDark ? Colors.white : const Color(0xFF0A0F1D);

    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      iconTheme: IconThemeData(color: iconColor),
      actionsIconTheme: IconThemeData(color: iconColor),
      backgroundColor: isDark ? AppColors.deepNavy : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? null : Colors.white,
                gradient: isDark ? AppColors.navBarGradient : null,
              ),
            ),
          ),
          // Solar Orange accent strip (matches web --primary #FF5100)
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
        ],
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: titleColor,
              letterSpacing: 0.2,
            ),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: isDark ? FontWeight.w500 : FontWeight.w600,
                color: subtitleColor,
                letterSpacing: 0.3,
              ),
            ),
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}

// ============================================================
// OFFICIAL MTMMS CARD
// ============================================================
class MTMMSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;

  const MTMMSCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.color,
    this.borderColor,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = color ?? AppColors.cardBg(context);
    final effectiveBorder = borderColor ?? AppColors.borderCol(context);

    Widget content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: effectiveBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}

// ============================================================
// OFFICIAL MTMMS STAT CARD (METRICS)
// ============================================================
class MTMMSStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback? onTap;

  const MTMMSStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.badgeText,
    this.badgeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MTMMSCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? iconColor).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (badgeColor ?? iconColor).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    badgeText!,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: badgeColor ?? iconColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMut(context),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPri(context),
              height: 1.1,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textSec(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// OFFICIAL MTMMS BUTTON
// ============================================================
enum MTMMSButtonType { primary, secondary, outline, danger }

class MTMMSButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final MTMMSButtonType type;
  final double? width;
  final double height;

  const MTMMSButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.type = MTMMSButtonType.primary,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (type) {
      case MTMMSButtonType.primary:
        bg = AppColors.primary;
        fg = Colors.white;
        break;
      case MTMMSButtonType.secondary:
        bg = AppColors.primaryLight;
        fg = Colors.white;
        break;
      case MTMMSButtonType.outline:
        bg = Colors.transparent;
        fg = AppColors.textPri(context);
        border = BorderSide(color: AppColors.borderCol(context), width: 1.2);
        break;
      case MTMMSButtonType.danger:
        bg = AppColors.error;
        fg = Colors.white;
        break;
    }

    Widget labelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && !isLoading) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
        ],
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: fg,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: type == MTMMSButtonType.outline ? 0 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: isLoading ? null : onPressed,
        child: labelWidget,
      ),
    );
  }
}

// ============================================================
// OFFICIAL SECTION HEADER
// ============================================================
class MTMMSSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;

  const MTMMSSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.primaryLight),
                const SizedBox(width: 7),
              ],
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMut(context),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ============================================================
// STATUS BADGE
// ============================================================
class StatusBadge extends StatelessWidget {
  final String status;
  final bool isSolid;

  const StatusBadge({
    super.key,
    required this.status,
    this.isSolid = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.trim().toLowerCase();
    Color bg;
    Color fg;
    Color border;

    if (s == 'active' || s == 'paid' || s == 'live grid') {
      fg = AppColors.success;
      bg = AppColors.successSurface;
      border = AppColors.successBorder;
    } else if (s == 'due' || s == 'pending' || s == 'warning') {
      fg = AppColors.warning;
      bg = AppColors.warningSurface;
      border = AppColors.warningBorder;
    } else if (s == 'inactive' || s == 'overdue' || s == 'error') {
      fg = AppColors.error;
      bg = AppColors.errorSurface;
      border = AppColors.errorBorder;
    } else if (s == 'government') {
      fg = AppColors.primaryLight;
      bg = AppColors.primarySurface;
      border = AppColors.border;
    } else if (s == 'private') {
      fg = const Color(0xFF7C3AED);
      bg = const Color(0xFFF3E8FF);
      border = const Color(0xFFDDD6FE);
    } else {
      fg = AppColors.textSecondary;
      bg = AppColors.borderLight;
      border = AppColors.border;
    }

    final displayText = status.isNotEmpty
        ? status[0].toUpperCase() + status.substring(1)
        : 'Status';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSolid ? fg : bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isSolid ? fg : border, width: 1),
      ),
      child: Text(
        displayText,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: isSolid ? Colors.white : fg,
        ),
      ),
    );
  }
}

// ============================================================
// SECURE STATUS INDICATOR
// ============================================================
class SecureStatusIndicator extends StatelessWidget {
  final String label;
  final bool isSecure;

  const SecureStatusIndicator({
    super.key,
    this.label = 'Secure Government Network',
    this.isSecure = true,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isSecure ? AppColors.primary : AppColors.error;
    final surfaceColor =
        isSecure ? const Color(0xFFFFF4EC) : AppColors.errorSurface;
    final borderColor = isSecure
        ? const Color(0xFFFF5100).withValues(alpha: 0.35)
        : AppColors.errorBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7.5,
            height: 7.5,
            decoration: BoxDecoration(
              color: activeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.6),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: activeColor,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BIOMETRIC AUTH BUTTON
// ============================================================
class BiometricButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isSupported;
  final String label;

  const BiometricButton({
    super.key,
    required this.onTap,
    this.isSupported = true,
    this.label = 'Biometric Sign In',
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: const Color(0xFFFFF4EC),
        side: const BorderSide(color: AppColors.primary, width: 1.3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: isSupported ? onTap : null,
      icon: const Icon(
        Icons.fingerprint_rounded,
        size: 22,
        color: AppColors.primary,
      ),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

