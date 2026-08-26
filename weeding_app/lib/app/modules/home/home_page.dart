import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/animated_widgets.dart';
import '../../core/widgets/micro_interactions.dart';
import '../../core/widgets/shared_components.dart';
import '../../routes/app_routes.dart';
import 'home_controller.dart';
import '../auth/auth_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.loadStats,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: FadeInSlide(
                  duration: const Duration(milliseconds: 600),
                  child: _buildHeader(authController),
                ),
              ),

              // ── KPI Grid ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Obx(() => _buildKpiGrid(controller)),
                ),
              ),

              // ── Invitation Status ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Obx(() => FadeInSlide(
                    delay: const Duration(milliseconds: 300),
                    child: _buildInvitationStatus(controller),
                  )),
                ),
              ),

              // ── Quick Actions ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: FadeInSlide(
                    delay: const Duration(milliseconds: 450),
                    child: _buildQuickActions(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  // ── Header ──
  Widget _buildHeader(AuthController authController) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  final name = authController.profile.value?.fullName ?? 'Marie';
                  return Text(
                    'Bonjour, $name 👋',
                    style: AppTextStyles.headlineLgMobile.copyWith(
                      color: AppColors.onSurface,
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Text(
                  '${DateTime.now().day} ${_monthName(DateTime.now().month)} ${DateTime.now().year}',
                  style: AppTextStyles.bodyMdOnVariant,
                ),
              ],
            ),
          ),
          Obx(() {
            final initials = authController.profile.value?.fullName
                    .split(' ')
                    .map((e) => e.isNotEmpty ? e[0] : '')
                    .join()
                    .toUpperCase()
                    .substring(0, 2) ??
                'AD';
            return UserAvatar(
              initials: initials,
              radius: 24,
              backgroundColor: AppColors.primary,
            );
          }),
        ],
      ),
    );
  }

  // ── KPI Grid ──
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF7A3D), Color(0xFFE85D2A)],
          ),
          label: 'Invités',
          value: controller.totalGuests.value,
          delay: 0,
        ),
        _KpiCard(
          icon: Icons.table_restaurant_rounded,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9C4236), Color(0xFFB85A4E)],
          ),
          label: 'Tables',
          value: controller.totalTables.value,
          delay: 100,
        ),
        _KpiCard(
          icon: Icons.event_seat_rounded,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF76583D), Color(0xFF9A7A5E)],
          ),
          label: 'Chaises',
          value: controller.totalChairs.value,
          delay: 200,
        ),
        _KpiCard(
          icon: Icons.perm_media_rounded,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
          ),
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
              StatusBadge(
                label: '$total total',
                color: AppColors.primary,
              ),
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
                  // Animated donut segments
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
                        ),
                      ),
                      Text(
                        'Invités',
                        style: AppTextStyles.labelMdOnVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _StatusLegend(
            color: AppColors.primaryContainer,
            label: 'En attente',
            count: pending,
          ),
          const SizedBox(height: 10),
          _StatusLegend(
            color: AppColors.tertiaryContainer,
            label: 'Média reçu',
            count: mediaUploaded,
          ),
          const SizedBox(height: 10),
          _StatusLegend(
            color: const Color(0xFF4CAF50),
            label: 'Carte débloquée',
            count: cardUnlocked,
          ),
        ],
      ),
    );
  }

  // ── Quick Actions ──
  Widget _buildQuickActions() {
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actions rapides', style: AppTextStyles.titleLg),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.person_add_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7A3D), Color(0xFFE85D2A)],
                  ),
                  title: 'Ajouter\nun invité',
                  onTap: () => Get.toNamed(AppRoutes.guests),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.table_restaurant_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C4236), Color(0xFFB85A4E)],
                  ),
                  title: 'Gérer\nles tables',
                  onTap: () => Get.toNamed(AppRoutes.tables),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.analytics_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                  ),
                  title: 'Suivi des\ninvitations',
                  onTap: () => Get.toNamed(AppRoutes.invitations),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.qr_code_2_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF76583D), Color(0xFF9A7A5E)],
                  ),
                  title: 'QR entrée\nsalle',
                  onTap: () => Get.toNamed(AppRoutes.entranceQr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    return months[month];
  }
}

// ── KPI Card ──
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String label;
  final int value;
  final int delay;

  const _KpiCard({
    required this.icon,
    required this.gradient,
    required this.label,
    required this.value,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInSlide(
      delay: Duration(milliseconds: 100 + delay),
      duration: const Duration(milliseconds: 500),
      child: HoverCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: AppTextStyles.headlineLg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(label, style: AppTextStyles.labelMd),
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: AppTextStyles.bodyMdOnVariant),
        ),
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
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Quick Action Card ──
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradient.colors.first.withValues(alpha: 0.08),
              gradient.colors.last.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: gradient.colors.first.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
                height: 1.3,
              ),
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

    // Pending
    final pendingAngle = (pending / total) * totalAngle;
    if (pendingAngle > 0) {
      paint.color = AppColors.primaryContainer;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        pendingAngle,
        false,
        paint,
      );
      startAngle += pendingAngle;
    }

    // Media uploaded
    final mediaAngle = (mediaUploaded / total) * totalAngle;
    if (mediaAngle > 0) {
      paint.color = AppColors.tertiaryContainer;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        mediaAngle,
        false,
        paint,
      );
      startAngle += mediaAngle;
    }

    // Card unlocked
    final unlockedAngle = (cardUnlocked / total) * totalAngle;
    if (unlockedAngle > 0) {
      paint.color = const Color(0xFF4CAF50);
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
