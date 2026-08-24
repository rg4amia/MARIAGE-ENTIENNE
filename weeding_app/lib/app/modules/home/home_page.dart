import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(authController),
                const SizedBox(height: 32),

                // KPI Grid
                Obx(() => _buildKpiGrid(controller)),
                const SizedBox(height: 32),

                // Invitation Status
                Obx(() => _buildInvitationStatus(controller)),
                const SizedBox(height: 32),

                // Actions Rapides
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(0),
    );
  }

  Widget _buildHeader(AuthController authController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final name = authController.profile.value?.fullName ?? 'Marie';
          return Text(
            'Bonjour, $name 🕊️',
            style: AppTextStyles.headlineLgMobilePrimary,
          );
        }),
        const SizedBox(height: 4),
        Text(
          '${DateTime.now().day} ${_monthName(DateTime.now().month)} ${DateTime.now().year}',
          style: AppTextStyles.bodyMdOnVariant,
        ),
      ],
    );
  }

  Widget _buildKpiGrid(HomeController controller) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _KpiCard(
          icon: Icons.group,
          iconColor: AppColors.primaryContainer,
          label: 'Invités',
          value: controller.totalGuests.value.toString(),
        ),
        _KpiCard(
          icon: Icons.table_restaurant,
          iconColor: AppColors.tertiary,
          label: 'Tables',
          value: controller.totalTables.value.toString(),
        ),
        _KpiCard(
          icon: Icons.event_seat,
          iconColor: AppColors.secondaryContainer,
          label: 'Chaises',
          value: controller.totalChairs.value.toString(),
        ),
        _KpiCard(
          icon: Icons.perm_media,
          iconColor: AppColors.primary,
          label: 'Médias reçus',
          value: controller.totalMedia.value.toString(),
        ),
      ],
    );
  }

  Widget _buildInvitationStatus(HomeController controller) {
    final total = controller.totalGuests.value;
    final pending = controller.pendingGuests.value;
    final mediaUploaded = controller.mediaUploaded.value;
    final cardUnlocked = controller.cardUnlocked.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statut des invitations', style: AppTextStyles.titleLg),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Donut chart placeholder
                    CircularProgressIndicator(
                      value: total > 0 ? 1.0 : 0,
                      strokeWidth: 20,
                      backgroundColor: AppColors.secondaryFixedDim,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryContainer,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          total.toString(),
                          style: AppTextStyles.displayMdPrimary,
                        ),
                        Text('Total', style: AppTextStyles.labelMdOnVariant),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _StatusLegend(
              color: AppColors.secondaryFixedDim,
              label: 'En attente',
              count: pending,
            ),
            const SizedBox(height: 8),
            _StatusLegend(
              color: AppColors.tertiaryContainer,
              label: 'Média reçu',
              count: mediaUploaded,
            ),
            const SizedBox(height: 8),
            _StatusLegend(
              color: AppColors.primaryContainer,
              label: 'Carte débloquée',
              count: cardUnlocked,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions Rapides', style: AppTextStyles.titleLgPrimary),
            const SizedBox(height: 16),
            _ActionTile(
              icon: Icons.person_add,
              iconBg: AppColors.primaryFixed,
              iconColor: AppColors.primaryContainer,
              title: 'Ajouter un invité',
              onTap: () => Get.toNamed(AppRoutes.guests),
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.qr_code_scanner,
              iconBg: AppColors.secondaryFixed,
              iconColor: AppColors.secondary,
              title: 'Gérer les tables',
              onTap: () => Get.toNamed(AppRoutes.tables),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            break; // déjà sur home
          case 1:
            Get.toNamed(AppRoutes.guests);
            break;
          case 2:
            Get.toNamed(AppRoutes.tables);
            break;
          case 3:
            Get.toNamed(AppRoutes.invitations);
            break;
          case 4:
            Get.toNamed(AppRoutes.settings);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          activeIcon: Icon(Icons.home, fill: 1.0),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          activeIcon: Icon(Icons.group, fill: 1.0),
          label: 'Invités',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.table_restaurant),
          activeIcon: Icon(Icons.table_restaurant, fill: 1.0),
          label: 'Tables',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_2),
          activeIcon: Icon(Icons.qr_code_2, fill: 1.0),
          label: 'Invitations',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          activeIcon: Icon(Icons.more_horiz, fill: 1.0),
          label: 'Plus',
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month];
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.labelMd,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: AppTextStyles.displayMdPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.bodyMdOnVariant),
          ],
        ),
        Text(
          count.toString(),
          style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBg.withAlpha(77),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: AppTextStyles.bodyLg),
      trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outlineVariant, width: 0.5),
      ),
    );
  }
}
