import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

enum WeddingNavItem { dashboard, guests, tables, invitations }

/// Barre de navigation editoriale (mobile only).
/// Reproduit la "BottomNavBar" du design Stitch.
class WeddingBottomNav extends StatelessWidget {
  const WeddingBottomNav({
    super.key,
    required this.current,
    required this.onTap,
  });

  final WeddingNavItem current;
  final ValueChanged<WeddingNavItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: Color(0x33E0BFBF))),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F570013),
            blurRadius: 40,
            offset: Offset(0, -12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavTab(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                active: current == WeddingNavItem.dashboard,
                onTap: () => onTap(WeddingNavItem.dashboard),
              ),
              _NavTab(
                icon: Icons.group_rounded,
                label: 'Invites',
                active: current == WeddingNavItem.guests,
                onTap: () => onTap(WeddingNavItem.guests),
              ),
              _NavTab(
                icon: Icons.table_bar_rounded,
                label: 'Tables',
                active: current == WeddingNavItem.tables,
                onTap: () => onTap(WeddingNavItem.tables),
              ),
              _NavTab(
                icon: Icons.mail_rounded,
                label: 'Invitations',
                active: current == WeddingNavItem.invitations,
                onTap: () => onTap(WeddingNavItem.invitations),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : const Color(0xFFA8A29E);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: active ? 16 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceContainerLow : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 9,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
