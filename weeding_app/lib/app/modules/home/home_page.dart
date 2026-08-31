import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/animated_widgets.dart';
import '../../core/widgets/micro_interactions.dart';
import '../../core/widgets/shared_components.dart';
import '../../core/widgets/wedding_header.dart';
import '../../routes/app_routes.dart';
import 'home_controller.dart';
import '../auth/auth_controller.dart';
import '../navigation/main_navigation_controller.dart';
import '../subscription/subscription_banner.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Gradient Header with greeting ──
          _buildWeddingHeader(authController),
          // ── Scrollable Content ──
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // ── Rappel de forfait (silencieux tant que tout va bien) ──
                    const SubscriptionBanner(),
                    // ── KPI Grid ──
                    Obx(() => _buildKpiGrid(controller)),
                    const SizedBox(height: 20),
                    // ── Invitation Status ──
                    Obx(
                      () => FadeInSlide(
                        delay: const Duration(milliseconds: 300),
                        child: _buildInvitationStatus(controller),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ── Quick Actions ──
                    FadeInSlide(
                      delay: const Duration(milliseconds: 450),
                      child: _buildQuickActions(),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Wedding Header with Greeting + Avatar ──
  Widget _buildWeddingHeader(AuthController authController) {
    return WeddingHeader(
      title: '',
      showBack: false,
      trailing: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.tune_rounded, color: AppColors.dark, size: 21),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final name =
                authController.profile.value?.fullName ?? 'Organisateur';
            final parts = name.split(' ').where((e) => e.isNotEmpty).toList();
            final initials = parts.length >= 2
                ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                : name.substring(0, math.min(2, name.length)).toUpperCase();
            return Row(
              children: [
                UserAvatar(
                  initials: initials,
                  radius: 20,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.titleLg),
                      const SizedBox(height: 2),
                      Text(
                        '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}',
                        style: AppTextStyles.bodyMdOnVariant.copyWith(
                          color: AppColors.dark.withValues(alpha: 0.58),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          Text(
            'Comment organiser votre mariage ?',
            style: AppTextStyles.displayMd.copyWith(
              color: AppColors.dark,
              fontSize: 26,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          TapScale(
            onTap: () => Get.find<MainNavigationController>().selectTab(
              MainNavigationController.guestsTab,
            ),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.dark,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Rechercher un invité, une table…',
                    style: AppTextStyles.bodyMdOnVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── KPI Grid — Dark cards matching design ──
  Widget _buildKpiGrid(HomeController controller) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        _KpiCard(
          icon: Icons.group_rounded,
          color: AppColors.dark,
          label: 'Invités',
          value: controller.totalGuests.value,
          delay: 0,
        ),
        _KpiCard(
          icon: Icons.table_restaurant_rounded,
          color: Colors.white,
          label: 'Tables',
          value: controller.totalTables.value,
          delay: 100,
        ),
        _KpiCard(
          icon: Icons.event_seat_rounded,
          color: AppColors.secondary,
          label: 'Chaises',
          value: controller.totalChairs.value,
          delay: 200,
        ),
        _KpiCard(
          icon: Icons.perm_media_rounded,
          color: AppColors.primary,
          label: 'Médias reçus',
          value: controller.totalMedia.value,
          delay: 300,
        ),
      ],
    );
  }

  // ── Invitation Status ──
  Widget _buildInvitationStatus(HomeController controller) {
    final total = controller.totalGuests.value;
    final pending = controller.pendingGuests.value;
    final mediaUploaded = controller.mediaUploaded.value;
    final cardUnlocked = controller.cardUnlocked.value;

    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Statut des invitations', style: AppTextStyles.titleLg),
              StatusBadge(label: '$total total', color: AppColors.dark),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CustomPaint(
                      painter: _DonutPainter(
                        pending: pending,
                        mediaUploaded: mediaUploaded,
                        cardUnlocked: cardUnlocked,
                        total: total,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        total.toString(),
                        style: AppTextStyles.displayMdPrimary.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      Text('Invités', style: AppTextStyles.labelMdOnVariant),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _StatusLegend(
            color: AppColors.statusPending,
            label: 'En attente',
            count: pending,
          ),
          const SizedBox(height: 10),
          _StatusLegend(
            color: AppColors.statusMediaReceived,
            label: 'Média reçu',
            count: mediaUploaded,
          ),
          const SizedBox(height: 10),
          _StatusLegend(
            color: AppColors.statusCardUnlocked,
            label: 'Carte débloquée',
            count: cardUnlocked,
          ),
        ],
      ),
    );
  }

  // ── Quick Actions — 2x2 grid of service cards ──
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions rapides', style: AppTextStyles.titleLg),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _QuickActionCard(
              icon: Icons.person_add_rounded,
              color: AppColors.primary,
              title: 'Ajouter\nun invité',
              subtitle: 'Invités',
              onTap: () => Get.find<MainNavigationController>().selectTab(
                MainNavigationController.guestsTab,
              ),
            ),
            _QuickActionCard(
              icon: Icons.table_restaurant_rounded,
              color: AppColors.dark,
              title: 'Gérer\nles tables',
              subtitle: 'Tables',
              onTap: () => Get.find<MainNavigationController>().selectTab(
                MainNavigationController.tablesTab,
              ),
            ),
            _QuickActionCard(
              icon: Icons.analytics_rounded,
              color: AppColors.dark,
              title: 'Suivi des\ninvitations',
              subtitle: 'Suivi',
              onTap: () => Get.find<MainNavigationController>().selectTab(
                MainNavigationController.invitationsTab,
              ),
            ),
            _QuickActionCard(
              icon: Icons.qr_code_2_rounded,
              color: AppColors.secondary,
              title: 'QR entrée\nsalle',
              subtitle: 'QR Code',
              onTap: () => Get.toNamed(AppRoutes.entranceQr),
            ),
          ],
        ),
      ],
    );
  }
}

