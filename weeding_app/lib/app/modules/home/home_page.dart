import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/animated_widgets.dart';
import '../../core/widgets/micro_interactions.dart';
import '../../core/widgets/shared_components.dart';
import '../../routes/app_routes.dart';
import 'home_controller.dart';
import '../auth/auth_controller.dart';
import '../navigation/main_navigation_controller.dart';
import '../subscription/subscription_banner.dart';

/// Tableau de bord tenant entièrement dans un écran.
///
/// Tout est visible d'un coup d'œil : les compteurs sont sur une seule ligne,
/// le donut partage sa carte avec sa légende et les actions rapides tiennent en
/// bas de page. Le geste de tirer pour rafraîchir reste disponible même si le
/// contenu ne défile jamais.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final authController = Get.find<AuthController>();
    final tight = MediaQuery.sizeOf(context).height < 780;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildWeddingHeader(authController, tight),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.loadStats,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      // Hauteur figée sur le viewport : le contenu s'ajuste au
                      // lieu de déborder, la liste ne défile donc jamais.
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        maxHeight: constraints.maxHeight,
                      ),
                      child: _buildBody(controller, tight),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(HomeController controller, bool tight) {
    final gap = tight ? 8.0 : 12.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, gap, 16, gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SubscriptionBanner(compact: true),
          Obx(() => _buildKpiRow(controller, tight)),
          SizedBox(height: gap),
          Expanded(
            child: Obx(
              () => FadeInSlide(
                delay: const Duration(milliseconds: 250),
                child: _buildInvitationStatus(controller, tight),
              ),
            ),
          ),
          SizedBox(height: gap),
          FadeInSlide(
            delay: const Duration(milliseconds: 400),
            child: _buildQuickActions(tight),
          ),
        ],
      ),
    );
  }

  // ── En-tête : identité, question du jour et recherche ──
  Widget _buildWeddingHeader(AuthController authController, bool tight) {
    return Builder(
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 10,
          20,
          tight ? 14 : 18,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
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
                    radius: 18,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleLg.copyWith(fontSize: 17),
                        ),
                        Text(
                          '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}',
                          style: AppTextStyles.bodyMdOnVariant.copyWith(
                            fontSize: 12,
                            color: AppColors.dark.withValues(alpha: 0.58),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  TapScale(
                    onTap: () => Get.find<MainNavigationController>().selectTab(
                      MainNavigationController.settingsTab,
                    ),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: AppColors.dark,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              );
            }),
            SizedBox(height: tight ? 10 : 14),
            Text(
              'Comment organiser votre mariage ?',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.displayMd.copyWith(
                color: AppColors.dark,
                fontSize: tight ? 19 : 22,
                letterSpacing: -0.6,
                height: 1.12,
              ),
            ),
            SizedBox(height: tight ? 10 : 12),
            TapScale(
              onTap: () => Get.find<MainNavigationController>().selectTab(
                MainNavigationController.guestsTab,
              ),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: AppColors.dark,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Rechercher un invité, une table…',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMdOnVariant.copyWith(
                          fontSize: 13.5,
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
    );
  }

  // ── Compteurs : quatre tuiles sur une seule ligne ──
  Widget _buildKpiRow(HomeController controller, bool tight) {
    final tiles = [
      _KpiTile(
        icon: Icons.group_rounded,
        color: AppColors.dark,
        label: 'Invités',
        value: controller.totalGuests.value,
        delay: 0,
        tight: tight,
      ),
      _KpiTile(
        icon: Icons.table_restaurant_rounded,
        color: Colors.white,
        label: 'Tables',
        value: controller.totalTables.value,
        delay: 80,
        tight: tight,
      ),
      _KpiTile(
        icon: Icons.event_seat_rounded,
        color: AppColors.secondary,
        label: 'Chaises',
        value: controller.totalChairs.value,
        delay: 160,
        tight: tight,
      ),
      _KpiTile(
        icon: Icons.perm_media_rounded,
        color: AppColors.primary,
        label: 'Médias',
        value: controller.totalMedia.value,
        delay: 240,
        tight: tight,
      ),
    ];

    return SizedBox(
      height: tight ? 78 : 88,
      child: Row(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 9),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }

  // ── Statut des invitations : donut et légende côte à côte ──
  Widget _buildInvitationStatus(HomeController controller, bool tight) {
    final total = controller.totalGuests.value;
    final pending = controller.pendingGuests.value;
    final mediaUploaded = controller.mediaUploaded.value;
    final cardUnlocked = controller.cardUnlocked.value;

    return GradientCard(
      padding: EdgeInsets.all(tight ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Statut des invitations',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleLg.copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(label: '$total total', color: AppColors.dark),
            ],
          ),
          SizedBox(height: tight ? 8 : 12),
          Expanded(
            child: Row(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final diameter = math.max(
                      86.0,
                      math.min(constraints.maxHeight, 150.0),
                    );
                    return SizedBox(
                      width: diameter,
                      height: diameter,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: Size.square(diameter),
                            painter: _DonutPainter(
                              pending: pending,
                              mediaUploaded: mediaUploaded,
                              cardUnlocked: cardUnlocked,
                              total: total,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                total.toString(),
                                style: AppTextStyles.displayMd.copyWith(
                                  fontSize: diameter * 0.24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.dark,
                                ),
                              ),
                              Text(
                                'Invités',
                                style: AppTextStyles.labelMdOnVariant.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatusLegend(
                        color: AppColors.statusPending,
                        label: 'En attente',
                        count: pending,
                      ),
                      _StatusLegend(
                        color: AppColors.statusMediaReceived,
                        label: 'Média reçu',
                        count: mediaUploaded,
                      ),
                      _StatusLegend(
                        color: AppColors.statusCardUnlocked,
                        label: 'Carte débloquée',
                        count: cardUnlocked,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions rapides : quatre raccourcis sur une ligne ──
  Widget _buildQuickActions(bool tight) {
    final actions = [
      _QuickActionCard(
        icon: Icons.person_add_rounded,
        color: AppColors.primary,
        title: 'Ajouter\nun invité',
        onTap: () => Get.find<MainNavigationController>().selectTab(
          MainNavigationController.guestsTab,
        ),
      ),
      _QuickActionCard(
        icon: Icons.table_restaurant_rounded,
        color: AppColors.dark,
        title: 'Gérer\nles tables',
        onTap: () => Get.find<MainNavigationController>().selectTab(
          MainNavigationController.tablesTab,
        ),
      ),
      _QuickActionCard(
        icon: Icons.analytics_rounded,
        color: Colors.white,
        title: 'Suivi des\ninvitations',
        onTap: () => Get.find<MainNavigationController>().selectTab(
          MainNavigationController.invitationsTab,
        ),
      ),
      _QuickActionCard(
        icon: Icons.qr_code_2_rounded,
        color: AppColors.secondary,
        title: 'QR entrée\nsalle',
        onTap: () => Get.toNamed(AppRoutes.entranceQr),
      ),
    ];

    return SizedBox(
      height: tight ? 82 : 92,
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 9),
            Expanded(child: actions[i]),
          ],
        ],
      ),
    );
  }
}

// ── Tuile compteur compacte ──
class _KpiTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int value;
  final int delay;
  final bool tight;

  const _KpiTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.delay,
    required this.tight,
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: tight ? 24 : 27,
              height: tight ? 24 : 27,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary
                    : AppColors.dark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                color: isDark ? AppColors.onPrimary : AppColors.dark,
                size: tight ? 13 : 15,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value.toString(),
                    maxLines: 1,
                    style: AppTextStyles.headlineLg.copyWith(
                      fontSize: tight ? 19 : 22,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: contentColor,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppTextStyles.labelMd.copyWith(
                      fontSize: 11,
                      color: contentColor.withValues(alpha: 0.62),
                    ),
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

// ── Légende de statut ──
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
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMdOnVariant.copyWith(fontSize: 12.5),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: AppTextStyles.bodyLg.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Raccourci compact ──
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = color.computeLuminance() < 0.35;
    final contentColor = isDark ? Colors.white : AppColors.dark;
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.dark, width: 1.25),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                color: isDark ? AppColors.onPrimary : AppColors.dark,
                size: 15,
              ),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: contentColor,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Donut du statut des invitations ──
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
    final strokeWidth = size.width * 0.13;
    final radius = size.width / 2 - strokeWidth / 2 - 2;

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
