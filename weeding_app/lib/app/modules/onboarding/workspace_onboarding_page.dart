import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/animated_widgets.dart';
import '../../core/widgets/micro_interactions.dart';
import '../../core/widgets/wedding_rings_icon.dart';
import '../auth/auth_controller.dart';
import 'workspace_onboarding_controller.dart';

class WorkspaceOnboardingPage extends StatelessWidget {
  const WorkspaceOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkspaceOnboardingController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: CustomScrollView(
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        ScaleIn(
                          delay: const Duration(milliseconds: 80),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.dark,
                                width: 1.2,
                              ),
                            ),
                            child: WeddingRingsIcon(
                              color: AppColors.onPrimary,
                              size: 24,
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: Get.find<AuthController>().logout,
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Déconnexion'),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Hero ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Créons votre\nespace mariage',
                            style: AppTextStyles.displayMd.copyWith(
                              color: AppColors.dark,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Un espace sécurisé pour votre équipe, vos lieux, '
                            'vos invités, vos cartes et votre plan de salle.',
                            style: AppTextStyles.bodyLg.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Organisation card ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 180),
                      child: _SectionCard(
                        stepNumber: 1,
                        title: 'Votre organisation',
                        child: TextField(
                          controller: controller.organizationNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nom de l\'organisation',
                            hintText: 'Ex. Mariage Aïcha & Karim',
                            prefixIcon: Icon(Icons.business_rounded),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Marriage details card ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 260),
                      child: _SectionCard(
                        stepNumber: 2,
                        title: 'Le mariage',
                        child: Column(
                          children: [
                            TextField(
                              controller: controller.eventTitleController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Titre du mariage',
                                hintText: 'Ex. Le grand jour',
                                prefixIcon:
                                    Icon(Icons.favorite_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller:
                                        controller.brideNameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      labelText: 'Nom de la mariée',
                                      prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller:
                                        controller.groomNameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      labelText: 'Nom du marié',
                                      prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Obx(() {
                              final date = controller.eventDate.value;
                              return InkWell(
                                onTap: () => _pickDate(context, controller),
                                borderRadius: BorderRadius.circular(16),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date prévue (facultatif)',
                                    prefixIcon: Icon(
                                      Icons.calendar_month_rounded,
                                    ),
                                  ),
                                  child: Text(
                                    date == null
                                        ? 'À définir plus tard'
                                        : MaterialLocalizations.of(context)
                                            .formatMediumDate(date),
                                    style: AppTextStyles.bodyLg,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Tip card ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 340),
                      child: _TipCard(),
                    ),
                  ),
                ),

                // ── CTA button ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 400),
                      child: Obx(
                        () => GradientButton(
                          label: controller.isLoading.value
                              ? 'Création en cours…'
                              : 'Créer mon espace',
                          icon: controller.isLoading.value
                              ? null
                              : Icons.arrow_forward_rounded,
                          isLoading: controller.isLoading.value,
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.createWorkspace,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WorkspaceOnboardingController controller,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          controller.eventDate.value ?? now.add(const Duration(days: 90)),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) controller.selectDate(picked);
  }
}

// ── Section Card with step number ──
class _SectionCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.stepNumber,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.dark, width: 1.25),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTextStyles.titleLg),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

// ── Tip / info card ──
class _TipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.onPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pack Essentiel gratuit',
                  style: AppTextStyles.titleLg.copyWith(
                    color: AppColors.dark,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jusqu\'à 30 invitations. Passez à un pack supérieur '
                  'à tout moment.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
