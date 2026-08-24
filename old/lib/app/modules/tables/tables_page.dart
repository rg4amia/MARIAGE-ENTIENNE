import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/wedding_bottom_nav.dart';
import '../../core/widgets/wedding_cards.dart';
import '../../core/widgets/wedding_top_bar.dart';
import '../../data/models/invitation_models.dart';
import '../../routes/app_routes.dart';
import '../home/home_controller.dart';

/// Page "Gestion des Tables & Places" reproduisant le design Stitch :
/// hero serif, recherche, statistiques bento, articles par table avec
/// chaises en grille, FAB editorial.
class TablesPage extends StatelessWidget {
  const TablesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const WeddingTopBar(),
      bottomNavigationBar: WeddingBottomNav(
        current: WeddingNavItem.tables,
        onTap: (item) {
          if (item == WeddingNavItem.tables) return;
          Get.offAllNamed(AppRoutes.home);
        },
      ),
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: kEditorialGradient,
          boxShadow: const [
            BoxShadow(
              color: Color(0x55570013),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () => Get.offAllNamed(AppRoutes.home),
          icon: const Icon(Icons.add_circle, color: Colors.white, size: 30),
        ),
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.isAdminDemoMode) ...[
                const _BackendModeNotice(),
                const SizedBox(height: 18),
              ],
              const EyebrowLabel('Configuration de la salle'),
              const SizedBox(height: 10),
              Text(
                'Gestion des\nTables & Places',
                style: GoogleFonts.notoSerif(
                  color: AppColors.primary,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 24),
              _SearchBar(),
              const SizedBox(height: 24),
              _StatsRow(controller: controller),
              const SizedBox(height: 28),
              if (controller.tables.isEmpty)
                _EmptyState(controller: controller)
              else
                ...controller.tables.map(
                  (table) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _TableArticle(table: table, controller: controller),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher un invite ou une table...',
          prefixIcon: const Icon(Icons.search, color: AppColors.outline),
          filled: true,
          fillColor: Colors.transparent,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          border: InputBorder.none,
          hintStyle: GoogleFonts.manrope(color: AppColors.outline),
        ),
      ),
    );
  }
}

class _BackendModeNotice extends StatelessWidget {
  const _BackendModeNotice();

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowLabel('Mode backend'),
          const SizedBox(height: 8),
          Text(
            "Cette page utilise encore les donnees locales de demonstration pour l'espace maries. Le backend public en production couvre surtout l'acces invite par token.",
            style: GoogleFonts.manrope(
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final totalGuests = controller.guests.length;
    final tableCount = controller.tables.length;
    final assigned = controller.tables.fold<int>(
      0,
      (s, t) => s + t.occupiedSeats,
    );
    final capacity = controller.tables.fold<int>(0, (s, t) => s + t.capacity);
    final percent = capacity == 0 ? 0.0 : assigned / capacity;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatBentoCard(
                label: 'Total invites',
                value: '$totalGuests',
                suffix: 'enregistres',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: StatBentoCard(
                label: 'Tables dressees',
                value: '$tableCount',
                suffix: 'disponibles',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        StatBentoCard(
          label: 'Placement termine',
          value: '${(percent * 100).round()}%',
          progress: percent,
          icon: Icons.check_circle,
          highlighted: true,
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(36),
      child: Column(
        children: [
          Icon(
            Icons.table_bar,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune table pour le moment',
            style: GoogleFonts.notoSerif(
              fontSize: 22,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Creez une table depuis le tableau de bord pour commencer.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          GradientButton(
            label: 'Aller au tableau de bord',
            onPressed: () => Get.offAllNamed(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}

class _TableArticle extends StatelessWidget {
  const _TableArticle({required this.table, required this.controller});

  final WeddingTable table;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final progress = table.capacity == 0
        ? 0.0
        : table.occupiedSeats / table.capacity;

    return GlowCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      table.label,
                      style: GoogleFonts.notoSerif(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Salle de reception',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 110,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${table.occupiedSeats} / ${table.capacity} places'
                        .toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: 9,
                      letterSpacing: 1.2,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: table.chairs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
            ),
            itemBuilder: (_, index) {
              final chair = table.chairs[index];
              return _ChairCell(chair: chair);
            },
          ),
        ],
      ),
    );
  }
}

class _ChairCell extends StatelessWidget {
  const _ChairCell({required this.chair});

  final ChairModel chair;

  @override
  Widget build(BuildContext context) {
    final assigned = chair.isAssigned;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: assigned
              ? AppColors.outlineVariant.withValues(alpha: 0.4)
              : AppColors.outlineVariant.withValues(alpha: 0.4),
          style: assigned ? BorderStyle.solid : BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerHighest,
              border: assigned
                  ? null
                  : Border.all(
                      color: AppColors.outlineVariant,
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
            ),
            child: Icon(
              assigned ? Icons.person : Icons.add,
              color: assigned ? AppColors.primary : AppColors.outline,
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            assigned ? 'Chaise ${chair.number}' : 'Attribuer',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: assigned
                  ? AppColors.onSurface
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