// ── KPI Card — Dark card matching design ──
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int value;
  final int delay;

  const _KpiCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = color.computeLuminance() < 0.35;
    final contentColor = isDark ? Colors.white : AppColors.dark;
    return FadeInSlide(
      delay: Duration(milliseconds: 100 + delay),
      duration: const Duration(milliseconds: 500),
      child: HoverCard(
        backgroundColor: color,
        padding: const EdgeInsets.all(16),
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary
                    : AppColors.dark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDark ? AppColors.onPrimary : AppColors.dark,
                size: 18,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: AppTextStyles.headlineLg.copyWith(
                    fontWeight: FontWeight.w800,
                    color: contentColor,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.labelMd.copyWith(
                    color: contentColor.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Legend ──
class _StatusLegend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _StatusLegend({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTextStyles.bodyMdOnVariant)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: AppTextStyles.bodyLg.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Quick Action Card — matching design style ──
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = color.computeLuminance() < 0.35;
    final contentColor = isDark ? Colors.white : AppColors.dark;
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.dark, width: 1.25),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isDark)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.onPrimary, size: 18),
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.dark, size: 18),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: contentColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.labelMd.copyWith(
                    color: contentColor.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Donut Chart Painter ──
class _DonutPainter extends CustomPainter {
  final int pending;
  final int mediaUploaded;
  final int cardUnlocked;
  final int total;

  _DonutPainter({
    required this.pending,
    required this.mediaUploaded,
    required this.cardUnlocked,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 20.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background
    paint.color = AppColors.surfaceContainerHigh;
    canvas.drawCircle(center, radius, paint);

    if (total == 0) return;

    double startAngle = -math.pi / 2;
    final totalAngle = 2 * math.pi;

    // Pending — yellow
    final pendingAngle = (pending / total) * totalAngle;
    if (pendingAngle > 0) {
      paint.color = AppColors.statusPending;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        pendingAngle,
        false,
        paint,
      );
      startAngle += pendingAngle;
    }

    // Media uploaded — dark
    final mediaAngle = (mediaUploaded / total) * totalAngle;
    if (mediaAngle > 0) {
      paint.color = AppColors.statusMediaReceived;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        mediaAngle,
        false,
        paint,
      );
      startAngle += mediaAngle;
    }

    // Card unlocked — terracotta
    final unlockedAngle = (cardUnlocked / total) * totalAngle;
    if (unlockedAngle > 0) {
      paint.color = AppColors.statusCardUnlocked;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        unlockedAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) => true;
}
